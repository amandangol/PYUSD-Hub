import 'dart:ui';
import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget body;
  final String? loadingText;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.body,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        body,
        if (isLoading)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Blur effect
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(0.3), // Slight overlay
                    ),
                  ),
                  // Loading content
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (loadingText != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            loadingText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
