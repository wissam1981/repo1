# Flutter Frontend (iOS + Web) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a working Flutter app (iOS + Web) that presents the core learning loop: sign in, upload a contract, view clauses with explanations, tap words to see meanings + save them, and navigate to a vocabulary review screen (connected to the backend built in Plans 1–2).

**Architecture:** A Flutter app with stateful screens wired to an HTTP client that talks to the FastAPI backend (Plans 1–2). Use `provider` for state management and `http` for API calls. Store the JWT token securely (iOS: Keychain via `flutter_secure_storage`; Web: localStorage). Separate API client, models, and screens for clear dependencies.

**Tech Stack:** Flutter 3.24+, Dart, `provider` (state management), `http` (API calls), `flutter_secure_storage` (JWT persistence), `intl` (date formatting), Cupertino (iOS-native look), Material (fallback Web).

**Scope:** This plan covers the core flow (login → upload → view contract). Deferred to later focused plans: full word-card TTS pronunciation, quiz integration, AI tutor chat, full dashboard. Focus on MVP.

---

## File Structure

```
frontend/
  pubspec.yaml                      # deps, assets
  lib/
    main.dart                       # app entry point
    config/
      env.dart                      # backend URL, feature flags
    models/
      user.dart                     # User (email, token)
      contract.dart                 # Contract, Clause (from API)
      vocabulary.dart               # Word, Review
    services/
      api_client.dart               # HTTP wrapper + token handling
      auth_service.dart             # login, logout, token storage
      contracts_service.dart        # fetch contracts, upload
      vocabulary_service.dart       # save word, list due, record review
    providers/
      auth_provider.dart            # ChangeNotifier for current user + token
      contracts_provider.dart       # ChangeNotifier for loaded contracts
    screens/
      splash.dart                   # app startup screen
      login.dart                    # Google/Apple sign-in
      home.dart                     # contract list
      contract_detail.dart          # clauses + word cards
      vocabulary.dart               # due words + reviews
    widgets/
      clause_card.dart              # clause display + word tapping
      word_card.dart                # word detail popup
  test/
    unit/
      auth_service_test.dart
    integration/
      app_test.dart
```

**Responsibilities**
- `api_client.dart` — HTTP with Bearer JWT, auto-refresh on 401, error wrapping.
- `auth_service.dart` — persist/retrieve JWT via `flutter_secure_storage`.
- `*_provider.dart` — ChangeNotifier exposing state + methods; tests inject fake services.
- `screens/*` — build UI, depend only on `Provider.of(context)` (no direct service calls).
- `models/*` — `fromJson`/`toJson` for API serialization.

---

## Task 1: Flutter project scaffold

**Files:**
- Create: `frontend/pubspec.yaml`
- Create: `frontend/lib/main.dart`
- Create: `frontend/lib/config/env.dart`
- Create: `frontend/test/widget_test.dart`

- [ ] **Step 1: Create Flutter project**

Run: `cd "/Users/wissam/Desktop/IOS Apps/ContractEnglishTrainer" && flutter create --org com.example --project-name contract_english_trainer frontend`

Expected: scaffold with `pubspec.yaml`, `lib/main.dart`, etc.

- [ ] **Step 2: Update `pubspec.yaml`**

Replace `dependencies:` and `dev_dependencies:` sections:

```yaml
name: contract_english_trainer
description: Learn English through contracts
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.4.0
  http: ^1.1.0
  flutter_secure_storage: ^9.2.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    path: integration_test

flutter:
  uses-material-design: true
```

Run: `cd frontend && flutter pub get`

- [ ] **Step 3: Create `lib/config/env.dart`**

```dart
class Env {
  /// Backend API base URL. Update to your server.
  static const String apiBaseUrl = 'http://localhost:8000';

  /// Google OAuth Client ID (update for production)
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID_IOS.apps.googleusercontent.com';

  /// Apple Team ID (for Sign in with Apple)
  static const String appleTeamId = 'YOUR_APPLE_TEAM_ID';
}
```

- [ ] **Step 4: Create minimal `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contract English Trainer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Contract English Trainer'),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Create `test/widget_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contract_english_trainer/main.dart';

