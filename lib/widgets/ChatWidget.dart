import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../constant/AppAssets.dart';
import '../screens/ChatScreen/ChatController.dart';

class ChatWidget extends StatelessWidget {
  const ChatWidget({
    super.key,
    required this.msg,
    required this.isUser,
    required this.file,
    required this.isFeed,
    required this.index
  });

  final String msg;
  final bool isUser;
  final String? file;
  final bool isFeed;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      isUser == true ? CrossAxisAlignment.start : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 0),
            decoration: BoxDecoration(
              color:
              isUser == true
                  ? Colors.transparent
                  : context.theme.primaryColor.withOpacity(0.05),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isUser
                      ? Icon(Icons.account_circle_rounded, size: 25)
                      : Image.asset(AppAssets.aiIcon,height: 25,width: 25,),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                          MediaQuery.of(context).size.width *
                              0.8, // Adjust max width
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (file != null && isUser)
                              Container(
                                height: 180,
                                width: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  image: DecorationImage(
                                    image: FileImage(File(file!)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ).paddingOnly(top: 10, bottom: 10),
                            if (msg.toString().isNotEmpty)
                              Text(
                                msg,
                                style: context.textTheme.titleMedium,
                                softWrap: true,
                                // Allow text wrapping
                                overflow:
                                TextOverflow
                                    .clip, // Handle text overflow gracefully
                              )
                            else
                              Lottie.asset(AppAssets.loadingChat).paddingOnly(left: 10),
                            if(isUser == false && msg.isNotEmpty)
                              Row(children: [
                                IconButton(onPressed: ()  {
                                  Get.find<ChatController>().showFeedbackSheet(context,index);
                                }, icon: Image.asset(AppAssets.thumbsDown,height: 30,width: 30,color: Colors.grey,)),
                                IconButton(onPressed: () {
                                  Clipboard.setData(ClipboardData(text: msg));
                                  Fluttertoast.showToast(msg: 'Copy'.tr);
                                }, icon: const Icon(Icons.copy,color: Colors.grey,))
                              ],)
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
