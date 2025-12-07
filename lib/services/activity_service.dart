import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bill_item.dart';

class ActivityService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ➕ Buat aktivitas baru
  Future<String> createActivity({
    required String activityName,
    required DateTime activityDate,
    required List<String> members,
    required List<BillItem> items,
    required double taxPercent,
    required double servicePercent,
    required double discountNominal,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'ActivityService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login untuk membuat aktivitas.',
      );
    }

    final docRef = await _firestore.collection('activities').add({
      'createdBy': currentUser.uid,
      'activityName': activityName,
      'activityDate': Timestamp.fromDate(activityDate),
      'members': members,
      'items': items
          .map(
            (item) => <String, dynamic>{
              'member': item.member,
              'name': item.name,
              'price': item.price,
            },
          )
          .toList(),
      'taxPercent': taxPercent,
      'servicePercent': servicePercent,
      'discountNominal': discountNominal,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // 📖 Ambil semua aktivitas user
  Future<List<Map<String, dynamic>>> getUserActivities() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'ActivityService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login untuk melihat aktivitas.',
      );
    }

    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('createdBy', isEqualTo: currentUser.uid)
          .orderBy('activityDate', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw FirebaseException(
        plugin: 'ActivityService',
        code: 'GET_ACTIVITIES_ERROR',
        message: 'Gagal mengambil aktivitas: $e',
      );
    }
  }

  // 🔍 Ambil detail aktivitas berdasarkan ID
  Future<Map<String, dynamic>?> getActivityById(String activityId) async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .doc(activityId)
          .get();

      if (!snapshot.exists) return null;

      return {'id': snapshot.id, ...snapshot.data()!};
    } catch (e) {
      throw FirebaseException(
        plugin: 'ActivityService',
        code: 'GET_ACTIVITY_ERROR',
        message: 'Gagal mengambil detail aktivitas: $e',
      );
    }
  }

  // ✏️ Update aktivitas
  Future<void> updateActivity({
    required String activityId,
    required String activityName,
    required DateTime activityDate,
    required List<String> members,
    required List<BillItem> items,
    required double taxPercent,
    required double servicePercent,
    required double discountNominal,
  }) async {
    await _firestore.collection('activities').doc(activityId).update({
      'activityName': activityName,
      'activityDate': Timestamp.fromDate(activityDate),
      'members': members,
      'items': items
          .map(
            (item) => <String, dynamic>{
              'member': item.member,
              'name': item.name,
              'price': item.price,
            },
          )
          .toList(),
      'taxPercent': taxPercent,
      'servicePercent': servicePercent,
      'discountNominal': discountNominal,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 🗑️ Hapus aktivitas
  Future<void> deleteActivity(String activityId) async {
    try {
      await _firestore.collection('activities').doc(activityId).delete();
    } catch (e) {
      throw FirebaseException(
        plugin: 'ActivityService',
        code: 'DELETE_ACTIVITY_ERROR',
        message: 'Gagal menghapus aktivitas: $e',
      );
    }
  }

  // 💰 Hitung total untuk setiap member
  Future<Map<String, double>> calculateMemberTotals({
    required String activityId,
  }) async {
    final activity = await getActivityById(activityId);
    if (activity == null) return {};

    final items =
        (activity['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        [];
    final taxPercent = (activity['taxPercent'] as num?)?.toDouble() ?? 0;
    final servicePercent =
        (activity['servicePercent'] as num?)?.toDouble() ?? 0;
    final discountNominal =
        (activity['discountNominal'] as num?)?.toDouble() ?? 0;

    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + ((item['price'] as num?)?.toDouble() ?? 0),
    );
    if (subtotal == 0) return {};

    final tax = subtotal * (taxPercent / 100);
    final service = subtotal * (servicePercent / 100);

    final memberSub = <String, double>{};
    for (final item in items) {
      final member = item['member'] as String?;
      final price = (item['price'] as num?)?.toDouble() ?? 0;
      if (member != null) {
        memberSub[member] = (memberSub[member] ?? 0) + price;
      }
    }

    final totals = <String, double>{};
    memberSub.forEach((member, sub) {
      final prop = sub / subtotal;
      final memberTax = tax * prop;
      final memberService = service * prop;
      final memberDiscount = discountNominal * prop;
      totals[member] = sub + memberTax + memberService - memberDiscount;
    });

    return totals;
  }
}
