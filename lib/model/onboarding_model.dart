import 'package:flutter/material.dart';

class OnboardingModel {
  final String titleBlack;
  final String titleBlue;
  final String description;
  final IconData placeholderIcon; // Replace with your custom SVG vectors later

  OnboardingModel({
    required this.titleBlack,
    required this.titleBlue,
    required this.description,
    required this.placeholderIcon,
  });
}

final List<OnboardingModel> onboardingSlides = [
  OnboardingModel(
    titleBlack: "Manage work,\n",
    titleBlue: "achieve more",
    description: "Organize tasks, set priorities and track progress - all in one place.",
    placeholderIcon: Icons.analytics_rounded,
  ),
  OnboardingModel(
    titleBlack: "Collaborate\n",
    titleBlue: "effortlessly",
    description: "Communicate, share files and stay aligned with your team in real life.",
    placeholderIcon: Icons.forum_rounded,
  ),
  OnboardingModel(
    titleBlack: "Secure &\n",
    titleBlue: "reliable",
    description: "Your data is safe with enterprise-grade security and privacy.",
    placeholderIcon: Icons.gpp_good_rounded,
  ),
];