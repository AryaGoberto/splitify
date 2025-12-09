import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';
import 'push_notification_service.dart';

class UserService {
  final PushNotificationService _pushNotificationService =
      PushNotificationService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // 🔍 Cari user berdasarkan email (Menggunakan normalisasi email)
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    // Normalisasi email menjadi huruf kecil untuk pencarian yang konsisten
    final normalizedEmail = email.toLowerCase().trim();

    final result = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (result.docs.isEmpty) return null;

    final doc = result.docs.first;
    final data = doc.data();
    data['uid'] = doc.id; // tambahkan UID user
    return data;
  }

  // ➕ Kirim Friend Request (Menggantikan addFriend langsung)
  Future<void> sendFriendRequest(String friendUid) async {
    final currentUser = _auth.currentUser;

    // Pengecekan: Pastikan pengguna sedang login dan tidak mencoba menambah diri sendiri
    if (currentUser == null || currentUser.uid == friendUid) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'INVALID_FRIEND_ID',
        message:
            'User tidak terautentikasi atau mencoba menambah diri sendiri.',
      );
    }

    final currentUid = currentUser.uid;

    // Cek apakah sudah berteman
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

    // Cek apakah request sudah ada
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

    // Buat friend request baru
    await _firestore.collection('friendRequests').add({
      'fromUid': currentUid,
      'toUid': friendUid,
      'status': 'pending', // pending, accepted, declined
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 🔔 Kirim push notification
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

  // 📨 Get Incoming Friend Requests (yang diterima user)
  Future<List<Map<String, dynamic>>> getIncomingFriendRequests() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login.',
      );
    }

    final snapshot = await _firestore
        .collection('friendRequests')
        .where('toUid', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    List<Map<String, dynamic>> requests = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      data['requestId'] = doc.id;

      // Ambil data sender
      final senderDoc = await _firestore
          .collection('users')
          .doc(data['fromUid'])
          .get();
      if (senderDoc.exists) {
        data['senderData'] = senderDoc.data();
      }

      requests.add(data);
    }

    return requests;
  }

  // ✅ Accept Friend Request
  Future<void> acceptFriendRequest(String requestId, String fromUid) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login.',
      );
    }

    final batch = _firestore.batch();

    // 1. Update status request menjadi accepted
    final requestRef = _firestore.collection('friendRequests').doc(requestId);
    batch.update(requestRef, {
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // 2. Tambahkan ke daftar friends kedua user
    final currentUserRef = _firestore.collection('users').doc(currentUser.uid);
    batch.update(currentUserRef, {
      'friends': FieldValue.arrayUnion([fromUid]),
    });

    final friendRef = _firestore.collection('users').doc(fromUid);
    batch.update(friendRef, {
      'friends': FieldValue.arrayUnion([currentUser.uid]),
    });

    await batch.commit();
  }

  // ❌ Decline Friend Request
  Future<void> declineFriendRequest(String requestId) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login.',
      );
    }

    // Update status request menjadi declined
    await _firestore.collection('friendRequests').doc(requestId).update({
      'status': 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔄 Cancel Friend Request (hapus request yang kita kirim)
  Future<void> cancelFriendRequest(String requestId) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login.',
      );
    }

    await _firestore.collection('friendRequests').doc(requestId).delete();
  }

  // 👥 Ambil daftar teman user saat ini (Menambah pengecekan null safety)
  Future<List<String>> getFriends() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login untuk melihat daftar teman.',
      );
    }

    final uid = currentUser.uid;
    final snapshot = await _firestore.collection('users').doc(uid).get();

    final data = snapshot.data();
    // Menggunakan safe cast (List<String>.from)
    return List<String>.from(data?['friends'] ?? []);
  }

  // ✏️ Update user profile (Name)
  Future<void> updateUserProfile({required String name}) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login untuk mengupdate profil.',
      );
    }

    // 1. Update Display Name di FirebaseAuth
    await currentUser.updateDisplayName(name);

    // 2. Update Name di Firestore
    await _firestore.collection('users').doc(currentUser.uid).update({
      'name': name,
    });
  }

  // 🔒 Ganti Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login untuk mengganti password.',
      );
    }

    final email = currentUser.email;
    if (email == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NO_EMAIL',
        message: 'User tidak memiliki email.',
      );
    }

    // Re-authenticate user
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await currentUser.reauthenticateWithCredential(credential);

    // Update password
    await currentUser.updatePassword(newPassword);
  }

  // 🗑️ Hapus Akun
  Future<void> deleteAccount({required String password}) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login untuk menghapus akun.',
      );
    }

    final email = currentUser.email;
    if (email == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NO_EMAIL',
        message: 'User tidak memiliki email.',
      );
    }

    // Re-authenticate user
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await currentUser.reauthenticateWithCredential(credential);

    // Hapus data user dari Firestore
    await _firestore.collection('users').doc(currentUser.uid).delete();

    // Hapus user dari Authentication
    await currentUser.delete();
  }

  // 📧 Ganti Email
  Future<void> updateEmail({required String newEmail}) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login untuk mengganti email.',
      );
    }

    // Update email di Authentication (Mengirim verifikasi)
    await currentUser.verifyBeforeUpdateEmail(newEmail);

    // Update email di Firestore
    await _firestore.collection('users').doc(currentUser.uid).update({
      'email': newEmail,
    });
  }

  // 📸 Upload Profile Picture
  Future<String> uploadProfilePicture(File imageFile) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login untuk mengupload foto profil.',
      );
    }

    try {
      // 1) Upload ke Cloudinary via unsigned upload preset
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset;

      if (CloudinaryConfig.folder.isNotEmpty) {
        request.fields['folder'] = CloudinaryConfig.folder;
      }

      // Gunakan UID agar mudah dilacak, tapi biarkan Cloudinary membuat versi unik jika sudah ada
      request.fields['public_id'] = currentUser.uid;

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw FirebaseException(
          plugin: 'UserService',
          code: 'UPLOAD_FAILED',
          message: 'Cloudinary error ${response.statusCode}: ${response.body}',
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

      // 2. Update Photo URL di FirebaseAuth
      await currentUser.updatePhotoURL(downloadUrl);

      // 3. Update Photo URL di Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'photoUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'UPLOAD_FAILED',
        message: 'Gagal mengupload foto profil: $e',
      );
    }
  }

  // 👥 Get Friends Data Lengkap (dengan info user)
  Future<List<Map<String, dynamic>>> getFriendsData() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login.',
      );
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final friendUids = List<String>.from(userDoc.data()?['friends'] ?? []);

    List<Map<String, dynamic>> friendsData = [];

    for (final friendUid in friendUids) {
      final friendDoc = await _firestore
          .collection('users')
          .doc(friendUid)
          .get();
      if (friendDoc.exists) {
        final data = friendDoc.data()!;
        data['uid'] = friendUid;
        friendsData.add(data);
      }
    }

    return friendsData;
  }

  // 📩 Get Activity Invitations (Notifikasi aktivitas dari teman)
  Future<List<Map<String, dynamic>>> getActivityInvitations() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login.',
      );
    }

    try {
      final snapshot = await _firestore
          .collection('activityInvitations')
          .where('invitedUid', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final invitations = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final invitorUid = data['invitorUid'] as String?;

        // Ambil data invitor
        if (invitorUid != null) {
          final invitorDoc = await _firestore
              .collection('users')
              .doc(invitorUid)
              .get();

          if (invitorDoc.exists) {
            final invitorData = invitorDoc.data()!;
            data['invitorData'] = invitorData;
          }
        }

        // Ambil data aktivitas
        final activityId = data['activityId'] as String?;
        if (activityId != null) {
          final activityDoc = await _firestore
              .collection('activities')
              .doc(activityId)
              .get();

          if (activityDoc.exists) {
            final activityData = activityDoc.data()!;
            data['activityData'] = activityData;
          }
        }

        data['invitationId'] = doc.id;
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

  // ✅ Accept Activity Invitation
  Future<void> acceptActivityInvitation(
    String invitationId,
    String activityId,
  ) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login.',
      );
    }

    try {
      // Update invitation status
      await _firestore
          .collection('activityInvitations')
          .doc(invitationId)
          .update({
            'status': 'accepted',
            'respondedAt': FieldValue.serverTimestamp(),
          });

      // Tambahkan user ke members aktivitas (jika belum ada)
      final activityDoc = await _firestore
          .collection('activities')
          .doc(activityId)
          .get();

      if (activityDoc.exists) {
        final members = List<String>.from(activityDoc.data()?['members'] ?? []);
        if (!members.contains(currentUser.displayName)) {
          members.add(currentUser.displayName ?? 'Unknown');
          await _firestore.collection('activities').doc(activityId).update({
            'members': members,
          });
        }
      }
    } catch (e) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'ACCEPT_INVITATION_ERROR',
        message: 'Gagal menerima invitasi: $e',
      );
    }
  }

  // ❌ Decline Activity Invitation
  Future<void> declineActivityInvitation(String invitationId) async {
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
