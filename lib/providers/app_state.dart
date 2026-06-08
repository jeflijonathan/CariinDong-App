import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/item_model.dart';

class AppState extends ChangeNotifier {
  UserModel _currentUser = UserModel.empty;
  UserModel get currentUser => _currentUser;

  List<ItemModel> _items = [];
  List<ItemModel> get items => _items;

  StreamSubscription? _userSub;
  StreamSubscription? _itemsSub;

  AppState() {
    _initAuthListener();
    _initItemsListener();
  }

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _userSub?.cancel();
        _userSub = FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .snapshots()
            .listen((doc) {
          if (doc.exists) {
            _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>);
            notifyListeners();
          }
        });
      } else {
        _userSub?.cancel();
        _currentUser = UserModel.empty;
        notifyListeners();
      }
    });
  }

  void _initItemsListener() {
    _itemsSub = FirebaseFirestore.instance
        .collection('items')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      _items = snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _itemsSub?.cancel();
    super.dispose();
  }

  // Statistics
  int get totalLost => _items.where((i) => i.status == ItemStatus.lost).length;
  int get totalFound => _items.where((i) => i.status == ItemStatus.found).length;
  int get totalClaimed => _items.where((i) => i.status == ItemStatus.claimed).length;
  int get totalResolved => _items.where((i) => i.status == ItemStatus.resolved).length;

  // Add Item
  Future<void> addItem(ItemModel item) async {
    await FirebaseFirestore.instance.collection('items').doc(item.id).set(item.toMap());
  }

  // Delete Item (SuperAdmin only)
  Future<void> deleteItem(String id) async {
    await FirebaseFirestore.instance.collection('items').doc(id).delete();
  }

  // Claim Item — a user claims they found/have the item
  Future<void> claimItem(String itemId, UserModel claimer, {String? claimerProofUrl}) async {
    final Map<String, dynamic> data = {
      'status': ItemStatus.claimed.toString(),
      'claimedByUid': claimer.uid,
      'claimedByName': claimer.name,
      'claimedByPhone': claimer.phoneNumber,
    };
    if (claimerProofUrl != null) {
      data['claimerProofUrl'] = claimerProofUrl;
    }
    await FirebaseFirestore.instance.collection('items').doc(itemId).update(data);
  }

  // Confirm Claim — reporter confirms the claim, with proof photo URL
  Future<void> confirmClaim(String itemId, {String? proofUrl}) async {
    final Map<String, dynamic> updateData = {
      'status': ItemStatus.resolved.toString(),
    };
    if (proofUrl != null) {
      updateData['claimProofUrl'] = proofUrl;
    }
    await FirebaseFirestore.instance.collection('items').doc(itemId).update(updateData);
  }

  // Reject Claim — reporter rejects the claim, revert to original status
  Future<void> rejectClaim(String itemId, ItemStatus originalStatus) async {
    await FirebaseFirestore.instance.collection('items').doc(itemId).update({
      'status': originalStatus.toString(),
      'claimedByUid': FieldValue.delete(),
      'claimedByName': FieldValue.delete(),
      'claimedByPhone': FieldValue.delete(),
      'claimerProofUrl': FieldValue.delete(),
    });
  }

  // Update Item Status (legacy helper)
  Future<void> updateItemStatus(String id, ItemStatus newStatus, {String? receiverName}) async {
    final Map<String, dynamic> updateData = {
      'status': newStatus.toString(),
    };
    if (receiverName != null) {
      updateData['receiverName'] = receiverName;
    }
    await FirebaseFirestore.instance.collection('items').doc(id).update(updateData);
  }

  // Search and Filter
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  ItemStatus? _selectedStatus;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  ItemStatus? get selectedStatus => _selectedStatus;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String category, ItemStatus? status) {
    _selectedCategory = category;
    _selectedStatus = status;
    notifyListeners();
  }

  List<ItemModel> get filteredItems {
    return _items.where((item) {
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || item.category == _selectedCategory;
      final matchesStatus = _selectedStatus == null || item.status == _selectedStatus;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }
}
