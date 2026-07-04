import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/comment_repository.dart';

class CommentSection extends ConsumerStatefulWidget {
  final String ticketId;

  const CommentSection({super.key, required this.ticketId});

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await ref.read(commentRepositoryProvider).addComment(
        widget.ticketId,
        _currentUserId,
        _commentController.text.trim(),
      );
      _commentController.clear();
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
    final commentsStream = ref.watch(commentRepositoryProvider).getCommentsStream(widget.ticketId);

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
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: commentsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final comments = snapshot.data ?? [];
              
              if (comments.isEmpty) {
                return const Center(child: Text('Belum ada komentar.'));
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  final isMe = comment['user_id'] == _currentUserId;
                  
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMe ? Colors.blue.withOpacity(0.5) : Colors.grey.withOpacity(0.5),
                        ),
                      ),
                      child: Text(comment['content']?.toString() ?? ''),
                    ),
                  );
                },
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
                onPressed: _submitComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}