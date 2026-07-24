import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/advisor_model.dart';
import '../models/advisor_chat_message.dart';
import '../providers/advisor_chat_provider.dart';
import '../models/consultation_booking_model.dart';
import 'advisor_call_screen.dart';

class AdvisorChatScreen extends StatelessWidget {
  final Advisor advisor;

  const AdvisorChatScreen({super.key, required this.advisor});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdvisorChatProvider(advisor: advisor),
      child: _AdvisorChatBody(advisor: advisor),
    );
  }
}

class _AdvisorChatBody extends StatefulWidget {
  final Advisor advisor;

  const _AdvisorChatBody({required this.advisor});

  @override
  State<_AdvisorChatBody> createState() => _AdvisorChatBodyState();
}

class _AdvisorChatBodyState extends State<_AdvisorChatBody> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(AdvisorChatProvider chatProv) {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    chatProv.sendMessage(text);
    _scrollToBottom();
  }

  void _sendQuickPrompt(AdvisorChatProvider chatProv, String prompt) {
    chatProv.sendMessage(prompt);
    _scrollToBottom();
  }

  void _showAttachmentModal(AdvisorChatProvider chatProv) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isNepali ? 'सरकारी कागजात/फाइल संलग्न गर्नुहोस्' : 'Attach Document or Image',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F0FF),
                  child: Icon(Icons.badge_rounded, color: AppColors.primary),
                ),
                title: Text(isNepali ? 'नागरिकता / NID फोटो' : 'Citizenship / NID Photo'),
                subtitle: Text(isNepali ? 'समीक्षाको लागि नागरिकताको फोटो पठाउनुहोस्' : 'Upload front & back photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  chatProv.sendMessage(
                    'म मेरो नागरिकताको फोटो समीक्षाको लागि पठाउँदै छु।',
                    type: ChatMessageType.image,
                    attachmentName: 'Citizenship_Front_Back.jpg',
                  );
                  _scrollToBottom();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2E7D32)),
                ),
                title: Text(isNepali ? 'सरकारी निवेदन / PDF कागजात' : 'Official Application PDF'),
                subtitle: Text(isNepali ? 'डिजिटल फारम वा फाइल अपलोड' : 'Upload application document'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  chatProv.sendMessage(
                    'म सम्बन्धित फारमको PDF फाइल पठाउँदै छु।',
                    type: ChatMessageType.document,
                    attachmentName: 'Government_Application_Form.pdf',
                  );
                  _scrollToBottom();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final chatProv = Provider.of<AdvisorChatProvider>(context);

    final quickPrompts = [
      isNepali ? 'कस्तो कागजात चाहिन्छ?' : 'What documents required?',
      isNepali ? 'प्रक्रिया कति समय लाग्छ?' : 'How long does process take?',
      isNepali ? 'सरकारी शुल्क कति हो?' : 'What is government fee?',
      isNepali ? 'नागरिकता संशोधन विधि' : 'Citizenship correction guide',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(widget.advisor.avatarUrl),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.advisor.isOnline ? const Color(0xFF388E3C) : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.advisor.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    chatProv.isAdvisorTyping
                        ? (isNepali ? 'टाइप गर्दै हुनुहुन्छ...' : 'Typing response...')
                        : (isNepali ? 'सक्रिय परामर्श' : 'Active Session'),
                    style: TextStyle(
                      fontSize: 11,
                      color: chatProv.isAdvisorTyping ? AppColors.accentLight : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isNepali ? 'अडियो कल सुरु गर्नुहोस्' : 'Start Voice Call',
            icon: const Icon(Icons.phone_rounded, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdvisorCallScreen(
                    advisor: widget.advisor,
                    callType: ConsultationType.audioCall,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              itemCount: chatProv.messages.length,
              itemBuilder: (context, index) {
                final msg = chatProv.messages[index];
                return _MessageBubble(message: msg, advisorAvatar: widget.advisor.avatarUrl);
              },
            ),
          ),

          // Typing animation indicator
          if (chatProv.isAdvisorTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(widget.advisor.avatarUrl),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        SizedBox(width: 8),
                        Text('Advisor is typing...', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Quick Suggestion Chips
          Container(
            height: 42,
            color: const Color(0xFFF1F5F9),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: quickPrompts.length,
              itemBuilder: (context, index) {
                final prompt = quickPrompts[index];
                return GestureDetector(
                  onTap: () => _sendQuickPrompt(chatProv, prompt),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      prompt,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                    onPressed: () => _showAttachmentModal(chatProv),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: isNepali ? 'यहाँ सन्देश वा प्रश्न लेख्नुहोस्...' : 'Type message or query...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFF),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _handleSend(chatProv),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _handleSend(chatProv),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AdvisorChatMessage message;
  final String advisorAvatar;

  const _MessageBubble({required this.message, required this.advisorAvatar});

  @override
  Widget build(BuildContext context) {
    if (message.messageType == ChatMessageType.system) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.bold),
        ),
      );
    }

    final isMe = !message.isFromAdvisor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(advisorAvatar),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.attachmentName != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withOpacity(0.2) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            message.messageType == ChatMessageType.image
                                ? Icons.image_rounded
                                : Icons.insert_drive_file_rounded,
                            size: 18,
                            color: isMe ? Colors.white : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              message.attachmentName!,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white : AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isMe ? Colors.white : AppColors.textDark,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${message.timestamp.hour.toString().padLeft(2, "0")}:${message.timestamp.minute.toString().padLeft(2, "0")}',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isMe ? Colors.white70 : AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
