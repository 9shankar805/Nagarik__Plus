import 'package:flutter/material.dart';
import '../../data/models/device_model.dart';

class DeviceTile extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onTap;
  const DeviceTile({super.key, required this.device, required this.onTap});

  static const _kText  = Color(0xFF0D1B34);
  static const _kSub   = Color(0xFF8A96A8);
  static const _kBord  = Color(0xFFE4EAF4);
  static const _kBlue  = Color(0xFF3461FF);
  static const _kGreen = Color(0xFF00C17C);

  @override
  Widget build(BuildContext context) {
    final isWifi = device.connectionType.contains('Wi-Fi Direct');
    final typeColor = isWifi ? _kBlue : _kGreen;
    final typeIcon  = isWifi
        ? Icons.wifi_tethering_rounded
        : Icons.router_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBord),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Device avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.phone_android_rounded, color: typeColor, size: 26),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(device.name, style: const TextStyle(
                color: _kText, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(typeIcon, color: typeColor, size: 13),
              const SizedBox(width: 4),
              Text(device.connectionType,
                  style: TextStyle(color: typeColor,
                      fontSize: 12, fontWeight: FontWeight.w600)),
              if (device.ipAddress != null) ...[
                const SizedBox(width: 8),
                Text(device.ipAddress!,
                    style: const TextStyle(color: _kSub, fontSize: 11)),
              ],
            ]),
          ])),
          // Connect button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Connect',
                style: TextStyle(color: Colors.white,
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
