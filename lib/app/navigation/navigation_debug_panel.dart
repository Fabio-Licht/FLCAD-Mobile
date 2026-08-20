import 'package:flutter/material.dart';

import 'navigation_contracts.dart';
import 'navigation_engine.dart';

class NavigationDebugPanel extends StatelessWidget {
  const NavigationDebugPanel({super.key, required this.engine});

  final NavigationEngine engine;

  @override
  Widget build(BuildContext context) => StreamBuilder<NavigationDebugSnapshot>(
    stream: engine.debugSnapshots,
    builder: (context, snapshot) {
      final data = snapshot.data;
      if (data == null) return const SizedBox.shrink();
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .78),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
            child: Text(
              'State: ${data.state.name}\n'
              'Profile: ${data.profile.name}\n'
              'Context: ${data.context.name}\n'
              'Command: ${data.command}\n'
              'Destination: ${data.destination}\n'
              'Time: ${data.timestamp.toIso8601String()}\n'
              'FPS: ${data.fps?.toStringAsFixed(1) ?? '--'}\n'
              'Picking: ${data.pickingState}',
            ),
          ),
        ),
      );
    },
  );
}
