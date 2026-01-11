import 'dart:async';

import 'package:flida_auth_sdk/flida_auth_sdk.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlidaUser? _user;
  FlidaToken? _token;
  String _status = 'Not initialized';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _startMonitoring();
    unawaited(_restoreSession());
  }

  Future<void> _restoreSession() async {
    _log('Checking for existing session...');
    try {
      final token = await FlidaAuthSdk.loadToken();
      if (token != null) {
        setState(() {
          _token = token;
          _status = 'Restoring session...';
        });
        _log('Token found. Fetching user info...');
        await _getUserInfo(token.accessToken);
        setState(() => _status = 'Session Restored');
      } else {
        _log('No existing session found.');
      }
    } on Exception catch (e) {
      _log('Failed to restore session: $e');
    }
  }

  void _log(String message) {
    if (!mounted) return;
    setState(() {
      _logs.insert(
        0,
        "${DateTime.now().toIso8601String().split('T').last.split('.').first}: $message",
      );
    });
    debugPrint(message);
  }

  void _startMonitoring() {
    FlidaAuthSdk.events.listen((event) {
      _log('Event: ${event.type}');
      switch (event.type) {
        case FlidaEventType.signedIn:
          setState(() {
            _user = event.user;
            // Token might be available (partial or full)
            if (event.token != null) {
              _token = event.token;
            }
            _status = 'Signed In';
          });
        case FlidaEventType.loggedOut:
          setState(() {
            _user = null;
            _token = null;
            _status = 'Logged Out (${event.logoutReason})';
          });
        case FlidaEventType.signInFailed:
          _log('Sign In Failed: ${event.error}');
        // Handle other cases
        // ignore: no_default_cases
        default:
          break;
      }
    });
  }

  Future<void> _signIn() async {
    try {
      _log('Signing in...');
      final token = await FlidaAuthSdk.signIn(
        scopes: ['openid', 'name', 'e-mail-address', 'phone-number'],
      );
      if (token != null) {
        setState(() => _token = token);
        _log(
          'Sign In result received. Token: ${token.accessToken.substring(0, 10)}...',
        );

        // Fetch user info immediately
        await _getUserInfo(token.accessToken);
      }
    } on Exception catch (e) {
      _log('Error during sign in: $e');
    }
  }

  Future<void> _getUserInfo(String accessToken) async {
    try {
      _log('Fetching user info...');
      final user = await FlidaAuthSdk.getUserInfo(accessToken: accessToken);
      if (user != null) {
        setState(() => _user = user);
        _log('User Info: ${user.name} (${user.id})');
      }
    } on Exception catch (e) {
      _log('Error fetching user info: $e');
    }
  }

  Future<void> _refreshTokens() async {
    if (_token == null || _token!.refreshToken == null) {
      _log('No refresh token available');
      return;
    }
    try {
      _log('Refreshing tokens...');
      final newToken = await FlidaAuthSdk.refreshTokens(
        refreshToken: _token!.refreshToken!,
      );
      if (newToken != null) {
        setState(() => _token = newToken);
        _log(
          'Refreshed! New Access: ${newToken.accessToken.substring(0, 10)}...',
        );
      }
    } on Exception catch (e) {
      _log('Error refreshing token: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      _log('Signing out...');
      await FlidaAuthSdk.signOut();
      _log('Signed out called.');
    } on Exception catch (e) {
      _log('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flida Auth SDK Example'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $_status',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_user != null) ...[
                  Text('User: ${_user!.name}'),
                  Text('ID: ${_user!.id}'),
                  if (_user!.email != null) Text('Email: ${_user!.email}'),
                  if (_user!.phoneNumber != null)
                    Text('Phone: ${_user!.phoneNumber}'),
                ],
                if (_token != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Access Token: ${_token!.accessToken.substring(0, 10)}...',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _signIn,
                  child: const Text('Sign In'),
                ),
                ElevatedButton(
                  onPressed: _signOut,
                  child: const Text('Sign Out'),
                ),
                ElevatedButton(
                  onPressed: _refreshTokens,
                  child: const Text('Refresh Token'),
                ),
                ElevatedButton(
                  onPressed: _token != null
                      ? () => _getUserInfo(_token!.accessToken)
                      : null,
                  child: const Text('Get User Info'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                child: Text(_logs[index], style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
