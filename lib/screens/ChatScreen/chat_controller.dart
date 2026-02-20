import 'package:macroaize/shared/widgets/premium_required_dialog.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:macroaize/Model/main_chat_model.dart';
import 'package:macroaize/Model/subchat_model.dart';
import 'package:macroaize/constant/database_helper.dart';
import 'package:macroaize/shared/services/usage_service.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import 'package:macroaize/shared/services/app_user_service.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:macroaize/features/auth/presentation/auth_modal.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../main_controller.dart';
import '../../Model/chat_model.dart';
import '../../Model/ai_model.dart';
import 'package:macroaize/shared/services/app_config_service.dart';
import '../../constant/font_family.dart';
import '../../widgets/cropper_ui_settings.dart';
import '../../shared/services/rate_us_service.dart';

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
  bool isSending = false; // New state to track sending status
  String streamedText = "";
  bool speechEnabled = false;
  int mainChatId = 0;
  String selectedReason = "Wrong answer";
  bool isMainChat = true;
  int? rateLimitRemaining;
  DateTime? rateLimitReset;
  bool get isRateLimited =>
      rateLimitRemaining != null &&
      rateLimitRemaining! <= 0 &&
      rateLimitReset != null &&
      DateTime.now().isBefore(rateLimitReset!);

  final _usageService = UsageService();
  final _appUserService = AppUserService();

  @override
  void onInit() {
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
    try {
      speechEnabled = await speech.initialize();
    } catch (_) {
      speechEnabled = false;
    }
    update();
  }

  void sendMsg({required String text}) async {
    // 1. Prevent multiple sends
    if (isSending) return;

    if (text.isEmpty) return;

    // 2. Optimistic Update
    isSending = true;
    text = text.trim();
    final String textToSend = text; // Keep a copy
    controller.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    // Add user message immediately
    if (messages.isEmpty) {
      isMainChat = true;
    } else {
      isMainChat = false;
    }
    messages.insert(0, ChatModel(true, textToSend, imagePath?.path, false));

    // Add "Typing..." placeholder immediately
    isStreamedText = true;
    streamedText = ""; // Start empty or with "..."
    messages.insert(
      0,
      ChatModel(false, "", imagePath?.path, false),
    ); // Placeholder
    isTyping = true; // Trigger typing animation if used

    // Capture image before clearing
    File? sentImage = imagePath;
    imagePath = null; // Clear immediately from UI

    update(); // Update UI to show messages

    // Scroll to bottom
    await Future.delayed(const Duration(milliseconds: 50));
    scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    try {
      // 3. Perform Checks (Auth, Account, Rate Limit)
      if (!_appUserService.checkAccountActivation('chat')) {
        _revertOptimisticUI();
        return;
      }

      if (isRateLimited) {
        _revertOptimisticUI();
        NotificationService.showError(
          rateLimitReset != null
              ? "Rate limit reached. Try again after ${rateLimitReset!.hour.toString().padLeft(2, '0')}:${rateLimitReset!.minute.toString().padLeft(2, '0')}."
              : "Rate limit reached. Please try later.",
        );
        return;
      }

      try {
        final result = await _usageService.incrementUsage('chat');

        if (!result.success) {
          _revertOptimisticUI();
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
        _revertOptimisticUI();
        // redirect to login if actually unauthenticated
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

      // 4. Prepare API Call
      update();

      // Build History (Last 10 messages, excluding current user message and placeholder)
      // Current state: [Placeholder, UserMsg, ...History...]
      final history = messages.skip(2).take(10).toList().reversed.toList();
      List<Map<String, dynamic>> contextMessages = [];

      for (var msg in history) {
        contextMessages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        });
      }

      final langName = Get.find<MainController>().getLanguageName();
      final systemPrompt =
          "You are the MacroAize AI Coach, an expert in food nutrition and tracking for the MacroAize app. "
          "Your goal is to help users track their meals, understand nutrition, and reach their health goals. "
          "Be concise, encouraging, and helpful. "
          "If asked about yourself, strictly identify as the MacroAize AI Coach. "
          "Reply ONLY in $langName.";

      if (sentImage != null) {
        File imageDemo = sentImage;
        final bytes = await imageDemo.readAsBytes();
        final base64Image = base64Encode(bytes);

        final parameters = {
          'model': Get.find<AppConfigService>().aiModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...contextMessages,
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': textToSend},
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
        final raw = responseData.data;
        final normalized = jsonDecode(jsonEncode(raw));
        final decodedJson =
            (normalized is String) ? jsonDecode(normalized) : normalized;

        try {
          if (decodedJson is Map && decodedJson['error'] != null) {
            final errMsg = decodedJson['error']['message'] ?? 'Unknown error';
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
                    question: textToSend,
                    answer: answer,
                    date: DateTime.now().toString(),
                  ),
                );
              }
              await dbHelper.insertSubChatModel(
                SubChatModel(
                  question: textToSend,
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
        // isSending = false; // Will set at end
        update();
        RateUsService.showRateUsIfEligible(RateUsService.actionChat);
      } else {
        final parameters = {
          'model': Get.find<AppConfigService>().aiModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...contextMessages,
            {'role': 'user', 'content': textToSend},
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
            final errMsg = decodedJson['error']['message'] ?? 'Unknown error';
            messages.first = ChatModel(false, errMsg.toString(), null, true);
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
                    question: textToSend,
                    answer: answer,
                    date: DateTime.now().toString(),
                  ),
                );
              }
              await dbHelper.insertSubChatModel(
                SubChatModel(
                  question: textToSend,
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
        // isSending = false; // Will set at end
        update();
        RateUsService.showRateUsIfEligible(RateUsService.actionChat);
      }

      await Future.delayed(const Duration(milliseconds: 100));
      scrollController.animateTo(
        0.0,
        duration: const Duration(seconds: 1),
        curve: Curves.easeOut,
      );
    } catch (err) {
      // 5. General Error Handling
      // If we failed after adding the optimistic message, remove it or show error
      // Since we already added messages, let's keep the user message but remove placeholder/error

      // If we are here, it means something went wrong during API call mostly
      NotificationService.showError('hmm_something_went_wrong');
      if (kDebugMode) {
        print("ERROR $err");
      }

      // Remove the typing placeholder we added
      if (messages.isNotEmpty && isStreamedText) {
        messages.removeAt(0); // Remove typing placeholder
      }
      // If we want to remove the user message too:
      if (messages.isNotEmpty && messages.first.isUser) {
        messages.removeAt(0); // Remove user message if failed completely
        // Restore text?
        controller.text = text;
      }

      imagePath = null;
      streamedText = "";
      isStreamedText = false;
      update();
    } finally {
      isSending = false;
      isTyping = false; // Stop typing animation
      update();
    }
  }

  void _revertOptimisticUI() {
    isSending = false;
    isTyping = false;
    isStreamedText = false;
    streamedText = "";

    // We added 2 messages: user msg and placeholder
    if (messages.isNotEmpty) messages.removeAt(0); // Placeholder
    if (messages.isNotEmpty) messages.removeAt(0); // User message

    imagePath = null;
    update();
  }

  takeImage(ImageSource source, BuildContext context) async {
    // premium check
    try {
      final appUserService = Get.find<AppUserService>();
      final isPremium = await appUserService.isPremiumNow();
      if (!isPremium) {
        _showImageAttachmentPremiumDialog();
        return;
      }
    } catch (_) {
      // fail closed
      _showImageAttachmentPremiumDialog();
      return;
    }

    XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      File imagePath = File(image.path);
      update();
      if (!context.mounted) return;
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
    super.onClose();
  }

  void startListening() async {
    if (!speechEnabled) {
      await _initSpeech();
      if (!speechEnabled) return;
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
    // Give the speech recognizer a short moment to deliver any final result
    // Some devices or engines deliver the final chunk slightly after stop()
    int tries = 0;
    while (!_lastResultIsFinal && tries < 8) {
      await Future.delayed(const Duration(milliseconds: 100));
      tries++;
    }

    recording = false;
    soundLevel = 0.0;
    _lastResultIsFinal = false;

    // only send if heard speech
    if (_heardSpeech && speechToText.trim().isNotEmpty) {
      final textToSend = speechToText.trim();
      speechToText = "";
      _heardSpeech = false;
      sendMsg(text: textToSend);
    } else {
      update();
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    speechToText = result.recognizedWords;
    try {
      if (result.recognizedWords.trim().isNotEmpty) {
        _heardSpeech = true;
      }
    } catch (_) {}
    try {
      _lastResultIsFinal = result.finalResult;
    } catch (_) {}
    update();
  }

  void _onSoundLevelChange(double level) {
    // normalize to 0..1
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
                      SizedBox(width: 48),

                      Text(
                        'Help us do better',
                        style: context.textTheme.headlineMedium,
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.close,
                          color: context.theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  RadioGroup<String>(
                    groupValue: selectedReason,
                    onChanged: (String? value) {
                      if (value != null) {
                        selectedReason = value;
                        update();
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: Text(
                            'Wrong answer',
                            style: context.textTheme.titleSmall,
                          ),
                          value: 'Wrong answer',
                          activeColor: context.theme.focusColor,
                        ),
                        RadioListTile<String>(
                          title: Text(
                            'Unsatisfactory explanation',
                            style: context.textTheme.titleSmall,
                          ),
                          value: 'Unsatisfactory explanation',
                          activeColor: context.theme.focusColor,
                        ),
                      ],
                    ),
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
                      NotificationService.showInfo('Thanks');
                      selectedReason = "Wrong answer";
                      feedController.clear();
                      messages.removeRange(index, index + 2);
                      update();
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

  Future<void> _handleAuthenticationRequired() async {
    final success = await AuthModal.show();

    if (success) {
      Get.snackbar(
        'success'.tr,
        'auth_chat_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'auth_chat_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
