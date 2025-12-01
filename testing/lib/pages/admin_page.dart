import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/auth.dart';
import '../utils/date_formatter.dart';
import '../widgets/admin/route_dialog.dart';
import '../widgets/admin/user_details_dialog.dart';
import '../widgets/admin/overview_cards.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final Auth _auth = Auth();
  final FirebaseService _firebaseService = FirebaseService();

  final TextEditingController _routeSearchController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();

  List<Map<String, dynamic>> _allRoutes = [];
  List<Map<String, dynamic>> _filteredRoutes = [];
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  int _selectedTab = 0;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadRoutes();
    _loadUsers();
    _routeSearchController.addListener(_filterRoutes);
    _userSearchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _routeSearchController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _firebaseService.isUserAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    final routes = await _firebaseService.getAllJeepneyRoutes();
    routes.sort((a, b) => a['code'].compareTo(b['code']));
    setState(() {
      _allRoutes = routes;
      _filteredRoutes = routes;
      _isLoading = false;
    });
  }

  void _filterRoutes() {
    final query = _routeSearchController.text.toLowerCase();
    setState(() {
      _filteredRoutes = _allRoutes.where((route) {
        return route['code'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showAddRouteDialog() {
    showDialog(
      context: context,
      builder: (context) => RouteDialog(
        onSave: (code, stops) async {
          try {
            await _firebaseService.addJeepneyRoute(
              routeCode: code,
              stops: stops,
            );
            _loadRoutes();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Route $code added successfully'), backgroundColor: Colors.green,),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditRouteDialog(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder: (context) => RouteDialog(
        routeCode: route['code'],
        existingStops: List<Map<String, dynamic>>.from(route['route']),
        onSave: (code, stops) async {
          try {
            await _firebaseService.updateJeepneyRoute(
              routeCode: code,
              stops: stops,
            );
            _loadRoutes();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Route $code updated successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteDialog(String routeCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $routeCode?', style: TextStyle(fontWeight: FontWeight.bold),),
        content: Text(
          'All the fields within this jeepney route will be deleted. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black),),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firebaseService.deleteJeepneyRoute(routeCode);
                _loadRoutes();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Route $routeCode deleted'), backgroundColor: Colors.green,),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadUsers() async {
    final users = await _firebaseService.getAllUsers();
    if (!mounted) return;
    setState(() {
      _allUsers = users;
      _filteredUsers = users;
      _isLoading = false; 
    });
  }

  void _filterUsers() {
    final query = _userSearchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final email = (user['email'] ?? '').toLowerCase();
        return email.contains(query);
      }).toList();
    });
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => UserDetailsDialog(
        user: user,
        onDelete: () async {
          await _firebaseService.deleteUserByAdmin(user['id']);
          _loadUsers();
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User ${user['email']} deleted'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        onToggleAdmin: () async {
          final isAdmin = user['isAdmin'] == true;
          await _firebaseService.toggleUserAdminStatus(user['id'], !isAdmin);
          _loadUsers();
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isAdmin 
                    ? 'Admin rights removed from ${user['email']}'
                    : 'Admin rights granted to ${user['email']}'
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'You do not have admin access',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.w500),),
        elevation: 0,
        actions: [
          IconButton(onPressed:() {
            _auth.signOut();
          }, icon: Icon(Icons.login_rounded)),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildOverviewTab(),
                _buildJeepneyRoutesTab(),
                _buildUsersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.black,
      child: Row(
        children: [
          _buildTab('Overview', 0, Icons.dashboard),
          _buildTab('Jeepney Routes', 1, Icons.directions_bus),
          _buildTab('Users', 2, Icons.people),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final totalRoutes = _allRoutes.length;
    final totalUsers = _allUsers.length;
    final verifiedUsers = _allUsers.where((user) => user['isVerified'] == true).length;
    final unverifiedUsers = totalUsers - verifiedUsers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.2,
                children: [
                  StatCard(title: 'Total Routes', value: totalRoutes.toString(), icon: Icons.alt_route, color: Colors.blue),
                  StatCard(title: 'Total Users', value: totalUsers.toString(), icon: Icons.people, color: Colors.teal),
                  StatCard(title: 'Verified Users', value: verifiedUsers.toString(), icon: Icons.check_circle, color: Colors.green),
                  StatCard(title: 'Unverified Users', value: unverifiedUsers.toString(), icon: Icons.warning, color: Colors.orange),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          if (totalUsers > 0)
            UserDistributionCard(verified: verifiedUsers, unverified: unverifiedUsers, total: totalUsers),
          const SizedBox(height: 25,),
        ],
      ),
    );
  }

  Widget _buildJeepneyRoutesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _routeSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search route code...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showAddRouteDialog,
                icon: const Icon(Icons.add, color: Colors.blue,),
                label: const Text('Add Route', style: TextStyle(color: Colors.blue),),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredRoutes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _routeSearchController.text.isEmpty
                                ? 'No routes found'
                                : 'No routes match your search',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredRoutes.length,
                      itemBuilder: (context, index) {
                        final route = _filteredRoutes[index];
                        final stops =
                            List<Map<String, dynamic>>.from(route['route']);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).primaryColor.withOpacity(0.1),
                              foregroundColor: Colors.black,
                              child: const Icon(Icons.directions_bus),
                            ),
                            title: Text(
                              route['code'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text('${stops.length} stops'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  child: IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _showEditRouteDialog(route),
                                  ),
                                ),
                                InkWell(
                                  child: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _showDeleteDialog(route['code']),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: stops.length,
                                itemBuilder: (context, stopIndex) {
                                  final stop = stops[stopIndex];
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 12,
                                      child: Text(
                                        '${stopIndex + 1}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                    title: Text(stop['name'] ?? 'Unknown'),
                                    subtitle: Text(
                                      'Lat: ${stop['lat']?.toStringAsFixed(6) ?? 'N/A'}, '
                                      'Lng: ${stop['lng']?.toStringAsFixed(6) ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              hintText: 'Search by email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _userSearchController.text.isEmpty
                                ? 'No users found'
                                : 'No users match your search',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final isVerified = user['isVerified'] == true;
                        final isAdmin = user['isAdmin'] == true;
                        final email = user['email'] ?? 'No email';
                        final joinDate = DateFormatter.formatDate(user['createdAt']);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isAdmin 
                                  ? Colors.purple.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              child: Icon(
                                isAdmin ? Icons.admin_panel_settings : Icons.person,
                                color: isAdmin ? Colors.purple : Colors.blue,
                              ),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    email,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'ADMIN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isVerified 
                                          ? Icons.verified 
                                          : Icons.cancel,
                                      size: 16,
                                      color: isVerified 
                                          ? Colors.green 
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isVerified 
                                          ? 'Verified' 
                                          : 'Not Verified',
                                      style: TextStyle(
                                        color: isVerified 
                                            ? Colors.green 
                                            : Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Joined: $joinDate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showUserDetails(user),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    ); 
  }

}
