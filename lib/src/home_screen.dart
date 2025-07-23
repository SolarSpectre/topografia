import 'package:flutter/material.dart';
import '../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_crud_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menú Principal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Mapa'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Gestión de usuarios'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserCrudScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              child: const Text('Cerrar sesión'),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                // El StreamBuilder en main.dart redirigirá automáticamente al login
              },
            ),
          ],
        ),
      ),
    );
  }
}
