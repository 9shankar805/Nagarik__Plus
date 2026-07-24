import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _editing = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Controllers
  final _fullName   = TextEditingController();
  final _email      = TextEditingController();
  final _phone      = TextEditingController();
  final _dob        = TextEditingController();
  final _address    = TextEditingController();
  final _citizenNo  = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileUser = context.read<ProfileProvider>().user;
      final authUser = context.read<AuthProvider>().user;
      final user = profileUser ?? authUser;
      if (user != null) {
        _fullName.text = user.name;
        _email.text = user.email;
        _phone.text = user.phone;
        _dob.text = user.dob ?? '';
        _address.text = user.address ?? '';
        _citizenNo.text = user.citizenshipNumber ?? '';
      }
    });
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    _address.dispose();
    _citizenNo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        title: const Text('Personal Information',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () async {
              if (_editing) {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  try {
                    final data = {
                      'name': _fullName.text,
                      'email': _email.text,
                      'phone': _phone.text,
                      'dob': _dob.text,
                      'address': _address.text,
                      'citizenship_number': _citizenNo.text,
                    };
                    await context.read<ProfileProvider>().updateProfile(data);
                    if (mounted) {
                      setState(() => _editing = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Information updated successfully'),
                          backgroundColor: AppColors.secondary,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _errorMessage = e.toString().replaceFirst('Exception: ', '');
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update: $_errorMessage'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                }
              } else {
                setState(() => _editing = true);
              }
            },
            child: _isLoading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _editing ? 'Save' : 'Edit',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar section
              _buildAvatarSection(),
              const SizedBox(height: 24),
              // Form fields
              _buildCard([
                _buildField(
                  controller: _fullName,
                  label: 'Full Name',
                  icon: Icons.person_rounded,
                  iconColor: AppColors.primary,
                  iconBg: const Color(0xFFE3EEFF),
                  enabled: _editing,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                _divider(),
                _buildField(
                  controller: _email,
                  label: 'Email Address',
                  icon: Icons.email_rounded,
                  iconColor: const Color(0xFFE65100),
                  iconBg: const Color(0xFFFFEDE3),
                  enabled: _editing,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Enter valid email' : null,
                ),
                _divider(),
                _buildField(
                  controller: _phone,
                  label: 'Phone Number',
                  icon: Icons.phone_rounded,
                  iconColor: AppColors.secondary,
                  iconBg: const Color(0xFFE8F5E9),
                  enabled: _editing,
                  keyboardType: TextInputType.phone,
                ),
                _divider(),
                _buildField(
                  controller: _dob,
                  label: 'Date of Birth',
                  icon: Icons.cake_rounded,
                  iconColor: const Color(0xFF7B1FA2),
                  iconBg: const Color(0xFFEDE7FF),
                  enabled: _editing,
                  readOnly: true,
                  onTap: _editing ? () => _pickDate(context) : null,
                ),
                _divider(),
                _buildField(
                  controller: _address,
                  label: 'Address',
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFF0288D1),
                  iconBg: const Color(0xFFE3F2FD),
                  enabled: _editing,
                ),
                _divider(),
                _buildField(
                  controller: _citizenNo,
                  label: 'Citizenship Number',
                  icon: Icons.badge_rounded,
                  iconColor: const Color(0xFFF57F17),
                  iconBg: const Color(0xFFFFF8E1),
                  enabled: _editing,
                ),
              ]),
              const SizedBox(height: 20),
              // Info note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.info.withOpacity(0.2)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.info, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your personal information is securely stored and only visible to you.',
                        style: TextStyle(
                            color: Color(0xFF5A6A80),
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _isLoading = true);
        await context.read<ProfileProvider>().uploadAvatar(File(picked.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar updated successfully'),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar upload failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAvatarSection() {
    final profileUser = context.watch<ProfileProvider>().user;
    final authUser = context.watch<AuthProvider>().user;
    final user = profileUser ?? authUser;
    return Center(
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFBBDEFB),
              border: Border.all(color: AppColors.primary, width: 2.5),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: ClipOval(
              child: user?.avatarUrl != null
                  ? Image.network(
                      user!.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded,
                          size: 52, color: AppColors.primary),
                    )
                  : const Icon(Icons.person_rounded,
                      size: 52, color: AppColors.primary),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickAndUploadAvatar,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    bool enabled = true,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              readOnly: readOnly,
              keyboardType: keyboardType,
              validator: validator,
              onTap: onTap,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2B4A)),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                    fontSize: 12, color: Color(0xFF9AAABB)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (!enabled)
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCCD5E0), size: 18),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1, indent: 68, endIndent: 16, color: Color(0xFFF0F4FA));

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 6, 15),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dob.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }
}
