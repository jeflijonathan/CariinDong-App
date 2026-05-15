import 'dart:io';

class LostItemModel {
  String? id;
  String name;
  String description;
  String logitude;
  String latitude;
  DateTime? dateLost;
  String? contactInfo;
  File itemPhoto;
  String? photoOwner;

  LostItemModel({
    this.id,
    required this.name,
    required this.description,
    required this.logitude,
    required this.latitude,
    this.dateLost,
    this.contactInfo,
    required this.itemPhoto,
    this.photoOwner,
  });

  factory LostItemModel.fromJson(Map<String, dynamic> json) {
    return LostItemModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      logitude: json['logitude'],
      latitude: json['latitude'],
      dateLost: DateTime.parse(json['dateLost']),
      contactInfo: json['contactInfo'],
      itemPhoto: File(json['itemPhoto']),
      photoOwner: json['photoOwner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logitude': logitude,
      'latitude': latitude,
      'dateLost': dateLost?.toIso8601String(),
      'contactInfo': contactInfo,
      'itemPhoto': itemPhoto.path,
      'photoOwner': photoOwner,
    };
  }
}
