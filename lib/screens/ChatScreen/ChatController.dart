import 'package:foodcalorietracker/shared/widgets/PremiumRequiredDialog.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:foodcalorietracker/Model/MainChatModel.dart';
import 'package:foodcalorietracker/Model/SubchatModel.dart';
import 'package:foodcalorietracker/constant/DatabaseHelper.dart';
import 'package:foodcalorietracker/shared/services/usage_service.dart';
import 'package:foodcalorietracker/shared/services/notification_service.dart';
import 'package:foodcalorietracker/shared/services/app_user_service.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:foodcalorietracker/features/auth/presentation/auth_modal.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../MainController.dart';
import '../../Model/ChatModel.dart';
import '../../Model/openAIModel.dart';
import 'package:foodcalorietracker/shared/services/app_config_service.dart';
import '../../constant/FontFamily.dart';
import '../../widgets/CropperUiSettings.dart';

class ChatController extends GetxController {
  Map<String, dynamic>? argument = Get.arguments;
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
  bool get isRateLimited =>
      rateLimitRemaining != null &&
      rateLimitRemaining! <= 0 &&
      rateLimitReset != null &&
      DateTime.now().isBefore(rateLimitReset!);

  // Add usage service and app user service
  final _usageService = UsageService();
  final _appUserService = AppUserService();

