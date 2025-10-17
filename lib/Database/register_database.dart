import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> registerUser({
  required String email,
  required String password,
  required String name,
  required String phone,
  required String address,
  required String gender,
  required DateTime dob,
  required String avatar,
  required String roleId,
}) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    String uid = userCredential.user!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      "name": name,
      "phone": phone,
      "address": address,
      "gender": gender,
      "dob": dob,
      "avatar": avatar,
      "role_id": roleId,
      "e-mail": email,
      "createdAt": FieldValue.serverTimestamp(),
    });


  } on FirebaseAuthException catch (e) {
    print('Loi dang ky: ${e.message}');
  } catch (e) {
    print('Loi khac: $e');
  }
}
