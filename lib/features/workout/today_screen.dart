import 'package:flutter/material.dart';

/// Today's workout screen.
class TodayScreen extends StatelessWidget {
  const TodayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: const Center(
        child: Text('Today Workout Screen'),
      ),
    );
  }
}
