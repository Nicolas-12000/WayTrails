import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/route_model.dart';

class ActivityProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isTracking = false;
  List<LatLng> _currentRoute = [];
  double _currentDistance = 0.0;
  int _currentDuration = 0;

  bool get isTracking => _isTracking;
  List<LatLng> get currentRoute => _currentRoute;
  double get currentDistance => _currentDistance;
  int get currentDuration => _currentDuration;

  void startTracking() {
    _isTracking = true;
    _currentRoute = [];
    _currentDistance = 0.0;
    _currentDuration = 0;
    notifyListeners();
  }

  void addPoint(LatLng point) {
    _currentRoute.add(point);
    notifyListeners();
  }

  void updateStats(double distance, int duration) {
    _currentDistance = distance;
    _currentDuration = duration;
    notifyListeners();
  }

  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }

  Future<void> saveRoute({
    required String name,
    String? description,
    required String activityType,
    required List<LatLng> coordinates,
    required double distance,
    required int duration,
    required bool isPublic,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final avgSpeed = duration > 0 ? (distance / duration) * 3600 : 0.0;

      final routeData = {
        'id': const Uuid().v4(),
        'user_id': userId,
        'name': name,
        'description': description,
        'activity_type': activityType,
        'distance': distance,
        'duration': duration,
        'avg_speed': avgSpeed,
        'coordinates': coordinates
            .map((coord) => {
                  'latitude': coord.latitude,
                  'longitude': coord.longitude,
                })
            .toList(),
        'is_public': isPublic,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('routes').insert(routeData);

      // Update user stats
      await _updateUserStats(distance, duration);

      _currentRoute = [];
      _currentDistance = 0.0;
      _currentDuration = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving route: $e');
      rethrow;
    }
  }

  Future<void> _updateUserStats(double distance, int duration) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('users')
          .select('total_distance, total_time')
          .eq('id', userId)
          .single();

      final currentDistance =
          (response['total_distance'] as num?)?.toDouble() ?? 0.0;
      final currentTime = response['total_time'] as int? ?? 0;

      await _supabase.from('users').update({
        'total_distance': currentDistance + distance,
        'total_time': currentTime + duration,
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error updating user stats: $e');
    }
  }
}

class RouteProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<RouteModel> _userRoutes = [];
  List<RouteModel> _publicRoutes = [];
  bool _isLoading = false;

  List<RouteModel> get userRoutes => _userRoutes;
  List<RouteModel> get publicRoutes => _publicRoutes;
  bool get isLoading => _isLoading;

  Future<void> fetchUserRoutes() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('routes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _userRoutes =
          (response as List).map((json) => RouteModel.fromJson(json)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('Error fetching user routes: $e');
      notifyListeners();
    }
  }

  Future<void> fetchPublicRoutes() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase
          .from('routes')
          .select('''
            *,
            users!routes_user_id_fkey(full_name, avatar_url)
          ''')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(50);

      _publicRoutes = (response as List).map((json) {
        final route = RouteModel.fromJson(json);
        if (json['users'] != null) {
          route.userName = json['users']['full_name'];
          route.userAvatar = json['users']['avatar_url'];
        }
        return route;
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('Error fetching public routes: $e');
      notifyListeners();
    }
  }

  Future<void> deleteRoute(String routeId) async {
    try {
      await _supabase.from('routes').delete().eq('id', routeId);
      _userRoutes.removeWhere((route) => route.id == routeId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting route: $e');
      rethrow;
    }
  }

  Future<void> toggleLike(String routeId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Check if already liked
      final existing = await _supabase
          .from('likes')
          .select()
          .eq('route_id', routeId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Unlike
        await _supabase
            .from('likes')
            .delete()
            .eq('route_id', routeId)
            .eq('user_id', userId);

        await _supabase.rpc('decrement_likes', params: {'route_id': routeId});
      } else {
        // Like
        await _supabase.from('likes').insert({
          'route_id': routeId,
          'user_id': userId,
        });

        await _supabase.rpc('increment_likes', params: {'route_id': routeId});
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }
}
