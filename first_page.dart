import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


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

      // Check if user has already joined this specific post
      final alreadyJoinedThisPostDoc = await FirebaseFirestore.instance
          .collection('Posts')
          .doc(post['AuthorUsername'])
          .collection('users_joined')
          .doc(user.uid)
          .get();
          
      if (alreadyJoinedThisPostDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already joined this post'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if post is full
      final joinedUsersCount = await FirebaseFirestore.instance
          .collection('Posts')
          .doc(post['AuthorUsername'])
          .collection('users_joined')
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
        // Check if user is already in another post
        DocumentSnapshot userSnapshot = await transaction.get(
          FirebaseFirestore.instance.collection('users').doc(user.uid)
        );
        
        Map<String, dynamic>? userInfo = userSnapshot.data() as Map<String, dynamic>?;
        
        // If user is already in another post, remove them from it
        if (userInfo != null && userInfo['hasJoinedPost'] == true && 
            userInfo['joinedPostAuthor'] != null && 
            userInfo['joinedPostAuthor'] != post['AuthorUsername']) {
          
          String previousPostAuthor = userInfo['joinedPostAuthor'];
          
          // Remove user from previous post's users_joined collection
          transaction.delete(
            FirebaseFirestore.instance
                .collection('Posts')
                .doc(previousPostAuthor)
                .collection('users_joined')
                .doc(user.uid)
          );
          
          // Get the previous post to check if its status needs updating
          DocumentSnapshot previousPostSnapshot = await transaction.get(
            FirebaseFirestore.instance.collection('Posts').doc(previousPostAuthor)
          );
          
          // If the previous post was full, update its status to Open
          if (previousPostSnapshot.exists) {
            Map<String, dynamic>? previousPostData = 
                previousPostSnapshot.data() as Map<String, dynamic>?;
            if (previousPostData != null && previousPostData['Status'] == 'Full') {
              transaction.update(
                FirebaseFirestore.instance.collection('Posts').doc(previousPostAuthor),
                {'Status': 'Open'}
              );
            }
          }
        }

        // Add user to new post's users_joined collection
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
          }
        );

        // Update user's status with new post info
        transaction.update(
          FirebaseFirestore.instance.collection('users').doc(user.uid),
          {
            'hasJoinedPost': true,
            'joinedPostAuthor': post['AuthorUsername'],
          }
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
      body: StreamBuilder<QuerySnapshot>(
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
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final post = snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        '${post['GameMode']} - ${post['GroupSize']} Teammates',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
