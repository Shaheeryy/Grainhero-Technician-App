import 'package:flutter/material.dart';
import 'package:grainhero_technician_app/screens/auth/sign_up_screen.dart';
import 'package:app_links/app_links.dart';

class SignUpDeepLinkHandler extends StatefulWidget {
  final Widget fallback;
  const SignUpDeepLinkHandler({super.key, required this.fallback});

  @override
  State<SignUpDeepLinkHandler> createState() => _SignUpDeepLinkHandlerState();
}

class _SignUpDeepLinkHandlerState extends State<SignUpDeepLinkHandler> {
  String? _deepLinkEmail;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _handleStartupLink();
  }

  Future<void> _handleStartupLink() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null && initialLink.toString().contains('signup')) {
        final uri = initialLink;
        setState(() {
          _deepLinkEmail = uri.queryParameters['email'];
        });
      }
    } catch (e) {
      // Handle error silently or log it
      debugPrint('Error handling initial link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_deepLinkEmail != null) {
      return SignUpScreen(prefilledEmail: _deepLinkEmail);
    }
    return widget.fallback;
  }
}
