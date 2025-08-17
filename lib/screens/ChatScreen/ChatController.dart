import 'dart:convert';
import 'dart:io';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:foodcalorietracker/Model/MainChatModel.dart';
import 'package:foodcalorietracker/Model/SubchatModel.dart';
import 'package:foodcalorietracker/constant/DatabaseHelper.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../MainController.dart';
import '../../Model/ChatModel.dart';
import '../../Model/openAIModel.dart';
import '../../constant/Appkey.dart';
import '../../constant/FontFamily.dart';
import '../../widgets/CropperUiSettings.dart';

class ChatController extends GetxController {
  Map<String,dynamic>? argument = Get.arguments;
  bool recording = false;
  double soundLevel = 0.0;
  bool _lastResultIsFinal = false;
  bool _heardSpeech = false;
  TextEditingController controller = TextEditingController();
  ScrollController scrollController = ScrollController();
  TextEditingController feedController = TextEditingController();
  List<ChatModel> messages = [];
  final ImagePicker _picker = ImagePicker();
  String speechToText = "";
  final SpeechToText speech = SpeechToText();
  final dbHelper = DatabaseHelper();
  File? imagePath;
  bool isStreamedText = false;
  bool isTyping = false;
  String streamedText = "";
  bool speechEnabled = false;
  int mainChatId = 0;
  String selectedReason = "Wrong answer";
  bool isMainChat = true;
  // Rate limit tracking
  int? rateLimitRemaining;
  DateTime? rateLimitReset;
  bool get isRateLimited => rateLimitRemaining != null && rateLimitRemaining! <= 0 && rateLimitReset != null && DateTime.now().isBefore(rateLimitReset!);

