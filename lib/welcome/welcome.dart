import 'package:flutter/material.dart';
import 'package:minimal_onboarding/minimal_onboarding.dart';
import 'package:social_test/pages/home.dart';

class Welcome extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Welcome> {
  List<OnboardingPageModel> onboardingPages = [
    OnboardingPageModel('assets/new_welcome.png', 'Hi',
        'Before continuing, Please keep in mind the following'),
    OnboardingPageModel('assets/report.png', 'Honesty',
        'Be honest and moderate when reporting a crime or commenting on events'),
    OnboardingPageModel('assets/no_abuse.png', 'Very important',
        'No abusive speech and no blackmailing.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MinimalOnboarding(
        onboardingPages: onboardingPages,
        dotsDecoration: DotsDecorator(
          activeColor: Colors.deepPurple,
          size: const Size.square(9.0),
          activeSize: const Size(18.0, 9.0),
          activeShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
        onFinishButtonPressed: () {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Home("likes", true)),
              ModalRoute.withName("/Home"));
        },
        showSkipButton: false,
      ),
    );
  }
}
