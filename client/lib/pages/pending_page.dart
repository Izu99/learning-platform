import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/api_service.dart';

class PendingPage extends StatefulWidget {
  @override
  _PendingPageState createState() => _PendingPageState();
}

class _PendingPageState extends State<PendingPage> {
  List<Teacher> pending = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ApiService().getPendingTeachers();
    setState(() {
      pending = list;
      loading = false;
    });
  }

  Future<void> _approve(Teacher t) async {
    final ok = await ApiService().approveTeacher(t.id);
    if (ok) {
      setState(() {
        pending.removeWhere((x) => x.id == t.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text('Pending Approvals')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final t = pending[index];
            return Card(
              child: ListTile(
                title: Text(t.name),
                subtitle: Text(t.email),
                trailing: ElevatedButton(
                  onPressed: () => _approve(t),
                  child: Text('Approve'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
