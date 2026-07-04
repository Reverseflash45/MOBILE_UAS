import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentSection extends StatefulWidget {
  final String ticketId;

  const CommentSection({super.key, required this.ticketId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final response = await _supabase
          .from('comments')
          .select('*, profiles(full_name, role)')
          .eq('ticket_id', widget.ticketId)
          .order('created_at', ascending: true);

      setState(() {
        _comments = List<Map<String, dynamic>>.from(response);
      });
    } catch (_) {
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    if (_commentController.text.isEmpty) return;

    final text = _commentController.text;
    _commentController.clear();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('comments').insert({
        'ticket_id': widget.ticketId,
        'user_id': user.id,
        'content': text,
      });

      _fetchComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Komentar & Diskusi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    final profile = comment['profiles'] ?? {};
                    final senderName = profile['full_name'] ?? 'User';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          senderName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        subtitle: Text(comment['content'] ?? ''),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Tulis komentar...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _sendComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}