import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../pages/home/home.dart';
import '../pages/login/login.dart';
import '../pages/admin/admin.dart'; 

class AuthService {
  Future<void> signup({
    required String email,
    required String password,
    required String role,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String collectionName = role == 'Administrador' ? 'administradores' : 'users';
      String uid = userCredential.user!.uid;

      // Reemplaza caracteres no permitidos en el correo electrónico
      //String documentId = email.replaceAll(RegExp(r'[^\w\s]+'), '_');

      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(uid)
          .set({
        'email': email,
        'role': role,
      });

      await Future.delayed(const Duration(seconds: 1));

      // Redirige basado en el rol
      if (role == 'Administrador') {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const AdminMap(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const Home(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'La contraseña es muy débil.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Ya existe una cuenta registrada con ese correo electrónico.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error al registrar: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // ignore: unused_local_variable
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String documentId = email.replaceAll(RegExp(r'[^\w\s]+'), '_');

      // Obtiene el rol del usuario desde Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(documentId).get();
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('administradores').doc(documentId).get();

      String role = '';
      if (userDoc.exists) {
        role = 'Usuario';
      } else if (adminDoc.exists) {
        role = 'Administrador';
      }

      await Future.delayed(const Duration(seconds: 1));

      // Redirige basado en el rol
      if (role == 'Administrador') {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const AdminMap(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const Home(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'El correo electrónico no se encuentra registrado.';
      } else if (e.code == 'invalid-credential') {
        message = 'Contraseña incorrecta.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error al iniciar sesión: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> signout({
    required BuildContext context,
  }) async {
    await FirebaseAuth.instance.signOut();
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => Login(),
      ),
    );
  }
}
