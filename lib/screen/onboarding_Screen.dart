import 'package:flutter/material.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';
import 'package:neuroforge_workflow/core/utils/Landing_gatekeeper.dart'; // Verified import path matching your file schema
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
  void dispose() {
    _pageController.dispose(); // Always dispose of controllers to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // True only when we reach the extra final page (index equals length)
    bool isLastPage = _currentIndex == onboardingSlides.length;

    return Scaffold(
      backgroundColor: ForgeTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _currentIndex > 0
                      ? IconButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: ForgeTheme.brandBlue,
                            size: 20,
                          ),
                        )
                      : const SizedBox(width: 40, height: 40), // Balanced spacing

                  // SKIP BUTTON
                  if (!isLastPage)
                    TextButton(
                      onPressed: () {
                        // Animates smoothly or jumps directly to the last page index
                        _pageController.jumpToPage(onboardingSlides.length);
                      },
                      child: Text(
                        "Skip",
                        style: ForgeTheme.actionButtonText.copyWith(
                          color: ForgeTheme.brandBlue,
                          fontSize: 15,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),

            // PAGE VIEW
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingSlides.length + 1,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  // NORMAL SLIDES
                  if (index < onboardingSlides.length) {
                    final slide = onboardingSlides[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.35,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 45),
                              child: Image.asset(
                                slide.imageAsset,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: slide.titleBlack,
                                  style: ForgeTheme.displayHeader,
                                ),
                                TextSpan(
                                  text: slide.titleBlue,
                                  style: ForgeTheme.displayHeader.copyWith(
                                    color: ForgeTheme.brandBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(slide.description, style: ForgeTheme.bodyText),
                        ],
                      ),
                    );
                  }

                  // LAST PAGE (Fixed Expanded Layout Crash)
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.35,
                            margin: const EdgeInsets.only(bottom: 40),
                            child: Image.asset(
                              "assets/images/onboarding4.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Collaborate\n",
                                style: ForgeTheme.displayHeader.copyWith(
                                  fontSize: 24,
                                  color: ForgeTheme.textDark,
                                ),
                              ),
                              TextSpan(
                                text: "with team",
                                style: ForgeTheme.displayHeader.copyWith(
                                  fontSize: 24,
                                  color: ForgeTheme.brandBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Everything you need to get your team moving",
                          style: ForgeTheme.bodyText.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // BOTTOM SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: Column(
                children: [
                  // DOTS INDICATOR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: List.generate(
                      onboardingSlides.length + 1,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: index == _currentIndex ? 24 : 8,
                        decoration: BoxDecoration(
                          color: index == _currentIndex
                              ? ForgeTheme.brandBlue
                              : ForgeTheme.dotInactive,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // CONDITIONAL BUTTONS
                  if (!isLastPage)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ForgeTheme.brandBlue,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        "Next",
                        style: ForgeTheme.actionButtonText,
                      ),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ForgeTheme.brandBlue,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // Triggers preference checks, sets 'show_onboarding_flow' to false, and routes dynamically
                        LandingGatekeeper.completeOnboardingFlow(context);
                      },
                      child: Text(
                        "Get Started",
                        style: ForgeTheme.actionButtonText,
                      ),
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