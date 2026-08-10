import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/note.dart';
import '../../services/notes_service.dart';
import '../../utils/theme.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final notes = await NotesService.instance.getAll();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _openEditor([Note? note]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
    _refresh();
  }

  Future<void> _delete(Note note) async {
    if (note.id != null) {
      await NotesService.instance.delete(note.id!);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملاحظات')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('لا توجد ملاحظات بعد — اضغط + للإضافة',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final n = _notes[index];
                    final date = DateFormat('yyyy/MM/dd – HH:mm')
                        .format(DateTime.fromMillisecondsSinceEpoch(n.createdAt));
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        title: Text(n.title.isEmpty ? '(بدون عنوان)' : n.title,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(n.content,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (n.linkedLabel != null && n.linkedLabel!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('مرتبطة بـ: ${n.linkedLabel}',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppTheme.gold)),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(date,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade500)),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _delete(n),
                        ),
                        onTap: () => _openEditor(n),
                      ),
                    );
                  },
                ),
    );
  }
}
