import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/FontFamily.dart';

class CustomButtom extends StatelessWidget {
  final VoidCallback? ontap;
  final String btntext;
  final Color btncolor;
  final Color backgroundcolor;
  final Icon? sufixicon;
  final Icon? prefixicon;

  const CustomButtom({
    super.key,
    required this.backgroundcolor,
    required this.btncolor,
    required this.btntext,
    required this.ontap,
    this.sufixicon,
    this.prefixicon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: ontap,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: backgroundcolor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(child: prefixicon),
              Center(
                child: Text(
                  btntext,
                  style: TextStyle(
                    fontFamily: poppins,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: btncolor,
                  ),
                ),
              ),
              Container(child: sufixicon),
            ],
          ),
        ),
      ),
    );
  }
}