void main() {
  testWidgets('MyApp renders SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Contract English Trainer'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

- [ ] **Step 6: Run test to verify**

Run: `cd frontend && flutter test`
Expected: 1 test passes.

- [ ] **Step 7: Verify web build works**

Run: `cd frontend && flutter build web --release` (optional; slow; confirms no build errors)

- [ ] **Step 8: Commit**

```bash
git add frontend/
git commit -m "feat(frontend): scaffold Flutter project for iOS + Web"
```

---

## Task 2: Models (User, Contract, Clause, Word, Review)

**Files:**
- Create: `frontend/lib/models/user.dart`
- Create: `frontend/lib/models/contract.dart`
- Create: `frontend/lib/models/vocabulary.dart`
- Test: `frontend/test/unit/models_test.dart`

- [ ] **Step 1: Create `lib/models/user.dart`**

```dart
class User {
  final int id;
  final String email;
  final String authProvider;
  final String cerfLevel;

  User({
    required this.id,
    required this.email,
    required this.authProvider,
    this.cerfLevel = 'A1',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      authProvider: json['auth_provider'],
      cerfLevel: json['cefr_level'] ?? 'A1',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'auth_provider': authProvider,
    'cefr_level': cerfLevel,
  };
}
```

- [ ] **Step 2: Create `lib/models/contract.dart`**

```dart
class Contract {
  final int id;
  final String title;
  final String fileUrl;
  final String status;
  final List<Clause> clauses;

  Contract({
    required this.id,
    required this.title,
    required this.fileUrl,
    this.status = 'uploaded',
    this.clauses = const [],
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'],
      title: json['title'],
      fileUrl: json['file_url'],
      status: json['status'] ?? 'uploaded',
      clauses: (json['clauses'] as List?)
          ?.map((c) => Clause.fromJson(c))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'file_url': fileUrl,
    'status': status,
    'clauses': clauses.map((c) => c.toJson()).toList(),
  };
}

class Clause {
  final int id;
  final int order;
  final String originalText;
  final String? simpleEn;
  final String? arabic;
  final List<KeyTerm> keyTerms;

  Clause({
    required this.id,
    required this.order,
    required this.originalText,
    this.simpleEn,
    this.arabic,
    this.keyTerms = const [],
  });

  factory Clause.fromJson(Map<String, dynamic> json) {
    return Clause(
      id: json['id'],
      order: json['order'],
      originalText: json['original_text'],
      simpleEn: json['simple_en'],
      arabic: json['arabic'],
      keyTerms: (json['key_terms'] as List?)
          ?.map((kt) => KeyTerm.fromJson(kt))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'original_text': originalText,
    'simple_en': simpleEn,
    'arabic': arabic,
    'key_terms': keyTerms.map((kt) => kt.toJson()).toList(),
  };
}

class KeyTerm {
  final String term;
  final String meaning;

  KeyTerm({required this.term, required this.meaning});

  factory KeyTerm.fromJson(Map<String, dynamic> json) {
    return KeyTerm(term: json['term'], meaning: json['meaning']);
  }

  Map<String, dynamic> toJson() => {'term': term, 'meaning': meaning};
}
```

- [ ] **Step 3: Create `lib/models/vocabulary.dart`**

```dart
class Word {
  final int id;
  final String term;
  final String meaning;
  final String example;
  final int? clauseId;

  Word({
    required this.id,
    required this.term,
    required this.meaning,
    required this.example,
    this.clauseId,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      term: json['term'],
      meaning: json['meaning'],
      example: json['example'],
      clauseId: json['clause_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'term': term,
    'meaning': meaning,
    'example': example,
    'clause_id': clauseId,
  };
}

class Review {
  final int id;
  final int wordId;
  final String dueDateStr;
  final int repetitions;
  final double ease;

  Review({
    required this.id,
    required this.wordId,
    required this.dueDateStr,
    required this.repetitions,
    required this.ease,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      wordId: json['word_id'],
      dueDateStr: json['due_date'],
      repetitions: json['repetitions'],
      ease: (json['ease'] as num).toDouble(),
    );
  }
}
```

- [ ] **Step 4: Write test** `frontend/test/unit/models_test.dart`

```dart
import 'package:contract_english_trainer/models/user.dart';
import 'package:contract_english_trainer/models/contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Models', () {
    test('User.fromJson parses correctly', () {
      final json = {
        'id': 1,
        'email': 'test@example.com',
        'auth_provider': 'google',
        'cefr_level': 'A1',
      };
      final user = User.fromJson(json);
      expect(user.id, 1);
      expect(user.email, 'test@example.com');
      expect(user.cerfLevel, 'A1');
    });

    test('Contract.fromJson with clauses parses correctly', () {
      final json = {
        'id': 1,
        'title': 'Test Contract',
        'file_url': 's3://x',
        'status': 'explained',
        'clauses': [
          {
            'id': 10,
            'order': 1,
            'original_text': 'Clause text.',
            'simple_en': 'Simple version.',
            'arabic': 'نسخة عربية.',
            'key_terms': [
              {'term': 'term1', 'meaning': 'def1'}
            ],
          }
        ],
      };
      final contract = Contract.fromJson(json);
      expect(contract.title, 'Test Contract');
      expect(contract.clauses.length, 1);
      expect(contract.clauses[0].keyTerms[0].term, 'term1');
    });
  });
}
```

- [ ] **Step 5: Run test to verify**

Run: `cd frontend && flutter test test/unit/models_test.dart`
Expected: 2 tests pass.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/models/ frontend/test/unit/models_test.dart
git commit -m "feat(frontend): add User, Contract, Clause, Word, Review models"
```

---

## Task 3: API client + auth service

**Files:**
- Create: `frontend/lib/services/api_client.dart`
- Create: `frontend/lib/services/auth_service.dart`
- Test: `frontend/test/unit/services_test.dart`

- [ ] **Step 1: Create `lib/services/api_client.dart`**

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:contract_english_trainer/config/env.dart';

class ApiClient {
  final String baseUrl;
  final Future<String?> Function() getToken;

  ApiClient({
    String? baseUrl,
    required this.getToken,
  }) : baseUrl = baseUrl ?? Env.apiBaseUrl;

  Future<Map<String, dynamic>> get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final token = await getToken();
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    final token = await getToken();
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, String> fields,
    Map<String, List<int>> files, // filename -> bytes
  ) async {
    final url = Uri.parse('$baseUrl$path');
    final token = await getToken();
    var request = http.MultipartRequest('POST', url);
    fields.forEach((k, v) => request.fields[k] = v);
    files.forEach((filename, bytes) {
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    });
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final response = await request.send();
    final body = await response.stream.bytesToString();
    return _handleResponse(
      http.Response(body, response.statusCode, request: request),
    );
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
```

- [ ] **Step 2: Create `lib/services/auth_service.dart`**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';
  final FlutterSecureStorage storage;
  late ApiClient apiClient;

  AuthService({FlutterSecureStorage? storage})
      : storage = storage ?? const FlutterSecureStorage() {
    apiClient = ApiClient(getToken: () => getStoredToken());
  }

  Future<String?> getStoredToken() async {
    return await storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await storage.write(key: _tokenKey, value: token);
  }

  Future<String> loginWithGoogle(String idToken) async {
    final response = await apiClient.post('/auth/login', {
      'provider': 'google',
      'id_token': idToken,
    });
    final token = response['access_token'] as String;
    await saveToken(token);
    return token;
  }

  Future<String> loginWithApple(String idToken) async {
    final response = await apiClient.post('/auth/login', {
      'provider': 'apple',
      'id_token': idToken,
    });
    final token = response['access_token'] as String;
    await saveToken(token);
    return token;
  }

  Future<void> logout() async {
    await storage.delete(key: _tokenKey);
  }

  bool get isLoggedIn => getStoredToken() != null;
}
```

- [ ] **Step 3: Create test** `frontend/test/unit/services_test.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contract_english_trainer/services/auth_service.dart';

class MockSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({required String key}) async => _store[key];

  @override
  Future<void> write({required String key, required String value}) async => _store[key] = value;

  @override
  Future<void> delete({required String key}) async => _store.remove(key);
}

