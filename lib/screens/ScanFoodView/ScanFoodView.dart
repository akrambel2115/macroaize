import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/ScanFoodView/ScanFoodController.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../constant/AppAssets.dart';
import '../../constant/FontFamily.dart';

class ScanFoodView extends GetView<ScanFoodController> {
  const ScanFoodView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => ScanFoodController());
    return SafeArea(
      child: Scaffold(
        body: GetBuilder<ScanFoodController>(
          builder: (controller) {
            return Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(controller.cameraController),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(70),
                    child: Image.asset(AppAssets.scanIcon, color: Colors.white),
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(40),
                      color: Colors.black,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => controller.onChangeIdentify("BreakFast"),
                            child: Container(
                              alignment: Alignment.center,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                color:
                                    controller.isIdentify == "BreakFast"
                                        ? context.theme.focusColor
                                        : Colors.transparent,
                              ),
                              child: Text(
                                'BreakFast'.tr,
                                style: TextStyle(
                                  color:
                                      controller.isIdentify == "BreakFast"
                                          ? Colors.black
                                          : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: poppins,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: InkWell(
                            onTap: () => controller.onChangeIdentify("Lunch"),
                            child: Container(
                              alignment: Alignment.center,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                color:
                                    controller.isIdentify == "Lunch"
                                        ? context.theme.focusColor
                                        : Colors.transparent,
                              ),
                              child: Text(
                                'Lunch'.tr,
                                style: TextStyle(
                                  color:
                                      controller.isIdentify == "Lunch"
                                          ? Colors.black
                                          : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: poppins,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => controller.onChangeIdentify("snack(s)"),
                            child: Container(
                              alignment: Alignment.center,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                color:
                                controller.isIdentify == "snack(s)"
                                    ? context.theme.focusColor
                                    : Colors.transparent,
                              ),
                              child: Text(
                                'snack(s)'.tr,
                                style: TextStyle(
                                  color:
                                  controller.isIdentify == "snack(s)"
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: poppins,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: InkWell(
                            onTap: () => controller.onChangeIdentify("Dinner"),
                            child: Container(
                              alignment: Alignment.center,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                color:
                                controller.isIdentify == "Dinner"
                                    ? context.theme.focusColor
                                    : Colors.transparent,
                              ),
                              child: Text(
                                'Dinner'.tr,
                                style: TextStyle(
                                  color:
                                  controller.isIdentify == "Dinner"
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: poppins,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 30,
                  bottom: 20,
                  child: InkWell(
                    onTap: () {
                      controller.takeImage(ImageSource.gallery, context);
                    },
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          fit: BoxFit.fill,
                          image: AssetImage(AppAssets.galleryIcon,),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 80,
                  bottom: 20,
                  child: InkWell(
                    onTap: () {
                      showInfo(context);
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: context.theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.info, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  left: MediaQuery.of(context).size.width / 2.4,
                  bottom: 15,
                  child: InkWell(
                    onTap: () async {
                      // final image = await controller.cameraController.takePicture();
                      controller.onTackImageCamera(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(AppAssets.clickPhoto),
                    ),
                  ),
                ),


                controller.isLoading
                    ? Opacity(
                      opacity: 0.8,
                      child: ModalBarrier(
                        dismissible: false,
                        color: Colors.black,
                      ),
                    )
                    : Container(),
                controller.isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: context.theme.focusColor,
                      ),
                    )
                    : Container(),
              ],
            );
          },
        ),
      ),
    );
  }
  showInfo(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return SafeArea(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Colors.black),
            child: Column(
              children: [
                const SizedBox(
                  height: 200,
                ),
                Text(
                  'Snap Tips'.tr,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: poppins),
                ),
                Container(
                  height: 150,
                  width: 150,
                  padding: const EdgeInsets.all(10),
                  child: Stack(
                    children: [
                      Container(
                        height: 120,
                        width: 120,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.theme.focusColor),
                        child: Container(
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage(AppAssets.scanComplete),
                                  fit: BoxFit.cover),
                              shape: BoxShape.circle),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          height: 40,
                          width: 40,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              color: context.theme.focusColor.withOpacity(0.9),
                              shape: BoxShape.circle),
                          child: Container(
                              height: 35,
                              width: 35,
                              decoration: BoxDecoration(
                                  color: context.theme.focusColor,
                                  shape: BoxShape.circle),
                              child: const Icon(
                                Icons.done,
                                color: Colors.white,
                              )),
                        ),
                      )
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 150,
                              padding: const EdgeInsets.all(10),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 120,
                                    width: 120,
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle, color: Colors.red),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image: AssetImage(AppAssets.soClose),
                                              fit: BoxFit.cover),
                                          shape: BoxShape.circle),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.9),
                                          shape: BoxShape.circle),
                                      child: Container(
                                          height: 35,
                                          width: 35,
                                          decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                          )),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Text(
                              'Too close'.tr,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: poppins,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        )),
                    Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 150,
                              padding: const EdgeInsets.all(10),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 120,
                                    width: 120,
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle, color: Colors.red),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image: AssetImage(AppAssets.soFar),
                                              fit: BoxFit.cover),
                                          shape: BoxShape.circle),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.9),
                                          shape: BoxShape.circle),
                                      child: Container(
                                          height: 35,
                                          width: 35,
                                          decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                          )),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Text(
                              'Too far'.tr,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: poppins,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        )),
                    Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 150,
                              padding: const EdgeInsets.all(10),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 120,
                                    width: 120,
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle, color: Colors.red),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image: AssetImage(
                                                  AppAssets.scanComplete),
                                              fit: BoxFit.cover),
                                          shape: BoxShape.circle),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.9),
                                          shape: BoxShape.circle),
                                      child: Container(
                                          height: 35,
                                          width: 35,
                                          decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                          )),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Text(
                              'Multi-species'.tr,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: poppins,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        )),
                  ],
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: context.theme.focusColor,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        'Continue'.tr,
                        style: context.textTheme.headlineMedium,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
