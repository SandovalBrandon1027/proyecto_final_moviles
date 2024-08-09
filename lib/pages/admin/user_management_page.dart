import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

final logger =Logger();
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Usuarios'),
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index].data() as Map<String, dynamic>;
            String userId = users[index].id;

            return ListTile(
              title: Text(user['email']),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  bool? confirm = await _confirmDeletion(context);
                  if (confirm == true) {
                    // ignore: use_build_context_synchronously
                    await _deleteUser(userId, context);
                    // Forzar actualización
                    setState(() {});
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmDeletion(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este usuario?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(String userId, BuildContext context) async {
    try {
      // Elimina el usuario de Firestore usando el UID del documento
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      logger.i('Documento eliminado de Firestore');

      // Eliminar el usuario de Firebase Auth
      User? user = await _getUserById(userId);
      if (user != null) {
        await user.delete();
        logger.i('Usuario eliminado de Firebase Auth');
      }

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario eliminado exitosamente.'),
        ),
      );
    } catch (e) {
      // Manejo de errores, puedes mostrar un mensaje al usuario
      logger.i('Error al eliminar el usuario: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar el usuario.'),
        ),
      );
    }
  }

  Future<User?> _getUserById(String uid) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        return user;
      }
      return null;
    } catch (e) {
      logger.i('Error al obtener el usuario por UID: $e');
      return null;
    }
  }
}
