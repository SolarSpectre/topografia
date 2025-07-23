import 'package:flutter/material.dart';

class UserCrudScreen extends StatelessWidget {
  const UserCrudScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de usuarios')),
      body: const Center(
        child: Text('Aquí irá el CRUD de usuarios'),
      ),
    );
  }
}
