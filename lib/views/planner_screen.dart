import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  void _showAddTaskSheet() {
    final subjectController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'Medium';
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Add Task", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                hintText: "Subject / Task name",
                filled: true,
                fillColor: const Color(0xFFF5F3FF),
                prefixIcon: const Icon(Icons.book_outlined, color: Color(0xFFFF9966)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Description (optional)",
                filled: true,
                fillColor: const Color(0xFFF5F3FF),
                prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFFFF9966)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            const Text("Priority", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
                children: ['High', 'Medium', 'Low'].map((p) {
              final color = p == 'High'
                  ? Colors.red
                  : p == 'Medium'
                      ? Colors.orange
                      : Colors.green;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setModalState(() => priority = p),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: priority == p ? color : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(p,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: priority == p ? Colors.white : color,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setModalState(() => selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFFFF9966)),
                  const SizedBox(width: 12),
                  Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}", style: const TextStyle(fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (subjectController.text.trim().isEmpty) return;
                  final uid = _auth.getCurrentUserId();
                  await _firestore.collection("users").doc(uid).collection("tasks").add({
                    "subject": subjectController.text.trim(),
                    "description": descController.text.trim(),
                    "priority": priority,
                    "date": Timestamp.fromDate(selectedDate),
                    "completed": false,
                    "createdAt": Timestamp.now(),
                  });
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9966),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("Add Task", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.getCurrentUserId();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9966),
        foregroundColor: Colors.white,
        title: const Text("Study Planner", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskSheet,
        backgroundColor: const Color(0xFFFF9966),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Task"),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection("users").doc(uid).collection("tasks").orderBy("date").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          final pending = docs.where((d) => !(d.data()["completed"] as bool? ?? false)).toList();
          final completed = docs.where((d) => d.data()["completed"] as bool? ?? false).toList();

          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.event_note_outlined, size: 72, color: Colors.black26),
                const SizedBox(height: 16),
                const Text("No tasks yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black45)),
                const SizedBox(height: 8),
                const Text("Tap the button below to add your first task", style: TextStyle(color: Colors.black38)),
              ]),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // Stats row
              Row(children: [
                Expanded(child: _StatCard(label: "Total", value: "${docs.length}", color: const Color(0xFFFF9966), icon: Icons.task_alt)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: "Pending", value: "${pending.length}", color: Colors.orange, icon: Icons.pending_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: "Done", value: "${completed.length}", color: Colors.green, icon: Icons.check_circle_outline)),
              ]),

              // Progress bar
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Overall Progress", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("${docs.isEmpty ? 0 : (completed.length / docs.length * 100).round()}%",
                        style: const TextStyle(color: Color(0xFFFF9966), fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: docs.isEmpty ? 0 : completed.length / docs.length,
                      backgroundColor: Colors.black12,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9966)),
                      minHeight: 8,
                    ),
                  ),
                ]),
              ),

              if (pending.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text("Pending Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 10),
                ...pending.map((doc) => _TaskCard(doc: doc, uid: uid, firestore: _firestore)),
              ],

              if (completed.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text("Completed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black45)),
                const SizedBox(height: 10),
                ...completed.map((doc) => _TaskCard(doc: doc, uid: uid, firestore: _firestore)),
              ],

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
      ]),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String uid;
  final FirebaseFirestore firestore;
  const _TaskCard({required this.doc, required this.uid, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final completed = data["completed"] as bool? ?? false;
    final priority = data["priority"] as String? ?? "Medium";
    final date = (data["date"] as Timestamp?)?.toDate();
    final priorityColor = priority == 'High'
        ? Colors.red
        : priority == 'Medium'
            ? Colors.orange
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => firestore.collection("users").doc(uid).collection("tasks").doc(doc.id).update({"completed": !completed}),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: completed ? const Color(0xFFFF9966) : Colors.transparent,
              border: Border.all(color: completed ? const Color(0xFFFF9966) : Colors.black26, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: completed ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              data["subject"] as String? ?? "",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  decoration: completed ? TextDecoration.lineThrough : null,
                  color: completed ? Colors.black38 : Colors.black87),
            ),
            if ((data["description"] as String? ?? "").isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(data["description"] as String, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: priorityColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(priority, style: TextStyle(color: priorityColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              if (date != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_outlined, size: 12, color: Colors.black38),
                const SizedBox(width: 4),
                Text("${date.day}/${date.month}/${date.year}", style: const TextStyle(color: Colors.black38, fontSize: 11)),
              ],
            ]),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.black26, size: 20),
          onPressed: () => firestore.collection("users").doc(uid).collection("tasks").doc(doc.id).delete(),
        ),
      ]),
    );
  }
}
