import 'package:flutter/material.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/ChatHistoryScreen/DeleteDailog.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
import 'package:get/get.dart';
import 'ChatHistoryController.dart';

class ChatHistoryView extends GetView<ChatHistoryController> {
  const ChatHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: AppWidgets.backButton(context, () {
          Get.back();
        }),
        backgroundColor: context.theme.scaffoldBackgroundColor,
        title: Text("Chat History".tr, style: context.textTheme.headlineMedium),
      ),
      body: GetBuilder<ChatHistoryController>(
        builder: (controller) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                controller.history.isNotEmpty
                    ? ListView.builder(
                      itemCount: controller.history.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(top: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: context.theme.cardColor,
                          ),
                          child: ListTile(
                            onTap: () {
                              Get.toNamed(
                                Routes.chatView,
                                arguments: {
                                  "mainChatId": controller.history[index].id!,
                                },
                              );
                            },
                            title: Text(
                              controller.history[index].question,
                              style: context.textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              controller.history[index].answer,
                              style: context.textTheme.titleSmall,
                              maxLines: 1,
                            ),
                            trailing: GestureDetector(
                              onTap: () {
                                showChatDeleteDialog(
                                  onDelete: () {
                                    controller.deleteChatHistory(
                                      controller.history[index].id!,
                                    );
                                  },
                                  context: context,
                                );
                              },
                              child: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                    : Center(
                      child: Text(
                        "History Not Found",
                        style: context.textTheme.titleMedium,
                      ),
                    ),
          );
        },
      ),
    );
  }
}
