class CallModel {
  final int id;
  final int callerId;
  final int receiverId;
  final String type; // 'video' or 'audio'
  final String status; // 'initiated', 'accepted', 'rejected', 'ended'
  final DateTime startedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int duration; // in seconds
  final CallUser caller;
  final CallUser receiver;

  CallModel({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.type,
    required this.status,
    required this.startedAt,
    this.answeredAt,
    this.endedAt,
    required this.duration,
    required this.caller,
    required this.receiver,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'] as int,
      callerId: json['caller_id'] as int,
      receiverId: json['receiver_id'] as int,
      type: json['type'] as String,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      answeredAt: json['answered_at'] != null 
          ? DateTime.parse(json['answered_at'] as String) 
          : null,
      endedAt: json['ended_at'] != null 
          ? DateTime.parse(json['ended_at'] as String) 
          : null,
      duration: json['duration'] as int,
      caller: CallUser.fromJson(json['caller'] as Map<String, dynamic>),
      receiver: CallUser.fromJson(json['receiver'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caller_id': callerId,
      'receiver_id': receiverId,
      'type': type,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'answered_at': answeredAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration': duration,
      'caller': caller.toJson(),
      'receiver': receiver.toJson(),
    };
  }

  bool get isVideoCall => type == 'video';
  bool get isAudioCall => type == 'audio';
  bool get isActive => status == 'accepted' || status == 'initiated';
  bool get isEnded => status == 'ended' || status == 'rejected';
}

class CallUser {
  final int id;
  final String name;
  final String? avatar;

  CallUser({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory CallUser.fromJson(Map<String, dynamic> json) {
    return CallUser(
      id: json['id'] as int,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
    };
  }
}

class CallHistoryResponse {
  final int currentPage;
  final List<CallModel> data;
  final int total;

  CallHistoryResponse({
    required this.currentPage,
    required this.data,
    required this.total,
  });

  factory CallHistoryResponse.fromJson(Map<String, dynamic> json) {
    return CallHistoryResponse(
      currentPage: json['current_page'] as int,
      data: (json['data'] as List)
          .map((item) => CallModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }
}

class CallInitiateResponse {
  final int callId;
  final String status;

  CallInitiateResponse({
    required this.callId,
    required this.status,
  });

  factory CallInitiateResponse.fromJson(Map<String, dynamic> json) {
    return CallInitiateResponse(
      callId: json['call_id'] as int,
      status: json['status'] as String,
    );
  }
}
