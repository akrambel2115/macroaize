import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import '../screens/ChatScreen/ChatController.dart';

/// Chat message bubble widget
class ChatWidget extends StatelessWidget {
  const ChatWidget({
    super.key,
    required this.msg,
    required this.isUser,
    required this.file,
    required this.isFeed,
    required this.index,
  });

  final String msg;
  final bool isUser;
  final String? file;
  final bool isFeed;
  final int index;

  @override
  Widget build(BuildContext context) {
    const double kTypingIndicatorSize = 16.0;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = isUser
        ? (context.theme.brightness == Brightness.dark
            ? AppColor.neutralGrey800
            : AppColor.neutralGrey100)
        : context.theme.cardColor;
    final textColor = isUser
        ? (context.theme.brightness == Brightness.dark
            ? AppColor.neutralWhite
            : AppColor.neutralGrey900)
        : context.textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Image.asset(AppAssets.coachIcon, height: 28, width: 28),
            const SizedBox(width: 10),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: align,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (file != null && isUser)
                    Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(File(file!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ).paddingOnly(top: 6, bottom: 8),

                  if (msg.toString().isNotEmpty)
                    Text(
                      msg,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        fontSize: 15,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Lottie.asset(
                        AppAssets.loadingChat,
                        width: kTypingIndicatorSize,
                        height: kTypingIndicatorSize,
                      ),
                    ),

                  if (!isUser && msg.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            Get.find<ChatController>().showFeedbackSheet(context, index);
                          },
                          icon: Image.asset(AppAssets.thumbsDown, height: 26, width: 26, color: Colors.grey),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: msg));
                            Fluttertoast.showToast(msg: 'Copy'.tr);
                          },
                          icon: const Icon(Icons.copy, color: Colors.grey),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 10),
            Icon(Icons.account_circle_rounded, size: 28),
          ],
        ],
      ),
    );
  }
}
