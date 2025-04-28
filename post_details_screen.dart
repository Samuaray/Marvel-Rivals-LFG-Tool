import 'package:flutter/material.dart';

class PostDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    bool isAuthor = post['author'] == 'Player1'; // Mock current user check

    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mode: ${post['mode']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Teammates: ${post['teammates']}'),
            const SizedBox(height: 8),
            Text('Mic: ${post['mic'] ? "Required" : "Not Required"}'),
            const SizedBox(height: 16),
            
            Text('Author: ${post['author']}'),
            const Spacer(),

            // Join/Leave and Edit/Delete buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Join or leave group logic here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Joined the group!')),
                    );
                  },
                  child: const Text('Join Group'),
                ),
                if (isAuthor) ...[
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to Edit Screen (to be added)
                    },
                    child: const Text('Edit'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Delete post logic here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post deleted')),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
                if (!isAuthor)
                  ElevatedButton(
                    onPressed: () {
                      // Leave group logic here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Left the group')),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Leave'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
