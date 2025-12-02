import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:testing/widgets/auth_gate.dart';
import '../controllers/navigation_manager.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/firebase_service.dart';
import 'package:testing/services/auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int currentIndex = 3;
  final NavigationManager nav = NavigationManager();
  final FirebaseService _firebaseService = FirebaseService();
  final Auth _auth = Auth();
  
  // ignore: unused_field
  Map<String, dynamic>? _userProfile;
  Map<String, int> _statistics = {'recentSearches': 0, 'savedRoutes': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      await _auth.syncEmailIfChanged();
      
      final profile = await _firebaseService.getUserProfile();
      final stats = await _firebaseService.getUserStatistics();
      
      setState(() {
        _userProfile = profile;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }
  
  String _formatMemberSince() {
    if (_auth.currentUser?.metadata.creationTime == null) return 'Unknown';
    return DateFormat('MMM yyyy').format(_auth.currentUser!.metadata.creationTime!);
  }
  
  String _formatLastLogin() {
    if (_auth.currentUser?.metadata.lastSignInTime == null) return 'Unknown';
    
    final lastLogin = _auth.currentUser!.metadata.lastSignInTime!;
    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    
    if (difference.inMinutes < 60) {
      return 'Today, ${DateFormat('h:mm a').format(lastLogin)}';
    } else if (difference.inHours < 24 && now.day == lastLogin.day) {
      return 'Today, ${DateFormat('h:mm a').format(lastLogin)}';
    } else if (difference.inDays < 2) {
      return 'Yesterday, ${DateFormat('h:mm a').format(lastLogin)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(lastLogin);
    }
  }
  
  String _getInitials() {
    if (_auth.currentUser?.email == null) return '?';
    return _auth.currentUser!.email!.substring(0, 1).toUpperCase();
  }

  String _getDisplayName() {
    return _auth.currentUser?.email ?? 'No email';
  }

Future<void> _showEditEmailDialog() async {
    final emailController = TextEditingController(
      text: _auth.currentUser?.email ?? '',
    );
    final passwordController = TextEditingController();

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xfffef1d8),
        title: const Text('Change Email', style: TextStyle(fontWeight: FontWeight.bold),),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your new email address and current password to confirm.',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'New Email',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF6e2d1b),
                      width: 1,
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF6e2d1b),
                      width: 2,
                    ),
                  ),

                  prefixIcon: Icon(Icons.email),
                  labelStyle: TextStyle(color: Color(0xff6e2d1b))
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF6e2d1b),
                      width: 1,
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF6e2d1b),
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(Icons.lock),
                  labelStyle: TextStyle(color: Color(0xff6e2d1b))
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.black),),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                // Show local validation error if fields are empty
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }
              Navigator.pop(context, {
                'email': emailController.text,
                'password': passwordController.text,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xffdea855)
            ),
            child: const Text('Update Email', style: TextStyle(color: Color(0xff6e2d1b))),
          ),
        ],
      ),
    );

    if (result != null) {
      final String? currentEmail = _auth.currentUser?.email;
      if (currentEmail == null) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User email not found. Please log in again.')),
          );
        }
        return;
      }
      
      try {
        // Use the centralized service method: changeEmailLink
        await _auth.changeEmailLink(
          currentEmail: currentEmail, // Current user's email
          newEmail: result['email']!, // The new email from the dialog
          password: result['password']!, // The current password for re-authentication
        );
        
        // Success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification email sent to ${result['email']!}. Please verify to complete the change.'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        
        // Optional: Reload user data in the profile page
        // The email in Firebase Auth only changes AFTER the user clicks the link, 
        // but reloading might update other profile data.
        await _loadUserData(); 
        
      } catch (e) {
        if (mounted) {
          // Firebase error handling using the rethrow from your Auth class
          String errorMessage = 'Error updating email. Please check your password.';
          
          if (e.toString().contains('wrong-password')) {
            errorMessage = 'Incorrect password provided.';
          } else if (e.toString().contains('invalid-email')) {
            errorMessage = 'Invalid email address provided for the new email.';
          } else if (e.toString().contains('email-already-in-use')) {
            errorMessage = 'The new email is already associated with another account.';
          } else if (e.toString().contains('requires-recent-login')) {
            errorMessage = 'Re-login required. Please sign out and sign in again.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    }
  }

  // Future<void> _showChangePasswordDialog() async {
  //   final emailController = TextEditingController(
  //     text: _auth.currentUser?.email ?? '',
  //   );

  //   final result = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold),),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             'We will send a password reset link to your email address.',
  //             style: TextStyle(fontSize: 14),
  //           ),
  //           const SizedBox(height: 16),
  //           TextField(
  //             controller: emailController,
  //             decoration: const InputDecoration(
  //               labelText: 'Email',
  //               border: OutlineInputBorder(),
  //             ),
  //             readOnly: true,
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('Cancel', style: TextStyle(color: Colors.black),),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text('Send Link', style: TextStyle(color: Colors.black)),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (result == true) {
  //     try {
  //       await _auth.sendPasswordEmailLink(
  //         email: _auth.currentUser?.email ?? '',
  //       );
        
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Password reset link sent to your email'),
  //             duration: Duration(seconds: 3),
  //           ),
  //         );
  //       }
  //     } catch (e) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Error sending reset link: $e')),
  //         );
  //       }
  //     }
  //   }
  // }

  Future<void> _resendVerificationEmail() async {
    try {
      await _auth.sendEmailVerification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Please check your inbox.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending verification email: $e')),
        );
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    try {
      await _auth.reloadUser();
      setState(() {});
      
      if (_auth.isEmailVerified && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not yet verified. Please check your inbox.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking verification: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfffef1d8),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Color(0xfffef1d8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Color(0xfffef1d8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xff6e2d1b),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xfffef1d8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Text(
                            _getDisplayName(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          InkWell(
                            onTap: !_auth.isEmailVerified ? _resendVerificationEmail : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: _auth.isEmailVerified ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _auth.isEmailVerified ? 'Verified Account' : 'Unverified Account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _auth.isEmailVerified ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (!_auth.isEmailVerified) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          if (!_auth.isEmailVerified) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _resendVerificationEmail,
                                  icon: const Icon(Icons.email, size: 16),
                                  label: const Text('Resend'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _checkVerificationStatus,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Check Status'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 8),
                          
                          // joined 
                          Text(
                            'Member since: ${_formatMemberSince()}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // account info section
                    _buildSection(
                      title: 'Account Information',
                      child: Column(
                        children: [
                          _buildInfoRow('Email', _auth.currentUser?.email ?? 'No email'),
                          _buildDivider(),
                          _buildInfoRow('Last login', _formatLastLogin()),
                          _buildDivider(),
                          _buildInfoRow(
                            'Status',
                            _auth.isEmailVerified ? 'Verified' : 'Unverified',
                            statusColor: _auth.isEmailVerified ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // activity section
                    _buildSection(
                      title: 'Activity',
                      child: Column(
                        children: [
                          _buildActivityTile(
                            icon: Icons.location_on,
                            title: 'Recent Searches',
                            count: _statistics['recentSearches'] ?? 0,
                            onTap: () {
                              // navigate to activity page
                              Navigator.pushReplacementNamed(context, "/activitypage");
                            },
                          ),
                          _buildDivider(),
                          _buildActivityTile(
                            icon: Icons.bookmark,
                            title: 'Saved Routes',
                            count: _statistics['savedRoutes'] ?? 0,
                            onTap: () {
                              // navigate to saved routes page
                              Navigator.pushReplacementNamed(context, "/savedroutespage");
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // settings Section
                    _buildSection(
                      title: 'Settings',
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.email,
                            title: 'Change Email',
                            onTap: _showEditEmailDialog,
                          ),
                          // _buildDivider(),
                          // _buildSettingsTile(
                          //   icon: Icons.lock,
                          //   title: 'Change Password',
                          //   onTap: _showChangePasswordDialog,
                          // ),
                          _buildDivider(),
                          _buildSettingsTile(
                            icon: Icons.logout,
                            title: 'Logout',
                            titleColor: Colors.red,
                            iconColor: Colors.red,
                            onTap: () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Color(0xfffef1d8),
                                  title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold),),
                                  content: const Text('Are you sure you want to byebye?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.black),),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Logout'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (result == true) {
                                await _auth.signOut();
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (context) => const AuthGate()),
                                    (route) => false,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: JeepJamBottomNavbar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
          nav.navigate(context, index); 
        },
      ),
    );
  }
  
  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xffdea855),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xff6e2d1b),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: statusColor ?? Colors.black87,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityTile({
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Color(0xff6e2d1b)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xfffef1d8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xff6e2d1b)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor ?? Color(0xff6e2d1b)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? Colors.black87,
                ),
              ),
            ),
            if (titleColor == null)
              const Icon(Icons.chevron_right, color: Color(0xff6e2d1b)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[200],
      indent: 16,
      endIndent: 16,
    );
  }
}