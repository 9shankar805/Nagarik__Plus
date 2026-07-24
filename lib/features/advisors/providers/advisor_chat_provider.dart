import 'dart:async';
import 'package:flutter/material.dart';

import '../models/advisor_chat_message.dart';
import '../models/advisor_model.dart';

class AdvisorChatProvider extends ChangeNotifier {
  final Advisor advisor;

  AdvisorChatProvider({required this.advisor}) {
    _initializeChat();
  }

  final List<AdvisorChatMessage> _messages = [];
  bool _isAdvisorTyping = false;

  List<AdvisorChatMessage> get messages => List.unmodifiable(_messages);
  bool get isAdvisorTyping => _isAdvisorTyping;

  void _initializeChat() {
    _messages.add(
      AdvisorChatMessage(
        id: 'msg_system_init',
        senderId: 'system',
        senderName: 'System',
        text: 'Consultation Session Active with ${advisor.name}. Verification Pass #NGK-ADV-${advisor.id.toUpperCase()}',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        isFromAdvisor: false,
        messageType: ChatMessageType.system,
      ),
    );

    _messages.add(
      AdvisorChatMessage(
        id: 'msg_adv_welcome',
        senderId: advisor.id,
        senderName: advisor.name,
        text: 'नमस्ते! म ${advisor.name}। ${advisor.titleNp}। हजुरलाई कसरी सहयोग गर्न सक्छु? Please feel free to ask your query or upload relevant government documents.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        isFromAdvisor: true,
      ),
    );
  }

  void sendMessage(String text, {ChatMessageType type = ChatMessageType.text, String? attachmentName}) {
    if (text.trim().isEmpty && attachmentName == null) return;

    final userMsg = AdvisorChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'citizen_user',
      senderName: 'You (Citizen)',
      text: text,
      timestamp: DateTime.now(),
      isFromAdvisor: false,
      messageType: type,
      attachmentName: attachmentName,
    );

    _messages.add(userMsg);
    notifyListeners();

    // Trigger simulated advisor typing & smart response
    _simulateAdvisorReply(text);
  }

  void _simulateAdvisorReply(String promptText) {
    _isAdvisorTyping = true;
    notifyListeners();

    Timer(const Duration(seconds: 2), () {
      _isAdvisorTyping = false;

      String replyText = _generateSmartResponse(promptText, advisor.category);

      final replyMsg = AdvisorChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: advisor.id,
        senderName: advisor.name,
        text: replyText,
        timestamp: DateTime.now(),
        isFromAdvisor: true,
      );

      _messages.add(replyMsg);
      notifyListeners();
    });
  }

  String _generateSmartResponse(String input, AdvisorCategory category) {
    final lower = input.toLowerCase();

    if (category == AdvisorCategory.legal) {
      if (lower.contains('citizenship') || lower.contains('नागरिकता')) {
        return 'नागरिकता संशोधनको लागि सम्बन्धित वडा कार्यालयको सिफारिश, पुरानो नागरिकता वा जन्म दर्ता प्रमाणपत्र अनिवार्य चाहिन्छ। तपाइँको कुन विवरण सच्याउनुपर्ने हो?';
      }
      if (lower.contains('property') || lower.contains('जग्गा') || lower.contains('अंश')) {
        return 'अंशबण्डाको लागि परिवारको सबै हकवालाहरूको सहमतीपत्र र मालपोत कार्यालयको पूर्जा दर्ता नक्शा अनिवार्य हुन्छ।';
      }
      return 'तपाइँको कानूनी विषय प्राप्त भयो। यसमा मुलुकी देवानी संहिता अनुसार आवश्यक कागजात तयार गरी वडा वा अदालतमा निवेदन दिन सकिन्छ। थप विवरण पठाउनुहोस्।';
    }

    if (category == AdvisorCategory.tax) {
      if (lower.contains('pan') || lower.contains('प्यान')) {
        return 'व्यक्तिगत PAN निःशुल्क आन्तरिक राजस्व विभाग (IRD) को पोर्टलबाट १ दिनमै प्राप्त गर्न सकिन्छ। नागरिकता र फोटो अपलोड गर्नुहोला।';
      }
      if (lower.contains('vat') || lower.contains('भ्याट')) {
        return 'थ्रेसहोल्ड रु. ५० लाख (वस्तु) वा रु. २० लाख (सेवा) नाघेमा VAT दर्ता अनिवार्य हुन्छ।';
      }
      return 'कर चुक्ता प्रमाण पत्र लिन अघिल्लो आर्थिक वर्षको आय विवरण र बैंक भौचर चुक्ता गरेको प्रमाण बुझाउनुपर्छ।';
    }

    if (category == AdvisorCategory.passportNid) {
      if (lower.contains('passport') || lower.contains('राहदानी')) {
        return 'इ-राहदानी (e-Passport) को लागि राष्ट्रिय परिचयपत्र (NID) नम्बर अनिवार्य भइसकेको छ। NID बायोमेट्रिक गरिसकेपछि अपोइन्टमेन्ट लिनुहोला।';
      }
      return 'NID बायोमेट्रिक विवरण संकलन भएको १-२ हप्ताभित्र राष्ट्रिय परिचयपत्र नम्बर (NIN) एसएमएस मार्फत प्राप्त हुन्छ।';
    }

    return 'धन्यवाद! तपाइँको प्रश्नको आधारमा सम्बन्धित सरकारी कार्यविधि अनुसार कागजात तयार गर्नुपर्छ। के तपाइँसँग कागजातको फोटो वा पीडीएफ फाइल छ?';
  }
}
