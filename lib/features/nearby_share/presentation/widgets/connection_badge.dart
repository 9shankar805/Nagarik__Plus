import 'package:flutter/material.dart';
import '../../services/connection_service.dart'
    show ConnectionService, ShareConnectionState;

/// Small pill showing current connection state.
/// Uses ShareConnectionState to avoid conflict with Flutter's ConnectionState.
class ConnectionBadge extends StatelessWidget {
  final bool light;
  const ConnectionBadge({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShareConnectionState>(
      stream: ConnectionService().stateStream,
      initialData: ConnectionService().state,
      builder: (_, snap) {
        final state  = snap.data ?? ShareConnectionState.idle;
        final label  = _label(state);
        final color  = _color(state);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: light
                ? Colors.white.withOpacity(0.2)
                : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: light
                ? Border.all(color: Colors.white.withOpacity(0.4))
                : Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: light ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: light ? Colors.white : color,
              fontSize: 11, fontWeight: FontWeight.w700,
            )),
          ]),
        );
      },
    );
  }

  String _label(ShareConnectionState s) {
    if (s == ShareConnectionState.idle)                 return 'Ready';
    if (s == ShareConnectionState.searching)            return 'Searching';
    if (s == ShareConnectionState.connecting)           return 'Connecting';
    if (s == ShareConnectionState.connected)            return 'Connected';
    if (s == ShareConnectionState.transferring)         return 'Transferring';
    if (s == ShareConnectionState.completed)            return 'Done';
    if (s == ShareConnectionState.wifiDirectUnavailable) return 'Hotspot';
    if (s == ShareConnectionState.hotspotActive)        return 'Hotspot On';
    return 'Failed';
  }

  Color _color(ShareConnectionState s) {
    if (s == ShareConnectionState.idle)                 return const Color(0xFF8A96A8);
    if (s == ShareConnectionState.searching)            return const Color(0xFFFF9B2F);
    if (s == ShareConnectionState.connecting)           return const Color(0xFF3461FF);
    if (s == ShareConnectionState.connected)            return const Color(0xFF00C17C);
    if (s == ShareConnectionState.transferring)         return const Color(0xFF3461FF);
    if (s == ShareConnectionState.completed)            return const Color(0xFF00C17C);
    if (s == ShareConnectionState.wifiDirectUnavailable) return const Color(0xFFFF9B2F);
    if (s == ShareConnectionState.hotspotActive)        return const Color(0xFF00C17C);
    return Colors.red;
  }
}
