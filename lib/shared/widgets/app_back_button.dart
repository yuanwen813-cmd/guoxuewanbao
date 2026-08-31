import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A predictable return action for secondary pages.
///
/// Pushed pages return to their actual previous page. Direct links and desktop
/// shortcuts have no navigator history, so they use the configured fallback.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    required this.fallbackLocation,
  });

  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '返回',
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          return;
        }
        router.go(fallbackLocation);
      },
    );
  }
}
