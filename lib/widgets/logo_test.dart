import 'package:flutter/material.dart';

class LogoTest extends StatelessWidget {
  const LogoTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logo Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Testing Logo Loading:'),
            const SizedBox(height: 20),
            Container(
              width: 200,
              height: 200,
              color: Colors.grey[200], // Light grey background to see the logo
              child: Image.asset(
                'assets/images/mainLogo.png',
                width: 200,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  print('ERROR: $error');
                  return Container(
                    width: 200,
                    height: 200,
                    color: Colors.red,
                    child: const Center(
                      child: Text(
                        'ERROR LOADING LOGO',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  );
                },
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  print('SUCCESS: Logo loaded successfully');
                  return child;
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text('If you see a red box, the logo failed to load.'),
            const Text('If you see your logo, it\'s working!'),
          ],
        ),
      ),
    );
  }
} 