import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/l10n_extension.dart';
import 'package:provider/provider.dart';
import '../../scanner/screens/camera_scanner_screen.dart';
import '../../scanner/controllers/scanner_controller.dart';
import '../../scanner/screens/vault_screen.dart';
import '../models/document_model.dart';
import '../providers/documents_provider.dart';
import 'document_detail_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategory = 0;

  final List<_DocCategory> _categories = [
    _DocCategory('All', Icons.grid_view_rounded),
    _DocCategory('Identity', Icons.badge_rounded),
    _DocCategory('Vehicle', Icons.drive_eta_rounded),
    _DocCategory('Finance', Icons.account_balance_rounded),
    _DocCategory('Property', Icons.home_rounded),
    _DocCategory('Medical', Icons.medical_services_rounded),
    _DocCategory('Academic', Icons.school_rounded),
  ];




  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentsProvider>().loadDocuments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getCategoryLabel(BuildContext context, String labelKey) {
    switch (labelKey) {
      case 'All': return context.l10n.all;
      case 'Identity': return context.l10n.categoryIdentity;
      case 'Vehicle': return context.l10n.categoryVehicle;
      case 'Finance': return context.l10n.categoryFinance;
      case 'Property': return context.l10n.categoryProperty;
      case 'Medical': return context.l10n.categoryMedical;
      case 'Academic': return context.l10n.categoryAcademic;
      default: return labelKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          context.l10n.digitalLocker,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.folder_special_rounded, color: Colors.white),
            tooltip: 'Scan Vault',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VaultScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<DocumentsProvider>(
        builder: (context, provider, child) {
          if (provider.status == DocumentsStatus.loading && provider.documents.isEmpty) {
            return _buildSkeletonLoader();
          }
          if (provider.status == DocumentsStatus.error && provider.documents.isEmpty) {
            return _buildErrorWidget(
              provider.errorMessage,
              () => provider.loadDocuments(forceRefresh: true),
            );
          }

          final documents = provider.documents;
          final expiringDocs = provider.expiringDocuments;
          final uploadedCount = documents.where((d) => d.isUploaded).length;
          final missingCount = documents.where((d) => !d.isUploaded).length;
          final expiringCount = expiringDocs.length;

          // Filter documents by category
          final selectedCategory = _categories[_selectedCategory].label;
          final filteredDocuments = _selectedCategory == 0
              ? documents
              : documents.where((d) => d.category == selectedCategory).toList();

          return Column(
            children: [
              // Security Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.aesEncrypted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            context.l10n.allDocsSecured,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.l10n.secureTag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatChip(
                      label: '$uploadedCount ${context.l10n.uploaded}',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: '$missingCount ${context.l10n.missing}',
                      icon: Icons.warning_rounded,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: '$expiringCount ${context.l10n.expiring}',
                      icon: Icons.timer_rounded,
                      color: AppColors.danger,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Category filter
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategory == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          _getCategoryLabel(context, _categories[index].label),
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textMedium,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Document Grid
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.refreshDocuments(),
                  color: AppColors.primary,
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredDocuments.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filteredDocuments.length) {
                        return _AddDocumentCard(onTap: () => _showAddDocumentSheet(context));
                      }
                      return _DocumentCard(doc: filteredDocuments[index]);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 6,
              itemBuilder: (_, _) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String? error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            const Text(
              'Failed to load documents',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              error ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDocumentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddDocumentSheet(),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel doc;
  const _DocumentCard({required this.doc});

  String _getDocTitle(BuildContext context, DocumentModel doc) {
    switch (doc.type) {
      case 'national_id': return context.l10n.nationalId;
      case 'driving_license': return context.l10n.drivingLicense;
      case 'pan': return context.l10n.panCard;
      case 'citizenship': return context.l10n.citizenship;
      case 'passport': return context.l10n.passport;
      case 'voter_id': return context.l10n.voterId;
      case 'vehicle_bluebook': return context.l10n.vehicleBluebook;
      case 'insurance': return context.l10n.insurance;
      case 'birth_certificate': return context.l10n.birthCertificate;
      default: return doc.title;
    }
  }

  Color _getDocColor(DocumentModel doc) {
    switch (doc.type) {
      case 'national_id': return AppColors.primary;
      case 'driving_license': return AppColors.secondary;
      case 'pan': return AppColors.accent;
      case 'citizenship': return const Color(0xFF6A1B9A);
      case 'passport': return const Color(0xFF00695C);
      case 'voter_id': return AppColors.danger;
      case 'vehicle_bluebook': return const Color(0xFF1565C0);
      case 'insurance': return const Color(0xFF00838F);
      case 'birth_certificate': return const Color(0xFF558B2F);
      default: return AppColors.primary;
    }
  }

  IconData _getDocIcon(DocumentModel doc) {
    switch (doc.type) {
      case 'national_id': return Icons.badge_rounded;
      case 'driving_license': return Icons.drive_eta_rounded;
      case 'pan': return Icons.receipt_long_rounded;
      case 'citizenship': return Icons.assignment_ind_rounded;
      case 'passport': return Icons.book_rounded;
      case 'voter_id': return Icons.how_to_vote_rounded;
      case 'vehicle_bluebook': return Icons.directions_car_rounded;
      case 'insurance': return Icons.security_rounded;
      case 'birth_certificate': return Icons.child_care_rounded;
      default: return Icons.document_scanner_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpiring = doc.expiryDate != null &&
        doc.expiryDate!.difference(now).inDays < 90;
    final isExpired = doc.expiryDate != null && doc.expiryDate!.isBefore(now);
    final color = _getDocColor(doc);
    final icon = _getDocIcon(doc);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isExpired
            ? Border.all(color: AppColors.danger, width: 1.5)
            : isExpiring
                ? Border.all(color: AppColors.warning, width: 1.5)
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DocumentDetailScreen(document: doc),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: doc.assetImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                doc.assetImagePath!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(icon, color: color, size: 20),
                    ),
                    const Spacer(),
                    if (!doc.isUploaded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.l10n.missing,
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Expired',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  _getDocTitle(context, doc),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.isUploaded ? doc.subtitle : context.l10n.notUploadedYet,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 10,
                  ),
                ),
                if (doc.expiryDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 9,
                        color: isExpired
                            ? AppColors.danger
                            : isExpiring
                                ? AppColors.warning
                                : AppColors.textLight,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Exp: ${doc.expiryDate!.year}/${doc.expiryDate!.month.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: isExpired
                              ? AppColors.danger
                              : isExpiring
                                  ? AppColors.warning
                                  : AppColors.textLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddDocumentCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddDocumentCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppColors.primary, size: 32),
            SizedBox(height: 6),
            Text(
              'Add Document',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddDocumentSheet extends StatefulWidget {
  const _AddDocumentSheet();

  @override
  State<_AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<_AddDocumentSheet> {
  bool _isUploading = false;
  double _progress = 0.0;

  Future<void> _handleFilePick(BuildContext context, {required bool isCamera}) async {
    final provider = context.read<DocumentsProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      String? filePath;
      String title = 'Uploaded Document';
      if (isCamera) {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.camera);
        filePath = picked?.path;
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        );
        filePath = result?.files.single.path;
        if (result?.files.single.name != null) {
          title = result!.files.single.name;
        }
      }

      if (filePath == null) return;

      setState(() {
        _isUploading = true;
        _progress = 0.0;
      });

      final formData = FormData.fromMap({
        'title': title,
        'type': 'other',
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last.split('\\').last,
        ),
      });

      if (!mounted) return;
      await provider.uploadDocument(
        formData,
        onSendProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = sent / total);
          }
        },
      );

      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Document saved securely in Digital Locker!'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      _UploadOption(Icons.camera_alt_rounded, 'Take Photo', AppColors.primary),
      _UploadOption(Icons.upload_file_rounded, 'Upload File', AppColors.secondary),
      _UploadOption(Icons.document_scanner_rounded, 'Scan Document', AppColors.accent),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Add Document',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isUploading) ...[
            LinearProgressIndicator(value: _progress > 0 ? _progress : null, color: AppColors.primary),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Uploading document... ${(_progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
          ] else
            Row(
              children: options.asMap().entries.map((entry) {
                final i = entry.key;
                final o = entry.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (i == 0) {
                        _handleFilePick(context, isCamera: true);
                      } else if (i == 1) {
                        _handleFilePick(context, isCamera: false);
                      } else if (i == 2) {
                        // Scan Document
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider(
                                  create: (_) => ScannerController(),
                                  child: const CameraScannerScreen(),
                                )));
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: o.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(o.icon, color: o.color, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            o.label,
                            style: TextStyle(
                              color: o.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DocCategory {
  final String label;
  final IconData icon;
  const _DocCategory(this.label, this.icon);
}



class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadOption {
  final IconData icon;
  final String label;
  final Color color;
  const _UploadOption(this.icon, this.label, this.color);
}
