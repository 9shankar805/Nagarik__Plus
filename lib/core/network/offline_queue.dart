
import 'package:hive_flutter/hive_flutter.dart';

part 'offline_queue.g.dart';

@HiveType(typeId: 0)
class QueuedRequest extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String method;

  @HiveField(2)
  final String path;

  @HiveField(3)
  final String? data;

  @HiveField(4)
  final Map<String, dynamic>? queryParameters;

  @HiveField(5)
  final DateTime timestamp;

  QueuedRequest({
    required this.id,
    required this.method,
    required this.path,
    this.data,
    this.queryParameters,
    required this.timestamp,
  });
}

