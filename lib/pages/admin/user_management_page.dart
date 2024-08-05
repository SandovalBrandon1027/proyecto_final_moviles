import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Administrar Usuarios'),
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
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
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  bool? confirm = await _confirmDeletion(context);
                  if (confirm == true) {
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
          title: Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar este usuario?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Eliminar'),
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
      print('Documento eliminado de Firestore');

      // Eliminar el usuario de Firebase Auth
      User? user = await _getUserById(userId);
      if (user != null) {
        await user.delete();
        print('Usuario eliminado de Firebase Auth');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuario eliminado exitosamente.'),
        ),
      );
    } catch (e) {
      // Manejo de errores, puedes mostrar un mensaje al usuario
      print('Error al eliminar el usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
      print('Error al obtener el usuario por UID: $e');
      return null;
    }
  }
}
