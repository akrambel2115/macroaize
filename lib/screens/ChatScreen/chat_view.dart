import 'dart:io';
import 'package:flutter/material.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/constant/font_family.dart';
import 'package:macroaize/screens/ChatScreen/chat_controller.dart';
import 'package:macroaize/shared/services/subscription_service.dart';
import 'package:macroaize/shared/models/subscription.dart';
import 'package:macroaize/widgets/app_widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/voice_visualizer.dart';
import '../../widgets/chat_widget.dart';
import '../../SharePrefHelper/share_pref.dart';
import '../../SharePrefHelper/share_pref_key.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  OverlayEntry? _chatNoticeEntry;
  late final ChatController controller = Get.find();
  static const double _kActionGap = 6.0;
  static const double _kActionButtonSize = 44.0;
  static const double _kGallerySize = _kActionButtonSize + (_kActionGap * 2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: AppWidgets.backButton(context, () {
          Get.back();
        }),
        backgroundColor: context.theme.scaffoldBackgroundColor,
        title: Text("Ask Coach".tr, style: context.textTheme.headlineMedium),
        actions: [
          IconButton(
            tooltip: 'Show chat notice'.tr,
            onPressed: () async {
              // Remove existing entry first to avoid duplicates
              if (_chatNoticeEntry != null) {
                AppWidgets.hideTopNotification(_chatNoticeEntry);
                _chatNoticeEntry = null;
              }
              // mark as seen so first-time auto-show won't re-trigger
              await SharedPref.saveBool(
                SharePrefKey.hasSeenChatHistoryNotice,
                true,
              );
              if (!mounted) return;
              _chatNoticeEntry = AppWidgets.showTopNotification(
                this.context,
                'The coach does not memorize chat history. Each interaction is independent.'
                    .tr,
                duration: const Duration(seconds: 3),
                autoDismissAfter: const Duration(seconds: 3),
                persistent: true,
                onDismissed: () {
                  _chatNoticeEntry = null;
                  if (mounted) setState(() {});
                },
              );
              if (mounted) setState(() {});
            },
            icon: Icon(
              Icons.lightbulb_outline,
              color: context.theme.primaryColor,
            ),
          ),
        ],
      ),
      body: GetBuilder<ChatController>(
        builder: (_) {
          Future.microtask(() async {
            final seen =
                await SharedPref.readBool(
                  SharePrefKey.hasSeenChatHistoryNotice,
                ) ??
                false;
            if (!seen) {
              SharedPref.saveBool(SharePrefKey.hasSeenChatHistoryNotice, true);
              if (!mounted) return;
              // show and keep a reference so the lamp can toggle it
              _chatNoticeEntry = AppWidgets.showTopNotification(
                this.context,
                'The coach does not memorize chat history. Each interaction is independent.'
                    .tr,
                duration: const Duration(seconds: 3),
                autoDismissAfter: const Duration(seconds: 3),
                persistent: true,
                onDismissed: () {
                  _chatNoticeEntry = null;
                  if (mounted) setState(() {});
                },
              );
              setState(() {});
            }
          });
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: controller.scrollController,
                    itemCount: controller.messages.length,
                    shrinkWrap: true,
                    reverse: true,
                    itemBuilder: (context, index) {
                      if (controller.isStreamedText && index == 0) {
                        return ChatWidget(
                          index: index,
                          msg: controller.streamedText,
                          isUser: false,
                          file: controller.messages[index].file,
                          isFeed: controller.messages[index].isFeed,
                        );
                      } else {
                        return ChatWidget(
                          index: index,
                          msg: controller.messages[index].text,
                          isUser: controller.messages[index].isUser,
                          file: controller.messages[index].file,
                          isFeed: controller.messages[index].isFeed,
                        );
                      }
                    },
                  ),
                ),
                if (controller.imagePath != null)
                  Container(
                    margin: EdgeInsetsDirectional.only(start: 53, end: 53),
                    padding: EdgeInsets.all(10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: context.theme.cardColor,
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 100,
                          width: 100,
                          alignment: AlignmentDirectional.topEnd,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: FileImage(
                                File(controller.imagePath!.path),
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              controller.removeImage();
                            },
                            child: Icon(Icons.close, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Gallery / add button
                      StreamBuilder<Subscription?>(
                        stream: SubscriptionService().subscriptionStream,
                        builder: (context, snapshot) {
                          final isPremium = snapshot.data?.isActive == true;

                          return Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (controller.recording) {
                                    // When recording, this button acts as a close/stop control
                                    controller.stopListening(context);
                                  } else {
                                    controller.takeImage(
                                      ImageSource.gallery,
                                      context,
                                    );
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: _kGallerySize,
                                  height: _kGallerySize,
                                  margin: EdgeInsetsDirectional.only(
                                    end: _kActionGap,
                                  ),
                                  decoration: BoxDecoration(
                                    // change color smoothly when toggling recording
                                    color:
                                        controller.recording
                                            ? Colors.red.withValues(alpha: 0.12)
                                            : (isPremium
                                                ? AppColor.primaryOrange
                                                    .withValues(alpha: 0.12)
                                                : Colors.grey.withValues(
                                                  alpha: 0.12,
                                                )),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      transitionBuilder:
                                          (child, anim) => ScaleTransition(
                                            scale: anim,
                                            child: FadeTransition(
                                              opacity: anim,
                                              child: child,
                                            ),
                                          ),
                                      child: Icon(
                                        controller.recording
                                            ? Icons.close
                                            : Icons.photo_library_outlined,
                                        color:
                                            controller.recording
                                                ? Colors.red
                                                : (isPremium
                                                    ? AppColor.primaryOrange
                                                    : Colors.grey),
                                        size: 20,
                                        key: ValueKey(controller.recording),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Premium badge for non-premium users
                              if (!isPremium && !controller.recording)
                                Positioned(
                                  top: 0,
                                  right: _kActionGap,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),

                      Expanded(
                        child: Container(
                          padding: EdgeInsetsDirectional.only(
                            start: 10,
                            end: _kActionGap,
                            top: _kActionGap,
                            bottom: _kActionGap,
                          ),
                          decoration: BoxDecoration(
                            color:
                                context.theme.brightness == Brightness.dark
                                    ? AppColor.neutralGrey800
                                    : AppColor.neutralWhite,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color:
                                  context.theme.brightness == Brightness.dark
                                      ? AppColor.neutralGrey800
                                      : AppColor.neutralGrey200,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Input field
                              Expanded(
                                child:
                                    controller.recording == false
                                        ? TextField(
                                          controller: controller.controller,
                                          onChanged:
                                              (value) => controller.update(),
                                          onSubmitted:
                                              (_) => controller.sendMsg(
                                                text:
                                                    controller.controller.text,
                                              ),
                                          minLines: 1,
                                          maxLines: 4,
                                          style: TextStyle(
                                            color:
                                                context.theme.brightness ==
                                                        Brightness.dark
                                                    ? AppColor.neutralWhite
                                                    : AppColor.neutralGrey900,
                                            fontFamily: poppins,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            isCollapsed: true,
                                            hintText: 'Ask anything'.tr,
                                            hintStyle: TextStyle(
                                              color:
                                                  context.theme.brightness ==
                                                          Brightness.dark
                                                      ? AppColor.neutralWhite
                                                      : AppColor.neutralGrey500,
                                              fontSize: 15,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 4,
                                                ),
                                          ),
                                        )
                                        : SizedBox(
                                          height: 40,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2.0,
                                            ),
                                            child: VoiceVisualizer(
                                              level: controller.soundLevel,
                                              width: 40,
                                              height: 40,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                              ),

                              // Circular send / mic button
                              GestureDetector(
                                onTap: () {
                                  if (controller.isSending) {
                                    return; // Prevent interaction while sending
                                  }

                                  if (controller.recording) {
                                    controller.stopListening(context);
                                  } else if (controller
                                      .controller
                                      .text
                                      .isNotEmpty) {
                                    controller.sendMsg(
                                      text: controller.controller.text,
                                    );
                                  } else {
                                    controller.startListening();
                                  }
                                },
                                child: Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color:
                                        controller.isSending
                                            ? Colors
                                                .grey
                                                .shade800 // Dimmed color for loading state
                                            : Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child:
                                        controller.isSending
                                            ? const Padding(
                                              padding: EdgeInsets.all(5.0),
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : Icon(
                                              controller
                                                          .controller
                                                          .text
                                                          .isNotEmpty ||
                                                      controller.recording
                                                  ? Icons.arrow_upward
                                                  : Icons.multitrack_audio,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
