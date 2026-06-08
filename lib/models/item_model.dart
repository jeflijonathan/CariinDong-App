import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemStatus { lost, found, claimed, resolved }

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final ItemStatus status;
  final String category;
  final String reporterName;
  final String reporterUid;
  final String reporterPhone;
  final String? receiverName;
  final String? claimedByUid;
  final String? claimedByName;
  final String? claimedByPhone;
  final String? claimProofUrl;
  final String? claimerProofUrl;
  final DateTime date;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final List<Map<String, dynamic>> pendingClaims;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.category,
    required this.reporterName,
    this.reporterUid = '',
    this.reporterPhone = '',
    this.receiverName,
    this.claimedByUid,
    this.claimedByName,
    this.claimedByPhone,
    this.claimProofUrl,
    this.claimerProofUrl,
    required this.date,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.pendingClaims = const [],
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    ItemStatus parseStatus(String statusStr) {
      if (statusStr == 'ItemStatus.lost') return ItemStatus.lost;
      if (statusStr == 'ItemStatus.found') return ItemStatus.found;
      if (statusStr == 'ItemStatus.claimed') return ItemStatus.claimed;
      return ItemStatus.lost;
    }

    return ItemModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      status: parseStatus(data['status'] ?? ''),
      category: data['category'] ?? '',
      reporterName: data['reporterName'] ?? '',
      reporterUid: data['reporterUid'] ?? '',
      reporterPhone: data['reporterPhone'] ?? '',
      receiverName: data['receiverName'],
      claimedByUid: data['claimedByUid'],
      claimedByName: data['claimedByName'],
      claimedByPhone: data['claimedByPhone'],
      claimProofUrl: data['claimProofUrl'],
      claimerProofUrl: data['claimerProofUrl'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      pendingClaims: List<Map<String, dynamic>>.from(data['pendingClaims'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'status': status.toString(),
      'category': category,
      'reporterName': reporterName,
      'reporterUid': reporterUid,
      'reporterPhone': reporterPhone,
      'receiverName': receiverName,
      'claimedByUid': claimedByUid,
      'claimedByName': claimedByName,
      'claimedByPhone': claimedByPhone,
      'claimProofUrl': claimProofUrl,
      'claimerProofUrl': claimerProofUrl,
      'date': Timestamp.fromDate(date),
      'imageUrl': imageUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'pendingClaims': pendingClaims,
    };
  }
}
