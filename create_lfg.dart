import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateLFGPage extends StatefulWidget {
  const CreateLFGPage({super.key});

  @override
  State<CreateLFGPage> createState() => _CreateLFGPageState();
}

class _CreateLFGPageState extends State<CreateLFGPage> {
  bool isCasualSelected = false;
  bool isCompetitiveSelected = false;
  int? selectedGroupSize;
  String? selectedRank;
  bool isMicRequired = false;
  bool isPCSelected = false;
  bool isConsoleSelected = false;

  final List<String> ranks = [
    'Bronze',
    'Silver',
    'Gold',
    'Platinum',
    'Diamond',
    'Grandmaster+'
  ];

  Future<void> _createPost() async {
    // Validate required fields
    if (!isCasualSelected && !isCompetitiveSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a game mode')),
      );
      return;
    }

    if (selectedGroupSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a group size')),
      );
      return;
    }

    if (isCompetitiveSelected && selectedRank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rank for competitive mode')),
      );
      return;
    }

    if (!isPCSelected && !isConsoleSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a platform')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user's profile data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userData = userDoc.data();
      if (userData == null) return;

      final username = userData['Username'] ?? 'Unknown';

      // Create the post document
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(username)
          .set({
        'AuthorUsername': username,
        'AuthorUID': user.uid,
        'AuthorPlatform': userData['platform'] ?? 'Unknown',
        'GameMode': isCompetitiveSelected ? 'Ranked' : 'Casual',
        'GroupSize': selectedGroupSize,
        'Mic': isMicRequired ? 'Yes' : 'No',
        'MinimumRank': isCompetitiveSelected ? selectedRank : null,
        'Platform': isPCSelected ? 'PC' : 'Console',
        'Status': 'Open',
        'CreatedAt': FieldValue.serverTimestamp(),
      });

      // Create users_joined subcollection with placeholder document
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(username)
          .collection('users_joined')
          .doc('placeholder')
          .set({
        'created': FieldValue.serverTimestamp()
      });

      // Update user's status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'hasActivePost': true,
        'activePostId': username
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('LFG post created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create LFG Post'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Game Mode',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCasualSelected 
                          ? Colors.blue[900] 
                          : Colors.white,
                      foregroundColor: isCasualSelected 
                          ? Colors.white 
                          : Colors.blue[900],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        isCasualSelected = !isCasualSelected;
                        if (isCasualSelected) {
                          isCompetitiveSelected = false;
                          selectedRank = null;
                        }
                      });
                    },
                    child: const Text('Casual'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompetitiveSelected 
                          ? Colors.blue[900] 
                          : Colors.white,
                      foregroundColor: isCompetitiveSelected 
                          ? Colors.white 
                          : Colors.blue[900],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        isCompetitiveSelected = !isCompetitiveSelected;
                        if (isCompetitiveSelected) {
                          isCasualSelected = false;
                        }
                      });
                    },
                    child: const Text('Competitive'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Group Size',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedGroupSize == index + 1 
                          ? Colors.blue[900] 
                          : Colors.white,
                      foregroundColor: selectedGroupSize == index + 1 
                          ? Colors.white 
                          : Colors.blue[900],
                      minimumSize: const Size(50, 50),
                    ),
                    onPressed: () {
                      setState(() {
                        if (selectedGroupSize == index + 1) {
                          selectedGroupSize = null;
                        } else {
                          selectedGroupSize = index + 1;
                        }
                      });
                    },
                    child: Text('${index + 1}'),
                  );
                }),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  const Text(
                    'Competitive Rank',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (!isCompetitiveSelected)
                    const Text(
                      '(Select Competitive Mode)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ranks.map((rank) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedRank == rank && isCompetitiveSelected
                          ? Colors.blue[900]
                          : Colors.white,
                      foregroundColor: selectedRank == rank && isCompetitiveSelected
                          ? Colors.white
                          : Colors.blue[900],
                      disabledBackgroundColor: Colors.grey[400],
                      disabledForegroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onPressed: isCompetitiveSelected
                        ? () {
                            setState(() {
                              if (selectedRank == rank) {
                                selectedRank = null;
                              } else {
                                selectedRank = rank;
                              }
                            });
                          }
                        : null,
                    child: Text(rank),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  const Text(
                    'Mic Required',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Switch(
                    value: isMicRequired,
                    onChanged: (bool value) {
                      setState(() {
                        isMicRequired = value;
                      });
                    },
                    activeColor: Colors.blue[900],
                    activeTrackColor: Colors.blue[700],
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey[400],
                  ),
                  Text(
                    isMicRequired ? 'Yes' : 'No',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Platform',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPCSelected 
                          ? Colors.blue[900] 
                          : Colors.white,
                      foregroundColor: isPCSelected 
                          ? Colors.white 
                          : Colors.blue[900],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        isPCSelected = !isPCSelected;
                        if (isPCSelected) {
                          isConsoleSelected = false;
                        }
                      });
                    },
                    child: const Text('PC'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConsoleSelected 
                          ? Colors.blue[900] 
                          : Colors.white,
                      foregroundColor: isConsoleSelected 
                          ? Colors.white 
                          : Colors.blue[900],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        isConsoleSelected = !isConsoleSelected;
                        if (isConsoleSelected) {
                          isPCSelected = false;
                        }
                      });
                    },
                    child: const Text('Console'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    minimumSize: const Size(200, 60),
                  ),
                  onPressed: _createPost,
                  child: const Text(
                    'Create Post',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}