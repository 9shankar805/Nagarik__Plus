// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_queue.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QueuedRequestAdapter extends TypeAdapter<QueuedRequest> {
  @override
  final int typeId = 0;

  @override
  QueuedRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QueuedRequest(
      id: fields[0] as String,
      method: fields[1] as String,
      path: fields[2] as String,
      data: fields[3] as String?,
      queryParameters: (fields[4] as Map?)?.cast<String, dynamic>(),
      timestamp: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, QueuedRequest obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.method)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.queryParameters)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueuedRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