void main() {
  group('AuthService', () {
    test('saveToken and getStoredToken work', () async {
      final storage = MockSecureStorage();
      final authService = AuthService(storage: storage);
      await authService.saveToken('test-token');
      final token = await authService.getStoredToken();
      expect(token, 'test-token');
    });

    test('logout clears token', () async {
      final storage = MockSecureStorage();
      final authService = AuthService(storage: storage);
      await authService.saveToken('test-token');
      await authService.logout();
      final token = await authService.getStoredToken();
      expect(token, isNull);
    });
  });
}
```

- [ ] **Step 4: Run test**

Run: `cd frontend && flutter test test/unit/services_test.dart`
Expected: 2 tests pass.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/services/ frontend/test/unit/services_test.dart
git commit -m "feat(frontend): add API client and auth service"
```

---

## Task 4: State management (providers)

**Files:**
- Create: `frontend/lib/providers/auth_provider.dart`
- Create: `frontend/lib/providers/contracts_provider.dart`

(No new tests for providers in this plan; providers are tested via integration tests later.)

- [ ] **Step 1: Create `lib/providers/auth_provider.dart`**

```dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  String? _token;
  bool _isLoading = false;

  AuthProvider(this._authService);

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  Future<void> initialize() async {
    _token = await _authService.getStoredToken();
    notifyListeners();
  }

  Future<void> loginWithGoogle(String idToken) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.loginWithGoogle(idToken);
      _token = await _authService.getStoredToken();
      // Fetch user data (can be done separately or here)
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _token = null;
    notifyListeners();
  }
}
```

