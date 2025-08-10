import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/FontFamily.dart';
import 'package:foodcalorietracker/screens/ChatScreen/ChatController.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import '../../widgets/ChatWidget.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: AppWidgets.backButton(context, () {
          Get.back();
        }),
        backgroundColor: context.theme.scaffoldBackgroundColor,
        title: Text("Ask Botanist".tr, style: context.textTheme.headlineMedium),
      ),
      body: GetBuilder<ChatController>(
        builder: (controller) {
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
                    margin:
                    EdgeInsets.only(left: 53, right: 53),
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
                          alignment: Alignment.topRight,
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

                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        controller.takeImage(ImageSource.gallery, context);
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                            color: context.theme.primaryColor,
                            shape: BoxShape.circle
                        ),
                        child: Icon(Icons.add,color: context.theme.scaffoldBackgroundColor,size: 30,),
                      ),
                    ),
                    if(controller.recording == false)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: TextField(
                            style: TextStyle(
                              color: context.theme.scaffoldBackgroundColor,
                              fontFamily: poppins,
                              fontWeight: FontWeight.w500,
                            ),
                            onTapOutside: (event) {
                              FocusScope.of(context).unfocus();
                            },
                            controller: controller.controller,
                            onChanged: (value) {
                              controller.controller.text = value;
                              controller.update();
                            },
                            onSubmitted:
                                (value) => controller.sendMsg(
                              text: controller.controller.text,
                            ),
                            minLines: 1,
                            maxLines: 4,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              fillColor: context.theme.primaryColor,
                              filled: true,
                              hintText: 'Write your message'.tr,
                              constraints: const BoxConstraints(
                                minHeight: 30,
                                maxWidth: double.infinity,
                              ),
                              hintStyle: TextStyle(
                                color: context.theme.scaffoldBackgroundColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(color: context.theme.primaryColor,borderRadius: BorderRadius.circular(10)),
                                child: Lottie.asset(AppAssets.voiceWave,
                                    width: double.infinity,
                                    fit: BoxFit.fill,
                                    height: 50)),
                          )),

                    if (controller.controller.text.isNotEmpty || controller.recording)
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                            color: context.theme.primaryColor,
                            shape: BoxShape.circle
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (controller.recording) {
                              controller.stopListening(context);
                            } else {
                              controller.sendMsg(text: controller.controller.text,);
                            }
                          },
                          icon: Icon(Icons.arrow_upward, color: context.theme.scaffoldBackgroundColor,size: 30,),
                        ),
                      ),
                    if (controller.recording == false && controller.controller.text.isEmpty)
                      GestureDetector(
                        onTap: () {
                          if (controller.recording) {
                            controller.stopListening(context);
                          } else {
                            controller.startListening();
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,

                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.theme.primaryColor),
                          child: Icon(
                            Icons.mic,
                            color: context.theme.scaffoldBackgroundColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
