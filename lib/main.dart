import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core.dart';
import 'screens/admin_home.dart';
import 'screens/login_screen.dart';
import 'screens/staff_home.dart';

const String supabaseUrl = 'https://pommgimcnwgybkxgojng.supabase.co';
const String supabaseAnonKey = 'sb_publishable_wUOXIb48ds5TdVVlewAr8A_KowKTJU-';

bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty &&
    supabaseUrl.startsWith('http') &&
    !supabaseUrl.contains('YOUR_SUPABASE_URL');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isSupabaseConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
    );
  }
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Morning Munchies',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
        home: isSupabaseConfigured ? const AuthGate() : const SetupConfigScreen(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, _) {
        final session = supabase.auth.currentSession;
        if (session == null) return const LoginScreen();
        return FutureBuilder(
          key: ValueKey(session.user.id),
          future: supabase.from('profiles').select('role').eq('id', session.user.id).maybeSingle(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Database setup needed:\n${snap.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton(onPressed: () => supabase.auth.signOut(), child: const Text('Log out')),
                    ]),
                  ),
                ),
              );
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final role = snap.data?['role'] ?? 'staff';
            return role == 'admin' ? const AdminHome() : const StaffHome();
          },
        );
      },
    );
  }
}

class SetupConfigScreen extends StatelessWidget {
  const SetupConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Required'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              const Icon(Icons.cloud_sync, size: 72, color: Colors.deepOrange),
              const SizedBox(height: 16),
              Text(
                'Supabase Setup Required',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'To run Office Food, add your Supabase credentials in lib/main.dart.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Steps:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('1. Create a Supabase project at supabase.com.'),
                      const SizedBox(height: 4),
                      const Text('2. Run schema.sql in Supabase SQL Editor to set up tables.'),
                      const SizedBox(height: 4),
                      const Text('3. In Supabase Project Settings -> API, copy Project URL & Anon Key.'),
                      const SizedBox(height: 4),
                      const Text('4. Paste them into supabaseUrl and supabaseAnonKey in lib/main.dart.'),
                    ],
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