  // Rate-limit headers were only applicable to direct HTTP calls; removed in callable flow

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    if (argument != null) {
      if (argument!['mainChatId'] != null) {
        isMainChat = false;
        mainChatId = argument!['mainChatId'];
        getHistory();
      } else {
        imagePath = argument!['image'];
      }
    }
  }

  getHistory() async {
    List<SubChatModel> data = await dbHelper.getSubChat(mainChatId);
    for (var element in data) {
      messages.insert(
        0,
        ChatModel(true, element.question, element.image, false),
      );
      messages.insert(0, ChatModel(false, element.answer, element.image, true));
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
      // ACCOUNT ACTIVATION GATING: Check if account is activated before allowing chat
      if (!_appUserService.checkAccountActivation('chat')) {
        return;
      }

      if (isRateLimited) {
        Fluttertoast.showToast(
          msg:
              rateLimitReset != null
                  ? "Rate limit reached. Try again after ${rateLimitReset!.hour.toString().padLeft(2, '0')}:${rateLimitReset!.minute.toString().padLeft(2, '0')}."
                  : "Rate limit reached. Please try later.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          fontSize: 12.0,
        );
        return;
      }

      if (text.isNotEmpty) {
        // SECURE FEATURE GATING: Check chat usage before proceeding
        // This includes authentication AND email verification checks
        try {
          final result = await _usageService.incrementUsage('chat');

          if (!result.success) {
            // Usage limit reached -> show centralized notification
            if (result.limitReached) {
              NotificationService.showError(
                result.message.isNotEmpty
                    ? result.message
                    : 'daily_chat_limit_reached',
              );
            } else {
              NotificationService.showError('unable_to_send_message_try_again');
            }
            return;
          }
        } catch (e) {
          // Only redirect to login if actually unauthenticated; otherwise show error.
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            await _handleAuthenticationRequired();
            return;
          }

          final el = e.toString().toLowerCase();
          if (el.contains('limit') ||
              el.contains('permission-denied') ||
              el.contains('daily')) {
            NotificationService.showError('daily_limit_reached_try_again');
            return;
          }

          NotificationService.showError('unable_to_send_message_try_again');
          return;
        }
        // Usage allowed - proceed with chat
        text = text.trim();
        controller.clear();
        FocusManager.instance.primaryFocus?.unfocus();
        isTyping = true;
        if (messages.isEmpty) {
          isMainChat = true;
        } else {
          isMainChat = false;
        }
        messages.insert(0, ChatModel(true, text, imagePath?.path, false));
        isStreamedText = true;
        messages.insert(0, ChatModel(false, "", imagePath?.path, false));
        update();

        if (imagePath != null) {
          File imageDemo = imagePath!;
          imagePath = null;
          final bytes = await imageDemo.readAsBytes();
          final base64Image = base64Encode(bytes);
          update();
          final parameters = {
            'model': Get.find<AppConfigService>().aiModel,
            'messages': [
              {
                'role': 'system',
                'content':
                    "You are a food nutrition expert AI. Reply ONLY in ${Get.find<MainController>().language} language unless told otherwise.",
              },
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': text},
                  {
                    'type': 'image_url',
                    'image_url': {'url': "data:image/jpeg;base64,$base64Image"},
                  },
                ],
              },
            ],
            'max_tokens': 500,
          };

          final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
          final callable = functions.httpsCallable('chatWithOpenRouter');
      final responseData = await callable.call(parameters);
      // Normalize function result: it can be a Map or a JSON string
      final raw = responseData.data;
      final normalized = jsonDecode(jsonEncode(raw));
      final decodedJson =
        (normalized is String) ? jsonDecode(normalized) : normalized;

      // No HTTP status here; treat as success and handle error field if present
      try {
              if (decodedJson is Map && decodedJson['error'] != null) {
                final errMsg =
                    decodedJson['error']['message'] ?? 'Unknown error';
                messages.first = ChatModel(
                  false,
                  errMsg.toString(),
                  imageDemo.path,
                  true,
                );
              } else {
                OpenAiModel data = OpenAiModel.fromJson(decodedJson);
                final answer =
                    data.choices?.isNotEmpty == true
                        ? (data.choices!.first.message?.content ?? "")
                        : "No response";
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
        print('Body: $decodedJson');
              }
              messages.first = ChatModel(
                false,
                'Parse error',
                imageDemo.path,
                true,
              );
      }
          streamedText = "";
          isStreamedText = false;
          update();
        } else {
          // Text-only messages via OpenRouter HTTP API
          final parameters = {
            'model': Get.find<AppConfigService>().aiModel,
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a Food Tracker expert. Reply ONLY in ${Get.find<MainController>().language}.',
              },
              {'role': 'user', 'content': text},
            ],
            'max_tokens': 500,
          };
          final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
          final callable = functions.httpsCallable('chatWithOpenRouter');
      final result = await callable.call(parameters);
      final raw = result.data;
      final normalized = jsonDecode(jsonEncode(raw));
      final decodedJson =
        (normalized is String) ? jsonDecode(normalized) : normalized;
      try {
              if (decodedJson is Map && decodedJson['error'] != null) {
                final errMsg =
                    decodedJson['error']['message'] ?? 'Unknown error';
                messages.first = ChatModel(
                  false,
                  errMsg.toString(),
                  null,
                  true,
                );
              } else {
                OpenAiModel data = OpenAiModel.fromJson(decodedJson);
                final answer =
                    data.choices?.isNotEmpty == true
                        ? (data.choices!.first.message?.content ?? "")
                        : "No response";
                messages.first = ChatModel(false, answer, null, true);
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
                    ),
                  );
                }
              }
      } catch (e) {
              if (kDebugMode) {
        print('Decode/text branch error: $e');
        print('Body: $decodedJson');
              }
              messages.first = ChatModel(false, 'Parse error', null, true);
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
      // Centralized error notification for unexpected failures
      NotificationService.showError('hmm_something_went_wrong');

      // Print Error debug mode
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
    // Check if user has premium access for image attachments
    try {
      final appUserService = Get.find<AppUserService>();
      final isPremium = await appUserService.isPremiumNow();
      if (!isPremium) {
        _showImageAttachmentPremiumDialog();
        return;
      }
    } catch (_) {
      // Fail closed on any error
      _showImageAttachmentPremiumDialog();
      return;
    }

    // Premium user - proceed with image selection
    XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      File imagePath = File(image.path);
      update();
      await cropImage(imagePath, context);
    }
  }

  void _showImageAttachmentPremiumDialog() {
    Get.dialog(
      PremiumRequiredDialog(
        title: 'premium_required'.tr,
        message: 'chat_image_premium_message'.tr,
        badge: Text(
          'chat_image_premium_badge'.tr,
          textAlign: TextAlign.center,
          style: Get.textTheme.bodyMedium?.copyWith(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
        onUpgrade: () {
          Get.back();
          Get.toNamed(Routes.premiumView);
        },
        onCancel: () => Get.back(),
      ),
    );
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
    await speech.listen(
      onResult: _onSpeechResult,
      onSoundLevelChange: _onSoundLevelChange,
    );
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

  showFeedbackSheet(BuildContext context, int index) {
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
          child: GetBuilder<ChatController>(
            builder: (controller) {
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
                          Navigator.pop(context); // User dismissed manually
                        },
                        icon: Icon(
                          Icons.close,
                          color: context.theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  RadioListTile<String>(
                    title: Text(
                      'Wrong answer',
                      style: context.textTheme.titleSmall,
                    ),
                    value: 'Wrong answer',
                    groupValue: selectedReason,
                    activeColor: context.theme.focusColor,
                    onChanged: (value) {
                      selectedReason = value!;
                      update();
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(
                      'Unsatisfactory explanation',
                      style: context.textTheme.titleSmall,
                    ),
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
                    style: TextStyle(color: Colors.black),
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
                      messages.removeRange(index, index + 2);
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
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // chat limit dialog replaced by NotificationService.showError

  Future<void> _handleAuthenticationRequired() async {
    // Show authentication modal
    final success = await AuthModal.show();

    if (success) {
      // User logged in successfully - show success message
      Get.snackbar(
        'Welcome!',
        'You can now use the chat. Please try sending your message again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      // User cancelled or failed to login
      Get.snackbar(
        'Authentication Required',
        'Please login to use the chat feature',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
