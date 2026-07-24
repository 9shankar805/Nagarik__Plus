enum ChatMessageType {
  text,
  image,
  document,
  system,
}

class AdvisorChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isFromAdvisor;
  final ChatMessageType messageType;
  final String? attachmentUrl;
  final String? attachmentName;

  const AdvisorChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isFromAdvisor,
    this.messageType = ChatMessageType.text,
    this.attachmentUrl,
    this.attachmentName,
  });
}
