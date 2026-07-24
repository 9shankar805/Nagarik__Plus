import 'dart:io';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

/// Contact sharing: read contacts → VCF → transfer, then import VCF on receiver
class ContactService {
  static final ContactService _i = ContactService._();
  factory ContactService() => _i;
  ContactService._();

  /// Request contacts permission
  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  /// Read all contacts on device
  Future<List<Contact>> loadContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) return [];
    return FlutterContacts.getContacts(withProperties: true);
  }

  /// Convert selected contacts to a single VCF file, returns file path
  Future<String> exportToVcf(List<Contact> contacts) async {
    final buffer = StringBuffer();
    for (final c in contacts) {
      buffer.writeln('BEGIN:VCARD');
      buffer.writeln('VERSION:3.0');
      buffer.writeln('FN:${c.displayName}');
      if (c.name.first.isNotEmpty || c.name.last.isNotEmpty) {
        buffer.writeln('N:${c.name.last};${c.name.first};;;');
      }
      for (final phone in c.phones) {
        buffer.writeln('TEL;TYPE=${phone.label.name.toUpperCase()}:${phone.number}');
      }
      for (final email in c.emails) {
        buffer.writeln('EMAIL;TYPE=${email.label.name.toUpperCase()}:${email.address}');
      }
      if (c.organizations.isNotEmpty) {
        buffer.writeln('ORG:${c.organizations.first.company}');
      }
      buffer.writeln('END:VCARD');
    }

    final tmp = await getTemporaryDirectory();
    final file = File(p.join(tmp.path, 'contacts_${DateTime.now().millisecondsSinceEpoch}.vcf'));
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  /// Import a received VCF file into device contacts
  Future<int> importVcf(String vcfPath) async {
    if (!await FlutterContacts.requestPermission()) return 0;

    final content = await File(vcfPath).readAsString();
    final cards   = _parseVcf(content);
    int imported  = 0;

    for (final card in cards) {
      try {
        await FlutterContacts.insertContact(card);
        imported++;
      } catch (_) {}
    }
    return imported;
  }

  List<Contact> _parseVcf(String vcf) {
    final contacts = <Contact>[];
    final cards    = vcf.split('BEGIN:VCARD');

    for (final card in cards) {
      if (card.trim().isEmpty) continue;
      final lines = card.split('\n').map((l) => l.trim()).toList();

      final c     = Contact();
      String fn   = '';
      String nLast = '', nFirst = '';

      for (final line in lines) {
        if (line.startsWith('FN:')) {
          fn = line.substring(3);
        } else if (line.startsWith('N:')) {
          final parts = line.substring(2).split(';');
          nLast  = parts.isNotEmpty ? parts[0] : '';
          nFirst = parts.length > 1 ? parts[1] : '';
        } else if (line.startsWith('TEL')) {
          final number = line.contains(':') ? line.split(':').last : '';
          if (number.isNotEmpty) {
            c.phones.add(Phone(number));
          }
        } else if (line.startsWith('EMAIL')) {
          final email = line.contains(':') ? line.split(':').last : '';
          if (email.isNotEmpty) {
            c.emails.add(Email(email));
          }
        }
      }

      c.name = Name(first: nFirst, last: nLast);
      if (fn.isNotEmpty && nFirst.isEmpty) {
        final parts = fn.split(' ');
        c.name = Name(
          first: parts.first,
          last:  parts.length > 1 ? parts.sublist(1).join(' ') : '',
        );
      }

      if (c.name.first.isNotEmpty || c.name.last.isNotEmpty || fn.isNotEmpty) {
        contacts.add(c);
      }
    }
    return contacts;
  }
}
