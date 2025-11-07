import 'package:flutter/material.dart';

enum SocialLoginProvider {
  google,
  microsoft,
  apple,
}

class SocialLoginButton extends StatelessWidget {
  final SocialLoginProvider provider;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.white,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _getProviderIcon(),
                  const SizedBox(width: 12),
                  Text(
                    _getProviderText(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _getProviderIcon() {
    switch (provider) {
      case SocialLoginProvider.google:
        return Image.asset(
          'assets/icons/google_icon.png',
          height: 24,
          width: 24,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.g_mobiledata, size: 24, color: Colors.red);
          },
        );
      case SocialLoginProvider.microsoft:
        return Image.asset(
          'assets/icons/microsoft_icon.png',
          height: 24,
          width: 24,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.window, size: 24, color: Colors.blue);
          },
        );
      case SocialLoginProvider.apple:
        return const Icon(Icons.apple, size: 24, color: Colors.black);
    }
  }

  String _getProviderText() {
    switch (provider) {
      case SocialLoginProvider.google:
        return 'Continue with Google';
      case SocialLoginProvider.microsoft:
        return 'Continue with Microsoft';
      case SocialLoginProvider.apple:
        return 'Continue with Apple';
    }
  }
}

