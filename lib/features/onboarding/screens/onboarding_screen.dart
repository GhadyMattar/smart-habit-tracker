import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _getStarted(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 64), // Increased top spacing
            // Slogan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    fontFamily: 'Roboto',
                  ),
                  children: [
                    TextSpan(
                      text: 'GO FOR\n',
                      style: TextStyle(color: textColor),
                    ),
                    TextSpan(
                      text: 'BETTER\nHABITS\n',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(
                      text: 'WITH\nTRACKMATE',
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),
            ),

            // Image - Expanded to fill available space
            Expanded(
              child: Container(
                width: double.infinity,
                alignment: Alignment.centerRight, // Align to right
                child: Image.asset(
                  'assets/images/onboarding_image.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _getStarted(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48), // Bottom spacing
          ],
        ),
      ),
    );
  }
}
