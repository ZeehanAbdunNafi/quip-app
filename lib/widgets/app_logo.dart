import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/mainLogo.png',
      width: width,
      height: height,
      fit: fit,
      color: color, // Re-enable color filter for white logos on colored backgrounds
      errorBuilder: (context, error, stackTrace) {
        print('Error loading logo: $error');
        return Container(
          width: width ?? 50,
          height: height ?? 50,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.error_outline,
            color: Colors.red,
          ),
        );
      },
    );
  }
} 