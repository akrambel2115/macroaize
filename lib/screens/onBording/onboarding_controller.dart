import 'package:carousel_slider/carousel_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'OnBoardingItem/item_one.dart';
import 'OnBoardingItem/item_three.dart';
import 'OnBoardingItem/item_two.dart';

class OnBoardingController extends GetxController {
  RxInt selectedIndex = 0.obs;
  CarouselSliderController buttonCarouselController = CarouselSliderController();

  List<Widget> screens = [
    OnBoardingOne(),
    OnBoardingTwo(),
    OnBoardingThree(),
  ];
}
