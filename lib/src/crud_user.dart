import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CrudUserScreen extends StatefulWidget {
  const CrudUserScreen({Key? key}) : super(key: key);

  @override
  _CrudUserScreenState createState() => _CrudUserScreenState();
}

class _CrudUserScreenState extends State<CrudUserScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    final email = _emailController.text.trim();
    final role = _roleController.text.trim();
    if (email.isNotEmpty && role.isNotEmpty) {
      await _firestore.collection('users').add({
        'email': email,
        'role': role,
        'active': true,
      });
      _emailController.clear();
      _roleController.clear();
    }
  }

  Future<void> _deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<void> _toggleActive(String userId, bool currentStatus) async {
    await _firestore.collection('users').doc(userId).update({'active': !currentStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRUD Usuarios/Admins')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _roleController,
                    decoration: const InputDecoration(labelText: 'Rol (usuario/admin)'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addUser,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                  final email = user['email'] ?? '';
                  final role = user.data().toString().contains('role') ? user['role'] : 'usuario';
                  final active = user.data().toString().contains('active') ? user['active'] : true;
                  return ListTile(
                    title: Text(email),
                    subtitle: Text('Rol: $role'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(active ? Icons.visibility : Icons.visibility_off),
                          tooltip: active ? 'Desactivar' : 'Activar',
                          onPressed: () => _toggleActive(user.id, active),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Eliminar',
                          onPressed: () => _deleteUser(user.id),
                        ),
                      ],
                    ),
                  );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
