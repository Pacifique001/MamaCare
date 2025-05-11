import 'package:flutter/material.dart';

class NotFoundScreen extends StatelessWidget {
  final String? errorMessage;
  final String? errorDetails; // Add this line
  final VoidCallback? onRetry;

  const NotFoundScreen({
    super.key,
    this.errorMessage,
    this.errorDetails, // Add this parameter
    this.onRetry,
    required String message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? '404 - Page Not Found',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (errorDetails != null) ...[
              // Add this conditional block
              const SizedBox(height: 8),
              Text(
                errorDetails!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  onRetry ??
                  () {
                    Navigator.of(context).pop();
                  },
              child: Text(onRetry != null ? 'Try Again' : 'Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
