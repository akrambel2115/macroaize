import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/constant/FontFamily.dart';
import 'package:foodcalorietracker/screens/ChatScreen/ChatController.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/VoiceVisualizer.dart';
import '../../widgets/ChatWidget.dart';
import '../../SharePrefHelper/SharePref.dart';
import '../../SharePrefHelper/SharePrefKey.dart';

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
          // Persistent lamp icon to indicate/ toggle the chat-history notice
          IconButton(
            tooltip: 'Show chat notice'.tr,
            onPressed: () async {
              // Always remove existing entry first to avoid duplicates
              if (_chatNoticeEntry != null) {
                AppWidgets.hideTopNotification(_chatNoticeEntry);
                _chatNoticeEntry = null;
              }
              // mark as seen so first-time auto-show won't re-trigger
              await SharedPref.saveBool(SharePrefKey.hasSeenChatHistoryNotice, true);
              _chatNoticeEntry = AppWidgets.showTopNotification(
                context,
                'The coach does not memorize chat history. Each interaction is independent.'.tr,
                duration: const Duration(seconds: 10),
                autoDismissAfter: const Duration(seconds: 10),
                persistent: true,
                onDismissed: () {
                  // clear local reference so next click immediately shows a new banner
                  _chatNoticeEntry = null;
                  if (mounted) setState(() {});
                },
              );
              if (mounted) setState(() {});
            },
            icon: Icon(Icons.lightbulb_outline, color: context.theme.primaryColor),
          ),
        ],
      ),
      body: GetBuilder<ChatController>(
        builder: (_) {
          // One-time chat history notice: show top notification the first time user opens chat
          Future.microtask(() async {
            final seen = await SharedPref.readBool(SharePrefKey.hasSeenChatHistoryNotice) ?? false;
            if (!seen) {
              SharedPref.saveBool(SharePrefKey.hasSeenChatHistoryNotice, true);
              // show and keep a reference so the lamp can toggle it
              _chatNoticeEntry = AppWidgets.showTopNotification(
                context,
                'The coach does not memorize chat history. Each interaction is independent.'.tr,
                duration: const Duration(seconds: 10),
                autoDismissAfter: const Duration(seconds: 10),
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
                        color: context.theme.cardColor),
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
                                      File(controller.imagePath!.path)),
                                  fit: BoxFit.cover)),
                          child: GestureDetector(
                              onTap: () {
                                controller.removeImage();
                              },
                              child: Icon(
                                Icons.close,
                                color: Colors.red,
                              )),
                        )
                      ],
                    ),
                  ),

                // New rounded input bar matching the attached design
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                  child: Row(
                    children: [
                      // Gallery / add button (small)
                      // Gallery icon (rounded square, subtle border)
                      GestureDetector(
                        onTap: () {
                          if (controller.recording) {
                            // When recording, this button acts as a close/stop control
                            controller.stopListening(context);
                          } else {
                            controller.takeImage(ImageSource.gallery, context);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: _kGallerySize,
                          height: _kGallerySize,
                          margin: EdgeInsetsDirectional.only(end: _kActionGap),
                          decoration: BoxDecoration(
                            // change color smoothly when toggling recording
                            color: controller.recording
                                ? Colors.red.withOpacity(0.12)
                                : AppColor.primaryOrange.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                              child: Icon(
                                controller.recording ? Icons.close : Icons.photo_library_outlined,
                                color: controller.recording ? Colors.red : AppColor.primaryOrange,
                                size: 20,
                                key: ValueKey(controller.recording),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Centered rounded input container matching the image
            Expanded(
                        child: Container(
              padding: EdgeInsetsDirectional.only(start: 10, end: _kActionGap, top: _kActionGap, bottom: _kActionGap),
                          decoration: BoxDecoration(
                            color: AppColor.neutralWhite,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColor.neutralGrey200),
                          ),
                          child: Row(
                            children: [
                              // Input field (no avatar inside)
                              Expanded(
                                child: controller.recording == false
                                    ? TextField(
                                        controller: controller.controller,
                                        onChanged: (value) => controller.update(),
                                        onSubmitted: (_) => controller.sendMsg(text: controller.controller.text),
                                        minLines: 1,
                                        maxLines: 4,
                                        style: TextStyle(
                                          color: AppColor.neutralGrey900,
                                          fontFamily: poppins,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                        decoration: InputDecoration(
                                          isCollapsed: true,
                                          hintText: 'Ask anything'.tr,
                                          hintStyle: TextStyle(
                                            color: AppColor.neutralGrey500,
                                            fontSize: 15,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                        ),
                                      )
                                    : SizedBox(
                                        height: 40,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                                          child: VoiceVisualizer(
                                            level: controller.soundLevel,
                                            width: 40,
                                            height: 40,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                              ),

                              // removed internal mic icon per request

                              // Circular send / mic button (black) on the right - no outer padding; container provides the gap
                              GestureDetector(
                                onTap: () {
                                  if (controller.recording) {
                                    controller.stopListening(context);
                                  } else if (controller.controller.text.isNotEmpty) {
                                    controller.sendMsg(text: controller.controller.text);
                                  } else {
                                    controller.startListening();
                                  }
                                },
                                child: Container(
                                  height: 44,
                                  width: 44,
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      controller.controller.text.isNotEmpty || controller.recording
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
