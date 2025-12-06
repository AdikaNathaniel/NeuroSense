import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin-notification.dart';
import 'login_page.dart'; 
import 'support-settings.dart';
import 'users_summary.dart';

import 'set_profile.dart';
import 'map.dart';

class AdminHomePage extends StatefulWidget {
  final String userEmail;
  
  const AdminHomePage({super.key, required this.userEmail});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String _selectedPage = 'Users';

  Future<void> _logout(BuildContext context) async {
    try {
      final response = await http.put(
        Uri.parse('https://neurosense-palsy.fly.dev/api/v1/users/logout'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false
          );
        } else {
          _showSnackbar(
            context, 
            "Logout failed: ${responseData['message']}", 
            Colors.red
          );
        }
      } else {
        _showSnackbar(
          context, 
          "Logout failed: Server error", 
          Colors.red
        );
      }
    } catch (e) {
      _showSnackbar(
        context, 
        "Logout failed: ${e.toString()}", 
        Colors.red
      );
    }
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showUserInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  const Text(
                    'Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Email row
                  _buildProfileItem(
                    icon: Icons.email_outlined,
                    text: widget.userEmail,
                    onTap: null,
                  ),
                  
                  // Settings row
                  _buildProfileItem(
                    icon: Icons.settings_outlined,
                    text: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetProfilePage(userEmail: widget.userEmail),
                        ),
                      );
                    },
                  ),
                  
                  // Map row
                  _buildProfileItem(
                    icon: Icons.location_on,
                    text: 'View Location Of PregMama',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapPage(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Logout button
                  TextButton(
                    onPressed: () async {
                      await _logout(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Close button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null) 
                const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedPage == 'Users' 
          ? AppBar(
              title: const Text('All Users'),
              centerTitle: true,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: CircleAvatar(
                    radius: 16,
                    child: Text(
                      widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'A',
                      style: const TextStyle(color: Colors.green, fontSize: 16),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _showUserInfoDialog(context);
                  },
                ),
              ],
            )
          : AppBar(
              title: Text(_selectedPage),
              centerTitle: true,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedPage = 'Users';
                  });
                },
              ),
              actions: [
                IconButton(
                  icon: CircleAvatar(
                    radius: 16,
                    child: Text(
                      widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'A',
                      style: const TextStyle(color: Colors.green, fontSize: 16),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _showUserInfoDialog(context);
                  },
                ),
              ],
            ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.green,
                ),
                child: Center(
                  child: Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.supervised_user_circle, color: Colors.green),
                title: const Text('All Users'),
                selected: _selectedPage == 'Users',
                onTap: () {
                  setState(() {
                    _selectedPage = 'Users';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.green),
                title: const Text('Notifications'),
                selected: _selectedPage == 'Notifications',
                onTap: () {
                  setState(() {
                    _selectedPage = 'Notifications';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.support_agent, color: Colors.green),
                title: const Text('Support'),
                selected: _selectedPage == 'Support',
                onTap: () {
                  setState(() {
                    _selectedPage = 'Support';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: _buildContent(_selectedPage),
    );
  }

  Widget _buildContent(String page) {
    switch (page) {
      case 'Users':
        return UserListPage(userEmail: widget.userEmail);
      case 'Notifications':
        return NotificationSettingsPage(userEmail: widget.userEmail);
      case 'Support':
        return SupportSettingsPage(userEmail: widget.userEmail);
      default:
        return UserListPage(userEmail: widget.userEmail);
    }
  }
}

// UserListPage with updated UI
class UserListPage extends StatefulWidget {
  final String userEmail;

  const UserListPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  bool isLoading = true;
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      print('DEBUG: Fetching users from API...');
      final response = await http.get(
        Uri.parse('https://neurosense-palsy.fly.dev/api/v1/users'),
        headers: {'Content-Type': 'application/json'},
      );

      print('DEBUG: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['result'];
          print('DEBUG: Total users from API: ${data.length}');
          
          // Filter and parse only complete users
          List<User> completeUsers = [];
          
          for (var userData in data) {
            try {
              // Check if user has all required fields
              if (userData['name'] != null && 
                  userData['email'] != null && 
                  userData['type'] != null &&
                  userData['name'].toString().isNotEmpty &&
                  userData['email'].toString().isNotEmpty &&
                  userData['type'].toString().isNotEmpty) {
                
                final user = User.fromJson(userData);
                completeUsers.add(user);
              } else {
                print('DEBUG: Skipping incomplete user: ${userData['id']}');
              }
            } catch (e) {
              print('DEBUG: Error parsing user: $e');
            }
          }
          
          print('DEBUG: Complete users found: ${completeUsers.length}');
          
          setState(() {
            users = completeUsers;
            isLoading = false;
          });
        } else {
          print('DEBUG: API returned success: false');
          setState(() {
            isLoading = false;
          });
          _showSnackbar(
            context, 
            "Failed to load users: ${responseData['message']}", 
            Colors.red
          );
        }
      } else {
        print('DEBUG: HTTP error: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
        _showSnackbar(
          context, 
          "Server error: ${response.statusCode}", 
          Colors.red
        );
      }
    } catch (e) {
      print('DEBUG: Exception caught: $e');
      setState(() {
        isLoading = false;
      });
      _showSnackbar(
        context, 
        "Network error: ${e.toString()}", 
        Colors.red
      );
    }
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No complete user profiles found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Only users with name, email, and type are displayed',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refreshData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header with count
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[50],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Users: ${users.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Users list
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          return UserCard(user: users[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String type;
  final String? card;
  final bool isVerified;
  final bool isActive;
  final int failedLoginAttempts;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    this.card,
    required this.isVerified,
    required this.isActive,
    required this.failedLoginAttempts,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      card: json['card']?.toString(),
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? false,
      failedLoginAttempts: json['failedLoginAttempts'] ?? 0,
    );
  }
}

class UserCard extends StatelessWidget {
  final User user;

  const UserCard({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine icon, text and color based on user type
    IconData userTypeIcon;
    String userTypeText;
    Color userTypeColor;

    // Handle different user types with case-insensitive matching
    final typeLower = user.type.toLowerCase();
    
    if (typeLower.contains('admin')) {
      userTypeIcon = Icons.admin_panel_settings;
      userTypeText = 'Admin';
      userTypeColor = Colors.red;
    } else if (typeLower.contains('doctor') || typeLower.contains('physician')) {
      userTypeIcon = Icons.medical_services;
      userTypeText = 'Medic';
      userTypeColor = Colors.green;
    } else if (typeLower.contains('relative')) {
      userTypeIcon = Icons.family_restroom;
      userTypeText = 'Relative';
      userTypeColor = Colors.green;
    } else if (typeLower.contains('pregnant') || typeLower.contains('mother')) {
      userTypeIcon = Icons.pregnant_woman;
      userTypeText = 'Mother';
      userTypeColor = Colors.green;
    } else if (typeLower.contains('caregiver')) {
      userTypeIcon = Icons.health_and_safety;
      userTypeText = 'Caregiver';
      userTypeColor = Colors.green;
    } else {
      userTypeIcon = Icons.account_circle;
      userTypeText = user.type;
      userTypeColor = Colors.grey;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar/Icon with status indicator
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: userTypeColor.withOpacity(0.15),
                  ),
                  child: Icon(
                    userTypeIcon,
                    color: userTypeColor,
                    size: 32,
                  ),
                ),
                // Active/Inactive indicator
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: user.isActive ? Colors.green : Colors.grey,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // User Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Verification badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.isVerified ? Colors.green.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: user.isVerified ? Colors.green : Colors.green,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user.isVerified ? Icons.verified : Icons.pending,
                              size: 12,
                              color: user.isVerified ? Colors.green : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.isVerified ? 'Verified' : 'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: user.isVerified ? Colors.green : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Email
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Type and card row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: userTypeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          userTypeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: userTypeColor,
                          ),
                        ),
                      ),
                      
                      if (user.card != null && user.card!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Card: ${user.card}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                      
                      const Spacer(),
                      
                      // Failed login attempts indicator (if any)
                      if (user.failedLoginAttempts > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                size: 12,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${user.failedLoginAttempts} fails',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  // ID (small and discreet)
                  // const SizedBox(height: 6),
                  // Text(
                  //   'ID: ${user.id.substring(0, 8)}...',
                  //   style: TextStyle(
                  //     fontSize: 10,
                  //     color: Colors.grey[500],
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}