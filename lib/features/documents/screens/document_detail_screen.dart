import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:provider/provider.dart';
import 'document_scanner_screen.dart';
import '../models/document_model.dart';
import '../providers/document_service.dart';
import '../providers/documents_provider.dart';
import '../services/document_pdf_printer.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';

class DocumentDetailScreen extends StatefulWidget {
  final DocumentModel document;
  const DocumentDetailScreen({super.key, required this.document});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late DocumentModel _doc;
  bool _isBackView = false;
  final DocumentService _docService = DocumentService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _doc = widget.document;
    _refreshDoc();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _refreshDoc() async {
    final updated = await _docService.getById(widget.document.id);
    if (updated != null && mounted) {
      setState(() {
        _doc = updated;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  Future<void> _pickAndSaveImage(ImageSource source, {bool isBack = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image == null) return;
      await _processAndSaveFile(File(image.path), isBack: isBack);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _pickAndSaveFile({bool isBack = false}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result == null || result.files.single.path == null) return;

      await _processAndSaveFile(File(result.files.single.path!), isBack: isBack);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _processAndSaveFile(File sourceFile, {required bool isBack}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDir.path}/nagarik_docs');
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }

      final ext = p.extension(sourceFile.path);
      final filename = '${_doc.id}_${isBack ? "back" : "front"}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final savedFile = await sourceFile.copy('${docsDir.path}/$filename');

      final updatedDoc = _doc.copyWith(
        localFilePath: isBack ? _doc.localFilePath : savedFile.path,
        localBackFilePath: isBack ? savedFile.path : _doc.localBackFilePath,
        isUploaded: true,
        subtitle: '${_doc.title} • Verified',
      );

      await _docService.save(updatedDoc);

      if (!mounted) return;
      setState(() {
        _doc = updatedDoc;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_doc.title} (${isBack ? "Back Side" : "Front Side"}) saved to secure digital locker!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving document file: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _startNagarikScan({bool isBack = false}) async {
    try {
      final pictures = await CunningDocumentScanner.getPictures();
      if (pictures != null && pictures.isNotEmpty) {
        await _processAndSaveFile(File(pictures.first), isBack: isBack);
        return;
      }
    } catch (_) {
      // Fallback on platform error or cancel
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DocumentScannerScreen(),
      ),
    );
  }

  void _showUploadOptions({bool isBack = false}) {
    final sideText = isBack ? 'Back Side' : 'Front Side';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Upload / Capture ${_doc.title} ($sideText)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Capture or attach your document image for offline verification and digital locker storage.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Nagarik Document Scanner (Auto Crop & Align)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF003893), Color(0xFF1565C0)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.document_scanner_rounded, color: Colors.white),
                  ),
                  title: Row(
                    children: [
                      const Text('Scan with Nagarik Scanner',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('AUTO CROP',
                            style: TextStyle(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  subtitle: const Text('Auto edge detection, card boundary align & filters',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    _startNagarikScan(isBack: isBack);
                  },
                ),
                const Divider(color: Colors.white10),

                // Camera Option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Quick Camera Capture',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Take a instant photo of your card',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSaveImage(ImageSource.camera, isBack: isBack);
                  },
                ),
                const Divider(color: Colors.white10),

                // Gallery Option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF388E3C).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF4ADE80)),
                  ),
                  title: const Text('Upload from Photo Gallery',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Select photo from gallery or album',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSaveImage(ImageSource.gallery, isBack: isBack);
                  },
                ),
                const Divider(color: Colors.white10),

                // File Picker Option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.folder_rounded, color: Color(0xFFCE93D8)),
                  ),
                  title: const Text('Browse Files (PDF / Images)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Choose document file from internal storage',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSaveFile(isBack: isBack);
                  },
                ),

