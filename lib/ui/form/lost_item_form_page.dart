import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:cariindong_app/providers/app_state.dart';
import 'package:cariindong_app/models/item_model.dart';
import 'package:cariindong_app/ui/profile/edit_profile_page.dart';
import 'package:cariindong_app/ui/form/map_picker_page.dart';

class LostItemFormPage extends StatefulWidget {
  final ItemModel? existingItem;

  const LostItemFormPage({super.key, this.existingItem});

  @override
  State<LostItemFormPage> createState() => _LostItemFormPageState();
}

class _LostItemFormPageState extends State<LostItemFormPage> {
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _description = '';
  String _location = '';
  final _locationController = TextEditingController();
  String _category = 'Elektronik';
  ItemStatus _status = ItemStatus.lost;
  double? _latitude;
  double? _longitude;

  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _title = item.title;
      _description = item.description;
      _location = item.location;
      _locationController.text = item.location;
      _category = item.category;
      _status = item.status;
      _latitude = item.latitude;
      _longitude = item.longitude;
      _existingImageUrl = item.imageUrl;
    }
  }

  File? _imageFile;
  bool _isLoading = false;
  bool _isPickingImage = false;

  final List<String> _categories = [
    'Elektronik',
    'Dompet',
    'Dokumen',
    'Kunci',
    'Lainnya',
  ];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
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

  Future<String?> _uploadImage(String itemId) async {
    if (_imageFile == null) return null;
    try {
      final bytes = await _imageFile!.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final appState = Provider.of<AppState>(context, listen: false);
      final currentUser = appState.currentUser;

      if (currentUser.phoneNumber.trim().isEmpty) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.phone_missed, color: Colors.orange),
                SizedBox(width: 8),
                Text('Nomor Telepon Wajib'),
              ],
            ),
            content: const Text(
              'Nomor telepon diperlukan agar pengklaim dapat menghubungi Anda.\n\n'
              'Silakan lengkapi profil Anda terlebih dahulu sebelum membuat laporan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Lengkapi Profil'),
              ),
            ],
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      final itemId = widget.existingItem?.id ?? const Uuid().v4();

      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(itemId);
      }

      final newItem = ItemModel(
        id: itemId,
        title: _title,
        description: _description,
        location: _location,
        status: _status,
        category: _category,
        reporterName: widget.existingItem?.reporterName ?? currentUser.name,
        reporterUid: widget.existingItem?.reporterUid ?? currentUser.uid ?? '',
        reporterPhone: widget.existingItem?.reporterPhone ?? currentUser.phoneNumber,
        date: widget.existingItem?.date ?? DateTime.now(),
        imageUrl: imageUrl,
        latitude: _latitude,
        longitude: _longitude,
        claimedByUid: widget.existingItem?.claimedByUid,
        claimedByName: widget.existingItem?.claimedByName,
        claimedByPhone: widget.existingItem?.claimedByPhone,
        claimerProofUrl: widget.existingItem?.claimerProofUrl,
        claimProofUrl: widget.existingItem?.claimProofUrl,
        receiverName: widget.existingItem?.receiverName,
      );

      if (widget.existingItem != null) {
        await appState.updateItem(newItem);
      } else {
        await appState.addItem(newItem);
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingItem != null ? 'Laporan berhasil diperbarui!' : 'Laporan berhasil disimpan!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingItem != null ? 'Edit Laporan' : 'Buat Laporan Baru')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _existingImageUrl!.startsWith('http')
                                        ? Image.network(
                                            _existingImageUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          )
                                        : Image.memory(
                                            base64Decode(_existingImageUrl!),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                  )
                                : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap untuk tambah foto barang',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _title,
                      decoration: const InputDecoration(
                        labelText: 'Nama Barang',
                        hintText: 'Misal: KTP, Laptop ASUS, Kunci Motor',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                      onSaved: (value) => _title = value!,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      initialValue: _category,
                      items: _categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _category = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ItemStatus>(
                      decoration: const InputDecoration(
                        labelText: 'Status Laporan',
                      ),
                      initialValue: _status,
                      items: [
                        const DropdownMenuItem(
                          value: ItemStatus.lost,
                          child: Text('Kehilangan Barang'),
                        ),
                        const DropdownMenuItem(
                          value: ItemStatus.found,
                          child: Text('Menemukan Barang'),
                        ),
                        if (_status == ItemStatus.claimed)
                          const DropdownMenuItem(
                            value: ItemStatus.claimed,
                            child: Text('Diklaim (Menunggu Serah Terima)'),
                          ),
                        if (_status == ItemStatus.resolved)
                          const DropdownMenuItem(
                            value: ItemStatus.resolved,
                            child: Text('Selesai'),
                          ),
                      ],
                      onChanged: (_status == ItemStatus.claimed || _status == ItemStatus.resolved) 
                          ? null 
                          : (value) {
                              setState(() => _status = value!);
                            },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      readOnly: true,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapPickerPage(),
                          ),
                        );
                        if (result != null && result is Map) {
                          setState(() {
                            _locationController.text =
                                result['address'] as String;
                            _location = result['address'] as String;
                            _latitude = result['latitude'] as double?;
                            _longitude = result['longitude'] as double?;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Lokasi Kejadian/Penemuan',
                        prefixIcon: Icon(Icons.location_on),
                        suffixIcon: Icon(Icons.map),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                      onSaved: (value) => _location = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _description,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan Tambahan',
                        hintText:
                            'Berikan deskripsi spesifik tentang barang...',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                      onSaved: (value) => _description = value!,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _submitForm,
                      child: Text(widget.existingItem != null ? 'Simpan Perubahan' : 'Simpan Laporan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
