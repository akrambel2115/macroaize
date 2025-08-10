import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppWidgets {
  static Widget backButton(BuildContext context, VoidCallback onTap) {
    return IconButton(
        padding: EdgeInsets.all(0),
        onPressed: onTap,
        icon: Icon(Icons.arrow_back_ios, color: context.theme.primaryColor,));
  }
}