import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/item_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../core/theme.dart';
import 'full_screen_map_page.dart';

class ItemDetailPage extends StatefulWidget {
  final ItemModel item;

  const ItemDetailPage({super.key, required this.item});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  bool _isLoading = false;
  bool _isPickingImage = false;
  final _picker = ImagePicker();

  Color _getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.lost:
        return AppTheme.lostColor;
      case ItemStatus.found:
        return AppTheme.foundColor;
      case ItemStatus.claimed:
        return Colors.orange;
      case ItemStatus.resolved:
        return AppTheme.resolvedColor;
    }
  }

  String _getStatusText(ItemStatus status) {
    switch (status) {
      case ItemStatus.lost:
        return 'HILANG';
      case ItemStatus.found:
        return 'DITEMUKAN';
      case ItemStatus.claimed:
        return 'DIKLAIM';
      case ItemStatus.resolved:
        return 'SELESAI';
    }
  }

  Future<void> _claimItem() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentUser = appState.currentUser;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Klaim Barang'),
        content: const Text(
          'Anda akan mengklaim barang ini.\n\n'
          'Anda WAJIB mengupload foto bukti (misal: foto diri memegang barang, '
          'atau foto bukti bahwa barang ini milik Anda) untuk diperiksa pelapor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjut & Upload Bukti'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Upload Foto Bukti Klaim',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Foto ini akan dilihat oleh pelapor untuk memverifikasi klaim Anda.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.camera_alt)),
              title: const Text('Ambil Foto Sekarang'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.photo_library)),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto bukti diperlukan untuk mengklaim barang.'),
          ),
        );
      }
      return;
    }

    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    XFile? pickedFile;
    try {
      pickedFile = await _picker.pickImage(source: source, imageQuality: 75);
    } catch (e) {
      debugPrint('Image picker error: $e');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }

    if (pickedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto bukti diperlukan untuk mengklaim barang.'),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('claimer_proofs')
          .child('${widget.item.id}_claimer.jpg');
      await ref.putFile(file);
      final claimerProofUrl = await ref.getDownloadURL();

      await appState.claimItem(
        widget.item.id,
        currentUser,
        claimerProofUrl: claimerProofUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Klaim berhasil dikirim! Menunggu konfirmasi pelapor.',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengklaim: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmClaim() async {
    final appState = Provider.of<AppState>(context, listen: false);

    final proceed = await _showClaimerProofDialog();
    if (proceed != true) return;

    if (!mounted) return;
    final confirmPhoto = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Foto Serah Terima'),
        content: const Text(
          'Setelah memverifikasi foto pengklaim, Anda akan diminta mengambil '
          'foto serah terima sebagai bukti final bahwa barang telah dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ambil Foto Serah Terima'),
          ),
        ],
      ),
    );

    if (confirmPhoto != true) return;

    if (!mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Foto Bukti Serah Terima',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.camera_alt)),
              title: const Text('Ambil Foto Sekarang'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.photo_library)),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    XFile? pickedFile;
    try {
      pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    } catch (e) {
      debugPrint('Image picker error: $e');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }

    if (pickedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto bukti serah terima diperlukan.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('claim_proofs')
          .child('${widget.item.id}_proof.jpg');
      await ref.putFile(file);
      final proofUrl = await ref.getDownloadURL();

      await appState.confirmClaim(widget.item.id, proofUrl: proofUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Klaim dikonfirmasi! Laporan selesai.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengkonfirmasi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showClaimerProofDialog() {
    final item = widget.item;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Verifikasi Bukti Pengklaim',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Periksa foto bukti yang dikirim oleh pengklaim. '
                'Pastikan bukti valid sebelum mengonfirmasi.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),

              _buildInfoRowCompact(
                Icons.person,
                'Nama',
                item.claimedByName ?? '-',
              ),
              const SizedBox(height: 6),
              _buildInfoRowCompact(
                Icons.phone,
                'Telepon',
                item.claimedByPhone ?? '-',
              ),
              const SizedBox(height: 12),

              if (item.claimerProofUrl != null &&
                  item.claimerProofUrl!.isNotEmpty) ...[
                const Text(
                  '📷 Foto Bukti dari Pengklaim:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.claimerProofUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) => progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (ctx, e, st) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pengklaim tidak melampirkan foto bukti.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batalkan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Terima Klaim'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rejectClaim() async {
    final appState = Provider.of<AppState>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Klaim'),
        content: const Text(
          'Anda yakin ingin menolak klaim ini? '
          'Status barang akan kembali ke semula.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await appState.rejectClaim(widget.item.id, ItemStatus.lost);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Klaim ditolak. Status dikembalikan.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menolak klaim: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem() async {
    final appState = Provider.of<AppState>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: const Text(
          'Anda yakin ingin menghapus laporan ini? Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await appState.deleteItem(widget.item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil dihapus.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } else {
      try {
        final bytes = base64Decode(imageUrl);
        return Image.memory(
          bytes,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorPlaceholder(),
        );
      } catch (_) {
        return _buildErrorPlaceholder();
      }
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      height: 250,
      color: Colors.grey.shade300,
      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentUser = appState.currentUser;
    final item = widget.item;
    final isSuperAdmin = currentUser.role == UserRole.superAdmin;
    final isReporter = currentUser.uid == item.reporterUid;
    final isClaimed = item.status == ItemStatus.claimed;
    final isResolved = item.status == ItemStatus.resolved;
    final canClaim =
        !isReporter &&
        !isSuperAdmin &&
        (item.status == ItemStatus.lost || item.status == ItemStatus.found);

    final hasCoordinates = item.latitude != null && item.longitude != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        actions: [
          if (isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Hapus Laporan',
              onPressed: _isLoading ? null : _deleteItem,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    _buildImage(item.imageUrl!)
                  else
                    Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tidak ada foto',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  item.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getStatusColor(item.status),
                                ),
                              ),
                              child: Text(
                                _getStatusText(item.status),
                                style: TextStyle(
                                  color: _getStatusColor(item.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              '${item.date.day}/${item.date.month}/${item.date.year}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildInfoRow(
                          Icons.location_on,
                          'Lokasi',
                          item.location,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.category,
                          'Kategori',
                          item.category,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.person,
                          'Dilaporkan Oleh',
                          item.reporterName,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.phone,
                          'Telepon Pelapor',
                          item.reporterPhone.isNotEmpty
                              ? item.reporterPhone
                              : 'Tidak tersedia',
                        ),

                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '🗺️ Lokasi di Peta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasCoordinates)
                              TextButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse(
                                    'https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}',
                                  );
                                  try {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } catch (e) {
                                    try {
                                      await launchUrl(uri);
                                    } catch (_) {}
                                  }
                                },
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('Buka Maps'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 220,
                            child: hasCoordinates
                                ? GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FullScreenMapPage(
                                                lat: item.latitude!,
                                                lng: item.longitude!,
                                                locationName: item.location,
                                              ),
                                        ),
                                      );
                                    },
                                    child: AbsorbPointer(
                                      child: _buildMapView(
                                        item.latitude!,
                                        item.longitude!,
                                      ),
                                    ),
                                  )
                                : _buildNoMapPlaceholder(item.location),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'Keterangan Tambahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.description,
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ),

                        if (isClaimed || isResolved) ...[
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isClaimed
                                  ? Colors.orange.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isClaimed ? Colors.orange : Colors.green,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isClaimed
                                      ? '📋 Informasi Pengklaim'
                                      : '✅ Informasi Penerima (Selesai)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isClaimed
                                        ? Colors.orange.shade800
                                        : Colors.green.shade800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (item.claimedByName != null)
                                  _buildInfoRow(
                                    Icons.person_outline,
                                    'Nama',
                                    item.claimedByName!,
                                  ),
                                if (item.claimedByPhone != null &&
                                    item.claimedByPhone!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.phone,
                                    'Telepon',
                                    item.claimedByPhone!,
                                  ),
                                ],

                                if (isReporter &&
                                    item.claimerProofUrl != null &&
                                    item.claimerProofUrl!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    '📷 Foto Bukti Pengklaim',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isClaimed
                                          ? Colors.orange.shade800
                                          : Colors.green.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      item.claimerProofUrl!,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (ctx, child, progress) =>
                                          progress == null
                                          ? child
                                          : const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                      errorBuilder: (ctx, e, st) => Container(
                                        height: 180,
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else if (isClaimed && isReporter) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.amber.shade300,
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Pengklaim belum melampirkan foto bukti.',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        if (isResolved &&
                            item.claimProofUrl != null &&
                            item.claimProofUrl!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            '📸 Bukti Serah Terima',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.claimProofUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 200,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                    ),
                                  ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        if (canClaim)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _claimItem,
                              icon: const Icon(Icons.front_hand),
                              label: const Text(
                                'Klaim Barang Ini',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),

                        if (isReporter && isClaimed) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Periksa foto bukti pengklaim di atas, lalu putuskan apakah klaim diterima atau ditolak.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _confirmClaim,
                              icon: const Icon(Icons.check_circle),
                              label: const Text(
                                'Konfirmasi & Foto Serah Terima',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _rejectClaim,
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              label: const Text(
                                'Tolak Klaim',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMapView(double lat, double lng) {
    return _FlutterMapView(lat: lat, lng: lng);
  }

  Widget _buildNoMapPlaceholder(String location) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Koordinat tidak tersedia',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              location,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowCompact(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _FlutterMapView extends StatelessWidget {
  final double lat;
  final double lng;

  const _FlutterMapView({super.key, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);
    return FlutterMap(
      options: MapOptions(initialCenter: point, initialZoom: 15.0),
      children: [
        TileLayer(
          urlTemplate:
              'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.cariindong_app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 40.0,
              height: 40.0,
              point: point,
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
