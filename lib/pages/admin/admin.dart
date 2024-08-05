// lib/pages/admin/admin.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // Importa el paquete url_launcher
import 'package:firebase_auth/firebase_auth.dart';
import 'user_management_page.dart';
import '../../pages/login/login.dart';

class Admin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Administrador'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menú',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
           ListTile(
            title: Text('Cerrar Sesión'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pop(); // Cierra el menú
              // Usar un Builder para obtener un contexto adecuado para la navegación
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => Login()),
                (route) => false,
              );
            },
          ),

            ListTile(
              title: Text('Administrar Usuarios'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UserManagementPage(),
                ));
              },
            ),
          ],
        ),
      ),
      body: _buildMessagesList(),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var messages = snapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var message = messages[index].data() as Map<String, dynamic>;
            bool isLocation = message['isLocation'] ?? false;

            return ListTile(
              title: Text(message['userId']),
              subtitle: isLocation
                  ? InkWell(
                      onTap: () async {
                        var url = message['text'];
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No se puede abrir el enlace.'),
                            ),
                          );
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.containsKey('location') &&
                              message['location'] != null)
                            Container(
                              width: double.infinity,
                              child: Image.network(

                                'https://maps.googleapis.com/maps/api/staticmap?center=${message['location']['latitude']},${message['location']['longitude']}&zoom=15&size=200x200&markers=color:red%7Clabel:C%7C${message['location']['latitude']},${message['location']['longitude']}&key=AIzaSyCrEDcgmVLzf0tGj5Y8RJBlDHqmB9vKsVc',
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          SizedBox(height: 8),
                          Text(
                            'Ubicación exacta',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      message['message'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
