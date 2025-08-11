import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // Extract user data from Firebase Auth
    final String userName = currentUser?.displayName ?? 'User';
    final String phoneNumber =
        currentUser?.phoneNumber ?? (currentUser?.email ?? 'No phone number');

    return Scaffold(
      backgroundColor: const Color(0xFFEFF4F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF4F9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Menu',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User profile card
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                  ),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 10),

                      // User avatar
                      currentUser?.photoURL != null
                          ? CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(
                                currentUser!.photoURL!,
                              ),
                            )
                          : CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                color: Colors.grey[800],
                                size: 36,
                              ),
                            ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              phoneNumber,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16),
                      SizedBox(width: 4),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 1,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    width: double.infinity,
                    child: Divider(
                      color: const Color.fromARGB(255, 247, 247, 247),
                    ),
                  ),
                ),
                // Rating card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12.0),
                      bottomRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Row(
                    // mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 10),
                      Icon(Icons.star, color: Colors.amber, size: 24),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '5.00 My Rating',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16),
                      SizedBox(width: 4),
                    ],
                  ),
                ),
              ],
            ),

            //menu items
            SizedBox(height: 24),

            // Menu items
            _buildMenuItem(Icons.help_outline, 'Help'),
            _buildDivider(),
            _buildMenuItem(Icons.payment, 'Payment'),
            _buildDivider(),
            _buildMenuItem(Icons.access_time, 'My Rides'),
            _buildDivider(),
            _buildMenuItem(Icons.shield_outlined, 'Safety'),
            _buildDivider(),

            // Refer and earn with subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.card_giftcard, color: Colors.grey[700]),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Refer and Earn',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Get ₹50',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),

            _buildDivider(),
            _buildMenuItem(Icons.emoji_events_outlined, 'My Rewards'),
            _buildDivider(),
            _buildMenuItem(Icons.card_membership_outlined, 'Power Pass'),
            _buildDivider(),
            _buildMenuItem(Icons.monetization_on_outlined, 'Rapido Coins'),
            _buildDivider(),
            _buildMenuItem(Icons.notifications_outlined, 'Notifications'),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: Colors.grey[700]),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16.0),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey[200],
    );
  }
}
