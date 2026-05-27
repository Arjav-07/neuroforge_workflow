import 'package:flutter/material.dart';

class OnboardingModel {
  final String titleBlack;
  final String titleBlue;
  final String description;
  // Can be either an asset path (String) or an IconData
  final dynamic imageAsset; // Replace with your custom SVG vectors later

  OnboardingModel({
    required this.titleBlack,
    required this.titleBlue,
    required this.description,
    required this.imageAsset,
  });
}

final List<OnboardingModel> onboardingSlides = [
  OnboardingModel(
    titleBlack: "Manage work,\n",
    titleBlue: "achieve more",
    description: "Organize tasks, set priorities and track  progress - all in one place.",
    imageAsset: "assets/images/onboarding1.png",
  ),
  OnboardingModel(
    titleBlack: "Collaborate\n",
    titleBlue: "effortlessly",
    description: "Communicate, share files and stay aligned with your team in real life.",
    imageAsset: "assets/images/onboarding2.png",
  ),
  OnboardingModel(
    titleBlack: "Secure &\n",
    titleBlue: "reliable",
    description: "Your data is safe with enterprise-grade security and privacy.",
    imageAsset: "assets/images/onboarding3.png",
  ),
];