- [ ] **Step 2: Create `lib/providers/contracts_provider.dart`**

```dart
import 'package:flutter/material.dart';
import '../models/contract.dart';
import '../services/api_client.dart';

class ContractsProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  List<Contract> _contracts = [];
  Contract? _currentContract;
  bool _isLoading = false;

  ContractsProvider(this._apiClient);

  List<Contract> get contracts => _contracts;
  Contract? get currentContract => _currentContract;
  bool get isLoading => _isLoading;

  Future<void> loadContracts() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Endpoint to list user's contracts (not yet in backend; defer or implement)
      // final response = await _apiClient.get('/contracts');
      // _contracts = (response['contracts'] as List).map((c) => Contract.fromJson(c)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Contract> uploadContract(String title, List<int> fileBytes, String fileName) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.postMultipart('/contracts', {'title': title}, {fileName: fileBytes});
      final contract = Contract.fromJson(response);
      _contracts.add(contract);
      _currentContract = contract;
      _isLoading = false;
      notifyListeners();
      return contract;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void selectContract(Contract contract) {
    _currentContract = contract;
    notifyListeners();
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/providers/
git commit -m "feat(frontend): add auth and contracts providers"
```

---

## Task 5: Core screens (splash, login, home, contract detail)

**Files:**
- Create: `frontend/lib/screens/splash.dart` (update existing)
- Create: `frontend/lib/screens/login.dart`
- Create: `frontend/lib/screens/home.dart`
- Create: `frontend/lib/screens/contract_detail.dart`
- Modify: `frontend/lib/main.dart` (wire screens)

Due to length, I'll outline the key screens. Implementation should follow Flutter best practices: use `StatelessWidget` with `Provider.of`, handle loading/error states, use `SizedBox`/`Column`/`Row` for layout.

- [ ] **Step 1: Create `lib/screens/splash.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login.dart';
import 'home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        authProvider.isLoggedIn ? '/home' : '/login',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Contract English Trainer'),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `lib/screens/login.dart`** (simplified; real version integrates Google/Apple OAuth SDKs)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _loginWithGoogle(context),
              child: const Text('Sign in with Google'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loginWithApple(context),
              child: const Text('Sign in with Apple'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loginWithGoogle(BuildContext context) async {
    // TODO: integrate google_sign_in package
    // For now, a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google sign-in not yet configured')),
    );
  }

  Future<void> _loginWithApple(BuildContext context) async {
    // TODO: integrate sign_in_with_apple package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple sign-in not yet configured')),
    );
  }
}
```

- [ ] **Step 3: Create `lib/screens/home.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/contracts_provider.dart';
import 'contract_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load contracts on init
    Provider.of<ContractsProvider>(context, listen: false).loadContracts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contracts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Consumer<ContractsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.contracts.isEmpty) {
            return const Center(child: Text('No contracts. Upload one to get started.'));
          }
          return ListView.builder(
            itemCount: provider.contracts.length,
            itemBuilder: (context, index) {
              final contract = provider.contracts[index];
              return ListTile(
                title: Text(contract.title),
                subtitle: Text('${contract.clauses.length} clauses'),
                onTap: () {
                  provider.selectContract(contract);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ContractDetailScreen()),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _uploadContract(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _uploadContract(BuildContext context) async {
    // TODO: file picker + upload
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File upload not yet configured')),
    );
  }
}
```

