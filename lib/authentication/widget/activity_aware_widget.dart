import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/session_provider.dart';

class ActivityAwareWidget extends StatefulWidget {
  final Widget child;

  const ActivityAwareWidget({super.key, required this.child});

  @override
  State<ActivityAwareWidget> createState() => _ActivityAwareWidgetState();
}

class _ActivityAwareWidgetState extends State<ActivityAwareWidget> {
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        // Update activity in the session provider
        Provider.of<SessionProvider>(context, listen: false).updateActivity();
      },
      child: widget.child,
    );
  }
}
