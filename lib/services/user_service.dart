import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';
import 'push_notification_service.dart';

/// Kelas layanan yang menangani semua operasi terkait pengguna,
/// autentikasi, pertemanan, dan undangan kegiatan.
class UserService {
  final PushNotificationService _pushNotificationService =
      PushNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mengambil UID pengguna yang saat ini login.
  String? get _currentUid => _auth.currentUser?.uid;

  /// Memastikan pengguna saat ini terautentikasi.
  /// Melempar [FirebaseException] jika tidak ada user yang login.
  void _ensureAuthenticated() {
    if (_currentUid == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login.',
      );
    }
  }

  // --- [ 1. AUTENTIKASI & PROFIL DASAR ] ---

  /// 🔍 Mencari user di Firestore berdasarkan email yang dinormalisasi.
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final normalizedEmail = email.toLowerCase().trim();

    final result = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (result.docs.isEmpty) return null;

    final doc = result.docs.first;
    final Map<String, dynamic> data = doc.data();
    data['uid'] = doc.id; // Tambahkan UID user
    return data;
  }

  /// ✏️ Mengupdate nama tampilan (display name) user di Firebase Auth dan Firestore.
  Future<void> updateUserProfile({required String name}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _ensureAuthenticated(); // Throw jika null
      return;
    }

    // 1. Update Display Name di FirebaseAuth
    await currentUser.updateDisplayName(name);

    // 2. Update Name di Firestore
    await _firestore.collection('users').doc(currentUser.uid).update({
      'name': name,
    });
  }

  /// 🔒 Mengubah password user, memerlukan re-autentikasi.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null || currentUser.email == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_ALLOWED',
        message:
            'User tidak terautentikasi atau tidak menggunakan login email.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: currentUser.email!,
      password: currentPassword,
    );

    await currentUser.reauthenticateWithCredential(credential);
    await currentUser.updatePassword(newPassword);
  }

  /// 📧 Mengganti email user, akan mengirim verifikasi ke email baru.
  Future<void> updateEmail({required String newEmail}) async {
    final currentUser = _auth.currentUser;
    _ensureAuthenticated();

    // 1. Update email di Authentication (Mengirim verifikasi)
    await currentUser!.verifyBeforeUpdateEmail(newEmail);

    // 2. Update email di Firestore (Ini akan di-update ke email baru yang belum terverifikasi)
    await _firestore.collection('users').doc(currentUser.uid).update({
      'email': newEmail.toLowerCase().trim(),
    });
  }

  /// 🗑️ Menghapus akun user secara permanen dari Auth dan Firestore.
  Future<void> deleteAccount({required String password}) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null || currentUser.email == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_ALLOWED',
        message:
            'User tidak terautentikasi atau tidak menggunakan login email.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: currentUser.email!,
      password: password,
    );
    await currentUser.reauthenticateWithCredential(credential);

    // Hapus data user dari Firestore
    await _firestore.collection('users').doc(currentUser.uid).delete();

    // Hapus user dari Authentication
    await currentUser.delete();
  }

  // --- [ 2. UPLOAD FOTO PROFIL ] ---

  /// 📸 Mengupload foto profil ke Cloudinary dan memperbarui URL di Firebase.
  Future<String> uploadProfilePicture(File imageFile) async {
    final currentUser = _auth.currentUser;
    _ensureAuthenticated();

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset;

      if (CloudinaryConfig.folder.isNotEmpty) {
        request.fields['folder'] = CloudinaryConfig.folder;
      }

      request.fields['public_id'] = currentUser!.uid;

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode != 200 && response.statusCode != 201) {
        final body = jsonDecode(response.body);
        throw FirebaseException(
          plugin: 'UserService',
          code: 'UPLOAD_FAILED',
          message:
              'Cloudinary error ${response.statusCode}: ${body['error']['message'] ?? response.body}',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final downloadUrl = decoded['secure_url'] as String?;

      if (downloadUrl == null || downloadUrl.isEmpty) {
        throw FirebaseException(
          plugin: 'UserService',
          code: 'NO_URL',
          message: 'Cloudinary tidak mengembalikan secure_url',
        );
      }

      await currentUser.updatePhotoURL(downloadUrl);
      await _firestore.collection('users').doc(currentUser.uid).update({
        'photoUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      if (e is FirebaseException) rethrow;
      throw FirebaseException(
        plugin: 'UserService',
        code: 'UPLOAD_FAILED',
        message: 'Gagal mengupload foto profil: $e',
      );
    }
  }

  // --- [ 3. PERTEMANAN & FRIEND REQUEST ] ---

  /// ➕ Mengirim friend request ke user lain.
  Future<void> sendFriendRequest(String friendUid) async {
    _ensureAuthenticated();
    final currentUid = _currentUid!;

    if (currentUid == friendUid) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'INVALID_FRIEND_ID',
        message: 'Tidak dapat menambah diri sendiri.',
      );
    }

    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUid)
        .get();
    final friends = List<String>.from(currentUserDoc.data()?['friends'] ?? []);
    if (friends.contains(friendUid)) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'ALREADY_FRIENDS',
        message: 'Anda sudah berteman dengan user ini.',
      );
    }

    final existingRequest = await _firestore
        .collection('friendRequests')
        .where('fromUid', isEqualTo: currentUid)
        .where('toUid', isEqualTo: friendUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'REQUEST_EXISTS',
        message: 'Anda sudah mengirim friend request ke user ini.',
      );
    }

    final reverseRequest = await _firestore
        .collection('friendRequests')
        .where('fromUid', isEqualTo: friendUid)
        .where('toUid', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (reverseRequest.docs.isNotEmpty) {
      final requestId = reverseRequest.docs.first.id;
      await acceptFriendRequest(requestId, friendUid);
      return;
    }

    await _firestore.collection('friendRequests').add({
      'fromUid': currentUid,
      'toUid': friendUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final senderDoc = await _firestore
        .collection('users')
        .doc(currentUid)
        .get();
    final senderName = senderDoc.data()?['name'] ?? 'Someone';

    await _pushNotificationService.sendFriendRequestNotification(
      toUserId: friendUid,
      fromUserId: currentUid,
      fromUserName: senderName,
    );
  }

  /// 📩 Mengambil stream permintaan pertemanan yang masuk (pending) secara real-time.
  Stream<List<Map<String, dynamic>>> streamIncomingFriendRequests() {
    _ensureAuthenticated();
    final currentUid = _currentUid!;

    return _firestore
        .collection('friendRequests')
        .where('toUid', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final Map<String, dynamic> data = doc.data();
            data['requestId'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// 📨 Mengambil daftar permintaan pertemanan yang masuk (pending) dengan data sender.
  Future<List<Map<String, dynamic>>> getIncomingFriendRequests() async {
    _ensureAuthenticated();
    final currentUid = _currentUid!;

    final snapshot = await _firestore
        .collection('friendRequests')
        .where('toUid', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    final userIds = snapshot.docs
        .map((e) => e.data()['fromUid'] as String)
        .toSet();
    final userDataMap = <String, Map<String, dynamic>>{};

    // Mengambil data user secara paralel
    for (final uid in userIds) {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        userDataMap[uid] = doc.data()!;
      }
    }

    List<Map<String, dynamic>> requests = [];
    for (final doc in snapshot.docs) {
      final Map<String, dynamic> data = doc.data();
      data['requestId'] = doc.id;
      final senderUid = data['fromUid'] as String;

      if (userDataMap.containsKey(senderUid)) {
        data['senderData'] = userDataMap[senderUid];
      }

      requests.add(data);
    }
    return requests;
  }

  /// ✅ Menerima Friend Request dan menambahkan kedua user ke daftar teman.
  Future<void> acceptFriendRequest(String requestId, String fromUid) async {
    _ensureAuthenticated();
    final currentUid = _currentUid!;

    await _firestore.runTransaction((transaction) async {
      final requestRef = _firestore.collection('friendRequests').doc(requestId);
      final currentUserRef = _firestore.collection('users').doc(currentUid);
      final friendRef = _firestore.collection('users').doc(fromUid);

      // 1. Tulis: Update status request
      transaction.update(requestRef, {
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // 2. Tulis: Tambahkan teman ke daftar user saat ini
      transaction.update(currentUserRef, {
        'friends': FieldValue.arrayUnion([fromUid]),
      });

      // 3. Tulis: Tambahkan user saat ini ke daftar teman si pengirim
      transaction.update(friendRef, {
        'friends': FieldValue.arrayUnion([currentUid]),
      });
    });
  }

  /// ❌ Menolak Friend Request.
  Future<void> declineFriendRequest(String requestId) async {
    _ensureAuthenticated();

    await _firestore.collection('friendRequests').doc(requestId).update({
      'status': 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔄 Membatalkan Friend Request yang dikirim (menghapus dokumen request).
  Future<void> cancelFriendRequest(String requestId) async {
    _ensureAuthenticated();
    await _firestore.collection('friendRequests').doc(requestId).delete();
  }

  /// 👥 Mengambil daftar UID teman user saat ini.
  Future<List<String>> getFriends() async {
    _ensureAuthenticated();

    final snapshot = await _firestore
        .collection('users')
        .doc(_currentUid)
        .get();

    return List<String>.from(snapshot.data()?['friends'] ?? []);
  }

  /// 👥 Mengambil data lengkap dari semua teman user saat ini.
  Future<List<Map<String, dynamic>>> getFriendsData() async {
    _ensureAuthenticated();

    final userDoc = await _firestore.collection('users').doc(_currentUid).get();
    final friendUids = List<String>.from(userDoc.data()?['friends'] ?? []);

    final futures = friendUids
        .map((friendUid) => _firestore.collection('users').doc(friendUid).get())
        .toList();

    final friendDocs = await Future.wait(futures);

    List<Map<String, dynamic>> friendsData = [];
    for (var doc in friendDocs) {
      if (doc.exists) {
        final Map<String, dynamic> data = doc.data()!;
        data['uid'] = doc.id;
        friendsData.add(data);
      }
    }
    return friendsData;
  }

  // --- [ 4. INVITASI AKTIVITAS ] ---

  /// 📨 Mengambil stream undangan kegiatan yang masuk (pending) secara real-time.
  Stream<List<Map<String, dynamic>>> streamActivityInvitations() {
    _ensureAuthenticated();
    final currentUid = _currentUid!;

    return _firestore
        .collection('activityInvitations')
        .where('invitedUid', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final Map<String, dynamic> data = doc.data();
            data['invitationId'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// 📩 Mengambil daftar undangan kegiatan yang masuk dengan data lengkap (invitor & activity).
  Future<List<Map<String, dynamic>>> getActivityInvitations() async {
    _ensureAuthenticated();
    final currentUid = _currentUid!;

    try {
      final snapshot = await _firestore
          .collection('activityInvitations')
          .where('invitedUid', isEqualTo: currentUid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final invitations = <Map<String, dynamic>>[];
      final invitorUids = <String>{};
      final activityIds = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['invitorUid'] is String) invitorUids.add(data['invitorUid']);
        if (data['activityId'] is String) activityIds.add(data['activityId']);
      }

      // ** PERBAIKAN TANGGUH: Menggunakan loop for-async dengan try-catch **
      // Ini untuk menghindari error 'permission-denied' memblokir seluruh notifikasi.
      final invitorMap = await _fetchUsersInSafeBatch(invitorUids);
      final activityMap = await _fetchActivitiesInSafeBatch(activityIds);

      for (final doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        data['invitationId'] = doc.id;

        final invitorUid = data['invitorUid'] as String?;
        if (invitorUid != null && invitorMap.containsKey(invitorUid)) {
          data['invitorData'] = invitorMap[invitorUid];
        }

        final activityId = data['activityId'] as String?;
        if (activityId != null && activityMap.containsKey(activityId)) {
          data['activityData'] = activityMap[activityId];
        }

        invitations.add(data);
      }

      return invitations;
    } catch (e) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'GET_INVITATIONS_ERROR',
        message: 'Gagal mengambil invitasi aktivitas: $e',
      );
    }
  }

  // Fungsi Helper untuk mengambil data user secara aman
  Future<Map<String, Map<String, dynamic>>> _fetchUsersInSafeBatch(
    Set<String> uids,
  ) async {
    final Map<String, Map<String, dynamic>> userMap = {};
    for (final uid in uids) {
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          userMap[uid] = doc.data()!;
        }
      } catch (e) {
        print('Warning: Gagal membaca data user $uid: $e');
      }
    }
    return userMap;
  }

  // Fungsi Helper untuk mengambil data activity secara aman
  Future<Map<String, Map<String, dynamic>>> _fetchActivitiesInSafeBatch(
    Set<String> ids,
  ) async {
    final Map<String, Map<String, dynamic>> activityMap = {};
    for (final id in ids) {
      try {
        final doc = await _firestore.collection('activities').doc(id).get();
        if (doc.exists) {
          activityMap[id] = doc.data()!;
        }
      } catch (e) {
        print('Warning: Gagal membaca data activity $id: $e');
      }
    }
    return activityMap;
  }

  /// ✅ Menerima undangan kegiatan dan menambahkan user ke daftar anggota kegiatan.
  Future<void> acceptActivityInvitation(
    String invitationId,
    String activityId,
  ) async {
    _ensureAuthenticated();
    final currentUid = _currentUid!;

    try {
      await _firestore.runTransaction((transaction) async {
        final invitationRef = _firestore
            .collection('activityInvitations')
            .doc(invitationId);
        final activityRef = _firestore.collection('activities').doc(activityId);

        // --- 1. OPERASI BACA ---
        // Baca activityDoc untuk memastikan keberadaan dan validitas (jika perlu)
        final activityDoc = await transaction.get(activityRef);

        // --- 2. OPERASI TULIS ---

        // 2a. Update invitation status menjadi accepted
        transaction.update(invitationRef, {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        });

        // 2b. Update activity document (hanya jika activity ada)
        if (activityDoc.exists) {
          transaction.update(activityRef, {
            'members': FieldValue.arrayUnion([
              currentUid,
            ]), // Tambahkan ke members
            'invitedUids': FieldValue.arrayUnion([
              currentUid,
            ]), // Tambahkan ke invitedUids
          });
        }
      });
    } catch (e) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'ACCEPT_INVITATION_ERROR',
        message: 'Gagal menerima invitasi: $e',
      );
    }
  }

  /// ❌ Menolak undangan kegiatan.
  Future<void> declineActivityInvitation(String invitationId) async {
    _ensureAuthenticated();

    try {
      await _firestore
          .collection('activityInvitations')
          .doc(invitationId)
          .update({
            'status': 'declined',
            'respondedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'DECLINE_INVITATION_ERROR',
        message: 'Gagal menolak invitasi: $e',
      );
    }
  }
}
