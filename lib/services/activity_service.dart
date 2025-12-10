import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/bill_item.dart';
import 'push_notification_service.dart';

class ActivityService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _pushNotificationService = PushNotificationService();

  // ➕ Buat aktivitas baru
  Future<String> createActivity({
    required String activityName,
    required DateTime activityDate,
    required List<String> members,
    required List<String>
    memberUids, // UID dari member (exclude "Anda"/creator)
    required List<BillItem> items,
    required double taxPercent,
    required double servicePercent,
    required double discountNominal,
    String? inputMethod, // 'scan' atau 'manual'
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'ActivityService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login untuk membuat aktivitas.',
      );
    }

    // Hitung subtotal
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.price);

    // Hitung tax, service, dan grandTotal
    final tax = subtotal * (taxPercent / 100);
    final service = subtotal * (servicePercent / 100);
    final grandTotal = subtotal + tax + service - discountNominal;

    // Hitung subtotal per member (hanya item mereka, tanpa tax/service/discount)
    final memberSubtotals = <String, double>{};
    for (final member in members) {
      memberSubtotals[member] = 0;
    }
    for (final item in items) {
      memberSubtotals[item.member] =
          (memberSubtotals[item.member] ?? 0) + item.price;
    }

    // Hitung total per member dengan tax/service/discount di-distribute
    final memberTotals = <String, double>{};
    for (final member in members) {
      final memberSubtotal = memberSubtotals[member] ?? 0;
      final proportion = subtotal > 0 ? memberSubtotal / subtotal : 0;

      // Total = subtotal + (tax * proportion) + (service * proportion) - (discount * proportion)
      final memberTotal =
          memberSubtotal +
          (tax * proportion) +
          (service * proportion) -
          (discountNominal * proportion);
      memberTotals[member] = memberTotal;
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
      'subtotal': subtotal,
      'grandTotal': grandTotal,
      'memberTotals': memberTotals,
      'inputMethod': inputMethod, // 'scan' atau 'manual'
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Kirim invitasi ke member yang sudah punya UID
    final activityId = docRef.id;
    await _sendActivityInvitations(
      activityId,
      activityName,
      memberUids,
      currentUser.uid,
    );

    return activityId;
  }

  // 📩 Kirim invitasi aktivitas ke member dengan UID yang sudah diketahui
  Future<void> _sendActivityInvitations(
    String activityId,
    String activityName,
    List<String> memberUids,
    String createdByUid,
  ) async {
    // Get inviter name
    final inviterDoc = await _firestore
        .collection('users')
        .doc(createdByUid)
        .get();
    final inviterName = inviterDoc.data()?['name'] ?? 'Someone';

    // List untuk track invited UIDs
    List<String> invitedUids = [];

    // Kirim invitasi ke setiap member UID (exclude pembuat)
    for (final memberUid in memberUids) {
      if (memberUid == createdByUid) continue; // Skip pembuat aktivitas

      try {
        await _firestore.collection('activityInvitations').add({
          'invitorUid': createdByUid,
          'invitedUid': memberUid,
          'activityId': activityId,
          'activityName': activityName,
          'status': 'pending', // 'pending', 'accepted', 'declined'
          'createdAt': FieldValue.serverTimestamp(),
          'respondedAt': null,
        });

        invitedUids.add(memberUid); // Track invited UIDs

        // 🔔 Kirim push notification
        await _pushNotificationService.sendActivityInvitationNotification(
          toUserId: memberUid,
          activityId: activityId,
          activityName: activityName,
          inviterName: inviterName,
        );
      } catch (e) {
        print('Error sending invitation to $memberUid: $e');
      }
    }

    // 📝 Update activity dengan list invitedUids (untuk read permission di Firestore)
    if (invitedUids.isNotEmpty) {
      try {
        await _firestore.collection('activities').doc(activityId).update({
          'invitedUids': invitedUids,
        });
      } catch (e) {
        print('Error updating invitedUids: $e');
      }
    }
  } // 📖 Ambil semua aktivitas user (created + invited)

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
      // 1. Ambil aktivitas yang dibuat user
      final createdSnapshot = await _firestore
          .collection('activities')
          .where('createdBy', isEqualTo: currentUser.uid)
          .orderBy('activityDate', descending: true)
          .get();

      final activities = createdSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // 2. Ambil aktivitas yang user invited ke (dari accepted invitations)
      final invitationsSnapshot = await _firestore
          .collection('activityInvitations')
          .where('invitedUid', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      for (final invDoc in invitationsSnapshot.docs) {
        final invData = invDoc.data();
        final activityId = invData['activityId'] as String?;

        if (activityId != null) {
          final activityDoc = await _firestore
              .collection('activities')
              .doc(activityId)
              .get();

          if (activityDoc.exists) {
            // Tambahkan ke list jika belum ada (cek berdasarkan ID)
            if (!activities.any((act) => act['id'] == activityId)) {
              activities.add({'id': activityDoc.id, ...activityDoc.data()!});
            }
          }
        }
      }

      // Sort semua aktivitas by date
      activities.sort((a, b) {
        final dateA =
            (a['activityDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        final dateB =
            (b['activityDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        return dateB.compareTo(dateA); // descending
      });

      return activities;
    } catch (e) {
      print('❌ Error in getUserActivities: $e');
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

  // Helper function untuk konversi number yang aman
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
    final taxPercent = _toDouble(activity['taxPercent']);
    final servicePercent = _toDouble(activity['servicePercent']);
    final discountNominal = _toDouble(activity['discountNominal']);

    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['price']),
    );
    if (subtotal == 0) return {};

    final tax = subtotal * (taxPercent / 100);
    final service = subtotal * (servicePercent / 100);

    final memberSub = <String, double>{};
    for (final item in items) {
      final member = item['member'] as String?;
      final price = _toDouble(item['price']);
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
