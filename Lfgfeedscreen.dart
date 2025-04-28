import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_details_screen.dart';

class LFGFeedScreen extends StatefulWidget {
  const LFGFeedScreen({super.key});

  @override
  State<LFGFeedScreen> createState() => _LFGFeedScreenState();
}

class _LFGFeedScreenState extends State<LFGFeedScreen> {
 Future<void> _joinPost(BuildContext context, Map<String, dynamic> post) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get user's data
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    final userData = userDoc.data();
    if (userData == null) return;

    // Check if user is the author of the post
    if (post['AuthorUID'] == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot join your own post'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user has already joined this post
    final alreadyJoinedDoc = await FirebaseFirestore.instance
        .collection('Posts')
        .doc(post['AuthorUsername'])
        .collection('users_joined')
        .doc(user.uid)
        .get();
        
    if (alreadyJoinedDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already joined this post'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if post is full before attempting to join
    final joinedUsersCount = await FirebaseFirestore.instance
        .collection('Posts')
        .doc(post['AuthorUsername'])
        .collection('users_joined')
        .where(FieldPath.documentId, isNotEqualTo: 'placeholder')
        .count()
        .get();

    if ((joinedUsersCount.count ?? 0) >= post['GroupSize']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This group is full'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Use a transaction for all database operations
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Add user to post's users_joined collection
      transaction.set(
        FirebaseFirestore.instance
            .collection('Posts')
            .doc(post['AuthorUsername'])
            .collection('users_joined')
            .doc(user.uid),
        {
          'username': userData['Username'],
          'platform': userData['platform'],
          'joinedAt': FieldValue.serverTimestamp(),
        },
      );

      // Update user's status
      transaction.update(
        FirebaseFirestore.instance.collection('users').doc(user.uid),
        {
          'hasJoinedPost': true,
          'joinedPostAuthor': post['AuthorUsername'],
        },
      );

      // If adding this user would make the group full, update the post status
      if ((joinedUsersCount.count ?? 0) + 1 >= post['GroupSize']) {
        transaction.update(
          FirebaseFirestore.instance.collection('Posts').doc(post['AuthorUsername']),
          {'Status': 'Full'}
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully joined the group!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error joining post: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LFG Feed'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Posts')
              .orderBy('CreatedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No LFG posts available'));
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final post = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Column(
                    children: [
                      ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${post['GameMode']} - ${post['GroupSize']} Teammates',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (post['Mic'] == 'Yes')
                              const Icon(
                                Icons.mic,
                                size: 20,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Author: ${post['AuthorUsername']}'),
                            Text('Platform: ${post['AuthorPlatform']}'),
                            Text('Mic: ${post['Mic']}'),
                            if (post['MinimumRank'] != null)
                              Text('Rank: ${post['MinimumRank']}'),
                            Text('Status: ${post['Status']}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailsScreen(
                                post: post,
                              ),
                            ),
                          );
                        },
                      ),
                      OverflowBar(
                        children: [
                          TextButton(
                            onPressed: post['Status'] == 'Open' 
                                ? () => _joinPost(context, post)
                                : null,
                            style: TextButton.styleFrom(
                              foregroundColor: post['Status'] == 'Open' 
                                  ? Colors.blue[900] 
                                  : Colors.grey,
                            ),
                            child: Text(
                              post['Status'] == 'Open' 
                                  ? 'Join Group' 
                                  : post['Status'] == 'Full' 
                                      ? 'Full' 
                                      : 'Closed',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