  void _applyRateLimitHeaders(http.Response response){
    try {
      final remainingStr = response.headers['x-ratelimit-remaining'];
      final resetStr = response.headers['x-ratelimit-reset'];
      if(remainingStr != null){
        rateLimitRemaining = int.tryParse(remainingStr);
      }
      if(resetStr != null){
        // Could be milliseconds or seconds epoch
        int? raw = int.tryParse(resetStr);
        if(raw != null){
          if(raw > 9999999999){
            // milliseconds
            rateLimitReset = DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true).toLocal();
          }else{
            // seconds
            rateLimitReset = DateTime.fromMillisecondsSinceEpoch(raw*1000, isUtc: true).toLocal();
          }
        }
      }
    } catch(_){/* ignore parsing issues */}
  }


  @override
  void onInit() {
    OpenAI.apiKey = apiKey;

    // TODO: implement onInit

    super.onInit();
    if(argument != null)
    {
      if(argument!['mainChatId'] != null)
      {
        isMainChat = false;
        mainChatId = argument!['mainChatId'];
        getHistory();
      }else{
        imagePath = argument!['image'];
      }
    }
  }
  getHistory()
  async {
    List<SubChatModel> data = await dbHelper.getSubChat(mainChatId);
    for (var element in data) {
      messages.insert(0, ChatModel(true,element.question,element.image,false));
      messages.insert(0, ChatModel(false,element.answer,element.image,true));
    }
    update();
  }

  Future<void> _initSpeech() async {
    // Initialize speech only on demand to avoid permission prompt at app start
    try {
      speechEnabled = await speech.initialize();
    } catch (_) {
      speechEnabled = false;
    }
    update();
  }

  void sendMsg({required String text}) async {
    try {
      if(isRateLimited){
        Fluttertoast.showToast(
          msg: rateLimitReset != null ? "Rate limit reached. Try again after ${rateLimitReset!.hour.toString().padLeft(2,'0')}:${rateLimitReset!.minute.toString().padLeft(2,'0')}." : "Rate limit reached. Please try later.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          fontSize: 12.0,
        );
        return;
      }
      if (text.isNotEmpty) {
        text = text.trim();
        controller.clear();
        FocusManager.instance.primaryFocus?.unfocus();
        isTyping = true;
        if(messages.isEmpty)
        {
          isMainChat = true;
        }else{
          isMainChat = false;
        }
        messages.insert(0, ChatModel(true, text, imagePath?.path,false));
        isStreamedText = true;
        messages.insert(0, ChatModel(false, "", imagePath?.path,false));
        update();

        if (imagePath != null) {
          File imageDemo = imagePath!;
          imagePath = null;
        final bytes = await imageDemo.readAsBytes();
        final base64Image = base64Encode(bytes);
        update();
        final headers = {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'YOUR_APP_URL', // Optional, for OpenRouter analytics
          'X-Title': 'Food Calorie Tracker', // Optional, for OpenRouter analytics
        };
        final parameters = {
          'model': "qwen/qwen2.5-vl-72b-instruct:free",
          'messages': [
            {
              'role': 'system',
              'content': "You are a food nutrition expert AI. Reply ONLY in ${Get.find<MainController>().language} language unless told otherwise.",
            },
            {
              'role': 'user',
              'content': [
                { 'type': 'text', 'text': text },
                { 'type': 'image_url', 'image_url': { 'url': "data:image/jpeg;base64,$base64Image" } },
              ],
            }
          ],
          'max_tokens': 500,
        };

          final client = http.Client();
          String apiEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
          final request = http.Request('POST', Uri.parse(apiEndpoint))
            ..headers.addAll(headers)
            ..body = jsonEncode(parameters);

          final streamedResponse = await client.send(request);
          final response = await http.Response.fromStream(streamedResponse);

          _applyRateLimitHeaders(response);
          if (response.statusCode == 200) {
            try {
              final decodedJson = jsonDecode(response.body);
              if (decodedJson is Map && decodedJson['error'] != null) {
                final errMsg = decodedJson['error']['message'] ?? 'Unknown error';
                messages.first = ChatModel(false, errMsg.toString(), imageDemo.path, true);
              } else {
                OpenAiModel data = OpenAiModel.fromJson(decodedJson);
                final answer = data.choices?.isNotEmpty == true ? (data.choices!.first.message?.content ?? "") : "No response";
                messages.first = ChatModel(false, answer, imageDemo.path, true);
                if (answer.isNotEmpty) {
                  if (isMainChat) {
                    mainChatId = await dbHelper.insertMainChatModel(
                      MainChatModel(
                        question: text,
                        answer: answer,
                        date: DateTime.now().toString(),
                      ),
                    );
                  }
                  await dbHelper.insertSubChatModel(
                    SubChatModel(
                      question: text,
                      answer: answer,
                      date: DateTime.now().toString(),
                      mainCharId: mainChatId,
                      image: imageDemo.path,
                    ),
                  );
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('Decode/image branch error: $e');
                print('Body: ${response.body}');
              }
              messages.first = ChatModel(false, 'Parse error', imageDemo.path, true);
            }
          } else {
            _applyRateLimitHeaders(response);
            if (kDebugMode) {
              print('Image chat error ${response.statusCode}: ${response.body}');
            }
            String errText = 'Error ${response.statusCode}';
            if(response.statusCode == 429){
              try{final j=jsonDecode(response.body); errText = j['error']?['message']??errText;}catch(_){}
            }
            messages.first = ChatModel(false, errText, imageDemo.path, true);
          }
          streamedText = "";
          isStreamedText = false;
          update();
        } else {
          // Text-only messages via OpenRouter HTTP API
          final headers = {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'YOUR_APP_URL',
            'X-Title': 'Food Calorie Tracker',
          };
          final parameters = {
            'model': 'qwen/qwen2.5-vl-72b-instruct:free',
            'messages': [
              {
                'role': 'system',
                'content': 'You are a Food Tracker expert. Reply ONLY in ${Get.find<MainController>().language}.',
              },
              {
                'role': 'user',
                'content': text,
              },
            ],
            'max_tokens': 500,
          };
          final response = await http.post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: headers,
            body: jsonEncode(parameters),
          );
          _applyRateLimitHeaders(response);
          if (response.statusCode == 200) {
            try {
              final decodedJson = jsonDecode(response.body);
              if (decodedJson is Map && decodedJson['error'] != null) {
                final errMsg = decodedJson['error']['message'] ?? 'Unknown error';
                messages.first = ChatModel(false, errMsg.toString(), null, true);
              } else {
                OpenAiModel data = OpenAiModel.fromJson(decodedJson);
                final answer = data.choices?.isNotEmpty == true ? (data.choices!.first.message?.content ?? "") : "No response";
                messages.first = ChatModel(false, answer, null, true);
                if (answer.isNotEmpty) {
                  if (isMainChat) {
                    mainChatId = await dbHelper.insertMainChatModel(
                      MainChatModel(question: text, answer: answer, date: DateTime.now().toString()),
                    );
                  }
                  await dbHelper.insertSubChatModel(
                    SubChatModel(question: text, answer: answer, date: DateTime.now().toString(), mainCharId: mainChatId),
                  );
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('Decode/text branch error: $e');
                print('Body: ${response.body}');
              }
              messages.first = ChatModel(false, 'Parse error', null, true);
            }
          } else {
            _applyRateLimitHeaders(response);
            if (kDebugMode) {
              print('Text chat error ${response.statusCode}: ${response.body}');
            }
            String errText = 'Error ${response.statusCode}';
            if(response.statusCode == 429){
              try{final j=jsonDecode(response.body); errText = j['error']?['message']??errText;}catch(_){errText='Rate limit exceeded. Try later.';}
            }
            messages.first = ChatModel(false, errText, null, true);
          }
          streamedText = "";
          isStreamedText = false;
          update();
        }

        await Future.delayed(const Duration(milliseconds: 100));
        scrollController.animateTo(
          0.0,
          duration: const Duration(seconds: 1),
          curve: Curves.easeOut,
        );
      }
    } catch (err) {
      /// Show Error Toast USER
      Fluttertoast.showToast(
        msg: "Hmm...something seems to have gone wrong.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        fontSize: 12.0,
      );

      /// Print Error debug mode
      if (kDebugMode) {
        print("ERROR $err");
      }
      isTyping = false;
      imagePath = null;
      streamedText = "";
      isStreamedText = false;
      messages.removeAt(0);
      update();
    }
  }

  takeImage(ImageSource source, BuildContext context) async {
    XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      File imagePath = File(image.path);
      update();
      await cropImage(imagePath, context);
    }
  }

  Future<void> cropImage(final image, BuildContext context) async {
    update();
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: cropperUiSettings(context),
      );
      if (croppedFile != null) {
        imagePath = File(croppedFile.path);
        update();
      } else {
        update();
      }
    }
  }

  @override
  void onClose() {
    controller.dispose();
    scrollController.dispose();
    // TODO: implement onClose
    super.onClose();
  }

  void startListening() async {
  // Prepare a fresh listening session: clear previous transcript and flags
  if (!speechEnabled) {
    await _initSpeech();
    if (!speechEnabled) return; // can't start if init failed/denied
  }
  speechToText = "";
  _heardSpeech = false;
  _lastResultIsFinal = false;
  await speech.listen(onResult: _onSpeechResult, onSoundLevelChange: _onSoundLevelChange);
  recording = true;
  update();
  }

  void stopListening(BuildContext context) async {
    await speech.stop();
    // Give the speech recognizer a short moment to deliver any final result.
    // Some devices or engines deliver the final chunk slightly after stop().
    int tries = 0;
    while (!_lastResultIsFinal && tries < 8) {
      await Future.delayed(const Duration(milliseconds: 100));
      tries++;
    }

    recording = false;
    soundLevel = 0.0;
    // reset the final flag for next session
    _lastResultIsFinal = false;

    // Only send if this listening session actually captured speech. This avoids
    // re-sending the previous message when the user starts/stops without speaking.
    if (_heardSpeech && speechToText.trim().isNotEmpty) {
      final textToSend = speechToText.trim();
      // clear buffer so it won't be reused accidentally
      speechToText = "";
      _heardSpeech = false;
      sendMsg(text: textToSend);
    } else {
      // No new speech captured; update UI but do not send.
      update();
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    speechToText = result.recognizedWords;
    // mark that we heard something in this session
    try {
      if (result.recognizedWords.trim().isNotEmpty) {
        _heardSpeech = true;
      }
    } catch (_) {}
    // record whether this result was the final chunk so stopListening can wait
    try {
      _lastResultIsFinal = result.finalResult;
    } catch (_) {
      // some implementations may not expose finalResult; ignore
    }
    update();
  }

  void _onSoundLevelChange(double level) {
  // speech_to_text provides a sound level in a device-dependent range; normalize to 0..1
  final normalized = (level / 10.0).clamp(0.0, 1.0);
  soundLevel = normalized;
    update();
  }

  removeImage() {
    imagePath = null;
    update();
  }
  showFeedbackSheet(BuildContext context,int index)  {

    showModalBottomSheet(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 10,
          ),
          child: GetBuilder<ChatController>(builder: (controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 48), // balance left-right IconButton

                    Text(
                      'Help us do better',
                      style: context.textTheme.headlineMedium,
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context,); // User dismissed manually
                      },
                      icon: Icon(Icons.close, color: context.theme.primaryColor),
                    ),
                  ],
                ),
                RadioListTile<String>(
                  title: Text('Wrong answer',
                      style: context.textTheme.titleSmall),
                  value: 'Wrong answer',
                  groupValue: selectedReason,
                  activeColor: context.theme.focusColor,
                  onChanged: (value) {
                    selectedReason = value!;
                    update();
                  },
                ),
                RadioListTile<String>(
                  title: Text('Unsatisfactory explanation',
                      style: context.textTheme.titleSmall),
                  value: 'Unsatisfactory explanation',
                  groupValue: selectedReason,
                  activeColor: context.theme.focusColor,
                  onChanged: (value) {
                    selectedReason = value!;
                    update();
                  },
                ),
                TextField(
                  controller: feedController,
                  style:TextStyle(color: Colors.black),
                  cursorColor: context.theme.focusColor,
                  decoration: InputDecoration(
                    hintText: 'Correction or advice...',
                    filled: true,
                    fillColor: Colors.grey[300],
                    hintStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Fluttertoast.showToast(msg: 'Thanks');
                    selectedReason = "Wrong answer";
                    feedController.clear();
                    messages.removeRange(index, index+2);
                    update();
                    // Return true on submit
                  },
                  child: Container(
                    margin: EdgeInsets.all(10),
                    alignment: Alignment.center,
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.theme.focusColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Submit",
                      style: TextStyle(
                          fontFamily: poppins,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white),
                    ),
                  ),
                )
              ],
            );
          }),
        );
      },
    );
  }
}