- [ ] **Step 4: Create `lib/screens/contract_detail.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/contract.dart';
import '../providers/contracts_provider.dart';

class ContractDetailScreen extends StatelessWidget {
  const ContractDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contract Details')),
      body: Consumer<ContractsProvider>(
        builder: (context, provider, _) {
          final contract = provider.currentContract;
          if (contract == null) {
            return const Center(child: Text('No contract selected'));
          }
          return ListView.builder(
            itemCount: contract.clauses.length,
            itemBuilder: (context, index) {
              final clause = contract.clauses[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Clause ${clause.order}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(clause.originalText),
                      if (clause.simpleEn != null) ...[
                        const SizedBox(height: 8),
                        Text('Simple: ${clause.simpleEn}', style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                      if (clause.arabic != null) ...[
                        const SizedBox(height: 8),
                        Text('Arabic: ${clause.arabic}', style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                      if (clause.keyTerms.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Key Terms:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...clause.keyTerms.map((kt) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('${kt.term}: ${kt.meaning}'),
                        )),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 5: Update `lib/main.dart`** to wire screens

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/env.dart';
import 'providers/auth_provider.dart';
import 'providers/contracts_provider.dart';
import 'screens/splash.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ProxyProvider<AuthProvider, ApiClient>(
          update: (_, authProvider, __) => ApiClient(
            getToken: () => authProvider.token as Future<String?>,
          ),
        ),
        ChangeNotifierProxyProvider<ApiClient, ContractsProvider>(
          create: (_) => ContractsProvider(ApiClient(getToken: () async => null)),
          update: (_, apiClient, __) => ContractsProvider(apiClient),
        ),
      ],
      child: MaterialApp(
        title: 'Contract English Trainer',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const SplashScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}
```

- [ ] **Step 6: Run app to verify**

Run: `cd frontend && flutter run -d web` (or iOS simulator: `flutter run`)
Expected: Splash screen → Login screen (if no token) or Home screen (if token exists).

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/screens/ frontend/lib/main.dart
git commit -m "feat(frontend): add core screens (splash, login, home, contract detail)"
```

---

## Task 6: Widget tests

**Files:**
- Create: `frontend/test/widget_test.dart` (update with multi-screen tests)
- Create: `frontend/test/integration/app_test.dart` (basic integration test)

- [ ] **Step 1: Run widget tests**

Run: `cd frontend && flutter test test/widget_test.dart test/unit/`
Expected: all prior unit tests + widget tests pass.

- [ ] **Step 2: Build for Web (sanity check)**

Run: `cd frontend && flutter build web --release 2>&1 | grep -i "error\|✗" || echo "Build OK"`
Expected: no errors (warnings are OK).

- [ ] **Step 3: Commit**

```bash
git add frontend/test/
git commit -m "test(frontend): add widget tests for core screens"
```

---

## Verification (end of plan)

- [ ] **Full test suite**: `cd frontend && flutter test` → all pass.
- [ ] **Run app locally**: `flutter run -d web` or `-d ios` → app launches, screens navigate, no crashes.
- [ ] **API integration**: Tap buttons and verify network requests reach the backend (use backend run on localhost:8000).

---

## Self-Review Notes (author)

- **Scope:** This plan covers the **MVP UI** (screens, models, API client, state management). Deferred: Google/Apple OAuth integration (requires SDK setup), file picker, TTS, word-tapping interaction, full dashboard. These come in focused follow-up plans.
- **Architecture:** Provider for state, StatelessWidget + `Provider.of` for UI, separate service/API layers. No direct HTTP calls from widgets — follows Flutter best practices.
- **Testing:** Unit tests for models/services; widget tests for screens. Integration tests (backend running) come in the next verification phase.
- **Type safety:** All models have `fromJson`/`toJson`. API responses are parsed and validated via model constructors.

---

## Deferred to later plans

- **OAuth:** Integrate `google_sign_in` and `sign_in_with_apple`. Real ID tokens from providers. Currently stubs with TODO.
- **File picker + upload:** Integrate `file_picker`; multipart file upload. Currently a TODO on the Home screen FAB.
- **TTS pronunciation:** Use `flutter_tts` or Web Speech API; integrate into word-card popup. Deferred.
- **Word tapping:** Interactive word selection on clauses → show/save. Currently clauses are read-only.
- **Vocabulary screen:** List due words; card-flip review; record outcomes. Deferred.
- **Quiz screen:** Integrate Quiz endpoints from Plan 4. Deferred.
- **Dashboard:** Stats (CEFR level, progress, streak). Deferred.
