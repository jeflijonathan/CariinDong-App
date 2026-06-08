import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/app_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  bool _isPickingImage = false; // cegah PlatformException(already_active)
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AppState>(context, listen: false).currentUser;
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,   // sedikit lebih kecil agar base64 tidak terlalu besar
        maxWidth: 512,
        maxHeight: 512,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  /// Encode gambar ke base64 string
  Future<String?> _encodeImageToBase64() async {
    if (_imageFile == null) return null;
    try {
      final bytes = await _imageFile!.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Base64 encode error: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AppState>(context, listen: false).currentUser;
      final uid = user.uid;

      if (uid == null || uid.isEmpty) {
        throw Exception('User ID tidak ditemukan');
      }

      // Encode foto baru ke base64 jika ada
      String? newProfilePicture;
      if (_imageFile != null) {
        newProfilePicture = await _encodeImageToBase64();
      }

      final newName = _nameController.text.trim();
      final newPhone = _phoneController.text.trim();

      final Map<String, dynamic> updateData = {
        'name': newName,
        'phoneNumber': newPhone,
      };

      // Hanya update profilePicture jika ada gambar baru
      if (newProfilePicture != null) {
        updateData['profilePicture'] = newProfilePicture;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui profil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Build avatar: prioritaskan file lokal baru, lalu base64 dari Firestore, lalu fallback inisial
  Widget _buildAvatar(String currentProfilePicture) {
    ImageProvider? imageProvider;

    if (_imageFile != null) {
      // Preview gambar yang baru dipilih (belum disimpan)
      imageProvider = FileImage(_imageFile!);
    } else if (currentProfilePicture.isNotEmpty &&
        !currentProfilePicture.startsWith('http')) {
      // Dari Firestore sebagai base64
      try {
        final bytes = base64Decode(currentProfilePicture);
        imageProvider = MemoryImage(bytes);
      } catch (_) {
        imageProvider = null;
      }
    } else if (currentProfilePicture.startsWith('http')) {
      // Dari Google Sign-In (URL)
      imageProvider = NetworkImage(currentProfilePicture);
    }

    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppState>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar + tombol kamera
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          _buildAvatar(user.profilePicture),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ketuk foto untuk mengubah',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Nama tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Telepon',
                        hintText: 'Contoh: 08123456789',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _saveProfile,
                        child: const Text(
                          'SIMPAN PERUBAHAN',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
