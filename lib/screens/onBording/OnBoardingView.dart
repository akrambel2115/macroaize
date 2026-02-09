import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:get/get.dart';
import '../../widgets/customButton.dart';
import 'OnBoardingController.dart';

class OnBoardingView extends GetView<OnBoardingController> {
  const OnBoardingView({super.key});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    OnBoardingController controller = Get.put(OnBoardingController());
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            color: context.theme.scaffoldBackgroundColor,
          ),
          GetBuilder<OnBoardingController>(
            builder: (controller) {
              return Center(
                child: CarouselSlider(
                  items: controller.screens,
                  carouselController: controller.buttonCarouselController,
                  options: CarouselOptions(
                    height: height * 0.8,
                    viewportFraction: 1,
                    initialPage: controller.selectedIndex.value,
                    enableInfiniteScroll: true,
                    onPageChanged: (index, reason) {
                      index;
                      controller.selectedIndex.value = index;
                    },
                    scrollDirection: Axis.horizontal,
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 10,
            right: 10,
            left: 10,
            child: CustomButtom(
              backgroundcolor: context.theme.focusColor,
              btncolor: Colors.white,
              btntext: "Continue".tr,
              ontap: () async {
                if (controller.selectedIndex.value < 2) {
                  controller.buttonCarouselController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.linear,
                  );
                } else {
                  Get.toNamed(Routes.signUpView);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
