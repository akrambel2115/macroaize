import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class CustomText extends StatelessWidget {
  const CustomText({
    @override super.key,
    required this.text,
    this.fontSize,
    this.fontColor,
    this.fontWeight,
    this.height,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontFamily,
  });
  final String text;
  final double? fontSize;
  final Color? fontColor;
  final FontWeight? fontWeight;
  final int? maxLines;
  final FontStyle fontStyle = FontStyle.normal;
  final double? height;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.tr,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: fontSize,
        color: fontColor,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        height: height,
        fontFamily: fontFamily,
      ),
    );
  }
}