                if ((isBack && _doc.localBackFilePath != null) || (!isBack && _doc.localFilePath != null)) ...[
                  const Divider(color: Colors.white10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    ),
                    title: const Text('Remove Photo',
                        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 14)),
                    onTap: () async {
                      Navigator.pop(context);
                      final updated = _doc.copyWith(
                        localFilePath: isBack ? _doc.localFilePath : null,
                        localBackFilePath: isBack ? null : _doc.localBackFilePath,
                        isUploaded: isBack ? (_doc.localFilePath != null) : (_doc.localBackFilePath != null),
                      );
                      await _docService.save(updated);
                      setState(() => _doc = updated);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImageViewer(String path, String title) {
    showDialog(
      context: context,
      builder: (context) {
        final isAsset = path.startsWith('assets/');
        final fileExists = !isAsset && File(path).existsSync();

        return Dialog(
          backgroundColor: Colors.black.withValues(alpha: 0.92),
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.65,
                  ),
                  width: double.infinity,
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: isAsset
                        ? Image.asset(path, fit: BoxFit.contain)
                        : fileExists
                            ? Image.file(File(path), fit: BoxFit.contain)
                            : const Center(
                                child: Text('Image file not found on device',
                                    style: TextStyle(color: Colors.white54)),
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '🔍 Pinch to zoom • Drag to pan photo',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, _doc),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      // Side Toggle (Front / Back)
                      _buildSideToggle(),
                      const SizedBox(height: 8),

                      // Main Physical Card Representation
                      _buildCard(_doc),
                      const SizedBox(height: 20),

                      // Document Captured Image Preview Section
                      _buildUploadedImageSection(_doc),
                      const SizedBox(height: 16),

                      // Document Fields Details
                      _buildFieldsPanel(_doc),
                      const SizedBox(height: 16),

                      // Primary Action Row
                      _buildActionRow(context, _doc),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, DocumentModel doc) {
    final now = DateTime.now();
    final isExpired =
        doc.expiryDate != null && doc.expiryDate!.isBefore(now);
    final isExpiring = doc.expiryDate != null &&
        !isExpired &&
        doc.expiryDate!.difference(now).inDays < 90;

    Color statusColor = AppColors.success;
    String statusText = 'Valid';
    IconData statusIcon = Icons.verified_rounded;
    if (!doc.isUploaded) {
      statusColor = AppColors.warning;
      statusText = 'Missing Photo';
      statusIcon = Icons.warning_rounded;
    } else if (isExpired) {
      statusColor = AppColors.danger;
      statusText = 'Expired';
      statusIcon = Icons.cancel_rounded;
    } else if (isExpiring) {
      statusColor = AppColors.warning;
      statusText = 'Expiring';
      statusIcon = Icons.timer_rounded;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          Expanded(
            child: Text(doc.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(statusIcon, size: 12, color: statusColor),
              const SizedBox(width: 4),
              Text(statusText,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Download File',
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final docId = int.tryParse(doc.id);
                if (docId != null) {
                  final docProvider = context.read<DocumentsProvider>();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Downloading document...')),
                  );
                  await docProvider.downloadDoc(docId);
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Document downloaded successfully'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Download failed: ${e.toString().replaceFirst('Exception: ', '')}'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Print PDF Document',
            icon: const Icon(Icons.print_rounded, color: Colors.white, size: 22),
            onPressed: () => DocumentPdfPrinter.instance.printDocument(doc),
          ),
        ],
      ),
    );
  }

  Widget _buildSideToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2535),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isBackView = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isBackView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card_rounded,
                          color: !_isBackView ? Colors.white : Colors.white60, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Front Card View',
                        style: TextStyle(
                          color: !_isBackView ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isBackView = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isBackView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flip_to_back_rounded,
                          color: _isBackView ? Colors.white : Colors.white60, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Back Card View',
                        style: TextStyle(
                          color: _isBackView ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(DocumentModel doc) {
    switch (doc.type) {
      case 'national_id':
        return _NationalIdCard(
          doc: doc,
          isBack: _isBackView,
          onPhotoTap: () {
            if (_isBackView) {
              if (doc.localBackFilePath != null) {
                _showImageViewer(doc.localBackFilePath!, 'National ID Back Image');
              } else {
                _showUploadOptions(isBack: true);
              }
            } else {
              if (doc.localFilePath != null) {
                _showImageViewer(doc.localFilePath!, 'National ID Front Image');
              } else {
                _showUploadOptions(isBack: false);
              }
            }
          },
          onUploadTap: () => _showUploadOptions(isBack: _isBackView),
        );
      case 'driving_license':
        return _DrivingLicenseCard(doc: doc);
      case 'passport':
        return _PassportCard(doc: doc);
      case 'pan':
        return _PanCard(doc: doc);
      case 'citizenship':
        return _CitizenshipCard(doc: doc);
      default:
        return _GenericCard(doc: doc);
    }
  }

  Widget _buildUploadedImageSection(DocumentModel doc) {
    final hasFront = doc.localFilePath != null && File(doc.localFilePath!).existsSync();
    final hasBack = doc.localBackFilePath != null && File(doc.localBackFilePath!).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2535),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Captured / Uploaded Document Photos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (hasFront || hasBack)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Stored in Locker',
                      style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Front Photo Card
              Expanded(
                child: _ImagePreviewBox(
                  title: 'Front Side',
                  imagePath: doc.localFilePath,
                  fallbackAsset: doc.assetImagePath,
                  onTap: () {
                    if (hasFront) {
                      _showImageViewer(doc.localFilePath!, '${doc.title} (Front Side)');
                    } else if (doc.assetImagePath != null) {
                      _showImageViewer(doc.assetImagePath!, '${doc.title} Sample Card');
                    } else {
                      _showUploadOptions(isBack: false);
                    }
                  },
                  onEdit: () => _showUploadOptions(isBack: false),
                ),
              ),
              const SizedBox(width: 12),
              // Back Photo Card
              Expanded(
                child: _ImagePreviewBox(
                  title: 'Back Side',
                  imagePath: doc.localBackFilePath,
                  fallbackAsset: null,
                  onTap: () {
                    if (hasBack) {
                      _showImageViewer(doc.localBackFilePath!, '${doc.title} (Back Side)');
                    } else {
                      _showUploadOptions(isBack: true);
                    }
                  },
                  onEdit: () => _showUploadOptions(isBack: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsPanel(DocumentModel doc) {
    if (doc.fields.isEmpty) return const SizedBox.shrink();
    final entries = doc.fields.entries.toList();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2535),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Document Details',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...List.generate(entries.length, (i) {
            final e = entries[i];
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(e.key,
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: e.value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${e.key} copied'),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Text(e.value,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                if (i < entries.length - 1)
                  const Divider(color: Colors.white12, height: 18),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, DocumentModel doc) {
    return Column(
      children: [
        // Primary Nagarik Document Scanner button
        GestureDetector(
          onTap: () => _startNagarikScan(isBack: _isBackView),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003893), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Scan with Nagarik Scanner (${_isBackView ? "Back Side" : "Front Side"})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                icon: Icons.camera_alt_rounded,
                label: 'Capture Front',
                isPrimary: false,
                onTap: () => _showUploadOptions(isBack: false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionBtn(
                icon: Icons.flip_to_back_rounded,
                label: 'Capture Back',
                isPrimary: false,
                onTap: () => _showUploadOptions(isBack: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                icon: Icons.print_rounded,
                label: 'Print PDF',
                isPrimary: true,
                onTap: () async {
                  await DocumentPdfPrinter.instance.printDocument(_doc);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionBtn(
                icon: Icons.picture_as_pdf_rounded,
                label: 'Share PDF',
                isPrimary: false,
                onTap: () async {
                  await DocumentPdfPrinter.instance.sharePdf(_doc);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// National ID Card View (Front & Back)
// ─────────────────────────────────────────────────────────────────────────────
class _NationalIdCard extends StatelessWidget {
  final DocumentModel doc;
  final bool isBack;
  final VoidCallback onPhotoTap;
  final VoidCallback onUploadTap;

  const _NationalIdCard({
    required this.doc,
    this.isBack = false,
    required this.onPhotoTap,
    required this.onUploadTap,
  });

  @override
  Widget build(BuildContext context) {
    final f = doc.fields;

    if (isBack) {
      final hasBackPhoto = doc.localBackFilePath != null && File(doc.localBackFilePath!).existsSync();

      return _CardShell(
        height: 210,
        headerColors: const [Color(0xFF002970), Color(0xFF0D47A1)],
        headerContent: Row(
          children: [
            Image.asset(AppAssets.appIcon, width: 22, height: 22,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.shield, color: Colors.white, size: 18)),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Government of Nepal • National Identity Office',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                          fontWeight: FontWeight.w500)),
                  Text('NATIONAL IDENTITY CARD (BACK SIDE)',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
            const Text('NID BACK', style: TextStyle(
                color: Colors.white60, fontSize: 8.5, fontWeight: FontWeight.w700)),
          ],
        ),
        bodyContent: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Image or QR Code container
              GestureDetector(
                onTap: onPhotoTap,
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 95,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEF8),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBBCCE8), width: 1.2),
                      ),
                      child: hasBackPhoto
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.file(File(doc.localBackFilePath!), fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.qr_code_2_rounded,
                                    color: Color(0xFF003893), size: 36),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '+ Capture',
                                    style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Fields on Back
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: [
                      Expanded(child: _CardField('Citizenship No', f['Citizenship No'] ?? '040-02-54321')),
                      const SizedBox(width: 6),
                      Expanded(child: _CardField('District', f['Address']?.split(',').first ?? 'Kathmandu')),
                    ]),
                    const SizedBox(height: 5),
                    _CardField('Issuer Authority', 'Dept of National ID & Civil Reg.'),
                    const SizedBox(height: 5),
                    _CardField('Card Status', hasBackPhoto ? 'VERIFIED & STORED' : 'TAP TO CAPTURE BACK',
                        isLast: true,
                        valueColor: hasBackPhoto ? AppColors.success : AppColors.warning),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Front Side View
    final hasPhoto = doc.localFilePath != null && File(doc.localFilePath!).existsSync();

    return _CardShell(
      height: 210,
      headerColors: const [Color(0xFF003893), Color(0xFF1565C0)],
      headerContent: Row(
        children: [
          Image.asset(AppAssets.appIcon, width: 22, height: 22,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.shield, color: Colors.white, size: 18)),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Government of Nepal',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w500)),
                Text('NATIONAL IDENTITY CARD',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          const Text('NID', style: TextStyle(
              color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w700)),
        ],
      ),
      bodyContent: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Container with camera icon overlay
            GestureDetector(
              onTap: onPhotoTap,
              child: Stack(
                children: [
                  Container(
                    width: 75,
                    height: 95,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EEF8),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBBCCE8), width: 1.2),
                    ),
                    child: hasPhoto
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.file(File(doc.localFilePath!), fit: BoxFit.cover),
                          )
                        : doc.assetImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.asset(doc.assetImagePath!, fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                        Icons.person_rounded,
                                        color: Color(0xFF8899BB),
                                        size: 40)),
                              )
                            : const Icon(Icons.person_rounded,
                                color: Color(0xFF8899BB), size: 40),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Fields
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CardField('Name', f['Full Name'] ?? 'Ram Bahadur Thapa'),
                  const SizedBox(height: 5),
                  Row(children: [
                    Expanded(child: _CardField('NID Number', f['NID Number'] ?? '1234-5678-9012')),
                    const SizedBox(width: 6),
                    Expanded(child: _CardField('Gender', f['Gender'] ?? 'Male')),
                  ]),
                  const SizedBox(height: 5),
                  Row(children: [
                    Expanded(child: _CardField('Date of Birth', f['Date of Birth'] ?? '2045-06-15')),
                    const SizedBox(width: 6),
                    Expanded(child: _CardField('Address', f['Address'] ?? 'Kathmandu, Bagmati', isLast: true)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Driving License Card
// ─────────────────────────────────────────────────────────────────────────────
class _DrivingLicenseCard extends StatelessWidget {
  final DocumentModel doc;
  const _DrivingLicenseCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final f = doc.fields;
    return _CardShell(
      height: 210,
      headerColors: const [Color(0xFF1B5E20), Color(0xFF2E7D32)],
      headerContent: Row(
        children: [
          const Icon(Icons.drive_eta_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Government of Nepal — DoTM',
                    style: TextStyle(color: Colors.white70, fontSize: 8)),
                Text('DRIVING LICENSE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          const Text('DL', style: TextStyle(
              color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w700)),
        ],
      ),
      bodyContent: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFB8DBB8), width: 1),
              ),
              child: const Icon(Icons.person_rounded,
                  color: Color(0xFF88AA88), size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CardField('Name', f['Full Name'] ?? '—'),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: _CardField('License No', f['License No'] ?? '—')),
                    const SizedBox(width: 4),
                    Expanded(child: _CardField('Category', f['Category'] ?? '—')),
                  ]),
                  const SizedBox(height: 4),
                  _CardField('Expiry', f['Expiry Date'] ?? '—',
                      isLast: true,
                      valueColor: _isExpired(f['Expiry Date'])
                          ? AppColors.danger
                          : null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isExpired(String? dateStr) {
    if (dateStr == null) return false;
    try {
      final parts = dateStr.split('-');
      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]),
          int.parse(parts[2]));
      return d.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Passport Card
// ─────────────────────────────────────────────────────────────────────────────
class _PassportCard extends StatelessWidget {
  final DocumentModel doc;
  const _PassportCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final f = doc.fields;
    return _CardShell(
      height: 210,
      headerColors: const [Color(0xFF00695C), Color(0xFF00897B)],
      headerContent: Row(
        children: [
          const Icon(Icons.book_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Government of Nepal',
                    style: TextStyle(color: Colors.white70, fontSize: 8)),
                Text('PASSPORT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ],
            ),
          ),
          Text(f['Passport No'] ?? '',
              style: const TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
      bodyContent: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFB2DFDB), width: 1),
              ),
              child: const Icon(Icons.person_rounded,
                  color: Color(0xFF80CBC4), size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CardField('Name', f['Full Name'] ?? '—'),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: _CardField('Nationality', f['Nationality'] ?? '—')),
                    const SizedBox(width: 4),
                    Expanded(child: _CardField('Date of Birth', f['Date of Birth'] ?? '—')),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: _CardField('Place of Issue', f['Place of Issue'] ?? '—')),
                    const SizedBox(width: 4),
                    Expanded(child: _CardField('Expiry', f['Expiry Date'] ?? '—', isLast: true)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAN Card
// ─────────────────────────────────────────────────────────────────────────────
class _PanCard extends StatelessWidget {
  final DocumentModel doc;
  const _PanCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final f = doc.fields;
    return _CardShell(
      height: 180,
      headerColors: const [Color(0xFFF57F17), Color(0xFFF9A825)],
      headerContent: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inland Revenue Department',
                    style: TextStyle(color: Colors.white70, fontSize: 8)),
                Text('PERMANENT ACCOUNT NUMBER',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3)),
              ],
            ),
          ),
        ],
      ),
      bodyContent: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Center(
              child: Text(
                f['PAN Number'] ?? '—',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A2B4A),
                    letterSpacing: 3),
              ),
            ),
            const Divider(color: Color(0xFFEEEEEE), height: 1),
            _CardField('Name', f['Full Name'] ?? '—'),
            _CardField('Issue Date', f['Issue Date'] ?? '—', isLast: true),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Citizenship Card
// ─────────────────────────────────────────────────────────────────────────────
class _CitizenshipCard extends StatelessWidget {
  final DocumentModel doc;
  const _CitizenshipCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final f = doc.fields;
    return _CardShell(
      height: 210,
      headerColors: const [Color(0xFF4A148C), Color(0xFF6A1B9A)],
      headerContent: Row(
        children: [
          const Icon(Icons.assignment_ind_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Government of Nepal',
                    style: TextStyle(color: Colors.white70, fontSize: 8)),
                Text('CITIZENSHIP CERTIFICATE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3)),
              ],
            ),
          ),
        ],
      ),
      bodyContent: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Photo placeholder
            Container(
              width: 62,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCE93D8), width: 1),
              ),
              child: const Icon(Icons.person_rounded,
                  color: Color(0xFFBA68C8), size: 34),
            ),
            const SizedBox(width: 12),
            // 2-column grid — 3 rows × 2 cols = 6 fields, never overflows
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(children: [
                    Expanded(child: _CardField('Full Name', f['Full Name'] ?? '—')),
                    Expanded(child: _CardField('Citizenship No', f['Citizenship No'] ?? '—')),
                  ]),
                  const SizedBox(height: 7),
                  Row(children: [
                    Expanded(child: _CardField('Date of Birth', f['Date of Birth'] ?? '—')),
                    Expanded(child: _CardField('District', f['Issue District'] ?? '—')),
                  ]),
                  const SizedBox(height: 7),
                  Row(children: [
                    Expanded(child: _CardField('Father', f['Father Name'] ?? '—', isLast: true)),
                    Expanded(child: _CardField('Mother', f['Mother Name'] ?? '—', isLast: true)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic Card — image-based fallback
// ─────────────────────────────────────────────────────────────────────────────
class _GenericCard extends StatelessWidget {
  final DocumentModel doc;
  const _GenericCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: doc.assetImagePath != null
            ? Image.asset(doc.assetImagePath!, fit: BoxFit.cover)
            : doc.localFilePath != null
                ? Image.file(File(doc.localFilePath!), fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFF1A2535),
                    child: const Center(
                      child: Icon(Icons.insert_drive_file_rounded,
                          color: Colors.white38, size: 60),
                    ),
                  ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card field row — label + value
// ─────────────────────────────────────────────────────────────────────────────
class _CardField extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  final Color? valueColor;

  const _CardField(this.label, this.value,
      {this.isLast = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8899AA),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? const Color(0xFF1A2B4A),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Preview Box (Front / Back Card)
// ─────────────────────────────────────────────────────────────────────────────
class _ImagePreviewBox extends StatelessWidget {
  final String title;
  final String? imagePath;
  final String? fallbackAsset;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ImagePreviewBox({
    required this.title,
    required this.imagePath,
    this.fallbackAsset,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = imagePath != null && File(imagePath!).existsSync();
    final hasAsset = fallbackAsset != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF101923),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? AppColors.primary.withValues(alpha: 0.6) : Colors.white12,
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              if (hasFile)
                Positioned.fill(
                  child: Image.file(File(imagePath!), fit: BoxFit.cover),
                )
              else if (hasAsset)
                Positioned.fill(
                  child: Image.asset(fallbackAsset!, fit: BoxFit.cover),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_rounded,
                          color: Colors.white38, size: 28),
                      const SizedBox(height: 4),
                      Text('Add $title',
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),

              // Title overlay badge top-left
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold)),
                ),
              ),

              // Edit / Camera button bottom-right
              Positioned(
                bottom: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      hasFile ? Icons.edit_rounded : Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card shell — rounded rect with gradient header
// ─────────────────────────────────────────────────────────────────────────────
class _CardShell extends StatelessWidget {
  final List<Color> headerColors;
  final Widget headerContent;
  final Widget bodyContent;
  final double? height;

  const _CardShell({
    required this.headerColors,
    required this.headerContent,
    required this.bodyContent,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: height != null ? BoxConstraints(minHeight: height!) : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: headerColors.last.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Coloured header strip
            Container(
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: headerColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: headerContent,
            ),
            // White body
            bodyContent,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action button
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isPrimary ? Colors.white : Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isPrimary ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
