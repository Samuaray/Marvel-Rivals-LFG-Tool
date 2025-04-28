import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'first_page.dart';

class ProfilePage extends StatefulWidget {
  final String userID;

  const ProfilePage({
    super.key,
    required this.userID,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _showChangeUsernameDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Username'),
        content: TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'New Username',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (_usernameController.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userID)
                      .update({'Username': _usernameController.text.trim()});

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Username updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating username: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _kickPlayer(String postId, String playerId, String playerName) async {
    try {
      // Remove player from users_joined collection
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .collection('users_joined')
          .doc(playerId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kicked $playerName from the group'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error kicking player: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _closePost(String postId) async {
    try {
      // Update post status to Closed
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .update({'Status': 'Closed'});

      // Get all joined players
      final joinedPlayers = await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .collection('users_joined')
          .where(FieldPath.documentId, isNotEqualTo: 'placeholder')
          .get();

      // Update status for all joined players
      for (var player in joinedPlayers.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(player.id)
            .update({
          'hasJoinedPost': false,
          'joinedPostAuthor': null,
        });
      }

      // Update author's status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .update({
        'hasActivePost': false,
        'activePostId': null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post closed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error closing post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActivePost(Map<String, dynamic> userData) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Posts')
          .doc(userData['Username'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading post');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final postData = snapshot.data?.data() as Map<String, dynamic>?;
        if (postData == null) {
          return const Text('No active post');
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Active Post',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Game Mode: ${postData['GameMode']}'),
                Text('Group Size: ${postData['GroupSize']}'),
                Text('Platform: ${postData['Platform']}'),
                Text('Mic Required: ${postData['Mic']}'),
                if (postData['MinimumRank'] != null)
                  Text('Minimum Rank: ${postData['MinimumRank']}'),
                Text('Status: ${postData['Status']}'),
                const SizedBox(height: 16),
                if (postData['Status'] == 'Open') // Only show close button for open posts
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 40),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Close Post'),
                          content: const Text(
                            'Are you sure you want to close this post? All players will be removed.'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _closePost(userData['Username']);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                      child: const Text('Close Post'),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Joined Players:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildJoinedPlayersList(userData['Username']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJoinedPlayersList(String postId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .collection('users_joined')
          .where(FieldPath.documentId, isNotEqualTo: 'placeholder')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading players');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final players = snapshot.data?.docs ?? [];
        if (players.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No players have joined yet'),
          );
        }

        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(player['username'] ?? 'Unknown'),
                  subtitle: Text(player['platform'] ?? 'Unknown'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getTimeAgo(
                          (player['joinedAt'] as Timestamp).toDate(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Kick Player'),
                            content: Text(
                              'Are you sure you want to kick ${player['username']}?'
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _kickPlayer(
                                    postId,
                                    players[index].id,
                                    player['username'] ?? 'Unknown',
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Kick'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }

  Widget _buildJoinedPost(Map<String, dynamic> userData) {
    if (userData['hasJoinedPost'] != true || userData['joinedPostAuthor'] == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Posts')
          .doc(userData['joinedPostAuthor'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading joined post');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final postData = snapshot.data?.data() as Map<String, dynamic>?;
        if (postData == null) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Joined Post',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Host: ${postData['AuthorUsername']}'),
                Text('Game Mode: ${postData['GameMode']}'),
                Text('Group Size: ${postData['GroupSize']}'),
                Text('Platform: ${postData['Platform']}'),
                Text('Mic Required: ${postData['Mic']}'),
                if (postData['MinimumRank'] != null)
                  Text('Minimum Rank: ${postData['MinimumRank']}'),
                Text('Status: ${postData['Status']}'),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 40),
                    ),
                    onPressed: () => _showLeavePostDialog(userData['joinedPostAuthor']),
                    child: const Text('Leave Post'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLeavePostDialog(String postId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Post'),
        content: const Text('Are you sure you want to leave this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _leavePost(postId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

 Future<void> _leavePost(String postId) async {
  try {
    // First check if post is marked as Full
    final postDoc = await FirebaseFirestore.instance
        .collection('Posts')
        .doc(postId)
        .get();

    if (postDoc.exists) {
      final postData = postDoc.data() as Map<String, dynamic>;
      if (postData['Status'] == 'Full') {
        // Update post status to Open since a player is leaving
        await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postId)
            .update({'Status': 'Open'});
      }
    }

    // Remove user from users_joined collection
    await FirebaseFirestore.instance
        .collection('Posts')
        .doc(postId)
        .collection('users_joined')
        .doc(widget.userID)
        .delete();

    // Update user's status
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userID)
        .update({
      'hasJoinedPost': false,
      'joinedPostAuthor': null,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully left the post'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error leaving post: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[700]!,
              Colors.blue[400]!,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(widget.userID).get(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading profile'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userData = snapshot.data?.data() as Map<String, dynamic>?;

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Username',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userData?['Username'] ?? 'No username',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: _showChangeUsernameDialog,
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Change Username'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue[900],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Platform',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userData?['platform'] ?? 'No platform',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userData?['email'] ?? 'No email',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 30),
                                Center(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(120, 40),
                                    ),
                                    onPressed: () async {
                                      try {
                                        await FirebaseAuth.instance.signOut();
                                        if (context.mounted) {
                                          Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (context) => const FirstPage(),
                                            ),
                                            (route) => false,
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error signing out: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Log Out',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (userData != null) _buildJoinedPost(userData),
                        const SizedBox(height: 20),
                        if (userData != null) _buildActivePost(userData),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
