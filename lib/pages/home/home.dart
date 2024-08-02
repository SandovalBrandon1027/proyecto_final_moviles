// lib/screens/home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/calculation_service.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Chat'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu, color: Colors.black),
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
                await AuthService().signout(context: context);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Expanded(child: _buildChat()),
              _buildMessageInput(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChat() {
    var currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: ChatService().getMessages(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var messages = snapshot.data!.docs;

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var message = messages[index].data() as Map<String, dynamic>;
            bool isCurrentUser = message['userId'] == currentUser!.email;
            bool isLocation = message['isLocation'] ?? false;

            return Align(
              alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7),
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.blue[200] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          message['userId'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        if (isCurrentUser)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await ChatService().deleteMessage(messages[index].id);
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    isLocation
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
                            message['text'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Escribe un mensaje',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.location_on),
            onPressed: () async {
              var locationService = LocationService();
              var locationData = await locationService.getLocation();

              if (locationData != null) {
                var googleMapsLink = locationService.generateGoogleMapsLink(
                  locationData.latitude!,
                  locationData.longitude!,
                );

                var user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  GeoPoint geoPoint = GeoPoint(
                    locationData.latitude!,
                    locationData.longitude!,
                  );

                  await ChatService().sendMessage(
                    googleMapsLink,
                    user.email!,
                    isLocation: true,
                    location: geoPoint,
                  );

                  await ChatService().updateUserLocation(user.email!, geoPoint);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo obtener la ubicación.'),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () async {
              var user = FirebaseAuth.instance.currentUser;
              var text = _controller.text.trim(); // Eliminar espacios en blanco
              if (user != null && text.isNotEmpty) {
                await ChatService().sendMessage(
                  text,
                  user.email!,
                  isLocation: false,
                );
                _controller.clear(); // Limpiar el campo de texto solo después de enviar el mensaje
                _scrollToBottom(); // Autoscroll after sending a message
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('El mensaje no puede estar vacío.'),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.calculate),
            onPressed: () async {
              var calculationService = CalculationService();
              var result = await calculationService.calculate();

              var user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                String message;
                if (result['type'] == 'error') {
                  message = result['message'];
                } else if (result['type'] == 'distance') {
                  message = 'Distancia: ${result['value']} km';
                } else {
                  message =
                      'Perímetro: ${result['perimeter']} km\nÁrea: ${result['area']} km²';
                }
                await ChatService().sendMessage(
                  message,
                  'Servidor',
                  isLocation: false,
                );
                _scrollToBottom(); // Autoscroll after calculation
              }
            },
          ),
        ],
      ),
    );
  }
}
