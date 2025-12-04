import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
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

  // ➕ Tambahkan teman berdasarkan UID (Menambah pengecekan null safety)
  Future<void> addFriend(String friendUid) async {
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

    await _firestore.collection('users').doc(currentUid).update({
      // FieldValue.arrayUnion memastikan tidak ada duplikasi UID
      'friends': FieldValue.arrayUnion([friendUid]),
    });
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
      // 1. Upload ke Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profile_images')
          .child('${currentUser.uid}.jpg');

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

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
}
