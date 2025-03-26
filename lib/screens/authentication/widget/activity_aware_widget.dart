import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/session_provider.dart';

class ActivityAwareWidget extends StatefulWidget {
  final Widget child;

  const ActivityAwareWidget({super.key, required this.child});

  @override
  State<ActivityAwareWidget> createState() => _ActivityAwareWidgetState();
}

class _ActivityAwareWidgetState extends State<ActivityAwareWidget>
    with WidgetsBindingObserver {
  late SessionProvider _sessionProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Delay to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      _sessionProvider.updateActivity();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Update activity and reset timers when app comes to foreground
      _sessionProvider.updateActivity();
    } else if (state == AppLifecycleState.paused) {
      // Optional: You might want to start counting inactivity when app goes to background
      // _sessionProvider.onAppBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // Update activity in the session provider
        Provider.of<SessionProvider>(context, listen: false).updateActivity();
      },
      onPanUpdate: (_) {
        // Also catch scrolling/dragging
        Provider.of<SessionProvider>(context, listen: false).updateActivity();
      },
      child: widget.child,
    );
  }
}
