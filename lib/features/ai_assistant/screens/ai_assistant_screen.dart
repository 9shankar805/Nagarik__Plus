import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/ai_provider.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _isTyping = false;

  static const List<String> _suggestions = [
    'How to apply for a passport?',
    'Driving license requirements',
    'PAN card registration',
    'National ID card help',
    'Citizenship certificate',
    'Tax filing information',
    'Voter ID registration',
    'Birth certificate process',
  ];

  static const Map<String, String> _responses = {
    'passport':
        '📘 **Passport Application (Nepal):**\n\n• Requirements: Citizenship, Birth certificate, 2 PP photos, Rs. 5,000 fee\n• Apply online at: dop.gov.np (e-passport portal)\n• Visit District Administration Office (DAO) for biometrics\n• Processing: ~15–30 working days\n• Enquiry: 01-4416000\n\nWould you like step-by-step instructions?',
    'driving':
        '🚗 **Driving License (Nepal):**\n\n• Categories: A (2-wheeler), B (car), C (truck), etc.\n• Process: Written test → Trial → Medical → License\n• Fee: ~Rs. 1,500–2,500 depending on category\n• Apply at: Department of Transport Management (dotm.gov.np)\n• Required: Citizenship, Medical form, Photos\n• Validity: 5 years (renewable)\n\nNeed help with a specific step?',
    'pan':
        '💳 **PAN Card Registration:**\n\n• PAN = Permanent Account Number (tax ID)\n• Apply online at: ird.gov.np → Taxpayer Portal\n• Required: Citizenship, Photo, Phone number\n• Fee: Free (Rs. 0)\n• Processing: Same day to 3 days\n• Mandatory for: Business, Salary > Rs. 400K/year, Property transactions\n\nNeed the step-by-step online form guide?',
    'national id':
        '🆔 **National ID Card (NID):**\n\n• Issued by: Dept. of National ID & Civil Registration (nid.gov.np)\n• Required: Citizenship certificate, Birth cert, 1 photo, Biometrics\n• Age: 16+ years\n• Process: Visit nearest NID center → Form → Biometrics → Collect\n• Fee: Rs. 200 (first time)\n• Used for: Voter ID, Banking, Government services, SIM registration\n\nWant to find your nearest NID center?',
    'citizenship':
        '🏛️ **Citizenship Certificate:**\n\n• Types: By descent, By birth, Naturalization\n• By descent: One/both parents Nepali → Apply at DAO\n• Required: Parents\' citizenship, Birth cert, SEE cert, Photos\n• Fee: ~Rs. 100–500\n• Processing: 7–30 days\n• Also: Ward recommendation letter\n\nNeed the complete document checklist?',
    'tax':
        '💰 **Income Tax Filing (Nepal):**\n\n• Due date: As per IRD calendar (usually end of Ashadh)\n• Portal: ird.gov.np → Taxpayer Login\n• Slabs (Individual): Up to 5L: 1% · 5L–10L: 10% · 10L–20L: 20% · 20L+: 30%\n• Need: PAN, Income details, Deductions (insurance, PF)\n• Late fee: Rs. 1,000 + interest\n\nWant me to walk you through e-filing?',
    'voter':
        '🗳️ **Voter ID Registration:**\n\n• Age: 18+ years (by election date)\n• Required: Citizenship, Age proof, Residence proof\n• Process:\n  1. Visit election.gov.np or nearest ward office\n  2. Fill Voter Registration Form (Form 11)\n  3. Submit documents + photo\n  4. Verification → Published in voter list\n• Check status: election.gov.np/voter-search\n• EC Hotline: 1064\n\nWant help checking if you\'re registered?',
    'birth':
        '👶 **Birth Certificate Registration:**\n\n• Timeline: Within 35 days (free); After = late fee\n• Required: Hospital slip + Parents\' citizenship + Marriage cert\n• Process: Get form from hospital/ward → Submit to Local Level → Verification → Certificate\n• Online: crs.dcr.gov.np (Civil Registration System)\n• Fee: Free (on time); Rs. 100–500 (late)\n• Mandatory for: Citizenship, School, Passport\n\nNeed marriage or death certificate info?',
    'marriage':
        '💍 **Marriage Certificate Registration:**\n\n• Required: Both citizenship + 2 witnesses + Photo + Rs. 100 fee\n• Age: Bride ≥20, Groom ≥20\n• Process: Apply at District Court or Ward → Verification → Certificate\n• Online: crs.dcr.gov.np\n• Processing: Same day to 1 week\n• Needed for: Passport, Visa, Joint accounts, Legal rights\n\nWant help with the application form?',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiProvider>().loadSuggestions();
      context.read<AiProvider>().loadHistory();
    });
    _messages.add(
      _Message(
        text: '👋 Namaste! I\'m your Nagarik+ AI Assistant.\n\nI can help you with:\n• Government service information\n• Document requirements\n• Office locations\n• Application processes\n\nHow can I assist you today?',
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_Message(text: text, isUser: true, time: DateTime.now()));
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final response = _getResponse(text.toLowerCase());
      setState(() {
        _isTyping = false;
        _messages.add(_Message(
            text: response, isUser: false, time: DateTime.now()));
      });
      _scrollToBottom();
    });
  }

  String _getResponse(String query) {
    for (final key in _responses.keys) {
      if (query.contains(key)) return _responses[key]!;
    }
    return '🤔 I don\'t have specific information about that yet. Please contact the relevant government office:\n\n• Passport: dop.gov.np | 01-4416000\n• Driving License: dotm.gov.np\n• Tax/PAN: ird.gov.np\n• National ID: nid.gov.np\n\nWould you like to know about any specific service?';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Assistant',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white)),
                Text('Online',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggestions
          if (_messages.length == 1)
            Container(
              height: 44,
              margin: const EdgeInsets.only(top: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => _sendMessage(_suggestions[index]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _suggestions[index],
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _TypingIndicator();
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask me about government services...',
                        hintStyle: const TextStyle(
                            color: AppColors.textLight, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: _sendMessage,
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_controller.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
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
  final _Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : AppColors.textDark,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 600))
        ..repeat(reverse: true),
    );
    _animations = _controllers
        .asMap()
        .entries
        .map((e) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: e.value,
                curve: Interval(e.key * 0.2, 1.0, curve: Curves.easeInOut),
              ),
            ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => AnimatedBuilder(
              animation: _animations[i],
              builder: (_, _) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8 + _animations[i].value * 6,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.4 + _animations[i].value * 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  final DateTime time;
  const _Message(
      {required this.text, required this.isUser, required this.time});
}
