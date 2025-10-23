# 🏃‍♂️ WayTrails - Route Tracking App

Una aplicación móvil desarrollada en Flutter para registrar y seguir rutas de actividades al aire libre como correr, caminar, andar en bicicleta, similar a Strava.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![Supabase](https://img.shields.io/badge/Supabase-Latest-green.svg)

## 📱 Características

- ✅ Seguimiento GPS en tiempo real
- 🗺️ Mapas interactivos con OpenStreetMap
- 📊 Estadísticas detalladas (distancia, tiempo, velocidad)
- 💾 Historial de rutas guardadas
- 🌐 Red social para compartir rutas
- 👥 Sistema de seguimiento de usuarios

## 🛠️ Tecnologías

- **Flutter** - Framework multiplataforma
- **Dart** - Lenguaje de programación
- **Supabase** - Backend as a Service (Auth, Database, Storage)
- **OpenStreetMap** - Mapas interactivos
- **Flutter Map** - Visualización de mapas
- **Geolocator** - Seguimiento GPS

## 📋 Requisitos Previos

- Flutter SDK 3.0 o superior
- Dart 3.0 o superior
- Android Studio / VS Code
- Cuenta en Supabase (gratis)
- Dispositivo físico o emulador Android/iOS

## 🚀 Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/waytrails.git
cd waytrails
```

### 2. Instalar Dependencias

```bash
flutter pub get
```

### 3. Configurar Supabase

#### 3.1 Crear Proyecto en Supabase

1. Ve a [https://supabase.com](https://supabase.com)
2. Crea una cuenta o inicia sesión
3. Crea un nuevo proyecto
4. Guarda la **URL** y **anon key** del proyecto

#### 3.2 Configurar Base de Datos

1. En tu proyecto de Supabase, ve a **SQL Editor**
2. Copia y ejecuta el siguiente script SQL:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    total_distance FLOAT DEFAULT 0,
    total_time INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Routes table
CREATE TABLE routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    activity_type TEXT NOT NULL CHECK (activity_type IN ('running', 'walking', 'cycling', 'hiking')),
    distance FLOAT NOT NULL CHECK (distance >= 0),
    duration INTEGER NOT NULL CHECK (duration >= 0),
    avg_speed FLOAT,
    coordinates JSONB NOT NULL,
    is_public BOOLEAN DEFAULT false,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comments table
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id UUID REFERENCES routes(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Likes table
CREATE TABLE likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id UUID REFERENCES routes(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(route_id, user_id)
);

-- Follows table
CREATE TABLE follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    following_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

-- Create indexes for better performance
CREATE INDEX idx_routes_user_id ON routes(user_id);
CREATE INDEX idx_routes_is_public ON routes(is_public);
CREATE INDEX idx_routes_created_at ON routes(created_at DESC);
CREATE INDEX idx_comments_route_id ON comments(route_id);
CREATE INDEX idx_likes_route_id ON likes(route_id);
CREATE INDEX idx_likes_user_id ON likes(user_id);
CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view all profiles" 
    ON users FOR SELECT 
    USING (true);

CREATE POLICY "Users can update own profile" 
    ON users FOR UPDATE 
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
    ON users FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- RLS Policies for routes table
CREATE POLICY "Public routes are viewable by everyone" 
    ON routes FOR SELECT 
    USING (is_public = true OR auth.uid() = user_id);

CREATE POLICY "Users can insert own routes" 
    ON routes FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own routes" 
    ON routes FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own routes" 
    ON routes FOR DELETE 
    USING (auth.uid() = user_id);

-- RLS Policies for comments table
CREATE POLICY "Comments on public routes are viewable" 
    ON comments FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM routes 
            WHERE routes.id = comments.route_id 
            AND (routes.is_public = true OR routes.user_id = auth.uid())
        )
    );

CREATE POLICY "Authenticated users can insert comments" 
    ON comments FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments" 
    ON comments FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments" 
    ON comments FOR DELETE 
    USING (auth.uid() = user_id);

-- RLS Policies for likes table
CREATE POLICY "Likes are viewable by everyone" 
    ON likes FOR SELECT 
    USING (true);

CREATE POLICY "Authenticated users can insert likes" 
    ON likes FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

#### 3.3 Separar el SQL en un archivo (opcional)

Si prefieres, puedes mover todo el script SQL a un archivo `supabase/schema.sql` en el repo y ejecutarlo desde allí en el editor SQL de Supabase. Esto hace más fácil mantener versiones y aplicar cambios.

---

## ⚙️ Variables de entorno (.env)

La app usa variables de entorno para las credenciales de Supabase y ajustes sensibles. Crea un archivo `.env` en la raíz del proyecto (no lo subas al repositorio). Usa `.env.example` como plantilla.

Variables esperadas (ejemplo en `.env.example`):

```text
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
MAP_TILE_PROVIDER=OpenStreetMap
GOOGLE_MAPS_API_KEY=
ROUTE_IMAGES_BUCKET=route-images
PROFILE_IMAGES_BUCKET=profile-images
```

### Usar `flutter_dotenv`

1. Instalé `flutter_dotenv` en `pubspec.yaml`.
2. Inicializa dotenv en `main.dart` antes de `runApp`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
    // Valida que existan las variables requeridas (opcional)
    // SupabaseConfig.validate(); // si usas el helper
    runApp(const MyApp());
}
```

3. Leer variables desde el código (ejemplo en `lib/config/supabase_config.dart`)

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
    static String get url => dotenv.env['SUPABASE_URL'] ?? '';
    static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
```

---

## 🗺️ Mapa: OpenStreetMap (widget de ejemplo)

He añadido un widget reutilizable `OpenStreetMapView` en `lib/widgets/openstreet_map_view.dart` que usa `flutter_map` y `latlong2`. Ejemplo de uso en una pantalla:

```dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:waytrails/widgets/openstreet_map_view.dart';

class MapScreen extends StatelessWidget {
    const MapScreen({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        final center = LatLng(-0.180653, -78.467834); // Quito, ejemplo
        return Scaffold(
            appBar: AppBar(title: const Text('Mapa')),
            body: OpenStreetMapView(center: center, zoom: 13),
        );
    }
}
```

El widget usa por defecto las teselas de OpenStreetMap y no necesita API key. Si usas otro proveedor de teselas (Google, Mapbox), configura `MAP_TILE_PROVIDER` o modifica `OpenStreetMapView`.

---

CREATE POLICY "Users can delete own likes" 
    ON likes FOR DELETE 
    USING (auth.uid() = user_id);

-- RLS Policies for follows table
CREATE POLICY "Follows are viewable by everyone" 
    ON follows FOR SELECT 
    USING (true);

CREATE POLICY "Authenticated users can follow others" 
    ON follows FOR INSERT 
    WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow" 
    ON follows FOR DELETE 
    USING (auth.uid() = follower_id);

-- Functions to increment/decrement likes count
CREATE OR REPLACE FUNCTION increment_likes(route_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE routes 
    SET likes_count = likes_count + 1 
    WHERE id = route_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION decrement_likes(route_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE routes 
    SET likes_count = GREATEST(0, likes_count - 1) 
    WHERE id = route_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment comments count
CREATE OR REPLACE FUNCTION increment_comments()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE routes 
    SET comments_count = comments_count + 1 
    WHERE id = NEW.route_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement comments count
CREATE OR REPLACE FUNCTION decrement_comments()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE routes 
    SET comments_count = GREATEST(0, comments_count - 1) 
    WHERE id = OLD.route_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Triggers for comments count
CREATE TRIGGER on_comment_created
    AFTER INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION increment_comments();

CREATE TRIGGER on_comment_deleted
    AFTER DELETE ON comments
    FOR EACH ROW
    EXECUTE FUNCTION decrement_comments();

-- Function to create user profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create user profile
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();
```

#### 3.3 Configurar Storage (Opcional)

Si deseas permitir que los usuarios suban fotos de sus rutas:

1. Ve a **Storage** en tu proyecto Supabase
2. Crea dos buckets:
   - `route-images` (público)
   - `profile-images` (público)
3. Configura las políticas de acceso para cada bucket

### 4. Configurar Credenciales en la App

Edita el archivo `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'TU_SUPABASE_URL_AQUI';
  static const String anonKey = 'TU_SUPABASE_ANON_KEY_AQUI';
  
  // ... resto del código
}
```

**Dónde encontrar tus credenciales:**
- Ve a tu proyecto en Supabase
- Haz clic en el ícono de configuración (Settings)
- Ve a **API**
- Copia la **URL** y **anon/public key**

### 5. Configurar Permisos de Ubicación

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<manifest ...>
    <!-- Permisos de ubicación -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application ...>
        ...
    </application>
</manifest>
```

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>WayTrails necesita acceso a tu ubicación para registrar tus rutas.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>WayTrails necesita acceso a tu ubicación para registrar tus rutas en segundo plano.</string>
```

### 6. Ejecutar la App

```bash
# Para Android
flutter run

# Para iOS
flutter run -d ios

# Para dispositivo específico
flutter devices
flutter run -d [device-id]
```

## 📱 Uso de la Aplicación

### Registro e Inicio de Sesión

1. Abre la app
2. Regístrate con tu email y contraseña
3. Completa tu perfil

### Grabar una Ruta

1. En la pantalla principal, toca **"Start Tracking"**
2. Selecciona el tipo de actividad (correr, caminar, ciclismo, etc.)
3. Toca el botón verde de **Play** para iniciar
4. La app grabará tu ruta en tiempo real
5. Usa **Pause** para hacer pausas
6. Toca **Stop** para finalizar
7. Guarda tu ruta con un nombre y descripción

### Explorar Rutas de Otros

1. Ve a la pestaña **Explore**
2. Navega por las rutas públicas
3. Dale like o comenta en las rutas que te gusten
4. Sigue a otros usuarios

### Ver tu Historial

1. Ve a la pestaña **History**
2. Visualiza todas tus rutas guardadas
3. Toca una ruta para ver detalles completos
4. Comparte o elimina rutas

## 🎨 Estructura del Proyecto

```
waytrails/
├── lib/
│   ├── config/
│   │   └── supabase_config.dart          # Configuración de Supabase
│   ├── models/
│   │   └── route_model.dart              # Modelos de datos
│   ├── providers/
│   │   ├── auth_provider.dart            # Gestión de autenticación
│   │   ├── route_provider.dart           # Gestión de rutas
│   │   └── activity_provider.dart        # Gestión de actividades
│   ├── screens/
│   │   ├── splash_screen.dart            # Pantalla de carga
│   │   ├── auth/
│   │   │   ├── login_screen.dart         # Inicio de sesión
│   │   │   └── register_screen.dart      # Registro
│   │   ├── home/
│   │   │   └── home_screen.dart          # Pantalla principal
│   │   ├── tracking/
│   │   │   ├── tracking_screen.dart      # Seguimiento en vivo
│   │   │   └── save_route_screen.dart    # Guardar ruta
│   │   ├── history/
│   │   │   └── history_screen.dart       # Historial de rutas
│   │   ├── feed/
│   │   │   └── feed_screen.dart          # Feed social
│   │   └── profile/
│   │       └── profile_screen.dart       # Perfil de usuario
│   ├── widgets/
│   │   ├── activity_card.dart            # Tarjeta de actividad
│   │   └── stats_card.dart               # Tarjeta de estadísticas
│   ├── theme/
│   │   └── app_theme.dart                # Tema de la aplicación
│   └── main.dart                         # Punto de entrada
├── assets/
│   ├── images/
│   └── icons/
├── pubspec.yaml
└── README.md
```

## 🔧 Personalización

### Cambiar Colores

Edita `lib/theme/app_theme.dart`:

```dart
static const Color primaryOrange = Color(0xFFFF9500);
static const Color secondaryBlue = Color(0xFF007AFF);
// Cambia estos valores a tu preferencia
```

### Agregar Nuevos Tipos de Actividad

En `lib/models/route_model.dart`, actualiza el método `getActivityIcon()` y el SQL constraint.

## 🐛 Solución de Problemas

### Error de permisos de ubicación

- **Android**: Asegúrate de tener los permisos en `AndroidManifest.xml`
- **iOS**: Verifica `Info.plist`
- Reinicia la app después de cambiar permisos

### Error de conexión a Supabase

- Verifica que la URL y anon key sean correctas
- Asegúrate de tener conexión a internet
- Revisa las políticas RLS en Supabase

### El mapa no carga

- Verifica tu conexión a internet
- OpenStreetMap requiere conexión activa
- Prueba con un dispositivo real (no emulador) si es posible

### Error al guardar rutas

- Verifica que las tablas estén creadas correctamente
- Revisa las políticas RLS
- Asegúrate de estar autenticado

## 📚 Recursos Adicionales

- [Documentación de Flutter](https://flutter.dev/docs)
- [Documentación de Supabase](https://supabase.com/docs)
- [Flutter Map Package](https://pub.dev/packages/flutter_map)
- [OpenStreetMap](https://www.openstreetmap.org)

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request


## 👨‍💻 Autor

**Nicolás Alejandro García Pasmiño**


---

**¿Necesitas ayuda?** Abre un issue en GitHub o contacta al equipo de desarrollo.

**¡Feliz tracking! 🏃‍♂️🚴‍♀️🚶‍♂️**