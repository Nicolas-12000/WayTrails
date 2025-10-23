import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String get routeImagesBucket =>
      dotenv.env['ROUTE_IMAGES_BUCKET'] ?? 'route-images';
  static String get profileImagesBucket =>
      dotenv.env['PROFILE_IMAGES_BUCKET'] ?? 'profile-images';

  /// Validate required env variables and throw a helpful message if missing.
  static void validate() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. Make sure you have a valid .env file with SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
  }
}
