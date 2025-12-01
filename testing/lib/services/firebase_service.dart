import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../services/jeepney_route_service.dart';

class UserAppModel {
  final String email;
  final String uid;
  final bool isVerified;
  final bool isAdmin;
  final String timestampJoined;

  UserAppModel({
    required this.email,
    required this.uid,
    required this.isVerified,
    required this.isAdmin,
    required this.timestampJoined,
  });

  factory UserAppModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final email = doc.id; 
    final uid = data?['uid'] ?? 'N/A'; 
    final isVerified = data?['isVerified'] ?? false;
    final isAdmin = data?['isAdmin'] ?? false;
    
    String timestamp = 'Unknown';
    final timestampValue = data?['createdAt'] ?? data?['timestamp_joined'];

    if (timestampValue is String) {
      try {
        final ms = int.tryParse(timestampValue);
        if (ms != null) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(ms).toString();
        } else {
          timestamp = timestampValue; 
        }
      } catch (_) {
        timestamp = timestampValue;
      }
    } else if (timestampValue is Timestamp) {
      timestamp = timestampValue.toDate().toString();
    } else if (timestampValue is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue).toString();
    }
    
    return UserAppModel(
      email: email, 
      uid: uid,
      isVerified: isVerified,
      isAdmin: isAdmin,
      timestampJoined: timestamp, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': email,
      'uid': uid,
      'email': email,
      'isVerified': isVerified, 
      'isAdmin': isAdmin,
      'createdAt': timestampJoined, 
    };
  }
}

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final logger = Logger();

  String? get currentUserId => _auth.currentUser?.email;
  User? get currentUser => _auth.currentUser;

  // saves origin and dest
  Future<void> saveRecentSearch({
    required String origin,
    required String destination,
    required Map<String, dynamic> originDetails,
    required Map<String, dynamic> destinationDetails,
    required List<JeepneyRouteMatch> codes,
  }) async {
    try {
      if (currentUserId == null) return;

      final cleanOrigin = origin.replaceAll(RegExp(r'[/#]'), '_');
      final cleanDestination = destination.replaceAll(RegExp(r'[/#]'), '_');
      final docId = '$cleanOrigin - $cleanDestination';

      final userRecentRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('recent_searches');

      await userRecentRef.doc(docId).set({
        'origin': origin,
        'destination': destination,
        'originDetails': originDetails,
        'destinationDetails': destinationDetails,
        'codes': codes.map((c) => c.code).toList(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      await addToSearchCache(
        codes: codes,
        origin: origin,
        dest: destination,
        originLat: originDetails['latitude'].toDouble(),
        originLng: originDetails['longitude'].toDouble(),
        destLat: destinationDetails['latitude'].toDouble(),
        destLng: destinationDetails['longitude'].toDouble(),
      );

      logger.i('Recent search saved');
    } catch (e) {
      logger.e('Error saving recent search: $e');
    }
  }

  // gets recent 20 searches ordered by timestamp
  Future<List<Map<String, dynamic>>> getRecentSearches() async {
    try {
      if (currentUserId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('recent_searches')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'origin': data['origin'],
          'destination': data['destination'],
          'originDetails': data['originDetails'],
          'destinationDetails': data['destinationDetails'],
          'timestamp': data['timestamp'],
        };
      }).toList();
    } catch (e) {
      logger.e('Error getting recent searches: $e');
      return [];
    }
  }

  // deletes a search
  Future<void> deleteRecentSearch(String searchId) async {
    try {
      if (currentUserId == null) return;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('recent_searches')
          .doc(searchId)
          .delete();

      logger.i('Recent search deleted');
    } catch (e) {
      logger.e('Error deleting recent search: $e');
    }
  }

  // clears history
  Future<void> clearAllRecentSearches() async {
    try {
      if (currentUserId == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('recent_searches')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      logger.i('All recent searches cleared');
    } catch (e) {
      logger.e('Error clearing recent searches: $e');
    }
  }

  // all user's searches are added to search_cache and auto-increments count
  Future<void> addToSearchCache({
    required List<JeepneyRouteMatch> codes,
    required String origin,
    required String dest,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final List<String> codeList = codes.map((c) => c.code).toList();

      final cleanOrigin = origin.replaceAll(RegExp(r'[/#]'), '_');
      final cleanDest = dest.replaceAll(RegExp(r'[/#]'), '_');
      final docId = '$cleanOrigin - $cleanDest';
      final docRef = _firestore.collection('search_cache').doc(docId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.update({
          'searchCount': FieldValue.increment(1),
          'codes': codeList, 
          'originLat': originLat,
          'originLng': originLng,
          'destLat': destLat,
          'destLng': destLng,
        });
      } else {
        await docRef.set({
          'origin': origin,
          'dest': dest,
          'codes': codeList,
          'searchCount': 1,
          'originLat': originLat,
          'originLng': originLng,
          'destLat': destLat,
          'destLng': destLng,
        });
      }

    } catch (e) {
      logger.e('Error adding to search cache: $e');
    }
  }

  // gets top most searched dest
  Future<List<Map<String, dynamic>>> getSuggestedPlaces() async {
    try {
      final snapshot = await _firestore
          .collection('search_cache')
          .orderBy('searchCount', descending: true)
          .get();
      
      Map<String, Map<String, dynamic>> destinationMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final searchCount = data['searchCount'] ?? 0;
        
        if (searchCount >= 2) {
          String destination = data['dest'] ?? '';
          
          if (destination.isNotEmpty) {
            String normalizedDest = destination.trim();
            String lowerDest = normalizedDest.toLowerCase();

            if (destinationMap.containsKey(lowerDest)) {
              destinationMap[lowerDest]!['count'] += searchCount;
            } else {
              destinationMap[lowerDest] = {
                'id': doc.id,
                'location': normalizedDest, 
                'count': searchCount,
                'isLandmark': false,
              };
            }

            // popularSearches.add({
            //   'id': doc.id,
            //   'location': destination,
            //   'count': searchCount,
            //   'isLandmark': false,
            // });
          }
        }
      }

      List<Map<String, dynamic>> popularSearches = destinationMap.values.toList();
      popularSearches.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      List<Map<String, dynamic>> defaultLandmarks = _getDefaultLandmarks();

      Set<String> popularDestinations = popularSearches
          .map((place) => place['location'].toString().toLowerCase())
          .toSet();
      
      List<Map<String, dynamic>> filteredLandmarks = defaultLandmarks
          .where((landmark) => !popularDestinations.contains(landmark['location'].toString().toLowerCase()))
          .toList();

      List<Map<String, dynamic>> result = [];
      
      if (popularSearches.isNotEmpty) {
        result.addAll(popularSearches);
        
        result.add({
          'id': 'divider',
          'location': 'Popular Places',
          'isDivider': true,
        });
      }
      
      result.addAll(filteredLandmarks);

      if (result.isEmpty) {
        return defaultLandmarks;
      }

      return result;
    } catch (e) {
      logger.e('Error getting suggested places: $e');
      return _getDefaultLandmarks();
    }
  }

  // default landmarks if walay suggested places
  List<Map<String, dynamic>> _getDefaultLandmarks() {
    return [
      {
        'id': 'ayala_center',
        'location': 'Ayala Center Cebu',
        'count': 0,
        'isLandmark': true,
      },
      {
        'id': 'it_park',
        'location': 'IT Park',
        'count': 0,
        'isLandmark': true,
      },
      {
        'id': 'sm_city',
        'location': 'SM City Cebu',
        'count': 0,
        'isLandmark': true,
      },
      {
        'id': 'fuente',
        'location': 'Fuente Osmena Circle',
        'count': 0,
        'isLandmark': true,
      },
    ];
  }

  // saving a route
  Future<void> saveRoute({
    required String routeName,
    required String origin,
    required String destination,
    required Map<String, dynamic> originDetails,
    required Map<String, dynamic> destinationDetails,
    String? jeepneyCode,
  }) async {
    try {
      if (currentUserId == null) return;

      final cleanRouteName = routeName
        .replaceAll(RegExp(r'[/\\]'), '_')  
        .replaceAll(RegExp(r'[^\w\s-]'), '') 
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('saved_routes')
          .doc(cleanRouteName)
          .set({
        'routeName': routeName,
        'origin': origin,
        'destination': destination,
        'originDetails': originDetails,
        'destinationDetails': destinationDetails,
        'jeepneyCode': jeepneyCode,
        'timestamp': FieldValue.serverTimestamp(),
      });

      //logger.i('Route saved: $routeName');
    } catch (e) {
      logger.e('Error saving route: $e');
    }
  }

  // getting saved routes
  Future<List<Map<String, dynamic>>> getSavedRoutes() async {
    try {
      if (currentUserId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('saved_routes')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'routeName': data['routeName'],
          'origin': data['origin'],
          'destination': data['destination'],
          'originDetails': data['originDetails'],
          'destinationDetails': data['destinationDetails'],
          'jeepneyCode': data['jeepneyCode'],
          'timestamp': data['timestamp'],
        };
      }).toList();
    } catch (e) {
      logger.e('Error getting saved routes: $e');
      return [];
    }
  }

  // deleting saved routes
  Future<void> deleteSavedRoute(String routeId) async {
    try {
      if (currentUserId == null) return;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('saved_routes')
          .doc(routeId)
          .delete();

      //logger.i('Saved route deleted');
    } catch (e) {
      logger.e('Error deleting saved route: $e');
    }
  }

  // updating saved routes
  Future<void> updateSavedRoute({
    required String routeId,
    String? routeName,
    String? jeepneyCode,
  }) async {
    try {
      if (currentUserId == null) return;

      Map<String, dynamic> updates = {};
      if (routeName != null) updates['routeName'] = routeName;
      if (jeepneyCode != null) updates['jeepneyCode'] = jeepneyCode;

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('saved_routes')
            .doc(routeId)
            .update(updates);

        logger.i('Saved route updated');
      }
    } catch (e) {
      logger.e('Error updating saved route: $e');
    }
  }

  // get a specific saved route's detail, depending on the route id 
  Future<Map<String, dynamic>?> getSavedRoute(String routeId) async {
    try {
      if (currentUserId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('saved_routes')
          .doc(routeId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'id': doc.id,
        'routeName': data['routeName'],
        'origin': data['origin'],
        'destination': data['destination'],
        'originDetails': data['originDetails'],
        'destinationDetails': data['destinationDetails'],
        'jeepneyCode': data['jeepneyCode'],
        'timestamp': data['timestamp'],
      };
    } catch (e) {
      logger.e('Error getting saved route: $e');
      return null;
    }
  }

  // real time stream of updates
  Stream<List<Map<String, dynamic>>> watchRecentSearches() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('recent_searches')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'origin': data['origin'],
          'destination': data['destination'],
          'originDetails': data['originDetails'],
          'destinationDetails': data['destinationDetails'],
          'timestamp': data['timestamp'],
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> watchSavedRoutes() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('saved_routes')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'routeName': data['routeName'],
          'origin': data['origin'],
          'destination': data['destination'],
          'originDetails': data['originDetails'],
          'destinationDetails': data['destinationDetails'],
          'jeepneyCode': data['jeepneyCode'],
          'timestamp': data['timestamp'],
        };
      }).toList();
    });
  }

  Future<void> saveUserProfile({
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (currentUserId == null) return;

      final profileData = {
        'email': currentUser?.email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'photoUrl': photoUrl,
        'emailVerified': currentUser?.emailVerified ?? false,
        'lastUpdated': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set(profileData, SetOptions(merge: true));

      logger.i('User profile saved');
    } catch (e) {
      logger.e('Error saving user profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUserId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!doc.exists) return null;

      return {
        'id': doc.id,
        ...doc.data()!,
      };
    } catch (e) {
      logger.e('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      if (currentUserId == null) return;

      updates['lastUpdated'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update(updates);

      logger.i('User profile updated');
    } catch (e) {
      logger.e('Error updating user profile: $e');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> watchUserProfile() {
    if (currentUserId == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return {
        'id': snapshot.id,
        ...snapshot.data()!,
      };
    });
  }

  Future<Map<String, int>> getUserStatistics() async {
    try {
      if (currentUserId == null) {
        return {'recentSearches': 0, 'savedRoutes': 0};
      }

      final recentSearches = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('recent_searches')
          .count()
          .get();

      final savedRoutes = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('saved_routes')
          .count()
          .get();

      return {
        'recentSearches': recentSearches.count ?? 0,
        'savedRoutes': savedRoutes.count ?? 0,
      };
    } catch (e) {
      logger.e('Error getting user statistics: $e');
      return {'recentSearches': 0, 'savedRoutes': 0};
    }
  }

  Future<bool> isUserAdmin() async {
    if (currentUserId == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();

      if (!doc.exists) return false;

      final data = doc.data();
      return data?['isAdmin'] == true;
    } catch (e) {
      logger.e('Error checking admin status: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllJeepneyRoutes() async {
    try {
      final snapshot = await _firestore
          .collection('jeepney_routes')
          .get();

      return snapshot.docs.map((doc) {
        return {
          'code': doc.id,
          'route': doc.data()['route'] ?? [],
        };
      }).toList();
    } catch (e) {
      logger.e('Error getting jeepney routes: $e');
      return [];
    }
  }

  Future<void> addJeepneyRoute({
    required String routeCode,
    required List<Map<String, dynamic>> stops,
  }) async {
    try {
      await _firestore
          .collection('jeepney_routes')
          .doc(routeCode)
          .set({
        'route': stops,
      });

      logger.i('Jeepney route added: $routeCode');
    } catch (e) {
      logger.e('Error adding jeepney route: $e');
      rethrow;
    }
  }

  Future<void> updateJeepneyRoute({
    required String routeCode,
    required List<Map<String, dynamic>> stops,
  }) async {
    try {
      await _firestore
          .collection('jeepney_routes')
          .doc(routeCode)
          .update({
        'route': stops,
      });

      logger.i('Jeepney route updated: $routeCode');
    } catch (e) {
      logger.e('Error updating jeepney route: $e');
      rethrow;
    }
  }

  Future<void> deleteJeepneyRoute(String routeCode) async {
    try {
      await _firestore
          .collection('jeepney_routes')
          .doc(routeCode)
          .delete();

      logger.i('Jeepney route deleted: $routeCode');
    } catch (e) {
      logger.e('Error deleting jeepney route: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getJeepneyRoute(String routeCode) async {
    try {
      final doc = await _firestore
          .collection('jeepney_routes')
          .doc(routeCode)
          .get();

      if (!doc.exists) return null;

      return {
        'code': doc.id,
        'route': doc.data()?['route'] ?? [],
      };
    } catch (e) {
      logger.e('Error getting jeepney route: $e');
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> watchJeepneyRoutes() {
    return _firestore
        .collection('jeepney_routes')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'code': doc.id,
          'route': doc.data()['route'] ?? [],
        };
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final userModel = UserAppModel.fromFirestore(doc);
        return userModel.toMap();
      }).toList();
    } catch (e) {
      //logger.e('Error getting all users: $e');
      return [];
    }
  }

  Future<void> deleteUserByAdmin(String email) async {
    try {
      await _firestore.collection('users').doc(email).delete();
      //logger.i('User $uid deleted by admin');
    } catch (e) {
      //logger.e('Error deleting user by admin: $e');
      rethrow;
    }
  }

  Future<void> toggleUserAdminStatus(String email, bool isAdmin) async {
    try {
      await _firestore.collection('users').doc(email).update({'isAdmin': isAdmin});
      logger.i('User $email admin status set to $isAdmin');
    } catch (e) {
      logger.e('Error toggling admin status: $e');
      rethrow;
    }
  }

}