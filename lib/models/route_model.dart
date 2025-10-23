import 'package:latlong2/latlong.dart';

class RouteModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String activityType;
  final double distance;
  final int duration;
  final double? avgSpeed;
  final List<LatLng> coordinates;
  final bool isPublic;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  // User info (for feed)
  String? userName;
  String? userAvatar;

  RouteModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.activityType,
    required this.distance,
    required this.duration,
    this.avgSpeed,
    required this.coordinates,
    required this.isPublic,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.userName,
    this.userAvatar,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    List<LatLng> coords = [];
    if (json['coordinates'] is List) {
      coords = (json['coordinates'] as List).map((coord) {
        return LatLng(
          (coord['latitude'] as num).toDouble(),
          (coord['longitude'] as num).toDouble(),
        );
      }).toList();
    }

    return RouteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      activityType: json['activity_type'] as String,
      distance: (json['distance'] as num).toDouble(),
      duration: json['duration'] as int,
      avgSpeed: json['avg_speed'] != null
          ? (json['avg_speed'] as num).toDouble()
          : null,
      coordinates: coords,
      isPublic: json['is_public'] as bool? ?? false,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['user_name'] as String?,
      userAvatar: json['user_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String getFormattedDistance() {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    }
    return '${distance.toStringAsFixed(2)} km';
  }

  String getFormattedDuration() {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getActivityIcon() {
    switch (activityType.toLowerCase()) {
      case 'running':
        return '🏃';
      case 'walking':
        return '🚶';
      case 'cycling':
        return '🚴';
      case 'hiking':
        return '🥾';
      default:
        return '📍';
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final double totalDistance;
  final int totalTime;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.totalDistance = 0,
    this.totalTime = 0,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      totalDistance: (json['total_distance'] as num?)?.toDouble() ?? 0,
      totalTime: json['total_time'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'total_distance': totalDistance,
      'total_time': totalTime,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
