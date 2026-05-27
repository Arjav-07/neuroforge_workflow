import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';
import 'package:neuroforge_workflow/model/onboarding_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    bool isLastPage = _currentIndex == 3;

    return Scaffold(
      backgroundColor: ForgeTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _currentIndex > 0
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: ForgeTheme.brandBlue, size: 20),
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        )
                      : const SizedBox(width: 40),
                  if (!isLastPage)
                    TextButton(
                      onPressed: () => _pageController.jumpToPage(3),
                      child: Text(
                        "Skip",
                        style: GoogleFonts.inter(
                          color: ForgeTheme.brandBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Sliding Vector Artwork & Description Area
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: 4,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  if (index < 3) {
                    // Slides 1, 2, 3 Standard Template
                    final slide = onboardingSlides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vector Display Simulator Box
                          Center(
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.35,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 45),
                              decoration: BoxDecoration(
                                color: ForgeTheme.surfaceWhite,
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Icon(slide.placeholderIcon, size: 100, color: ForgeTheme.brandBlue.withOpacity(0.8)),
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: slide.titleBlack, style: ForgeTheme.displayHeader),
                                TextSpan(text: slide.titleBlue, style: ForgeTheme.displayHeader.copyWith(color: ForgeTheme.brandBlue)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(slide.description, style: ForgeTheme.bodyText),
                        ],
                      ),
                    );
                  } else {
                    // Final Screen 4 Split Functional Template
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.35,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 45),
                              decoration: BoxDecoration(
                                color: ForgeTheme.surfaceWhite,
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: const Icon(Icons.rocket_launch_rounded, size: 100, color: ForgeTheme.brandBlue),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Organize &\nYour work", style: ForgeTheme.displayHeader.copyWith(fontSize: 20)),
                                    const SizedBox(height: 8),
                                    Text("Everything you need to get your team moving", style: ForgeTheme.bodyText.copyWith(fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 80, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 16)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Collaborate\nwith team", style: ForgeTheme.displayHeader.copyWith(fontSize: 20)),
                                    const SizedBox(height: 8),
                                    Text("Everything you need to get your team moving", style: ForgeTheme.bodyText.copyWith(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),

            // Navigation Controller Indicator Dots & Primary Action Triggers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(
                      4,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: index == _currentIndex ? 24 : 8,
                        decoration: BoxDecoration(
                          color: index == _currentIndex ? ForgeTheme.brandBlue : ForgeTheme.dotInactive,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!isLastPage)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ForgeTheme.brandBlue,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text("Next", style: ForgeTheme.actionButtonText),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ForgeTheme.brandBlue,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              print("Navigating to Manager workspace Flow...");
                            },
                            child: Text("Next", style: ForgeTheme.actionButtonText),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: ForgeTheme.brandBlue,
                              side: BorderSide.none,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            ),
                            onPressed: () {
                              print("Navigating to Employee dashboard panel...");
                            },
                            child: Text("Get Started", style: ForgeTheme.actionButtonText),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}