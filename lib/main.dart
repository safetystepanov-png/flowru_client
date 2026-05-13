// Flowru Client V3 Concept
// Полностью новый визуальный подход: мобильный командный центр клиента.
// Логика API/авторизации/токенов сохранена, UI-слой пересобран в другом сценарии.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FlowInviteDeepLinks {
  static final AppLinks _appLinks = AppLinks();
  static String? pendingInviteToken;

  static String? parseInviteToken(Uri? uri) {
    if (uri == null) return null;

    // flowru://join/e/TOKEN
    if (uri.scheme == 'flowru' && uri.host == 'join') {
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'e') {
        final token = segments[1].trim();
        return token.isEmpty ? null : token;
      }
    }

    // https://mapi.flowru.ru/join/e/TOKEN ? ?? ???????
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == 'mapi.flowru.ru') {
      final segments = uri.pathSegments;
      if (segments.length >= 3 && segments[0] == 'join' && segments[1] == 'e') {
        final token = segments[2].trim();
        return token.isEmpty ? null : token;
      }
    }

    return null;
  }

  static Future<void> initInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      final token = parseInviteToken(uri);
      if (token != null && token.isNotEmpty) {
        pendingInviteToken = token;
      }
    } catch (_) {
      // ?? ????????? ?????? ?????????? ??-?? ?????? deep link.
    }
  }

  static Stream<Uri> get stream => _appLinks.uriLinkStream;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlowInviteDeepLinks.initInitialLink();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: FlowColors.bg,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const FlowruClientApp());
}

class FlowruClientApp extends StatelessWidget {
  const FlowruClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flowru',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: FlowColors.bg,
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSeed(
            seedColor: FlowColors.acid, brightness: Brightness.light),
        inputDecorationTheme:
            const InputDecorationTheme(border: InputBorder.none),
        textSelectionTheme: const TextSelectionThemeData(
            cursorColor: FlowColors.acid,
            selectionHandleColor: FlowColors.acid),
      ),
      home: const BootstrapScreen(),
    );
  }
}

class FlowColors {
  static const bg = Color(0xFFF2FBFC);
  static const bgDeep = Color(0xFFE0F4F6);
  static const paper = Color(0xFFFFFFFF);
  static const paper2 = Color(0xFFF8FCFD);
  static const ink = Color(0xFF0A2B47);
  static const ink2 = Color(0xFF064B64);
  static const muted = Color(0xFF29465A);
  static const soft = Color(0xFF3F647A);
  static const line = Color(0xFFE5EEF1);

  static const acid = Color(0xFFFFA51E);
  static const gold = Color(0xFFFFD700);
  static const aqua = Color(0xFF0FCAC5);
  static const violet = Color(0xFF7A4CFF);
  static const coral = Color(0xFFFF4F91);
  static const amber = Color(0xFFFFD966);
  static const green = Color(0xFF12B76A);
  static const red = Color(0xFFE85B63);
  static const blue = Color(0xFF246BFF);
  static const darkGlass = Color(0xE60A2B47);
}

// Палитра взята из файла-образца login_phone_screen.dart.
const Color kLoginMintTop = Color(0xFF0FCAC5);
const Color kLoginMintMid = Color(0xFF0BAEBB);
const Color kLoginMintBottom = Color(0xFF087D94);
const Color kLoginMintDeep = Color(0xFF064B64);
const Color kLoginAccent = Color(0xFFFFA51E);
const Color kLoginAccentSoft = Color(0xFFFFD966);
const Color kLoginCard = Color(0xD8FFFFFF);
const Color kLoginCardStrong = Color(0xF2FFFFFF);
const Color kLoginStroke = Color(0xD9FFFFFF);
const Color kLoginInk = Color(0xFF0A2B47);
const Color kLoginInkSoft = Color(0xFF29465A);
const Color kLoginBlue = Color(0xFF246BFF);
const Color kLoginPink = Color(0xFFFF4F91);
const Color kLoginViolet = Color(0xFF7A4CFF);

class AppConfig {
  static const apiBase = String.fromEnvironment(
    'FLOWRU_API_URL',
    defaultValue: 'https://mapi.flowru.ru/api/v1',
  );

  static const publicBase = String.fromEnvironment(
    'FLOWRU_PUBLIC_URL',
    defaultValue: 'https://flowru.ru',
  );
}

const String kIconEstablishmentPremium =
    'assets/icons/establishment_premium.png';
const String kIconBenefitsPremium = 'assets/icons/benefits_premium.png';
const String kIconQuestsPremium = 'assets/icons/quests_premium.png';
const String kIconHistoryPremium = 'assets/icons/history_premium.png';
const String kIconInfoPremium = 'assets/icons/info_premium.png';
const String kIconProfilePremium = 'assets/icons/profile_premium.png';
const String kIconQuestCardPremium = 'assets/icons/quest_card_premium.png';
const String kIconWalletPremium = 'assets/icons/wallet_premium.png';
const String kIconInvitePremium = 'assets/icons/invite_premium.png';

class ThemePreset {
  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color card;
  final Color text;

  const ThemePreset(
      {required this.id,
      required this.name,
      required this.primary,
      required this.secondary,
      required this.accent,
      required this.background,
      required this.card,
      required this.text});
}

class ThemeStore {
  static const current = ThemePreset(
    id: 'flowru_command_center',
    name: 'Command Center',
    primary: FlowColors.ink,
    secondary: FlowColors.aqua,
    accent: FlowColors.acid,
    background: FlowColors.bg,
    card: FlowColors.paper,
    text: FlowColors.ink,
  );

  static const futurePaidThemes = <ThemePreset>[
    ThemePreset(
        id: 'neo_black',
        name: 'Neo Black',
        primary: Color(0xFF050816),
        secondary: Color(0xFF38BDF8),
        accent: Color(0xFFA3E635),
        background: Color(0xFF080B12),
        card: Color(0xFF111827),
        text: Color(0xFFFFFFFF)),
    ThemePreset(
        id: 'soft_cafe',
        name: 'Soft Cafe',
        primary: Color(0xFF3A2118),
        secondary: Color(0xFFB45309),
        accent: Color(0xFFFBBF24),
        background: Color(0xFFFFF7ED),
        card: Color(0xFFFFFFFF),
        text: Color(0xFF1C1917)),
    ThemePreset(
        id: 'pop_club',
        name: 'Pop Club',
        primary: Color(0xFF111827),
        secondary: Color(0xFFEC4899),
        accent: Color(0xFF22C55E),
        background: Color(0xFFF8FAFC),
        card: Color(0xFFFFFFFF),
        text: Color(0xFF0F172A)),
  ];
}

class AuthStorage {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _access = 'flowru_client_access';
  static const _refresh = 'flowru_client_refresh';
  static const _biometricEnabled = 'flowru_client_biometric_enabled';
  static const _savedPhone = 'flowru_client_saved_phone';
  static const _savedPassword = 'flowru_client_saved_password';

  static Future<void> save(
      {required String access, required String refresh}) async {
    await _storage.write(key: _access, value: access);
    await _storage.write(key: _refresh, value: refresh);
  }

  static Future<void> saveAccess(String accessToken) =>
      _storage.write(key: _access, value: accessToken);
  static Future<String?> access() => _storage.read(key: _access);
  static Future<String?> refresh() => _storage.read(key: _refresh);

  static Future<void> saveRememberedCredentials(
      {required String phone, required String password}) async {
    await _storage.write(key: _savedPhone, value: phone);
    await _storage.write(key: _savedPassword, value: password);
  }

  static Future<String?> savedPhone() => _storage.read(key: _savedPhone);
  static Future<String?> savedPassword() => _storage.read(key: _savedPassword);

  static Future<void> clearRememberedCredentials() async {
    await _storage.delete(key: _savedPhone);
    await _storage.delete(key: _savedPassword);
  }

  static Future<void> setBiometricEnabled(bool value) async {
    await _storage.write(key: _biometricEnabled, value: value ? '1' : '0');
  }

  static Future<bool> biometricEnabled() async =>
      (await _storage.read(key: _biometricEnabled)) == '1';

  static Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }

  static Future<void> clearAll() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
    await _storage.delete(key: _biometricEnabled);
    await _storage.delete(key: _savedPhone);
    await _storage.delete(key: _savedPassword);
  }
}

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final biometrics = await _auth.getAvailableBiometrics();
      return supported && canCheck && biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    if (kIsWeb) return false;
    try {
      final available = await isAvailable();
      if (!available) return false;
      return await _auth.authenticate(
        localizedReason: 'Войдите в Flowru с помощью Face ID',
        options: const AuthenticationOptions(
            biometricOnly: true, stickyAuth: true, useErrorDialogs: true),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> enableAfterSuccessfulLogin() async {
    await AuthStorage.setBiometricEnabled(await isAvailable());
  }
}

class ApiError implements Exception {
  final String message;
  final int status;
  const ApiError(this.message, this.status);
}

class FlowApi {
  Future<Map<String, dynamic>> refresh(String refreshToken) => _request(
      path: '/auth/refresh',
      method: 'POST',
      body: {'refresh_token': refreshToken});
  Future<Map<String, dynamic>> me(String token) =>
      _request(path: '/client/me', token: token);
  Future<Map<String, dynamic>> login(String phone, String password) => _request(
      path: '/client/auth/login',
      method: 'POST',
      body: {'phone': phone, 'password': password});

  Future<Map<String, dynamic>> register(
      {required String phone,
      required String password,
      required String passwordConfirm,
      required String fullName}) {
    return _request(
      path: '/client/auth/register',
      method: 'POST',
      body: {
        'phone': phone,
        'password': password,
        'password_confirm': passwordConfirm,
        'full_name': fullName
      },
    );
  }

  Future<Map<String, dynamic>> home(String token, {int? establishmentId}) {
    return _request(
        path: '/client/home',
        token: token,
        query: establishmentId == null
            ? null
            : {'establishment_id': '$establishmentId'});
  }

  Future<Map<String, dynamic>> clientQr(String token) =>
      _request(path: '/client/qr', token: token);

  Future<Map<String, dynamic>> joinEstablishment(
      String token, String inviteToken) {
    return _request(
        path: '/client/establishments/join',
        method: 'POST',
        token: token,
        body: {'invite_token': inviteToken});
  }

  Future<Map<String, dynamic>> history(String token, int establishmentId) =>
      _request(
          path: '/client/history',
          token: token,
          query: {'establishment_id': '$establishmentId'});
  Future<Map<String, dynamic>> offers(String token, int establishmentId) =>
      _request(
          path: '/client/offers',
          token: token,
          query: {'establishment_id': '$establishmentId'});
  Future<Map<String, dynamic>> establishmentProfile(
          String token, int establishmentId) =>
      _request(
          path: '/client/establishment-profile',
          token: token,
          query: {'establishment_id': '$establishmentId'});
  Future<Map<String, dynamic>> rewards(String token, int establishmentId) =>
      _request(
          path: '/client/rewards',
          token: token,
          query: {'establishment_id': '$establishmentId'});

  Future<Map<String, dynamic>> updateBirthDate(
      String token, int establishmentId, String birthDate) async {
    final body = {'establishment_id': establishmentId, 'birth_date': birthDate};
    final query = {'establishment_id': '$establishmentId'};
    ApiError? lastError;
    for (final path in const [
      '/client/profile/birth-date',
      '/client/birth-date',
      '/client/birthday',
    ]) {
      try {
        return await _request(
            path: path, method: 'POST', token: token, body: body, query: query);
      } on ApiError catch (e) {
        lastError = e;
        if (e.status != 404 && e.status != 405) rethrow;
      }
    }
    throw lastError ??
        const ApiError(
            'Сервер пока не поддерживает сохранение даты рождения', 404);
  }

  Future<Map<String, dynamic>> generateReferralLink(
      String token, int establishmentId) async {
    final query = {'establishment_id': '$establishmentId'};
    ApiError? lastError;
    for (final path in const [
      '/client/referral/link',
      '/client/referral',
      '/client/referrals/link',
    ]) {
      try {
        return await _request(
            path: path, method: 'POST', token: token, query: query);
      } on ApiError catch (e) {
        lastError = e;
        if (e.status != 404 && e.status != 405) rethrow;
      }
    }
    throw lastError ??
        const ApiError('Сервер пока не вернул реферальную ссылку', 404);
  }

  Future<Map<String, dynamic>> joinDraw(
      String token, int runId, int establishmentId) {
    return _request(
        path: '/client/draws/$runId/join',
        method: 'POST',
        token: token,
        query: {'establishment_id': '$establishmentId'});
  }

  Future<Map<String, dynamic>> _request(
      {required String path,
      String method = 'GET',
      String? token,
      Map<String, dynamic>? body,
      Map<String, String>? query}) async {
    final uri =
        Uri.parse('${AppConfig.apiBase}$path').replace(queryParameters: query);
    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null && token.isNotEmpty)
      headers['Authorization'] = 'Bearer $token';
    if (body != null) headers['Content-Type'] = 'application/json';

    late http.Response res;
    try {
      if (method == 'POST') {
        res = await http
            .post(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 18));
      } else {
        res = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 18));
      }
    } on TimeoutException {
      throw const ApiError('Сервер отвечает слишком долго', 408);
    } catch (_) {
      throw const ApiError('Нет соединения с сервером', 0);
    }

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {
      data = {'detail': res.body};
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw ApiError(
        readableApiError(data['detail']) ?? 'Ошибка сервера', res.statusCode);
  }
}

String? readableApiError(dynamic detail) {
  final raw = detail?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  if (raw.contains('at least 6 characters') || raw.contains('min_length'))
    return 'Пароль должен быть не короче 6 символов';
  if (raw.contains('Invalid token')) return 'Сессия устарела. Войдите снова';
  if (raw.contains('Not authenticated')) return 'Нужно войти в приложение';
  if (raw.contains('Неверный телефон или пароль'))
    return 'Неверный телефон или пароль';
  if (raw.length > 140 || raw.startsWith('{') || raw.startsWith('['))
    return 'Проверьте введённые данные';
  return raw;
}

Future<void> openExternalUrl(BuildContext context, String? url,
    {String emptyMessage = 'Ссылка не указана'}) async {
  final raw = url?.trim() ?? '';
  if (raw.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(emptyMessage)));
    return;
  }

  var fixed = raw;
  if (fixed.startsWith('/')) {
    fixed = '${AppConfig.publicBase}$fixed';
  } else if (!fixed.startsWith('http://') &&
      !fixed.startsWith('https://') &&
      !fixed.startsWith('tg://') &&
      !fixed.startsWith('mailto:') &&
      !fixed.startsWith('tel:')) {
    fixed = 'https://$fixed';
  }

  final uri = Uri.tryParse(fixed);
  if (uri == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Некорректная ссылка')));
    return;
  }

  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть ссылку')));
  }
}

DateTime? parseBirthDate(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  final cleaned = raw.replaceAll('T', ' ');
  final datePart = cleaned.split(' ').first;
  final parts = datePart.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  try {
    return DateTime(y, m, d);
  } catch (_) {
    return null;
  }
}

String formatClientDateTime(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return '';
  final cleaned = raw.replaceAll('T', ' ');
  final datePart = cleaned.split(' ').first;
  final timePart = cleaned.contains(' ') ? cleaned.split(' ')[1] : '';
  final d = datePart.split('-');
  if (d.length != 3) return raw;
  final day = d[2].padLeft(2, '0');
  final month = d[1].padLeft(2, '0');
  final year = d[0];
  var time = '';
  if (timePart.isNotEmpty) {
    final t = timePart.split(':');
    if (t.length >= 2) time = '${t[0].padLeft(2, '0')}:${t[1].padLeft(2, '0')}';
  }
  return time.isEmpty ? '$day.$month.$year' : '$day.$month.$year в $time';
}

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});
  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 650));
    final token = await AuthStorage.access();
    final refreshToken = await AuthStorage.refresh();
    final biometricEnabled = await AuthStorage.biometricEnabled();
    final biometricAvailable = await BiometricService.isAvailable();
    if (!mounted) return;

    final hasSession = (token != null && token.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);

    if (!hasSession) {
      Navigator.of(context).pushReplacement(appRoute(const AuthScreen()));
      return;
    }

    if (!kIsWeb && biometricEnabled && biometricAvailable) {
      Navigator.of(context)
          .pushReplacement(appRoute(const BiometricUnlockScreen()));
      return;
    }

    Navigator.of(context).pushReplacement(appRoute(const ClientShell()));
  }

  @override
  Widget build(BuildContext context) {
    return const AppFrame(
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: SplashMark())));
  }
}

class SplashMark extends StatefulWidget {
  const SplashMark({super.key});
  @override
  State<SplashMark> createState() => _SplashMarkState();
}

class _SplashMarkState extends State<SplashMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController c;

  @override
  void initState() {
    super.initState();
    c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final v = Curves.easeOutCubic.transform(c.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - v)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                FlowMark(size: 82),
                SizedBox(height: 18),
                Text('Flowru',
                    style: TextStyle(
                        color: FlowColors.ink,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.6)),
                SizedBox(height: 5),
                Text('client command center',
                    style: TextStyle(
                        color: FlowColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BiometricUnlockScreen extends StatefulWidget {
  const BiometricUnlockScreen({super.key});
  @override
  State<BiometricUnlockScreen> createState() => _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends State<BiometricUnlockScreen> {
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), unlock);
  }

  Future<void> unlock() async {
    setState(() {
      loading = true;
      error = null;
    });
    final ok = await BiometricService.authenticate();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(appRoute(const ClientShell()));
      return;
    }
    setState(() {
      loading = false;
      error = 'Не удалось войти через Face ID';
    });
  }

  Future<void> usePassword() async {
    await AuthStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(appRoute(const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(22),
                  radius: 34,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FlowMark(size: 78),
                      const SizedBox(height: 22),
                      const Text('Быстрый вход',
                          style: TextStyle(
                              color: FlowColors.ink,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1)),
                      const SizedBox(height: 6),
                      const Text(
                          'Подтвердите вход, чтобы открыть вашу карту Flowru.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: FlowColors.muted,
                              height: 1.4,
                              fontWeight: FontWeight.w600)),
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        ErrorBanner(text: error!)
                      ],
                      const SizedBox(height: 22),
                      PrimaryButton(
                          text:
                              loading ? 'Проверяем...' : 'Войти через Face ID',
                          icon: Icons.face_rounded,
                          onTap: loading ? null : unlock),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: usePassword,
                          child: const Text('Войти по телефону и паролю',
                              style: TextStyle(
                                  color: FlowColors.ink,
                                  fontWeight: FontWeight.w900))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final api = FlowApi();
  bool isRegister = false;
  bool loading = false;
  bool showLoginPassword = false;
  bool showRegPassword = false;
  bool showRegConfirm = false;
  bool rememberCredentials = true;
  bool biometricAvailable = false;
  bool biometricEnabled = false;
  bool biometricLoading = false;
  String? error;

  final loginPhone = TextEditingController();
  final loginPassword = TextEditingController();
  final regName = TextEditingController();
  final regPhone = TextEditingController();
  final regPassword = TextEditingController();
  final regConfirm = TextEditingController();

  late final AnimationController introController;
  late final AnimationController ambientController;
  late final AnimationController pulseController;
  late final Animation<double> fadeAnimation;
  late final Animation<Offset> slideAnimation;
  late final Animation<double> pulseAnimation;

  @override
  void initState() {
    super.initState();
    introController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    ambientController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 10000))
      ..repeat();
    pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    fadeAnimation =
        CurvedAnimation(parent: introController, curve: Curves.easeOutCubic);
    slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
            CurvedAnimation(
                parent: introController, curve: Curves.easeOutCubic));
    pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: pulseController, curve: Curves.easeInOut));
    _initSavedState();
  }

  Future<void> _initSavedState() async {
    final savedPhone = await AuthStorage.savedPhone();
    final savedPassword = await AuthStorage.savedPassword();
    final biomEnabled = await AuthStorage.biometricEnabled();
    final biomAvailable = await BiometricService.isAvailable();

    if (!mounted) return;
    setState(() {
      if ((savedPhone ?? '').trim().isNotEmpty)
        loginPhone.text = savedPhone!.trim();
      if ((savedPassword ?? '').isNotEmpty) loginPassword.text = savedPassword!;
      rememberCredentials =
          (savedPhone != null && savedPhone.trim().isNotEmpty) ||
              (savedPassword != null && savedPassword.isNotEmpty);
      biometricEnabled = biomEnabled;
      biometricAvailable = biomAvailable;
    });
  }

  @override
  void dispose() {
    loginPhone.dispose();
    loginPassword.dispose();
    regName.dispose();
    regPhone.dispose();
    regPassword.dispose();
    regConfirm.dispose();
    introController.dispose();
    ambientController.dispose();
    pulseController.dispose();
    super.dispose();
  }

  Future<void> submitLogin() async {
    if (loginPhone.text.trim().isEmpty) {
      setState(() => error = 'Введите номер телефона');
      return;
    }
    if (loginPassword.text.isEmpty) {
      setState(() => error = 'Введите пароль');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await api.login(loginPhone.text.trim(), loginPassword.text);
      await saveAndOpen(data,
          phone: loginPhone.text.trim(), password: loginPassword.text);
      TextInput.finishAutofillContext(shouldSave: true);
    } on ApiError catch (e) {
      setState(() => error = e.message);
    } catch (_) {
      setState(() => error = 'Не удалось войти');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> submitRegister() async {
    if (regName.text.trim().isEmpty) {
      setState(() => error = 'Введите имя');
      return;
    }
    if (regPhone.text.trim().isEmpty) {
      setState(() => error = 'Введите номер телефона');
      return;
    }
    if (regPassword.text.isEmpty) {
      setState(() => error = 'Введите пароль');
      return;
    }
    if (regPassword.text != regConfirm.text) {
      setState(() => error = 'Пароли не совпадают');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await api.register(
          phone: regPhone.text.trim(),
          password: regPassword.text,
          passwordConfirm: regConfirm.text,
          fullName: regName.text.trim());
      await saveAndOpen(data,
          phone: regPhone.text.trim(), password: regPassword.text);
      TextInput.finishAutofillContext(shouldSave: true);
    } on ApiError catch (e) {
      setState(() => error = e.message);
    } catch (_) {
      setState(() => error = 'Не удалось зарегистрироваться');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> saveAndOpen(Map<String, dynamic> data,
      {required String phone, required String password}) async {
    final access = data['access_token']?.toString() ?? '';
    final refresh = data['refresh_token']?.toString() ?? '';
    if (access.isEmpty || refresh.isEmpty)
      throw const ApiError('Сервер не вернул токены', 500);
    await AuthStorage.save(access: access, refresh: refresh);
    if (rememberCredentials) {
      await AuthStorage.saveRememberedCredentials(
          phone: phone, password: password);
    } else {
      await AuthStorage.clearRememberedCredentials();
    }
    final canUseBiometric = await BiometricService.isAvailable();
    if (canUseBiometric && rememberCredentials) {
      await AuthStorage.setBiometricEnabled(true);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(appRoute(const ClientShell()));
  }

  Future<void> _loginWithBiometric() async {
    if (biometricLoading || loading) return;
    final savedPhone = await AuthStorage.savedPhone();
    final savedPassword = await AuthStorage.savedPassword();
    if ((savedPhone ?? '').trim().isEmpty || (savedPassword ?? '').isEmpty) {
      if (!mounted) return;
      setState(() => error = 'Сначала войдите один раз с телефоном и паролем');
      return;
    }
    setState(() {
      biometricLoading = true;
      error = null;
    });
    try {
      final ok = await BiometricService.authenticate();
      if (!ok) {
        if (mounted) setState(() => biometricLoading = false);
        return;
      }
      final data = await api.login(savedPhone!.trim(), savedPassword!);
      await saveAndOpen(data,
          phone: savedPhone.trim(), password: savedPassword);
    } on ApiError catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = 'Не удалось войти по биометрии');
    } finally {
      if (mounted) setState(() => biometricLoading = false);
    }
  }

  Widget _softBlob(
      {required double width,
      required double height,
      required List<Color> colors}) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width),
              gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
        ),
      ),
    );
  }

  Widget _background() {
    return AnimatedBuilder(
      animation: Listenable.merge([ambientController, pulseController]),
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        final t = ambientController.value;
        final p = pulseController.value;
        final shiftA = math.sin(t * math.pi * 2) * 22;
        final shiftB = math.cos(t * math.pi * 2) * 18;

        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF087AA2),
                    Color(0xFF0CBBC5),
                    Color(0xFF66E2C4),
                    Color(0xFF073E63)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.36, 0.66, 1.0],
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.82, -0.88),
                    radius: 0.92,
                    colors: [
                      Colors.white.withOpacity(0.42),
                      Colors.white.withOpacity(0.08),
                      Colors.transparent
                    ],
                    stops: const [0.0, 0.36, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
                top: -120 + shiftA,
                right: -80 + shiftB,
                child: _softBlob(width: 360, height: 360, colors: [
                  Colors.white.withOpacity(0.30),
                  kLoginAccentSoft.withOpacity(0.16)
                ])),
            Positioned(
                left: -130 - shiftB,
                bottom: -40 + shiftA,
                child: _softBlob(width: 310, height: 310, colors: [
                  kLoginBlue.withOpacity(0.24),
                  Colors.white.withOpacity(0.10)
                ])),
            Positioned(
                top: size.height * 0.36 + shiftB,
                right: -120,
                child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.13), width: 2)))),
            Positioned(
                left: -58,
                bottom: size.height * 0.13,
                child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.34), width: 2)))),
            ...List.generate(22, (i) {
              final angle = (i * 1.73) + t * math.pi * 0.32;
              final x = (math.sin(i * 19.7) * 0.5 + 0.5) * size.width;
              final y = (math.cos(i * 13.1) * 0.5 + 0.5) * size.height;
              final driftX = math.cos(angle) * (8 + i % 5);
              final driftY = math.sin(angle) * (8 + i % 6);
              final dotSize = 2.0 + (i % 4) * 1.15;
              final opacity = (0.22 + 0.18 * math.sin(p * math.pi * 2 + i))
                  .clamp(0.08, 0.42);
              return Positioned(
                left: x + driftX,
                top: y + driftY,
                child: IgnorePointer(
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (i % 3 == 0 ? kLoginAccentSoft : Colors.white)
                          .withOpacity(opacity),
                      boxShadow: [
                        BoxShadow(
                            color:
                                (i % 3 == 0 ? kLoginAccentSoft : Colors.white)
                                    .withOpacity(opacity),
                            blurRadius: 10,
                            spreadRadius: 1)
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _orbitalLogo(double logoSize,
      {required bool isVerySmall, required bool isSmallScreen}) {
    return AnimatedBuilder(
      animation: Listenable.merge([ambientController, pulseController]),
      builder: (context, child) {
        final orbitSize = logoSize * 1.58;
        final centerSize = logoSize * 0.82;
        final badgeSize = logoSize * 0.58;

        return SizedBox(
          width: orbitSize,
          height: orbitSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: pulseAnimation.value,
                child: Container(
                  width: centerSize,
                  height: centerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: kLoginAccent.withOpacity(0.40),
                          blurRadius: isVerySmall
                              ? 26
                              : isSmallScreen
                                  ? 34
                                  : 46,
                          spreadRadius: isVerySmall
                              ? 4
                              : isSmallScreen
                                  ? 7
                                  : 10),
                      BoxShadow(
                          color: Colors.white.withOpacity(0.35),
                          blurRadius: 22,
                          spreadRadius: 2),
                    ],
                  ),
                ),
              ),
              Transform.rotate(
                angle: ambientController.value * math.pi * 2,
                child: Container(
                  width: orbitSize * 0.94,
                  height: orbitSize * 0.94,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: kLoginAccent.withOpacity(0.28), width: 1.5)),
                ),
              ),
              CustomPaint(
                  size: Size.square(orbitSize),
                  painter:
                      _LoginOrbitPainter(progress: ambientController.value)),
              Container(
                width: centerSize,
                height: centerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(colors: [
                    Color(0xFFFFEE7B),
                    Color(0xFFFFBD2E),
                    Color(0xFFFFA51E)
                  ], stops: [
                    0.0,
                    0.68,
                    1.0
                  ]),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.62), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                        color: kLoginAccent.withOpacity(0.42),
                        blurRadius: 24,
                        offset: const Offset(0, 10))
                  ],
                ),
              ),
              Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04)),
                child: Center(
                  child: Image.asset('assets/images/flowru_logo.png',
                      width: badgeSize * 0.86,
                      height: badgeSize * 0.86,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    Iterable<String>? autofillHints,
    TextInputAction? textInputAction,
    bool enableSuggestions = true,
    bool autocorrect = false,
    ValueChanged<String>? onSubmitted,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 24),
        color: Colors.white.withOpacity(0.72),
        border: Border.all(color: Colors.white.withOpacity(0.92), width: 1.35),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0A5270).withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8)),
          BoxShadow(
              color: Colors.white.withOpacity(0.75),
              blurRadius: 3,
              offset: const Offset(0, -1))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            autofillHints: autofillHints,
            textInputAction: textInputAction,
            enableSuggestions: enableSuggestions,
            autocorrect: autocorrect,
            onSubmitted: onSubmitted,
            style: TextStyle(
                color: kLoginInk,
                fontSize: isSmallScreen ? 13 : 16,
                fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Icon(icon,
                      color: kLoginInkSoft, size: isSmallScreen ? 18 : 22)
                  : null,
              suffixIcon: suffixIcon,
              labelText: label,
              labelStyle: TextStyle(
                  color: kLoginInkSoft.withOpacity(0.88),
                  fontWeight: FontWeight.w700,
                  fontSize: isSmallScreen ? 12 : 15),
              floatingLabelStyle: const TextStyle(
                  color: kLoginViolet, fontWeight: FontWeight.w800),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 22,
                  vertical: isSmallScreen ? 8 : 19),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassButton(
      {required VoidCallback? onPressed,
      required String text,
      required bool isLoading}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 25 : 31),
        gradient: const LinearGradient(
            colors: [Color(0xFF10C3C5), Color(0xFF0A7EA0), Color(0xFF6B57FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        border: Border.all(color: Colors.white.withOpacity(0.72), width: 1.1),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0A7EA0).withOpacity(0.24),
              blurRadius: 22,
              offset: const Offset(0, 10)),
          BoxShadow(
              color: kLoginAccentSoft.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 6))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isSmallScreen ? 25 : 31),
          child: Container(
            height: isSmallScreen ? 40.0 : 60.0,
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: isSmallScreen ? 18 : 24,
                    height: isSmallScreen ? 18 : 24,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white))
                : Text(text,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2)),
          ),
        ),
      ),
    );
  }

  Widget _outlineGlassButton(
      {required String text, required VoidCallback onTap}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.34),
          side: const BorderSide(color: kLoginViolet, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 26 : 30)),
          padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 8 : 17,
              horizontal: isSmallScreen ? 12 : 24),
          shadowColor: kLoginViolet.withOpacity(0.18),
        ),
        child: Text(text,
            style: TextStyle(
                color: kLoginViolet,
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: const Color(0xFFFFF4F2).withOpacity(0.98),
          border: Border.all(color: const Color(0xFFFFD7D0))),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Color(0xFFE85B63), size: 19),
        const SizedBox(width: 9),
        Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Color(0xFFE85B63), fontWeight: FontWeight.w800)))
      ]),
    );
  }

  Widget _authModeSwitch({required bool isSmallScreen}) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.50),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.70))),
      child: Row(children: [
        Expanded(
            child: _authModeItem(
                'Вход',
                !isRegister,
                () => setState(() {
                      isRegister = false;
                      error = null;
                    }),
                isSmallScreen)),
        Expanded(
            child: _authModeItem(
                'Регистрация',
                isRegister,
                () => setState(() {
                      isRegister = true;
                      error = null;
                    }),
                isSmallScreen))
      ]),
    );
  }

  Widget _authModeItem(
      String text, bool active, VoidCallback onTap, bool isSmallScreen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: isSmallScreen ? 30 : 46,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: active
                  ? const LinearGradient(colors: [
                      Color(0xFF10C3C5),
                      Color(0xFF0A7EA0),
                      Color(0xFF6B57FF)
                    ])
                  : null,
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: kLoginBlue.withOpacity(0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 8))
                    ]
                  : null),
          child: Center(
              child: Text(text,
                  style: TextStyle(
                      color: active ? Colors.white : kLoginInkSoft,
                      fontWeight: FontWeight.w900,
                      fontSize: isSmallScreen ? 12 : 14))),
        ),
      ),
    );
  }

  Widget _rememberRow(bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () =>
                setState(() => rememberCredentials = !rememberCredentials),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: rememberCredentials
                          ? const LinearGradient(colors: [
                              Color(0xFF10C3C5),
                              Color(0xFF0A7EA0),
                              Color(0xFF6B57FF)
                            ])
                          : null,
                      color: rememberCredentials
                          ? null
                          : Colors.white.withOpacity(0.75),
                      border: Border.all(
                          color: rememberCredentials
                              ? Colors.transparent
                              : kLoginInkSoft.withOpacity(0.32)),
                    ),
                    child: rememberCredentials
                        ? const Icon(Icons.check_rounded,
                            size: 15, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text('Запомнить логин и пароль',
                          style: TextStyle(
                              color: kLoginInkSoft,
                              fontSize: isSmallScreen ? 12 : 13,
                              fontWeight: FontWeight.w800))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _biometricButton(bool isSmallScreen) {
    // Кнопку Face ID / Touch ID на экране логина скрываем.
    // Логику биометрии не трогаем: автологин после сохранения по-прежнему работает.
    return const SizedBox.shrink();
  }

  Widget _loginFields(double gapMedium, bool isVerySmall, bool isSmallScreen) {
    return AutofillGroup(
      key: const ValueKey('login-fields'),
      child: Column(
        children: [
          _buildGlassInput(
              controller: loginPhone,
              label: 'Телефон',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              autofillHints: const [
                AutofillHints.telephoneNumber,
                AutofillHints.username
              ],
              textInputAction: TextInputAction.next,
              enableSuggestions: false,
              autocorrect: false),
          SizedBox(height: isVerySmall ? 8 : gapMedium),
          _buildGlassInput(
            controller: loginPassword,
            label: 'Пароль',
            icon: Icons.lock_outline_rounded,
            obscureText: !showLoginPassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            enableSuggestions: false,
            autocorrect: false,
            onSubmitted: (_) => loading ? null : submitLogin(),
            suffixIcon: IconButton(
                icon: Icon(
                    showLoginPassword ? Icons.visibility_off : Icons.visibility,
                    color: kLoginInkSoft,
                    size: isVerySmall
                        ? 16
                        : isSmallScreen
                            ? 18
                            : 20),
                onPressed: () =>
                    setState(() => showLoginPassword = !showLoginPassword),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints()),
          ),
        ],
      ),
    );
  }

  Widget _registerFields(
      double gapMedium, bool isVerySmall, bool isSmallScreen) {
    return AutofillGroup(
      key: const ValueKey('register-fields'),
      child: Column(
        children: [
          _buildGlassInput(
              controller: regName,
              label: 'Имя',
              icon: Icons.person_outline_rounded,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next),
          SizedBox(height: isVerySmall ? 8 : gapMedium),
          _buildGlassInput(
              controller: regPhone,
              label: 'Телефон',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              autofillHints: const [
                AutofillHints.telephoneNumber,
                AutofillHints.username
              ],
              textInputAction: TextInputAction.next,
              enableSuggestions: false,
              autocorrect: false),
          SizedBox(height: isVerySmall ? 8 : gapMedium),
          _buildGlassInput(
              controller: regPassword,
              label: 'Пароль',
              icon: Icons.lock_outline_rounded,
              obscureText: !showRegPassword,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              enableSuggestions: false,
              autocorrect: false,
              suffixIcon: IconButton(
                  icon: Icon(
                      showRegPassword ? Icons.visibility_off : Icons.visibility,
                      color: kLoginInkSoft,
                      size: isVerySmall
                          ? 16
                          : isSmallScreen
                              ? 18
                              : 20),
                  onPressed: () =>
                      setState(() => showRegPassword = !showRegPassword),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints())),
          SizedBox(height: isVerySmall ? 8 : gapMedium),
          _buildGlassInput(
              controller: regConfirm,
              label: 'Повторите пароль',
              icon: Icons.verified_outlined,
              obscureText: !showRegConfirm,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              enableSuggestions: false,
              autocorrect: false,
              onSubmitted: (_) => loading ? null : submitRegister(),
              suffixIcon: IconButton(
                  icon: Icon(
                      showRegConfirm ? Icons.visibility_off : Icons.visibility,
                      color: kLoginInkSoft,
                      size: isVerySmall
                          ? 16
                          : isSmallScreen
                              ? 18
                              : 20),
                  onPressed: () =>
                      setState(() => showRegConfirm = !showRegConfirm),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isVerySmall = screenWidth < 360 || screenHeight < 640;
    final isSmallScreen = screenWidth < 400 || screenHeight < 700;
    final isMediumScreen = screenWidth >= 400 && screenWidth < 600;

    final cardWidth = isVerySmall
        ? screenWidth * 0.94
        : isSmallScreen
            ? screenWidth * 0.92
            : isMediumScreen
                ? screenWidth * 0.86
                : 500.0;
    final horizontalPadding = isVerySmall
        ? 10.0
        : isSmallScreen
            ? 12.0
            : 24.0;
    final cardPadding = isVerySmall
        ? 7.0
        : isSmallScreen
            ? 8.0
            : 20.0;
    final innerPadding = isVerySmall
        ? 7.0
        : isSmallScreen
            ? 8.0
            : 20.0;
    final titleSize = isVerySmall
        ? 17.0
        : isSmallScreen
            ? 18.0
            : 30.0;
    final subtitleSize = isVerySmall
        ? 9.2
        : isSmallScreen
            ? 10.0
            : 14.0;
    final logoSize = isVerySmall
        ? 38.0
        : isSmallScreen
            ? 44.0
            : 88.0;
    final gapSmall = isVerySmall
        ? 2.0
        : isSmallScreen
            ? 3.0
            : 8.0;
    final gapMedium = isVerySmall
        ? 3.0
        : isSmallScreen
            ? 5.0
            : 14.0;
    final gapLarge = isVerySmall
        ? 6.0
        : isSmallScreen
            ? 8.0
            : 24.0;

    return Scaffold(
      backgroundColor: kLoginMintTop,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(children: [
          _background(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: Container(
                      width: cardWidth,
                      constraints: BoxConstraints(
                          maxWidth: 500,
                          minWidth: (screenWidth * 0.85).clamp(0.0, 500.0)),
                      padding: EdgeInsets.fromLTRB(cardPadding, cardPadding,
                          cardPadding, cardPadding + 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(isVerySmall
                            ? 26
                            : isSmallScreen
                                ? 32
                                : 44),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.13),
                              blurRadius: isVerySmall
                                  ? 18
                                  : isSmallScreen
                                      ? 24
                                      : 38,
                              offset: Offset(
                                  0,
                                  isVerySmall
                                      ? 7
                                      : isSmallScreen
                                          ? 12
                                          : 18)),
                          BoxShadow(
                              color: Colors.white.withOpacity(0.26),
                              blurRadius: 18,
                              spreadRadius: 1,
                              offset: const Offset(0, -2)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isVerySmall
                            ? 26
                            : isSmallScreen
                                ? 32
                                : 44),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: EdgeInsets.all(innerPadding),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isVerySmall
                                  ? 26
                                  : isSmallScreen
                                      ? 32
                                      : 44),
                              gradient: LinearGradient(
                                  colors: [
                                    kLoginCardStrong,
                                    kLoginCard,
                                    Colors.white.withOpacity(0.78)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                              border:
                                  Border.all(color: kLoginStroke, width: 1.2),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _orbitalLogo(logoSize,
                                    isVerySmall: isVerySmall,
                                    isSmallScreen: isSmallScreen),
                                SizedBox(height: isVerySmall ? 2 : gapMedium),
                                Text(
                                    isRegister
                                        ? 'Регистрация гостя'
                                        : 'Вход гостя',
                                    style: TextStyle(
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.w900,
                                        color: kLoginInk,
                                        letterSpacing: -0.8,
                                        height: 1.1),
                                    textAlign: TextAlign.center),
                                SizedBox(height: isVerySmall ? 2 : gapSmall),
                                Text(
                                    isRegister
                                        ? 'Создайте аккаунт, чтобы подключить\nкарты, бонусы и предложения.'
                                        : 'Введите номер телефона и пароль,\nчтобы открыть карту гостя.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: subtitleSize,
                                        fontWeight: FontWeight.w700,
                                        color: kLoginInkSoft,
                                        height: 1.3)),
                                SizedBox(height: isVerySmall ? 7 : gapMedium),
                                _authModeSwitch(isSmallScreen: isSmallScreen),
                                SizedBox(height: isVerySmall ? 8 : gapLarge),
                                AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 240),
                                    child: isRegister
                                        ? _registerFields(gapMedium,
                                            isVerySmall, isSmallScreen)
                                        : _loginFields(gapMedium, isVerySmall,
                                            isSmallScreen)),
                                if (!isRegister) ...[
                                  SizedBox(height: isVerySmall ? 5 : gapMedium),
                                  _rememberRow(isSmallScreen),
                                ],
                                if (error != null) ...[
                                  SizedBox(height: isVerySmall ? 5 : gapMedium),
                                  _errorBox(error!),
                                ],
                                SizedBox(height: isVerySmall ? 7 : gapLarge),
                                _glassButton(
                                    onPressed: loading
                                        ? null
                                        : (isRegister
                                            ? submitRegister
                                            : submitLogin),
                                    text: isRegister
                                        ? 'Создать аккаунт'
                                        : 'Войти',
                                    isLoading: loading),
                                if (!isRegister) ...[
                                  SizedBox(height: isVerySmall ? 5 : 8),
                                  _biometricButton(isSmallScreen),
                                ],
                                SizedBox(height: isVerySmall ? 4 : 8),
                                _outlineGlassButton(
                                    text: isRegister
                                        ? 'Уже есть аккаунт'
                                        : 'Зарегистрироваться',
                                    onTap: () => setState(() {
                                          isRegister = !isRegister;
                                          error = null;
                                        })),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _LoginOrbitPainter extends CustomPainter {
  _LoginOrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.39;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = Colors.white.withOpacity(0.58);

    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = kLoginAccentSoft.withOpacity(0.74);

    canvas.drawCircle(center, baseRadius, ringPaint);
    canvas.drawCircle(center, baseRadius * 1.16,
        ringPaint..color = Colors.white.withOpacity(0.32));

    final rectA = Rect.fromCircle(center: center, radius: baseRadius * 1.16);
    final rectB = Rect.fromCircle(center: center, radius: baseRadius * 0.98);
    canvas.drawArc(rectA, -math.pi * 0.82 + progress * math.pi * 2,
        math.pi * 0.38, false, accentPaint);
    canvas.drawArc(
        rectB,
        math.pi * 0.18 + progress * math.pi * 2,
        math.pi * 0.24,
        false,
        accentPaint..color = Colors.white.withOpacity(0.66));

    for (int i = 0; i < 4; i++) {
      final radius = i.isEven ? baseRadius * 1.16 : baseRadius;
      final angle = progress * math.pi * 2 + i * math.pi * 0.72;
      final dot = Offset(center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius);
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = i.isEven
            ? kLoginAccentSoft.withOpacity(0.92)
            : Colors.white.withOpacity(0.85);
      canvas.drawCircle(dot, i.isEven ? 2.6 : 3.2, dotPaint);
      canvas.drawCircle(
        dot,
        i.isEven ? 4.7 : 5.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.white.withOpacity(0.50),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LoginOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});
  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  final api = FlowApi();
  bool loading = true;
  bool historyLoading = false;
  bool joiningDraw = false;
  bool joiningInvite = false;
  StreamSubscription<Uri>? inviteDeepLinkSub;
  String? error;
  int tab = 0;

  Map<String, dynamic> home = {};
  Map<String, dynamic> offers = {};
  Map<String, dynamic> establishmentProfile = {};
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> establishments = [];
  int? selectedEstablishmentId;

  Map<int, Map<String, dynamic>> homeByEstablishment = {};
  Map<int, Map<String, dynamic>> offersByEstablishment = {};
  Map<int, Map<String, dynamic>> profileByEstablishment = {};
  Map<int, List<Map<String, dynamic>>> historyByEstablishment = {};

  String flowruQrPayload = '';
  DateTime? flowruQrExpiresAt;
  bool flowruQrLoading = false;
  Timer? flowruQrTimer;

  List<Map<String, dynamic>> get combinedHistory {
    final all = <Map<String, dynamic>>[];
    historyByEstablishment.forEach((estId, items) {
      final estName = establishmentNameById(estId);
      for (final item in items) {
        final copy = Map<String, dynamic>.from(item);
        copy['establishment_id'] ??= estId;
        copy['establishment_name'] ??= estName;
        all.add(copy);
      }
    });
    if (all.isEmpty) return history;
    all.sort((a, b) => (b['created_at'] ?? b['date'] ?? b['timestamp'] ?? '')
        .toString()
        .compareTo(
            (a['created_at'] ?? a['date'] ?? a['timestamp'] ?? '').toString()));
    return all;
  }

  String establishmentNameById(int id) {
    for (final e in establishments) {
      if (intOrNull(e['establishment_id']) == id) {
        return nonEmpty(e['establishment_name']) ??
            nonEmpty(e['name']) ??
            'Заведение';
      }
    }
    final h = map(homeByEstablishment[id]);
    return nonEmpty(map(h['establishment'])['name']) ?? 'Заведение';
  }

  List<PromoItem> _promoItemsFromData(
      {required Map<String, dynamic> sourceHome,
      required Map<String, dynamic> sourceOffers,
      required String estName,
      bool flowruOnly = false,
      bool establishmentOnly = false}) {
    final result = <PromoItem>[];
    final data = sourceOffers.isNotEmpty ? sourceOffers : sourceHome;

    final devRaw = <Map<String, dynamic>>[
      ...mapList(data['dev_banners']),
      ...mapList(data['global_banners']),
      ...mapList(sourceHome['dev_banners']),
      ...mapList(sourceHome['global_banners']),
    ];
    for (final e in devRaw.take(20)) {
      if (establishmentOnly) continue;
      result.add(PromoItem(
        tag: 'Flowru',
        title: nonEmpty(e['title']) ?? 'Новость от Flowru',
        subtitle: nonEmpty(e['short_text']) ??
            nonEmpty(e['subtitle']) ??
            nonEmpty(e['description']) ??
            'Важная информация для клиентов.',
        icon: Icons.campaign_rounded,
        color: FlowColors.blue,
        imageUrl: extractImageUrl(e),
        rawData: e,
      ));
    }

    if (flowruOnly) return result;

    final banner = map(data['draw_banner']).isNotEmpty
        ? map(data['draw_banner'])
        : map(sourceHome['draw_banner']);
    final draws = mapList(data['draws']).isNotEmpty
        ? mapList(data['draws'])
        : mapList(sourceHome['draws']);
    final drawItems = <Map<String, dynamic>>[];
    if (banner.isNotEmpty) drawItems.add(banner);
    drawItems.addAll(draws);
    final seenDraws = <String>{};
    for (final e in drawItems.take(10)) {
      final key =
          (e['run_id'] ?? e['id'] ?? e['title'] ?? e.hashCode).toString();
      if (!seenDraws.add(key)) continue;
      result.add(PromoItem(
        tag: 'розыгрыш',
        title: '$estName · ${nonEmpty(e['title']) ?? 'Розыгрыш'}',
        subtitle: nonEmpty(e['prize_text']) ??
            nonEmpty(e['description']) ??
            'Откройте подробности розыгрыша.',
        icon: Icons.celebration_rounded,
        color: kLoginViolet,
        imageUrl: extractImageUrl(e),
        rawData: {...e, 'establishment_name': estName},
        isRaffle: true,
      ));
    }

    final banners = mapList(data['banners']);
    for (final e in banners.take(20)) {
      result.add(PromoItem(
        tag: e['tag']?.toString() ?? 'акция',
        title: '$estName · ${nonEmpty(e['title']) ?? 'Акция'}',
        subtitle: nonEmpty(e['subtitle']) ??
            nonEmpty(e['description']) ??
            'Новое предложение заведения.',
        icon: Icons.local_fire_department_rounded,
        color: kLoginPink,
        imageUrl: extractImageUrl(e),
        rawData: {...e, 'establishment_name': estName},
      ));
    }

    final rewards = mapList(data['rewards']).isNotEmpty
        ? mapList(data['rewards'])
        : mapList(sourceHome['rewards']);
    for (final e in rewards.take(10)) {
      result.add(PromoItem(
        tag: 'награда',
        title:
            '$estName · ${nonEmpty(e['title']) ?? nonEmpty(e['name']) ?? 'Награда'}',
        subtitle: nonEmpty(e['description']) ?? 'Доступна награда или подарок.',
        icon: Icons.card_giftcard_rounded,
        color: FlowColors.green,
        imageUrl: extractImageUrl(e),
        rawData: {...e, 'establishment_name': estName},
      ));
    }

    return result;
  }

  List<PromoItem> get flowruTodayItems {
    final result = <PromoItem>[];
    if (homeByEstablishment.isEmpty) {
      result.addAll(_promoItemsFromData(
          sourceHome: home,
          sourceOffers: offers,
          estName: establishmentName,
          flowruOnly: true));
    } else {
      homeByEstablishment.forEach((id, h) {
        result.addAll(_promoItemsFromData(
            sourceHome: h,
            sourceOffers: offersByEstablishment[id] ?? {},
            estName: establishmentNameById(id),
            flowruOnly: true));
      });
    }
    final seen = <String>{};
    return result
        .where((e) => seen.add('${e.title}|${e.subtitle}'))
        .take(10)
        .toList();
  }

  List<PromoItem> get actualForYouItems {
    final result = <PromoItem>[];
    if (homeByEstablishment.isEmpty) {
      result.addAll(_promoItemsFromData(
          sourceHome: home,
          sourceOffers: offers,
          estName: establishmentName,
          establishmentOnly: true));
    } else {
      homeByEstablishment.forEach((id, h) {
        result.addAll(_promoItemsFromData(
            sourceHome: h,
            sourceOffers: offersByEstablishment[id] ?? {},
            estName: establishmentNameById(id),
            establishmentOnly: true));
      });
    }
    return result.take(40).toList();
  }

  void initInviteDeepLinks() {
    inviteDeepLinkSub = FlowInviteDeepLinks.stream.listen((uri) {
      final token = FlowInviteDeepLinks.parseInviteToken(uri);
      if (token != null && token.isNotEmpty) {
        handleInviteToken(token);
      }
    });
  }

  Future<void> consumePendingInviteToken() async {
    final token = FlowInviteDeepLinks.pendingInviteToken;
    if (token == null || token.trim().isEmpty) return;

    FlowInviteDeepLinks.pendingInviteToken = null;
    await handleInviteToken(token.trim());
  }

  Future<void> handleInviteToken(String inviteToken) async {
    final cleanToken = inviteToken.trim();
    if (cleanToken.isEmpty || joiningInvite) return;

    setState(() {
      joiningInvite = true;
      error = null;
    });

    try {
      final token = await getFreshAccessToken();
      if (token == null || token.isEmpty) {
        FlowInviteDeepLinks.pendingInviteToken = cleanToken;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('??????? ? Flowru, ????? ???????? ?????????')),
        );
        return;
      }

      final res = await api.joinEstablishment(token, cleanToken);

      if (!mounted) return;

      final message =
          (res['message'] ?? '????????? ????????? ? Flowru').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      final establishmentId = intOrNull(res['establishment_id']) ??
          intOrNull(map(res['establishment'])['id']);

      if (establishmentId != null) {
        selectedEstablishmentId = establishmentId;
      }

      await loadAll();
    } on ApiError catch (e) {
      if (!mounted) return;

      if (e.status == 401) {
        FlowInviteDeepLinks.pendingInviteToken = cleanToken;
        return logout();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('?? ??????? ???????? ????????? ?? ??????')),
      );
    } finally {
      if (mounted) {
        setState(() => joiningInvite = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    initInviteDeepLinks();
    loadAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      consumePendingInviteToken();
    });
    flowruQrTimer = Timer.periodic(
        const Duration(seconds: 95), (_) => refreshClientQr(silent: true));
  }

  @override
  void dispose() {
    inviteDeepLinkSub?.cancel();
    flowruQrTimer?.cancel();
    super.dispose();
  }

  Future<String?> getFreshAccessToken() async {
    final access = await AuthStorage.access();
    if (access != null && access.isNotEmpty) return access;
    final refresh = await AuthStorage.refresh();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final data = await api.refresh(refresh);
      final newAccess = data['access_token']?.toString() ?? '';
      if (newAccess.isEmpty) return null;
      await AuthStorage.saveAccess(newAccess);
      return newAccess;
    } catch (_) {
      return null;
    }
  }

  Future<String?> refreshAccessToken() async {
    final refresh = await AuthStorage.refresh();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final data = await api.refresh(refresh);
      final newAccess = data['access_token']?.toString() ?? '';
      if (newAccess.isEmpty) return null;
      await AuthStorage.saveAccess(newAccess);
      return newAccess;
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshClientQr({bool silent = false}) async {
    if (!silent && mounted) setState(() => flowruQrLoading = true);
    try {
      final token = await getFreshAccessToken();
      if (token == null || token.isEmpty) return;
      final res = await api.clientQr(token);
      if (!mounted) return;
      setState(() {
        flowruQrPayload =
            (res['qr_payload'] ?? res['qr_token'] ?? '').toString();
        flowruQrExpiresAt =
            DateTime.tryParse((res['expires_at'] ?? '').toString());
        flowruQrLoading = false;
      });
    } catch (_) {
      if (!silent && mounted) setState(() => flowruQrLoading = false);
    }
  }

  Future<void> loadAll() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      var token = await getFreshAccessToken();
      if (token == null || token.isEmpty) return logout();

      Map<String, dynamic> baseHome;
      try {
        baseHome =
            await api.home(token, establishmentId: selectedEstablishmentId);
      } on ApiError catch (e) {
        if (e.status != 401) rethrow;
        final refreshed = await refreshAccessToken();
        if (refreshed == null || refreshed.isEmpty) return logout();
        token = refreshed;
        baseHome =
            await api.home(token, establishmentId: selectedEstablishmentId);
      }

      final ests = dedupeEstablishments(mapList(baseHome['establishments']));
      final firstEstId = intOrNull(map(baseHome['establishment'])['id']) ??
          (ests.isNotEmpty ? intOrNull(ests.first['establishment_id']) : null);
      final activeId = selectedEstablishmentId ?? firstEstId;

      final nextHomeByEst = <int, Map<String, dynamic>>{};
      final nextOffersByEst = <int, Map<String, dynamic>>{};
      final nextProfilesByEst = <int, Map<String, dynamic>>{};
      final nextHistoryByEst = <int, List<Map<String, dynamic>>>{};

      for (final est in ests) {
        final id = intOrNull(est['establishment_id']);
        if (id == null) continue;

        try {
          nextHomeByEst[id] = await api.home(token, establishmentId: id);
        } catch (_) {
          if (id == activeId) nextHomeByEst[id] = baseHome;
        }

        try {
          nextOffersByEst[id] = await api.offers(token, id);
        } catch (_) {
          nextOffersByEst[id] = {};
        }

        try {
          nextProfilesByEst[id] = await api.establishmentProfile(token, id);
        } catch (_) {
          nextProfilesByEst[id] = {};
        }

        try {
          final res = await api.history(token, id);
          nextHistoryByEst[id] = visibleClientHistory(mapList(res['items']));
        } catch (_) {
          nextHistoryByEst[id] = [];
        }
      }

      Map<String, dynamic> selectedHome =
          activeId == null ? baseHome : (nextHomeByEst[activeId] ?? baseHome);
      Map<String, dynamic> selectedOffers = activeId == null
          ? <String, dynamic>{}
          : (nextOffersByEst[activeId] ?? <String, dynamic>{});
      Map<String, dynamic> selectedProfile = activeId == null
          ? <String, dynamic>{}
          : (nextProfilesByEst[activeId] ?? <String, dynamic>{});
      List<Map<String, dynamic>> selectedHistory = activeId == null
          ? <Map<String, dynamic>>[]
          : (nextHistoryByEst[activeId] ?? <Map<String, dynamic>>[]);

      if (!mounted) return;
      setState(() {
        home = selectedHome;
        offers = selectedOffers;
        establishmentProfile = selectedProfile;
        establishments = ests;
        selectedEstablishmentId = activeId;
        history = selectedHistory;
        homeByEstablishment = nextHomeByEst;
        offersByEstablishment = nextOffersByEst;
        profileByEstablishment = nextProfilesByEst;
        historyByEstablishment = nextHistoryByEst;
        loading = false;
      });

      await refreshClientQr(silent: true);
    } on ApiError catch (e) {
      if (e.status == 401) return logout();
      if (!mounted) return;
      setState(() {
        error = e.message;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Не удалось загрузить профиль';
        loading = false;
      });
    }
  }

  Future<void> loadHistory() async {
    final estId = selectedEstablishmentId;
    if (estId == null) return;
    setState(() => historyLoading = true);
    try {
      final token = await getFreshAccessToken();
      if (token == null || token.isEmpty) return logout();
      final res = await api.history(token, estId);
      if (!mounted) return;
      setState(() {
        history = visibleClientHistory(mapList(res['items']));
        historyLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => historyLoading = false);
    }
  }

  Future<void> joinDraw(Map<String, dynamic> draw) async {
    if (joiningDraw) return;
    final runId = intOrNull(draw['run_id']);
    final estId =
        selectedEstablishmentId ?? intOrNull(map(home['establishment'])['id']);
    if (runId == null || estId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось определить розыгрыш')));
      return;
    }
    setState(() => joiningDraw = true);
    try {
      final token = await getFreshAccessToken();
      if (token == null || token.isEmpty) return logout();
      final res = await api.joinDraw(token, runId, estId);
      final message = res['message']?.toString() ?? 'Вы участвуете в розыгрыше';
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      await loadAll();
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.status == 401) return logout();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось принять участие')));
    } finally {
      if (mounted) setState(() => joiningDraw = false);
    }
  }

  Future<void> selectEst(Map<String, dynamic> item) async {
    final id = intOrNull(item['establishment_id']);
    if (id == null) return;
    setState(() {
      selectedEstablishmentId = id;
      loading = true;
      error = null;
    });
    try {
      final token = await getFreshAccessToken();
      if (token == null || token.isEmpty) return logout();
      final h = await api.home(token, establishmentId: id);
      final res = await api.history(token, id);
      Map<String, dynamic> off = {};
      Map<String, dynamic> prof = {};
      try {
        off = await api.offers(token, id);
      } catch (_) {
        off = {};
      }
      try {
        prof = await api.establishmentProfile(token, id);
      } catch (_) {
        prof = {};
      }
      if (!mounted) return;
      setState(() {
        home = h;
        offers = off;
        establishmentProfile = prof;
        establishments = dedupeEstablishments(mapList(h['establishments']));
        history = visibleClientHistory(mapList(res['items']));
        loading = false;
      });
    } on ApiError catch (e) {
      if (e.status == 401) return logout();
      if (!mounted) return;
      setState(() {
        error = e.message;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Не удалось загрузить данные';
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    await AuthStorage.clear();
    if (!mounted) return;
    Navigator.of(context)
        .pushAndRemoveUntil(appRoute(const AuthScreen()), (_) => false);
  }

  Map<String, dynamic> get user => map(home['user']);
  Map<String, dynamic> get client => map(home['client']);
  Map<String, dynamic> get establishment => map(home['establishment']);
  Map<String, dynamic> get loyalty => map(home['loyalty']);
  Map<String, dynamic> get stats => map(home['stats']);
  Map<String, dynamic> get card => map(home['card']);
  Map<String, dynamic> get offerData => offers.isNotEmpty ? offers : home;
  Map<String, dynamic> get liveProfile => map(establishmentProfile['profile']);
  Map<String, dynamic> get liveProfileEstablishment =>
      map(liveProfile['establishment']);
  Map<String, dynamic> get liveContacts => map(liveProfile['contacts']);
  Map<String, dynamic> get liveRatings => map(liveProfile['ratings']);
  Map<String, dynamic> get liveModules => map(liveProfile['modules']);
  Map<String, dynamic> get liveLoyaltyRules => map(liveModules['loyalty']);
  ThemePreset get activeThemePreset => ThemeStore.current;
  bool get hasCard => home['has_card'] == true;
  String get clientName =>
      nonEmpty(client['name']) ?? nonEmpty(user['full_name']) ?? 'Клиент';
  String get establishmentName =>
      nonEmpty(establishment['name']) ?? 'Заведение';
  int get points => toInt(loyalty['points'] ?? stats['points']);
  int get visits => toInt(loyalty['visits'] ?? stats['visits']);
  double get sales => toDouble(loyalty['sales_total'] ?? stats['sales_total']);
  String get code => (card['qr_code'] ??
          card['code'] ??
          user['phone'] ??
          client['phone'] ??
          client['id'] ??
          '')
      .toString();
  String get phone => (user['phone'] ?? client['phone'] ?? '').toString();
  String get lastVisit =>
      (loyalty['last_visit_at'] ?? stats['last_visit_at'] ?? '').toString();

  String? _firstText(List<dynamic> values) {
    for (final value in values) {
      final v = nonEmpty(value);
      if (v != null) return v;
    }
    return null;
  }

  String get loyaltyLevel =>
      _firstText([
        loyalty['level_name'],
        loyalty['level'],
        loyalty['tier_name'],
        card['level_name'],
        card['level'],
        _currentCashbackLevelName(),
      ]) ??
      'Базовый уровень';

  String get loyaltyModeLabel =>
      _firstText([
        loyalty['system_label'],
        loyalty['mode_label'],
        loyalty['mechanic_label'],
        loyalty['loyalty_type_label'],
        establishment['loyalty_type_label'],
        establishment['loyalty_mode_label'],
        establishment['accrual_system'],
        home['loyalty_mode_label'],
        _loyaltyModeFromRules(),
      ]) ??
      'Балльная система';

  String get pointsExpireText =>
      _firstText([
        loyalty['expire_text'],
        loyalty['points_expire_text'],
        loyalty['bonus_expire_text'],
        loyalty['expires_text'],
        formatClientDateTime(loyalty['points_expire_at']),
        formatClientDateTime(loyalty['bonus_expire_at']),
        _pointsExpireFromRules(),
      ]) ??
      'Срок действия бонусов не указан';

  String? _loyaltyModeFromRules() {
    final mode = nonEmpty(liveLoyaltyRules['mode']);
    if (mode == 'cashback') return 'Кэшбэк';
    if (mode != null) return mode;
    return null;
  }

  String? _pointsExpireFromRules() {
    final expiration = map(liveLoyaltyRules['points_expiration']);
    if (expiration['enabled'] == true ||
        expiration['enabled']?.toString() == 'true') {
      final days = nonEmpty(expiration['lifetime_days']);
      if (days != null) return 'Баллы действуют $days дней';
    }
    return null;
  }

  String? _currentCashbackLevelName() {
    final levels = mapList(liveLoyaltyRules['cashback_levels']);
    if (levels.isEmpty) return null;
    Map<String, dynamic>? best;
    for (final level in levels) {
      if (sales >= toDouble(level['spent_required'])) best = level;
    }
    final name = nonEmpty(best?['name']);
    final percent = best == null ? '' : formatPercent(best['cashback_percent']);
    if (name == null) return null;
    return percent.isEmpty ? name : '$name · $percent%';
  }

  String get addressText =>
      _firstText([
        liveContacts['address'],
        liveProfileEstablishment['address'],
        establishment['address'],
        map(establishment['contacts'])['address'],
        map(establishment['location'])['address'],
        home['address'],
      ]) ??
      'Адрес заведения не указан';

  String get workingHoursText =>
      _firstText([
        liveContacts['working_hours'],
        establishment['working_hours'],
        establishment['schedule'],
        map(establishment['contacts'])['working_hours'],
        home['working_hours'],
      ]) ??
      'Время работы не указано';

  String? get yandexUrl => _firstText([
        map(liveRatings['yandex'])['url'],
        establishment['yandex_reviews_url'],
        establishment['yandex_url'],
        map(establishment['reviews'])['yandex_url'],
      ]);

  String? get twoGisUrl => _firstText([
        map(liveRatings['two_gis'])['url'],
        establishment['two_gis_url'],
        establishment['two_gis_reviews_url'],
        establishment['gis_url'],
        map(establishment['reviews'])['two_gis_url'],
      ]);

  String get yandexRatingText =>
      _firstText([
        map(liveRatings['yandex'])['rating'],
        establishment['yandex_rating'],
        map(establishment['reviews'])['yandex_rating'],
      ]) ??
      'отзывы';

  String get twoGisRatingText =>
      _firstText([
        map(liveRatings['two_gis'])['rating'],
        establishment['two_gis_rating'],
        establishment['gis_rating'],
        map(establishment['reviews'])['two_gis_rating'],
      ]) ??
      'отзывы';

  String? get referralLink {
    final direct = _firstText([
      user['referral_link'],
      client['referral_link'],
      home['referral_link'],
      map(home['referral'])['link'],
      map(home['referral'])['url'],
      map(home['referral'])['invite_link'],
      map(liveLoyaltyRules['client_referral'])['link'],
      map(liveLoyaltyRules['client_referral'])['url'],
      map(liveLoyaltyRules['client_referral'])['invite_link'],
    ]);
    if (direct != null) return direct;

    final code = _firstText([
      user['referral_code'],
      client['referral_code'],
      home['referral_code'],
      map(home['referral'])['code'],
      map(liveLoyaltyRules['client_referral'])['code'],
    ]);
    if (code == null) return null;
    final est = selectedEstablishmentId ??
        intOrNull(card['establishment_id']) ??
        intOrNull(establishment['id']);
    final suffix = est == null ? code : '$code?establishment_id=$est';
    return '${AppConfig.publicBase}/r/$suffix';
  }

  String? get birthDateText => _firstText([
        client['birth_date'],
        client['birthday'],
        client['date_of_birth'],
        user['birth_date'],
        user['birthday'],
        user['date_of_birth'],
        map(home['profile'])['birth_date'],
        map(home['profile'])['birthday'],
        map(home['profile'])['date_of_birth'],
      ]);

  int get birthdayGiftPoints =>
      toInt(map(liveLoyaltyRules['birthday_campaign'])['gift_points']);

  bool _truthy(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return defaultValue;
    return {'1', 'true', 'yes', 'on', 'да', 'вкл', 'enabled'}.contains(text);
  }

  bool get birthdayCampaignEnabled {
    final direct = _firstText([
      home['birthday_campaign_enabled'],
      client['birthday_campaign_enabled'],
      map(home['birthday_campaign'])['enabled'],
      map(client['birthday_campaign'])['enabled'],
      map(home['birthday_campaign'])['show_birthdate_block'],
      map(client['birthday_campaign'])['show_birthdate_block'],
    ]);
    if (direct != null) return _truthy(direct);

    final cfg = map(liveLoyaltyRules['birthday_campaign']);
    return _truthy(cfg['enabled']) || _truthy(cfg['show_birthdate_block']);
  }

  bool get referralProgramEnabled {
    final direct = _firstText([
      home['referral_enabled'],
      client['referral_enabled'],
      map(home['client_referral'])['enabled'],
      map(client['client_referral'])['enabled'],
      map(home['referral'])['enabled'],
    ]);
    if (direct != null) return _truthy(direct);

    final cfg = map(liveLoyaltyRules['client_referral']);
    return _truthy(cfg['enabled']);
  }

  String? get appleWalletUrl => _firstText([
        card['apple_wallet_url'],
        card['apple_wallet_link'],
        card['apple_pass_url'],
        card['apple_pass_link'],
        home['apple_wallet_url'],
        home['apple_wallet_link'],
        home['apple_pass_url'],
        home['apple_pass_link'],
        map(liveModules['wallet'])['apple_wallet_url'],
        map(liveModules['wallet'])['apple_wallet_link'],
        map(liveModules['wallet'])['apple_pass_url'],
        map(liveModules['wallet'])['apple_pass_link'],
      ]);

  String? get googleWalletUrl => _firstText([
        card['google_wallet_url'],
        card['google_wallet_link'],
        card['google_save_url'],
        card['google_save_link'],
        home['google_wallet_url'],
        home['google_wallet_link'],
        home['google_save_url'],
        home['google_save_link'],
        map(liveModules['wallet'])['google_wallet_url'],
        map(liveModules['wallet'])['google_wallet_link'],
        map(liveModules['wallet'])['google_save_url'],
        map(liveModules['wallet'])['google_save_link'],
      ]);

  bool get walletEnabled {
    final wallet = map(liveModules['wallet']);
    final enabledRaw = wallet['enabled'];
    final appleEnabledRaw = wallet['apple_enabled'];
    final googleEnabledRaw = wallet['google_enabled'];
    final enabled =
        enabledRaw == true || enabledRaw?.toString().toLowerCase() == 'true';
    final appleEnabled = appleEnabledRaw == true ||
        appleEnabledRaw?.toString().toLowerCase() == 'true';
    final googleEnabled = googleEnabledRaw == true ||
        googleEnabledRaw?.toString().toLowerCase() == 'true';
    return enabled ||
        appleEnabled ||
        googleEnabled ||
        appleWalletUrl != null ||
        googleWalletUrl != null;
  }

  String? get menuPhotoUrl => _firstText([
        establishment['menu_photo_url'],
        establishment['menu_image_url'],
        home['menu_photo_url'],
      ]);

  Map<String, dynamic> get liveSocialMedia => map(liveContacts['social_media']);

  List<PromoItem> get promoItems {
    final result = <PromoItem>[];

    final devRaw = <Map<String, dynamic>>[
      ...mapList(offerData['dev_banners']),
      ...mapList(offerData['global_banners']),
      ...mapList(home['dev_banners']),
      ...mapList(home['global_banners']),
    ];

    final seenDevIds = <String>{};
    final devBanners = <Map<String, dynamic>>[];
    for (final e in devRaw) {
      final key =
          (e['id'] ?? e['legacy_id'] ?? e['title'] ?? e.hashCode).toString();
      if (seenDevIds.add(key)) devBanners.add(e);
    }

    for (final e in devBanners.take(20)) {
      result.add(
        PromoItem(
          tag: e['tag']?.toString() ?? 'важное',
          title: e['title']?.toString() ?? 'Важное',
          subtitle: e['short_text']?.toString() ??
              e['subtitle']?.toString() ??
              e['description']?.toString() ??
              'Информация от Flowru',
          icon: Icons.campaign_rounded,
          color: FlowColors.blue,
          imageUrl: extractImageUrl(e),
          rawData: e,
        ),
      );
    }

    final banner = map(offerData['draw_banner']).isNotEmpty
        ? map(offerData['draw_banner'])
        : map(home['draw_banner']);
    final draws = mapList(offerData['draws']).isNotEmpty
        ? mapList(offerData['draws'])
        : mapList(home['draws']);
    final activeDraw = banner.isNotEmpty
        ? banner
        : (draws.isNotEmpty ? draws.first : <String, dynamic>{});

    if (activeDraw.isNotEmpty) {
      result.add(
        PromoItem(
          tag: 'розыгрыш',
          title: nonEmpty(activeDraw['title']) ?? 'Розыгрыш',
          subtitle: nonEmpty(activeDraw['prize_text']) ??
              nonEmpty(activeDraw['description']) ??
              'Откройте подробности розыгрыша.',
          icon: Icons.celebration_rounded,
          color: kLoginViolet,
          imageUrl: extractImageUrl(activeDraw),
          rawData: activeDraw,
          isRaffle: true,
        ),
      );
    }

    // Купоны и подарки не показываем в блоке «Важное».
    // Обычные акции заведения берём только из banners. DEV-плашки лежат отдельно в dev_banners.

    final remote = mapList(offerData['banners']);
    for (final e in remote.take(20)) {
      result.add(
        PromoItem(
          tag: e['tag']?.toString() ?? 'акция',
          title: e['title']?.toString() ?? 'Акция',
          subtitle: e['subtitle']?.toString() ??
              e['description']?.toString() ??
              'Новое предложение',
          icon: Icons.local_fire_department_rounded,
          color: kLoginPink,
          imageUrl: extractImageUrl(e),
          rawData: e,
        ),
      );
    }

    if (result.isEmpty) {
      return const [
        PromoItem(
            tag: 'акция',
            title: 'Персональные предложения',
            subtitle: 'Новые акции заведения появятся здесь.',
            icon: Icons.local_fire_department_rounded,
            color: kLoginPink),
      ];
    }

    return result;
  }

  List<PromoItem> get perksPromoItems {
    return promoItems.where((item) {
      final tag = item.tag.toLowerCase();
      final source =
          (item.rawData?['source'] ?? item.rawData?['banner_type'] ?? '')
              .toString()
              .toLowerCase();
      final isDevBanner = source.contains('dev_app_banner') ||
          source.contains('global') ||
          tag.contains('важ') ||
          tag.contains('flowru');
      return !isDevBanner;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: loading
              ? const LoadingState()
              : error != null
                  ? ErrorState(message: error!, onRetry: loadAll)
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: IndexedStack(
                              index: tab,
                              children: [commandTab(), profileTab()]),
                        ),
                        Positioned(
                            left: 18,
                            right: 18,
                            bottom: 14,
                            child: OrbitDock(
                                current: tab,
                                onChanged: (v) => setState(() => tab = v),
                                onScan: () => showQrSheet(context))),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget commandTab() {
    return RefreshIndicator(
      onRefresh: loadAll,
      color: FlowColors.ink,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 124),
        children: [
          FlowruMainHeader(name: clientName, onLogout: logout),
          const SizedBox(height: 16),
          FlowruClientQrPanel(
            name: clientName,
            phone: phone,
            payload: flowruQrPayload.isNotEmpty
                ? flowruQrPayload
                : (phone.isNotEmpty ? phone : code),
            loading: flowruQrLoading,
            onRefresh: () => refreshClientQr(),
            onOpen: () => showQrSheet(context),
          ),
          const SizedBox(height: 18),
          const SectionTitle(
              title: 'Flowru сегодня',
              subtitle: 'Новости, обновления и объявления от команды Flowru'),
          const SizedBox(height: 10),
          OfferTicker(items: flowruTodayItems, joining: joiningDraw),
          const SizedBox(height: 18),
          const SectionTitle(
              title: 'Актуальное для вас',
              subtitle:
                  'Акции, розыгрыши и награды из заведений, где вы уже есть'),
          const SizedBox(height: 10),
          OfferTicker(
              items: actualForYouItems,
              joining: joiningDraw,
              onJoin: joinDrawFromAggregatedItem,
              onOpenEstablishment: openEstablishmentById),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                  child: SectionTitle(
                      title: 'Мои заведения',
                      subtitle:
                          'Откройте заведение, чтобы посмотреть акции, историю, правила и контакты')),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF143A63).withOpacity(0.88),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Text(
                  '${establishments.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (establishments.isEmpty)
            EmptyState(
              icon: Icons.storefront_rounded,
              title: 'Заведений пока нет',
              subtitle:
                  'Покажите QR на кассе или добавьте заведение по QR/ссылке.',
            )
          else
            Column(
              children: List.generate(establishments.length, (index) {
                final e = establishments[index];
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index == establishments.length - 1 ? 0 : 12),
                  child: FlowruEstablishmentEntry(
                    item: e,
                    home: homeByEstablishment[
                            intOrNull(e['establishment_id']) ?? -1] ??
                        {},
                    offers: offersByEstablishment[
                            intOrNull(e['establishment_id']) ?? -1] ??
                        {},
                    onOpen: () => openEstablishmentPage(e),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget perksTab() {
    return RefreshIndicator(
      onRefresh: loadAll,
      color: FlowColors.ink,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 124),
        children: [
          const ScreenHeader(
              title: 'Выгода',
              subtitle: 'Акции, розыгрыши и полезные предложения',
              accent: kLoginPink,
              icon: Icons.auto_awesome_rounded,
              variant: OrbitLogoVariant.comet),
          const SizedBox(height: 16),
          PerksHub(
              home: home,
              promoItems: actualForYouItems,
              joining: joiningDraw,
              onJoin: joinDrawFromAggregatedItem),
        ],
      ),
    );
  }

  Widget timelineTab() {
    return RefreshIndicator(
      onRefresh: loadHistory,
      color: FlowColors.ink,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 124),
        children: [
          const ScreenHeader(
              title: 'История',
              subtitle: 'Все начисления, списания и покупки по карте',
              accent: kLoginAccent,
              icon: Icons.timeline_rounded,
              variant: OrbitLogoVariant.pulse),
          const SizedBox(height: 16),
          TimelineList(history: combinedHistory, loading: historyLoading),
        ],
      ),
    );
  }

  Widget profileTab() {
    return RefreshIndicator(
      onRefresh: loadAll,
      color: FlowColors.ink,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 124),
        children: [
          const ScreenHeader(
              title: 'Профиль',
              subtitle:
                  'Общий аккаунт Flowru, персонализация и системные настройки',
              accent: kLoginBlue,
              icon: Icons.person_rounded,
              variant: OrbitLogoVariant.orbit),
          const SizedBox(height: 14),
          SurfaceCard(
            radius: 28,
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              ProfileSettingsRow(
                  icon: Icons.badge_rounded,
                  title: 'Имя',
                  subtitle: clientName.isNotEmpty
                      ? clientName
                      : 'Пользователь Flowru',
                  onTap: () {}),
              const Divider(height: 18, color: FlowColors.line),
              ProfileSettingsRow(
                  icon: Icons.phone_rounded,
                  title: 'Телефон',
                  subtitle: phone.isNotEmpty ? phone : 'Не указан',
                  onTap: () {}),
              const Divider(height: 18, color: FlowColors.line),
              ProfileSettingsRow(
                  icon: Icons.domain_rounded,
                  title: 'Подключено заведений',
                  subtitle: establishments.isEmpty
                      ? 'Пока нет подключённых заведений'
                      : '${establishments.length} заведений доступны на главном экране',
                  onTap: () {}),
            ]),
          ),
          const SizedBox(height: 18),
          const SectionTitle(
              title: 'Персонализация',
              subtitle:
                  'Будущие настройки внешнего вида и персонального стиля приложения'),
          const SizedBox(height: 10),
          SurfaceCard(
            radius: 26,
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              ProfileSettingsRow(
                  icon: Icons.palette_outlined,
                  title: 'Оформление и персонализация',
                  subtitle: 'Раздел-заглушка для следующего этапа разработки',
                  onTap: () => showCardDesignComingSoonSheet(context)),
            ]),
          ),
          const SizedBox(height: 18),
          const SectionTitle(
              title: 'Настройки', subtitle: 'Основные действия по аккаунту'),
          const SizedBox(height: 10),
          SurfaceCard(
            radius: 24,
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              ProfileSettingsRow(
                  icon: Icons.logout_rounded,
                  title: 'Выйти из аккаунта',
                  subtitle: 'Завершить текущую сессию',
                  destructive: true,
                  onTap: logout),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> joinDrawFromAggregatedItem(Map<String, dynamic> draw) async {
    final estId =
        intOrNull(draw['establishment_id']) ?? selectedEstablishmentId;
    if (estId == null) return joinDraw(draw);
    if (joiningDraw) return;
    final runId = intOrNull(draw['run_id']);
    if (runId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось определить розыгрыш')));
      return;
    }
    setState(() => joiningDraw = true);
    try {
      final token = await getFreshAccessToken();
      if (token == null || token.isEmpty) return logout();
      final res = await api.joinDraw(token, runId, estId);
      final message = res['message']?.toString() ?? 'Вы участвуете в розыгрыше';
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      await loadAll();
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.status == 401) return logout();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось принять участие')));
    } finally {
      if (mounted) setState(() => joiningDraw = false);
    }
  }

  Future<void> openEstablishmentById(int establishmentId) async {
    Map<String, dynamic>? found;
    for (final e in establishments) {
      if (intOrNull(e['establishment_id']) == establishmentId) {
        found = e;
        break;
      }
    }
    found ??= {
      'establishment_id': establishmentId,
      'establishment_name': establishmentNameById(establishmentId),
    };
    await openEstablishmentPage(found);
  }

  Future<void> openEstablishmentPage(Map<String, dynamic> item) async {
    final estId = intOrNull(item['establishment_id']);
    if (estId == null) return;

    selectedEstablishmentId = estId;

    Map<String, dynamic> h = homeByEstablishment[estId] ?? home;
    Map<String, dynamic> off = offersByEstablishment[estId] ?? offers;
    Map<String, dynamic> prof =
        profileByEstablishment[estId] ?? establishmentProfile;
    List<Map<String, dynamic>> hist = historyByEstablishment[estId] ?? history;

    // ВАЖНО: перед открытием заведения принудительно берём свежий /client/home.
    // Так вкладка «Квесты» не зависит от старого кэша главного экрана.
    try {
      final token = await getFreshAccessToken();
      if (token != null && token.isNotEmpty) {
        final freshHome = await api.home(token, establishmentId: estId);
        if (freshHome.isNotEmpty) {
          h = freshHome;
          homeByEstablishment[estId] = freshHome;
        }
      }
    } catch (_) {
      // Если свежий запрос не прошёл, открываем по уже загруженным данным.
    }

    if (!mounted) return;

    Navigator.of(context).push(appRoute(EstablishmentFullScreen(
      item: item,
      home: h,
      offers: off,
      profile: prof,
      history: hist,
      onJoinDraw: joinDrawFromAggregatedItem,
      birthDateText: birthDateText,
      birthdayGiftPoints: birthdayGiftPoints,
      birthdayCampaignEnabled: birthdayCampaignEnabled,
      referralLink: referralLink,
      referralProgramEnabled: referralProgramEnabled,
      appleWalletUrl: appleWalletUrl,
      googleWalletUrl: googleWalletUrl,
      onOpenBirthday:
          birthdayCampaignEnabled ? () => showBirthDateSheet(context) : null,
      onOpenReferral: referralProgramEnabled
          ? () => showReferralActionsSheet(context)
          : null,
    )));
  }

  void showCardDesignComingSoonSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: SingleChildScrollView(
          child: ProfileFeatureShell(
            icon: Icons.palette_rounded,
            title: 'Оформление карты',
            subtitle: 'Раздел в разработке.',
            color: FlowColors.violet,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                'Скоро здесь можно будет выбрать стиль карты, оформление фона и внешний вид клиентской карточки.',
                style: TextStyle(
                    color: FlowColors.ink,
                    fontWeight: FontWeight.w800,
                    height: 1.35),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Понятно',
                  icon: Icons.check_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void showWalletActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: SingleChildScrollView(
          child: ProfileFeatureShell(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Wallet-карта',
            subtitle:
                'Добавьте карту выбранного заведения в Apple Wallet или Google Wallet.',
            color: FlowColors.aqua,
            child: WalletInlineButtons(
                appleWalletUrl: appleWalletUrl,
                googleWalletUrl: googleWalletUrl),
          ),
        ),
      ),
    );
  }

  void showReferralActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: SingleChildScrollView(
          child: ReferralInviteCard(
              referralLink: referralLink,
              onRefresh: () => refreshReferralLink(context)),
        ),
      ),
    );
  }

  void showLoyaltyRulesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 6,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.70),
                    borderRadius: BorderRadius.circular(999)),
              ),
              LiveLoyaltyRulesCard(
                  rules: liveLoyaltyRules, points: points, sales: sales),
            ],
          ),
        ),
      ),
    );
  }

  void showQrSheet(BuildContext context) {
    final qr = flowruQrPayload.trim().isNotEmpty
        ? flowruQrPayload.trim()
        : (phone.trim().isNotEmpty ? phone.trim() : code.trim());
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ScanModeSheet(
            establishment: 'Flowru ID', phone: phone, qr: qr, points: points));
  }

  Future<void> showBirthDateSheet(BuildContext context) async {
    if (!birthdayCampaignEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Модуль дня рождения выключен для этого заведения')));
      return;
    }
    if (selectedEstablishmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сначала выберите карту заведения')));
      return;
    }

    final now = DateTime.now();
    final initial = parseBirthDate(birthDateText) ??
        DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now)
          ? DateTime(now.year - 25, now.month, now.day)
          : initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      helpText: 'Дата рождения',
      cancelText: 'Отмена',
      confirmText: 'Сохранить',
    );
    if (picked == null) return;

    final birthDate =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    try {
      final token = await getFreshAccessToken();
      if (token == null || token.isEmpty) return logout();
      await api.updateBirthDate(token, selectedEstablishmentId!, birthDate);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Дата рождения сохранена')));
      await loadAll();
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить дату рождения')));
    }
  }

  Future<void> refreshReferralLink(BuildContext context) async {
    if (!referralProgramEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Реферальная программа выключена для этого заведения')));
      return;
    }
    if (selectedEstablishmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сначала выберите карту заведения')));
      return;
    }
    try {
      final token = await getFreshAccessToken();
      if (token == null || token.isEmpty) return logout();
      await api.generateReferralLink(token, selectedEstablishmentId!);
      await loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Реферальная ссылка обновлена')));
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Не удалось получить реферальную ссылку')));
    }
  }

  void showEstablishmentDetailsSheet(
      BuildContext context, Map<String, dynamic> item) {
    final id = intOrNull(item['establishment_id']);
    final isActive = id != null && id == selectedEstablishmentId;
    final title = nonEmpty(item['establishment_name']) ??
        nonEmpty(item['name']) ??
        establishmentName;
    final address = isActive
        ? addressText
        : (nonEmpty(item['address']) ??
            nonEmpty(item['establishment_address']) ??
            nonEmpty(map(item['establishment'])['address']) ??
            'Адрес будет показан после выбора этой карты.');
    final phoneValue = isActive
        ? (nonEmpty(liveContacts['phone']) ?? '')
        : (nonEmpty(item['phone']) ??
            nonEmpty(map(item['contacts'])['phone']) ??
            '');
    final hours = isActive
        ? workingHoursText
        : (nonEmpty(item['working_hours']) ??
            nonEmpty(item['hours']) ??
            nonEmpty(map(item['contacts'])['working_hours']) ??
            '');
    final cardPoints = toInt(item['points']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
        child: SingleChildScrollView(
          child: EstablishmentDetailsSheet(
            title: title,
            address: address,
            phone: phoneValue,
            workingHours: hours,
            points: cardPoints,
            active: isActive,
            appleWalletUrl: isActive ? appleWalletUrl : null,
            googleWalletUrl: isActive ? googleWalletUrl : null,
            onSelect: isActive
                ? null
                : () {
                    Navigator.of(context).pop();
                    selectEst(item);
                  },
            onShowRules: isActive
                ? () {
                    Navigator.of(context).pop();
                    showLoyaltyRulesSheet(context);
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

class AppFrame extends StatelessWidget {
  final Widget child;
  const AppFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FlowColors.bg,
      child: Stack(
        children: [
          const Positioned.fill(child: CommandBackground()),
          Positioned.fill(child: CustomPaint(painter: MicroGridPainter())),
          child,
        ],
      ),
    );
  }
}

class CommandBackground extends StatelessWidget {
  const CommandBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF087AA2),
                Color(0xFF0CBBC5),
                Color(0xFF66E2C4),
                Color(0xFF073E63)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.36, 0.66, 1.0],
            ),
          ),
          child: SizedBox.expand(),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.82, -0.88),
                radius: 0.92,
                colors: [
                  Colors.white.withOpacity(0.42),
                  Colors.white.withOpacity(0.08),
                  Colors.transparent
                ],
                stops: const [0.0, 0.36, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
            top: -120,
            right: -80,
            child: GlowOrb(color: Colors.white.withOpacity(0.30), size: 360)),
        Positioned(
            left: -130,
            bottom: -40,
            child: GlowOrb(color: kLoginBlue.withOpacity(0.24), size: 310)),
        Positioned(
            right: -120,
            top: 260,
            child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.13), width: 2)))),
        Positioned(
            left: -58,
            bottom: 120,
            child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.34), width: 2)))),
      ],
    );
  }
}

class AuthCommandHero extends StatelessWidget {
  final bool isRegister;
  const AuthCommandHero({super.key, required this.isRegister});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(38),
      child: Container(
        height: 430,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F1720),
                Color(0xFF142032),
                Color(0xFF22301D)
              ]),
        ),
        child: Stack(
          children: [
            Positioned(
                top: -120,
                right: -130,
                child: GlowOrb(
                    color: FlowColors.acid.withOpacity(0.45), size: 270)),
            Positioned(
                bottom: -130,
                left: -120,
                child: GlowOrb(
                    color: FlowColors.aqua.withOpacity(0.28), size: 290)),
            Positioned(
                right: -28,
                bottom: -10,
                child: Transform.rotate(
                    angle: -0.18, child: const PhonePreviewCard())),
            const Positioned(
                top: 0, left: 0, child: FlowMark(size: 62, dark: true)),
            Positioned(
              left: 0,
              right: 132,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      isRegister
                          ? 'Создайте личный центр бонусов'
                          : 'Откройте свой центр лояльности',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          height: 0.94,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.6)),
                  const SizedBox(height: 12),
                  Text(
                      isRegister
                          ? 'Один телефон — все карты, бонусы, акции и розыгрыши.'
                          : 'Не карточка ради карточки, а понятный экран действий: сканировать, получить бонус, посмотреть выгоду.',
                      style: const TextStyle(
                          color: Color(0xDFFFFFFF),
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhonePreviewCard extends StatelessWidget {
  const PhonePreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.24),
                blurRadius: 34,
                offset: const Offset(0, 18))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: FlowColors.ink,
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: FlowColors.acid, size: 19)),
          const Spacer(),
          Container(
              width: 34,
              height: 12,
              decoration: BoxDecoration(
                  color: FlowColors.line,
                  borderRadius: BorderRadius.circular(99))),
        ]),
        const Spacer(),
        const Text('293',
            style: TextStyle(
                color: FlowColors.ink,
                fontSize: 44,
                height: 0.9,
                fontWeight: FontWeight.w900,
                letterSpacing: -2)),
        const SizedBox(height: 5),
        const Text('баллов',
            style: TextStyle(
                color: FlowColors.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Container(
            height: 48,
            decoration: BoxDecoration(
                color: FlowColors.ink, borderRadius: BorderRadius.circular(18)),
            child: const Center(
                child: Icon(Icons.bolt_rounded, color: FlowColors.acid))),
      ]),
    );
  }
}

class AuthPanel extends StatelessWidget {
  final bool isRegister;
  final bool loading;
  final String? error;
  final ValueChanged<bool> onSwitch;
  final Widget loginForm;
  final Widget registerForm;
  final VoidCallback? onSubmit;

  const AuthPanel(
      {super.key,
      required this.isRegister,
      required this.loading,
      required this.error,
      required this.onSwitch,
      required this.loginForm,
      required this.registerForm,
      required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      radius: 36,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AuthModeSwitch(isRegister: isRegister, onChanged: onSwitch),
        const SizedBox(height: 22),
        Text(isRegister ? 'Новый аккаунт' : 'Вход',
            style: const TextStyle(
                color: FlowColors.ink,
                fontSize: 30,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2)),
        const SizedBox(height: 8),
        Text(
            isRegister
                ? 'Телефон станет ключом для всех будущих карт.'
                : 'Введите телефон и пароль. Пароль можно показать кнопкой справа.',
            style: const TextStyle(
                color: FlowColors.muted,
                height: 1.38,
                fontWeight: FontWeight.w600)),
        if (error != null) ...[
          const SizedBox(height: 14),
          ErrorBanner(text: error!)
        ],
        const SizedBox(height: 18),
        AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: isRegister ? registerForm : loginForm),
        const SizedBox(height: 18),
        PrimaryButton(
            text: loading
                ? 'Подождите...'
                : (isRegister ? 'Создать аккаунт' : 'Войти'),
            icon: isRegister
                ? Icons.person_add_alt_1_rounded
                : Icons.arrow_forward_rounded,
            onTap: onSubmit),
      ]),
    );
  }
}

class AuthModeSwitch extends StatelessWidget {
  final bool isRegister;
  final ValueChanged<bool> onChanged;
  const AuthModeSwitch(
      {super.key, required this.isRegister, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: FlowColors.bgDeep, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        Expanded(child: _item('Вход', !isRegister, () => onChanged(false))),
        Expanded(
            child: _item('Регистрация', isRegister, () => onChanged(true))),
      ]),
    );
  }

  Widget _item(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46,
        decoration: BoxDecoration(
            color: active ? FlowColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(20)),
        child: Center(
            child: Text(text,
                style: TextStyle(
                    color: active ? Colors.white : FlowColors.muted,
                    fontWeight: FontWeight.w900))),
      ),
    );
  }
}

class FlowInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const FlowInput(
      {super.key,
      required this.controller,
      required this.label,
      required this.icon,
      this.obscure = false,
      this.keyboardType,
      this.autofillHints,
      this.textInputAction,
      this.onSubmitted});

  @override
  State<FlowInput> createState() => _FlowInputState();
}

class _FlowInputState extends State<FlowInput> {
  late bool hidden;

  @override
  void initState() {
    super.initState();
    hidden = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: hidden,
      keyboardType: widget.keyboardType,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      style: const TextStyle(
          color: FlowColors.ink, fontWeight: FontWeight.w800, fontSize: 16),
      cursorColor: FlowColors.ink,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(
            color: FlowColors.muted, fontWeight: FontWeight.w700),
        prefixIcon: Icon(widget.icon, color: FlowColors.ink),
        suffixIcon: widget.obscure
            ? IconButton(
                onPressed: () => setState(() => hidden = !hidden),
                icon: Icon(
                    hidden
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: FlowColors.muted))
            : null,
        filled: true,
        fillColor: FlowColors.paper2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: FlowColors.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: FlowColors.ink, width: 1.5)),
      ),
    );
  }
}

class DailyWishAnimation extends StatefulWidget {
  final double size;
  const DailyWishAnimation({super.key, required this.size});

  @override
  State<DailyWishAnimation> createState() => _DailyWishAnimationState();
}

class _DailyWishAnimationState extends State<DailyWishAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController c;

  @override
  void initState() {
    super.initState();
    c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5200))
      ..repeat();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (context, child) {
        final t = c.value * math.pi * 2;
        final pulse = 0.94 + math.sin(t) * 0.06;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: t * 0.10,
                child: Container(
                  width: widget.size * 0.92,
                  height: widget.size * 0.92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.30),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.24), width: 1.2),
                  ),
                ),
              ),
              Transform.rotate(
                angle: -t * 0.16,
                child: Container(
                  width: widget.size * 0.70,
                  height: widget.size * 0.70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.26),
                    border: Border.all(
                        color: kLoginAccentSoft.withOpacity(0.42), width: 1.1),
                  ),
                ),
              ),
              ...List.generate(5, (i) {
                final r = widget.size * (0.25 + (i % 2) * 0.09);
                final a = t * (i.isEven ? 0.85 : -0.55) + i * 1.27;
                final dot = i == 0 ? 7.0 : 4.4;
                return Positioned(
                  left: widget.size / 2 + math.cos(a) * r - dot / 2,
                  top: widget.size / 2 + math.sin(a) * r - dot / 2,
                  child: Container(
                    width: dot,
                    height: dot,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i.isEven
                          ? kLoginAccentSoft
                          : Colors.white.withOpacity(0.92),
                      boxShadow: [
                        BoxShadow(
                            color: (i.isEven ? kLoginAccentSoft : Colors.white)
                                .withOpacity(0.35),
                            blurRadius: 10)
                      ],
                    ),
                  ),
                );
              }),
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: widget.size * 0.54,
                  height: widget.size * 0.54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.70)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.55)),
                    boxShadow: [
                      BoxShadow(
                          color: kLoginAccent.withOpacity(0.20),
                          blurRadius: 16,
                          offset: const Offset(0, 7))
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: kLoginAccent, size: 22),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GuestCardSignalAnimation extends StatefulWidget {
  final double size;
  const GuestCardSignalAnimation({super.key, required this.size});

  @override
  State<GuestCardSignalAnimation> createState() =>
      _GuestCardSignalAnimationState();
}

class _GuestCardSignalAnimationState extends State<GuestCardSignalAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController c;

  @override
  void initState() {
    super.initState();
    c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4600))
      ..repeat();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (context, child) {
        final t = c.value;
        final scanY =
            (math.sin(t * math.pi * 2) * 0.5 + 0.5) * widget.size * 0.42;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * 0.88,
                height: widget.size * 0.66,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.size * 0.24),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0A2B47), Color(0xFF0B5D78)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  boxShadow: [
                    BoxShadow(
                        color: kLoginBlue.withOpacity(0.20),
                        blurRadius: 18,
                        offset: const Offset(0, 8))
                  ],
                ),
              ),
              Positioned(
                top: widget.size * 0.20 + scanY,
                left: widget.size * 0.17,
                right: widget.size * 0.17,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      kLoginAccentSoft.withOpacity(0.95),
                      Colors.transparent
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color: kLoginAccentSoft.withOpacity(0.55),
                          blurRadius: 12)
                    ],
                  ),
                ),
              ),
              Positioned(
                right: widget.size * 0.12,
                top: widget.size * 0.10,
                child: Transform.rotate(
                  angle: math.sin(t * math.pi * 2) * 0.18,
                  child: Container(
                    width: widget.size * 0.34,
                    height: widget.size * 0.25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.size * 0.10),
                      color: Colors.white.withOpacity(0.92),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: Icon(Icons.credit_card_rounded,
                        color: kLoginBlue, size: widget.size * 0.16),
                  ),
                ),
              ),
              Container(
                width: widget.size * 0.34,
                height: widget.size * 0.34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: kLoginAccent.withOpacity(0.20),
                        blurRadius: 16,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Icon(Icons.qr_code_2_rounded,
                    color: kLoginAccent, size: widget.size * 0.21),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum OrbitLogoVariant { orbit, comet, pulse }

class AnimatedOrbitLogo extends StatefulWidget {
  final double size;
  final OrbitLogoVariant variant;
  const AnimatedOrbitLogo(
      {super.key, required this.size, this.variant = OrbitLogoVariant.orbit});

  @override
  State<AnimatedOrbitLogo> createState() => _AnimatedOrbitLogoState();
}

class PremiumAnimatedSurface extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const PremiumAnimatedSurface(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.radius = 28});

  @override
  State<PremiumAnimatedSurface> createState() => _PremiumAnimatedSurfaceState();
}

class _PremiumAnimatedSurfaceState extends State<PremiumAnimatedSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final lift = math.sin(controller.value * math.pi) * 3.0;
        return Transform.translate(
          offset: Offset(0, -lift),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: double.infinity,
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius),
                  gradient: LinearGradient(colors: [
                    kLoginCardStrong,
                    kLoginCard,
                    Colors.white.withOpacity(0.78)
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.95), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                        color: kLoginBlue
                            .withOpacity(0.08 + controller.value * 0.05),
                        blurRadius: 24 + controller.value * 10,
                        offset: const Offset(0, 14)),
                    BoxShadow(
                        color: Colors.white.withOpacity(0.22),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, -2)),
                  ],
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimatedQrFrame extends StatefulWidget {
  final String qrData;
  final double size;
  const AnimatedQrFrame({super.key, required this.qrData, required this.size});

  @override
  State<AnimatedQrFrame> createState() => _AnimatedQrFrameState();
}

class _AnimatedQrFrameState extends State<AnimatedQrFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4200))
      ..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        final scanY = -0.92 + (1.84 * t);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: SweepGradient(
                  startAngle: 0,
                  endAngle: math.pi * 2,
                  transform: GradientRotation(t * math.pi * 2),
                  colors: [
                    kLoginBlue.withOpacity(0.55),
                    kLoginAccent.withOpacity(0.46),
                    kLoginMintTop.withOpacity(0.46),
                    const Color(0xFFFFC766).withOpacity(0.42),
                    kLoginBlue.withOpacity(0.55),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                      color: kLoginBlue.withOpacity(0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10)),
                  BoxShadow(
                      color: kLoginAccent.withOpacity(0.10),
                      blurRadius: 28,
                      offset: const Offset(0, 12)),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data: widget.qrData,
                        size: widget.size,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square, color: FlowColors.ink),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: FlowColors.ink),
                      ),
                      Align(
                        alignment: Alignment(0, scanY),
                        child: Container(
                          width: widget.size * 0.84,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              const Color(0xFF38D5D5).withOpacity(0.95),
                              Colors.transparent
                            ]),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color(0xFF38D5D5).withOpacity(0.40),
                                  blurRadius: 10,
                                  offset: const Offset(0, 0))
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 6,
              child: _QrSpark(
                  dotSize: 8, color: const Color(0xFF5E6CFF), progress: t),
            ),
            Positioned(
              right: 10,
              top: 18,
              child: _QrSpark(
                  dotSize: 6,
                  color: const Color(0xFFFF4FB8),
                  progress: (t + 0.33) % 1),
            ),
            Positioned(
              right: 12,
              bottom: 8,
              child: _QrSpark(
                  dotSize: 9,
                  color: const Color(0xFFFFC766),
                  progress: (t + 0.66) % 1),
            ),
          ],
        );
      },
    );
  }
}

class _QrSpark extends StatelessWidget {
  final double dotSize;
  final Color color;
  final double progress;
  const _QrSpark(
      {required this.dotSize, required this.color, required this.progress});

  @override
  Widget build(BuildContext context) {
    final scale = 0.8 + math.sin(progress * math.pi * 2) * 0.25;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.42),
                blurRadius: 10,
                offset: const Offset(0, 0))
          ],
        ),
      ),
    );
  }
}

class _AnimatedOrbitLogoState extends State<AnimatedOrbitLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 9000))
      ..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final size = widget.size;
        final angle = controller.value * math.pi * 2;
        final pulse = 0.96 + math.sin(angle) * 0.06;

        if (widget.variant == OrbitLogoVariant.comet) {
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: angle * 0.24,
                  child: Container(
                    width: size * 0.96,
                    height: size * 0.62,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.42), width: 1.4),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -angle * 0.18,
                  child: Container(
                    width: size * 0.72,
                    height: size * 0.96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size),
                      border: Border.all(
                          color: kLoginAccentSoft.withOpacity(0.58),
                          width: 1.2),
                    ),
                  ),
                ),
                ...List.generate(3, (i) {
                  final radius = size * (0.30 + i * 0.04);
                  final orbitAngle = angle + i * 2.15;
                  return Positioned(
                    left: size / 2 +
                        math.cos(orbitAngle) * radius -
                        (i == 1 ? 4 : 5),
                    top: size / 2 +
                        math.sin(orbitAngle) * radius -
                        (i == 1 ? 4 : 5),
                    child: Container(
                      width: i == 1 ? 8 : 10,
                      height: i == 1 ? 8 : 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i.isEven ? kLoginAccentSoft : Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color:
                                  (i.isEven ? kLoginAccentSoft : Colors.white)
                                      .withOpacity(0.42),
                              blurRadius: 12)
                        ],
                      ),
                    ),
                  );
                }),
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: size * 0.66,
                    height: size * 0.66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        Colors.white.withOpacity(0.98),
                        Colors.white.withOpacity(0.85)
                      ]),
                      boxShadow: [
                        BoxShadow(
                            color: kLoginAccent.withOpacity(0.22),
                            blurRadius: 16,
                            spreadRadius: 1),
                        BoxShadow(
                            color: Colors.white.withOpacity(0.20),
                            blurRadius: 10),
                      ],
                    ),
                    child: Center(child: FlowMark(size: size * 0.44)),
                  ),
                ),
              ],
            ),
          );
        }

        if (widget.variant == OrbitLogoVariant.pulse) {
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: size * (0.96 + math.sin(angle) * 0.03),
                  height: size * (0.96 + math.sin(angle) * 0.03),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.26), width: 1.2),
                  ),
                ),
                Container(
                  width: size * (0.78 + math.cos(angle) * 0.02),
                  height: size * (0.78 + math.cos(angle) * 0.02),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: kLoginAccentSoft.withOpacity(0.55), width: 1.2),
                  ),
                ),
                ...List.generate(4, (i) {
                  final radius = size * 0.43;
                  final orbitAngle = angle + i * math.pi / 2;
                  return Positioned(
                    left: size / 2 + math.cos(orbitAngle) * radius - 4,
                    top: size / 2 + math.sin(orbitAngle) * radius - 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i.isEven ? kLoginAccentSoft : Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color:
                                  (i.isEven ? kLoginAccentSoft : Colors.white)
                                      .withOpacity(0.35),
                              blurRadius: 10)
                        ],
                      ),
                    ),
                  );
                }),
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: size * 0.64,
                    height: size * 0.64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [
                        Color(0xFFFFF6B5),
                        Color(0xFFFFC83F),
                        Color(0xFFFFA51E)
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [
                        BoxShadow(
                            color: kLoginAccent.withOpacity(0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: Center(child: FlowMark(size: size * 0.42)),
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: angle,
                child: CustomPaint(
                    size: Size.square(size),
                    painter: _LoginOrbitPainter(progress: controller.value)),
              ),
              FlowMark(size: size * 0.68),
            ],
          ),
        );
      },
    );
  }
}

class FlowruMainHeader extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;
  const FlowruMainHeader(
      {super.key, required this.name, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class FlowruClientQrPanel extends StatelessWidget {
  final String name;
  final String phone;
  final String payload;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onOpen;
  const FlowruClientQrPanel(
      {super.key,
      required this.name,
      required this.phone,
      required this.payload,
      required this.loading,
      required this.onRefresh,
      required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final qr = payload.trim().isNotEmpty ? payload.trim() : 'flowru-client';

    return LayoutBuilder(builder: (context, constraints) {
      final qrSize =
          (constraints.maxWidth * 0.60).clamp(196.0, 250.0).toDouble();

      return SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Text(
              'Привет, $name',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ваш единый кабинет',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'FLOWRU',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onOpen,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF27D8FF).withOpacity(0.90),
                      blurRadius: 92,
                      spreadRadius: 22,
                    ),
                    BoxShadow(
                      color: const Color(0xFF00E6FF).withOpacity(0.58),
                      blurRadius: 68,
                      spreadRadius: 12,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7F6FFF).withOpacity(0.42),
                      blurRadius: 58,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFB347).withOpacity(0.62),
                      blurRadius: 66,
                      spreadRadius: 10,
                      offset: const Offset(16, 18),
                    ),
                    BoxShadow(
                      color: FlowColors.ink.withOpacity(0.10),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: QrImageView(
                    data: qr,
                    size: qrSize,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: FlowColors.ink,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: FlowColors.ink,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _QrRefreshCapsule(
              loading: loading,
              onPressed: onRefresh,
            ),
          ],
        ),
      );
    });
  }
}

class _QrPanelActionButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _QrPanelActionButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _QrRefreshCapsule extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _QrRefreshCapsule({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF102747).withOpacity(0.58),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.0, color: Colors.white),
                )
              else
                const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Обновить код',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrDecorOrb extends StatelessWidget {
  final double size;
  final List<Color> colors;
  const _QrDecorOrb({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
        child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: colors))));
  }
}

class _FlowruQrChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FlowruQrChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class PremiumAssetIcon extends StatelessWidget {
  final String asset;
  final double size;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final bool withGlow;

  const PremiumAssetIcon({
    super.key,
    required this.asset,
    this.size = 44,
    this.fallbackIcon = Icons.auto_awesome_rounded,
    this.fallbackColor = FlowColors.ink,
    this.withGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (withGlow)
            Container(
              width: size * 0.82,
              height: size * 0.82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: FlowColors.gold.withOpacity(0.24),
                      blurRadius: size * 0.35,
                      offset: Offset(0, size * 0.10)),
                  BoxShadow(
                      color: const Color(0xFFFFC107).withOpacity(0.14),
                      blurRadius: size * 0.45,
                      offset: Offset(0, size * 0.12)),
                ],
              ),
            ),
          Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(fallbackIcon, color: fallbackColor, size: size * 0.58),
          ),
        ],
      ),
    );
  }
}

class FlowruEstablishmentEntry extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> home;
  final Map<String, dynamic> offers;
  final VoidCallback onOpen;
  const FlowruEstablishmentEntry(
      {super.key,
      required this.item,
      required this.home,
      required this.offers,
      required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final est = map(home['establishment']);
    final loyalty = map(home['loyalty']);
    final name = nonEmpty(item['establishment_name']) ??
        nonEmpty(item['name']) ??
        nonEmpty(est['name']) ??
        'Заведение';
    final points = toInt(
        item['points'] ?? loyalty['points'] ?? map(home['stats'])['points']);
    final visits = toInt(item['visits'] ??
        item['visit_count'] ??
        loyalty['visits'] ??
        map(home['stats'])['visits']);
    final imageUrl =
        extractImageUrl(item) ?? extractImageUrl(est) ?? extractImageUrl(home);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: Colors.white.withOpacity(0.34),
            border:
                Border.all(color: Colors.white.withOpacity(0.62), width: 1.15),
            boxShadow: [
              BoxShadow(
                color: FlowColors.ink.withOpacity(0.055),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 148,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(26),
                    bottomLeft: Radius.circular(26),
                  ),
                  child: SizedBox(
                    width: 132,
                    height: double.infinity,
                    child: _EstablishmentPreviewImage(
                      imageUrl: imageUrl,
                      title: name,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FlowColors.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const Spacer(),
                        _EstablishmentRowMetric(
                          label: 'Баланс бонусов',
                          value: '${formatMoney(points)}',
                          suffix: '',
                          accent: FlowColors.ink,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _EstablishmentRowMetric(
                                label: 'Посещения',
                                value: '${formatMoney(visits)}',
                                accent: FlowColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right_rounded,
                      color: FlowColors.ink, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EstablishmentPreviewImage extends StatelessWidget {
  final String? imageUrl;
  final String title;
  const _EstablishmentPreviewImage(
      {required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3BA7C9), Color(0xFF0B5278), Color(0xFF0A2B47)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.30)],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(Icons.storefront_rounded,
                color: Colors.white.withOpacity(0.82), size: 34),
          ),
        ],
      ),
    );
  }
}

class _EstablishmentRowMetric extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color accent;
  const _EstablishmentRowMetric({
    required this.label,
    required this.value,
    this.suffix = '',
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FlowColors.ink.withOpacity(0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FlowColors.ink.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FlowColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          RichText(
            textAlign: TextAlign.right,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
                if (suffix.isNotEmpty)
                  TextSpan(
                    text: ' $suffix',
                    style: TextStyle(
                      color: accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _resolveCashbackText(Map<String, dynamic> home) {
  final loyalty = map(home['loyalty']);
  final stats = map(home['stats']);
  final est = map(home['establishment']);
  final card = map(home['card']);
  final profile = map(home['profile']);
  final profileInner = map(profile['profile']);
  final modules = map(profileInner['modules']);
  final directRules = map(home['loyalty_rules']);
  final modulesDirect = map(home['modules']);
  final walletLike = map(home['settings']);
  final loyaltyRules = map(modules['loyalty']).isNotEmpty
      ? map(modules['loyalty'])
      : (map(modulesDirect['loyalty']).isNotEmpty
          ? map(modulesDirect['loyalty'])
          : (directRules.isNotEmpty ? directRules : walletLike));

  final direct = nonEmpty(loyalty['cashback_text']) ??
      nonEmpty(loyalty['percent_text']) ??
      nonEmpty(loyalty['cashback_label']) ??
      nonEmpty(card['cashback_text']) ??
      nonEmpty(card['cashback_label']) ??
      nonEmpty(est['cashback_text']) ??
      nonEmpty(est['cashback_percent_text']) ??
      nonEmpty(est['cashback_label']) ??
      nonEmpty(home['cashback_text']) ??
      nonEmpty(home['cashback_label']);
  if (direct != null) return direct;

  final directPercent = toDouble(loyalty['cashback_percent'] ??
      loyalty['cashback'] ??
      loyalty['percent'] ??
      card['cashback_percent'] ??
      est['cashback_percent'] ??
      est['cashback'] ??
      est['percent'] ??
      home['cashback_percent'] ??
      home['cashback']);
  if (directPercent > 0) return '${formatPercent(directPercent)}%';

  final levels = mapList(loyaltyRules['cashback_levels']).isNotEmpty
      ? mapList(loyaltyRules['cashback_levels'])
      : mapList(loyalty['cashback_levels']);
  if (levels.isNotEmpty) {
    Map<String, dynamic>? best;
    final sales = toDouble(loyalty['sales_total'] ?? stats['sales_total']);
    for (final level in levels) {
      final required = toDouble(level['spent_required'] ??
          level['min_spent'] ??
          level['from_amount'] ??
          level['threshold']);
      if (sales >= required) best = level;
    }
    best ??= levels.first;
    final percent = toDouble(best['cashback_percent'] ??
        best['percent'] ??
        best['cashback'] ??
        best['value']);
    if (percent > 0) return '${formatPercent(percent)}%';
  }

  final mode = (nonEmpty(loyaltyRules['mode']) ??
          nonEmpty(loyalty['mode']) ??
          nonEmpty(est['loyalty_mode']) ??
          '')
      .toLowerCase();
  if (mode == 'cashback' || mode.contains('кэш')) return 'Кэшбэк';
  return '—';
}

String? _resolveMenuPhotoUrl(
    Map<String, dynamic> est, Map<String, dynamic> home,
    [Map<String, dynamic>? profile]) {
  final safeProfile = profile == null ? <String, dynamic>{} : profile;
  final profileEst = map(safeProfile['establishment']);
  final estMenu = map(est['menu']);
  final homeMenu = map(home['menu']);
  final profileMenu = map(safeProfile['menu']);
  final estModules = map(est['modules']);
  final homeModules = map(home['modules']);
  final profileModules = map(safeProfile['modules']);
  final estModulesMenu = map(estModules['menu']);
  final homeModulesMenu = map(homeModules['menu']);
  final profileModulesMenu = map(profileModules['menu']);

  String? firstTextFromAny(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      return nonEmpty(value);
    }

    if (value is List) {
      for (final item in value) {
        final resolved = firstTextFromAny(item);
        if (resolved != null) return resolved;
      }
      return null;
    }

    if (value is Map) {
      final m = Map<String, dynamic>.from(value);
      return nonEmpty(m['photo_url']) ??
          nonEmpty(m['image_url']) ??
          nonEmpty(m['cover_url']) ??
          nonEmpty(m['url']) ??
          nonEmpty(m['src']) ??
          nonEmpty(m['file_url']) ??
          nonEmpty(m['menu_photo_url']) ??
          nonEmpty(m['menu_image_url']) ??
          nonEmpty(m['menu_cover_url']);
    }

    return null;
  }

  return nonEmpty(est['menu_photo_url']) ??
      nonEmpty(est['menu_image_url']) ??
      nonEmpty(est['menu_cover_url']) ??
      nonEmpty(est['menu_cover']) ??
      nonEmpty(est['menu_photo_path']) ??
      nonEmpty(est['menu_image_path']) ??
      nonEmpty(est['menu_url']) ??
      firstTextFromAny(est['menu_cover_urls']) ??
      firstTextFromAny(est['menu_images']) ??
      firstTextFromAny(est['menu_covers']) ??
      nonEmpty(estMenu['photo_url']) ??
      nonEmpty(estMenu['image_url']) ??
      nonEmpty(estMenu['cover_url']) ??
      nonEmpty(estMenu['url']) ??
      firstTextFromAny(estMenu['menu_cover_urls']) ??
      firstTextFromAny(estMenu['menu_images']) ??
      firstTextFromAny(estMenu['menu_covers']) ??
      firstTextFromAny(estModulesMenu['menu_cover_urls']) ??
      firstTextFromAny(estModulesMenu['menu_images']) ??
      firstTextFromAny(estModulesMenu['menu_covers']) ??
      nonEmpty(home['menu_photo_url']) ??
      nonEmpty(home['menu_image_url']) ??
      nonEmpty(home['menu_cover_url']) ??
      nonEmpty(home['menu_cover']) ??
      nonEmpty(home['menu_photo_path']) ??
      nonEmpty(home['menu_image_path']) ??
      firstTextFromAny(home['menu_cover_urls']) ??
      firstTextFromAny(home['menu_images']) ??
      firstTextFromAny(home['menu_covers']) ??
      nonEmpty(homeMenu['photo_url']) ??
      nonEmpty(homeMenu['image_url']) ??
      nonEmpty(homeMenu['cover_url']) ??
      nonEmpty(homeMenu['url']) ??
      firstTextFromAny(homeMenu['menu_cover_urls']) ??
      firstTextFromAny(homeMenu['menu_images']) ??
      firstTextFromAny(homeMenu['menu_covers']) ??
      firstTextFromAny(homeModulesMenu['menu_cover_urls']) ??
      firstTextFromAny(homeModulesMenu['menu_images']) ??
      firstTextFromAny(homeModulesMenu['menu_covers']) ??
      nonEmpty(safeProfile['menu_photo_url']) ??
      nonEmpty(safeProfile['menu_image_url']) ??
      nonEmpty(safeProfile['menu_cover_url']) ??
      firstTextFromAny(safeProfile['menu_cover_urls']) ??
      firstTextFromAny(safeProfile['menu_images']) ??
      firstTextFromAny(safeProfile['menu_covers']) ??
      nonEmpty(profileEst['menu_photo_url']) ??
      nonEmpty(profileEst['menu_image_url']) ??
      nonEmpty(profileEst['menu_cover_url']) ??
      firstTextFromAny(profileMenu['menu_cover_urls']) ??
      firstTextFromAny(profileMenu['menu_images']) ??
      firstTextFromAny(profileMenu['menu_covers']) ??
      firstTextFromAny(profileModulesMenu['menu_cover_urls']) ??
      firstTextFromAny(profileModulesMenu['menu_images']) ??
      firstTextFromAny(profileModulesMenu['menu_covers']);
}

class EstablishmentFullScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> home;
  final Map<String, dynamic> offers;
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> history;
  final Future<void> Function(Map<String, dynamic> draw)? onJoinDraw;
  final String? birthDateText;
  final int birthdayGiftPoints;
  final bool birthdayCampaignEnabled;
  final String? referralLink;
  final bool referralProgramEnabled;
  final String? appleWalletUrl;
  final String? googleWalletUrl;
  final VoidCallback? onOpenBirthday;
  final VoidCallback? onOpenReferral;

  const EstablishmentFullScreen({
    super.key,
    required this.item,
    required this.home,
    required this.offers,
    required this.profile,
    required this.history,
    this.onJoinDraw,
    this.birthDateText,
    this.birthdayGiftPoints = 0,
    this.birthdayCampaignEnabled = false,
    this.referralLink,
    this.referralProgramEnabled = false,
    this.appleWalletUrl,
    this.googleWalletUrl,
    this.onOpenBirthday,
    this.onOpenReferral,
  });

  @override
  State<EstablishmentFullScreen> createState() =>
      _EstablishmentFullScreenState();
}

class _EstablishmentFullScreenState extends State<EstablishmentFullScreen> {
  int innerTab = 0;

  List<Map<String, dynamic>> _extractQuestItems(Map<String, dynamic> data) {
    final raw = <Map<String, dynamic>>[
      ...mapList(data['quests']),
      ...mapList(data['active_quests']),
      ...mapList(map(data['quest_block'])['quests']),
      ...mapList(map(data['quest_block'])['items']),
      ...mapList(map(data['quest_progress'])['quests']),
      ...mapList(map(data['quest_progress'])['items']),
    ];

    final byKey = <String, Map<String, dynamic>>{};

    for (final item in raw) {
      final key = (item['id'] ??
              item['quest_id'] ??
              item['legacy_id'] ??
              item['title'] ??
              item['name'] ??
              item.hashCode)
          .toString();
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = item;
        continue;
      }

      // Если backend прислал несколько progress по одному квесту, оставляем более «живую» запись:
      // незавершённую — выше завершённой, иначе более свежую по completed_at/progress.
      final existingCompleted = boolValue(existing['is_completed']);
      final currentCompleted = boolValue(item['is_completed']);
      if (existingCompleted && !currentCompleted) {
        byKey[key] = item;
        continue;
      }
      final existingDate = (existing['completed_at'] ??
              existing['updated_at'] ??
              existing['created_at'] ??
              '')
          .toString();
      final currentDate = (item['completed_at'] ??
              item['updated_at'] ??
              item['created_at'] ??
              '')
          .toString();
      if (currentDate.compareTo(existingDate) > 0) byKey[key] = item;
    }

    final result = byKey.values.toList();
    result.sort((a, b) {
      final ac = boolValue(a['is_completed']);
      final bc = boolValue(b['is_completed']);
      if (ac != bc) return ac ? 1 : -1;
      return (a['title'] ?? '')
          .toString()
          .compareTo((b['title'] ?? '').toString());
    });
    return result;
  }

  String _questProgressText(Map<String, dynamic> quest) {
    final direct = nonEmpty(quest['progress_text']) ??
        nonEmpty(quest['status_text']) ??
        nonEmpty(quest['progress_label']);
    if (direct != null) return direct;
    final current = toInt(quest['progress'] ??
        quest['current'] ??
        quest['done'] ??
        quest['completed']);
    final target = toInt(quest['target'] ?? quest['goal'] ?? quest['required']);
    if (target > 0) return '$current из $target выполнено';
    return nonEmpty(quest['description']) ?? 'Активное задание от заведения';
  }

  String _questRewardText(Map<String, dynamic> quest) {
    return nonEmpty(quest['reward_text']) ??
        nonEmpty(quest['reward']) ??
        nonEmpty(quest['reward_title']) ??
        'Награда от заведения';
  }

  String _questConditionText(Map<String, dynamic> quest) {
    return nonEmpty(quest['condition_text']) ??
        nonEmpty(quest['conditions']) ??
        nonEmpty(quest['task_text']) ??
        nonEmpty(quest['description']) ??
        'Условия будут показаны после настройки квеста в заведении';
  }

  String _questPeriodText(Map<String, dynamic> quest) {
    final start = nonEmpty(quest['start_at']) ??
        nonEmpty(quest['starts_at']) ??
        nonEmpty(quest['start_date']);
    final end = nonEmpty(quest['end_at']) ??
        nonEmpty(quest['expires_at']) ??
        nonEmpty(quest['end_date']) ??
        nonEmpty(quest['finish_at']);
    if (start != null && end != null)
      return '${formatClientDateTime(start)} — ${formatClientDateTime(end)}';
    if (end != null) return 'До ${formatClientDateTime(end)}';
    if (start != null) return 'С ${formatClientDateTime(start)}';
    return nonEmpty(quest['period_text']) ??
        nonEmpty(quest['time_text']) ??
        'Срок не ограничен';
  }

  Map<String, dynamic> _jsonMapFromQuestValue(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return {};
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map)
        return decoded.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {}
    return {};
  }

  bool _questTextLooksGeneric(String text) {
    final v = text.trim().toLowerCase();
    if (v.isEmpty) return true;
    if (v == 'совершите визит' || v == 'совершите покупку') return true;
    if (v.contains('условия будут показаны')) return true;
    if (v.contains('активное задание от заведения')) return true;
    if (v.endsWith('...') || v.contains('...')) return true;
    return false;
  }

  dynamic _questParam(Map<String, dynamic> quest, Map<String, dynamic> params,
      List<String> keys) {
    for (final key in keys) {
      final fromParams = params[key];
      if (fromParams != null && fromParams.toString().trim().isNotEmpty)
        return fromParams;
      final fromQuest = quest[key];
      if (fromQuest != null && fromQuest.toString().trim().isNotEmpty)
        return fromQuest;
    }
    return null;
  }

  String _questWeekDaysText(dynamic value) {
    final names = {
      '1': 'понедельник',
      '2': 'вторник',
      '3': 'среду',
      '4': 'четверг',
      '5': 'пятницу',
      '6': 'субботу',
      '7': 'воскресенье',
      '0': 'воскресенье',
      'mon': 'понедельник',
      'monday': 'понедельник',
      'tue': 'вторник',
      'tuesday': 'вторник',
      'wed': 'среду',
      'wednesday': 'среду',
      'thu': 'четверг',
      'thursday': 'четверг',
      'fri': 'пятницу',
      'friday': 'пятницу',
      'sat': 'субботу',
      'saturday': 'субботу',
      'sun': 'воскресенье',
      'sunday': 'воскресенье',
    };
    final raw = value;
    final items = <String>[];
    if (raw is List) {
      for (final x in raw) {
        final key = x.toString().trim().toLowerCase();
        if (key.isNotEmpty) items.add(names[key] ?? key);
      }
    } else {
      final text = raw?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        for (final x in text
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(RegExp(r'[,;\s]+'))) {
          final key = x.trim().toLowerCase();
          if (key.isNotEmpty) items.add(names[key] ?? key);
        }
      }
    }
    final unique = items.toSet().toList();
    if (unique.isEmpty) return '';
    if (unique.length == 1) return 'по дням: ${unique.first}';
    return 'по дням: ${unique.join(', ')}';
  }

  String _questPeriodLabel(dynamic value) {
    final v = value?.toString().trim().toLowerCase() ?? '';
    if (v.isEmpty) return '';
    if (v == 'morning') return 'утром';
    if (v == 'day' || v == 'afternoon') return 'днём';
    if (v == 'evening') return 'вечером';
    if (v == 'night') return 'ночью';
    if (v == 'week') return 'в течение недели';
    if (v == 'month') return 'в течение месяца';
    return v;
  }

  String _normalizeQuestTime(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    final asNum = num.tryParse(raw.replaceAll(',', '.'));
    if (asNum != null) {
      final h = asNum.floor().clamp(0, 23);
      final m = ((asNum - asNum.floor()) * 60).round().clamp(0, 59);
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    final match = RegExp(r'(\d{1,2})(?::(\d{1,2}))?').firstMatch(raw);
    if (match == null) return raw;
    final h = int.tryParse(match.group(1) ?? '')?.clamp(0, 23) ?? 0;
    final m = int.tryParse(match.group(2) ?? '0')?.clamp(0, 59) ?? 0;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _questConditionReadable(Map<String, dynamic> quest) {
    final params = <String, dynamic>{
      ..._jsonMapFromQuestValue(quest['condition_params']),
      ..._jsonMapFromQuestValue(quest['params']),
      ..._jsonMapFromQuestValue(quest['settings']),
      ..._jsonMapFromQuestValue(quest['rules']),
      ..._jsonMapFromQuestValue(quest['condition']),
      ..._jsonMapFromQuestValue(quest['criteria']),
      ..._jsonMapFromQuestValue(quest['config']),
      ..._jsonMapFromQuestValue(quest['completion_rules']),
      ..._jsonMapFromQuestValue(quest['trigger_params']),
      ..._jsonMapFromQuestValue(quest['schedule']),
      ..._jsonMapFromQuestValue(quest['time_rules']),
    };

    final direct = nonEmpty(quest['condition_text']) ??
        nonEmpty(quest['conditions_text']) ??
        nonEmpty(quest['condition_description']) ??
        nonEmpty(quest['how_to_complete']) ??
        nonEmpty(quest['task_text']) ??
        nonEmpty(quest['rules_text']);

    final type = (quest['condition_type'] ??
            quest['template_key'] ??
            quest['quest_type'] ??
            '')
        .toString()
        .toLowerCase();
    final minAmountRaw = _questParam(quest, params, [
      'min_amount',
      'amount_from',
      'min_purchase_amount',
      'purchase_amount',
      'required_amount',
      'amount',
      'sum_from',
      'min_sum',
      'min_check',
      'check_from',
      'min_total',
      'purchase_sum',
      'required_spend',
      'amount_rub',
      'min_bill',
      'check_amount'
    ]);
    final requiredCountRaw = _questParam(quest, params, [
      'required_count',
      'count',
      'visits_count',
      'visit_count',
      'target',
      'goal',
      'required'
    ]);
    final periodDaysRaw = _questParam(
        quest, params, ['period_days', 'days', 'within_days', 'duration_days']);
    final fromTime = nonEmpty(_normalizeQuestTime(_questParam(quest, params, [
      'from_time',
      'start_time',
      'time_from',
      'hour_from',
      'starts_time',
      'time_window_from',
      'visit_time_from',
      'start_hour'
    ])));
    final toTime = nonEmpty(_normalizeQuestTime(_questParam(quest, params, [
      'to_time',
      'end_time',
      'time_to',
      'hour_to',
      'ends_time',
      'time_window_to',
      'visit_time_to',
      'end_hour'
    ])));
    final daysText = _questWeekDaysText(_questParam(quest, params, [
      'weekdays',
      'days_of_week',
      'weekday',
      'week_days',
      'allowed_weekdays',
      'week_days_json',
      'valid_days'
    ]));
    final period = nonEmpty(_questPeriodLabel(
        _questParam(quest, params, ['period', 'period_text', 'period_label'])));

    if (direct != null && !_questTextLooksGeneric(direct)) return direct;

    final parts = <String>[];
    final minAmount = toDouble(minAmountRaw);
    final requiredCount = toInt(requiredCountRaw);
    final periodDays = toInt(periodDaysRaw);

    if (type.contains('amount') ||
        type.contains('purchase') ||
        type.contains('check') ||
        minAmount > 0) {
      parts.add(minAmount > 0
          ? 'Покупка от ${formatMoney(minAmount)} ₽'
          : 'Совершите покупку');
    } else if (type.contains('streak')) {
      parts.add(requiredCount > 0
          ? 'Серия из ${formatMoney(requiredCount)} визитов'
          : 'Серия визитов');
    } else if (type.contains('morning')) {
      parts.add('Утренний визит');
    } else if (type.contains('evening')) {
      parts.add('Вечерний визит');
    } else if (type.contains('visit') || requiredCount > 0) {
      parts.add(requiredCount > 0
          ? '${formatMoney(requiredCount)} визита'
          : 'Совершите визит');
    }

    if (fromTime != null && toTime != null) {
      parts.add('с $fromTime до $toTime');
    } else if (fromTime != null) {
      parts.add('после $fromTime');
    } else if (toTime != null) {
      parts.add('до $toTime');
    }
    if (daysText.isNotEmpty) parts.add(daysText);
    if (periodDays > 0) parts.add('за ${formatMoney(periodDays)} дней');
    if (period != null &&
        !parts.join(' ').toLowerCase().contains(period.toLowerCase()))
      parts.add(period);

    if (parts.isNotEmpty) {
      final text = parts.join(' · ');
      return text[0].toUpperCase() + text.substring(1);
    }

    if (direct != null) return direct;
    return _questConditionText(quest);
  }

  String _questRewardReadable(Map<String, dynamic> quest) {
    final type = (quest['reward_type'] ?? '').toString();
    final params = _jsonMapFromQuestValue(quest['reward_params']);
    final value = params['value'];

    if (type == 'bonus_points' && value != null)
      return '+${formatMoney(toInt(value))} баллов';
    if (type == 'cashback_boost_percent' && value != null)
      return '+${formatMoney(toInt(value))}% кэшбэка';
    return _questRewardText(quest);
  }

  @override
  Widget build(BuildContext context) {
    final est = map(widget.home['establishment']);
    final client = map(widget.home['client']);
    final loyalty = map(widget.home['loyalty']);
    final stats = map(widget.home['stats']);
    final liveProfile = map(widget.profile['profile']);
    final liveEst = map(liveProfile['establishment']);
    final contacts = map(liveProfile['contacts']);
    final ratings = map(liveProfile['ratings']);
    final modules = map(liveProfile['modules']);
    final liveLoyaltyRules = map(modules['loyalty']);
    final name = nonEmpty(widget.item['establishment_name']) ??
        nonEmpty(est['name']) ??
        nonEmpty(liveEst['name']) ??
        'Заведение';
    final points =
        toInt(widget.item['points'] ?? loyalty['points'] ?? stats['points']);
    final visits =
        toInt(widget.item['visits'] ?? loyalty['visits'] ?? stats['visits']);
    final sales = toDouble(loyalty['sales_total'] ?? stats['sales_total']);
    final lastVisit =
        (loyalty['last_visit_at'] ?? stats['last_visit_at'] ?? '').toString();
    final establishmentImageUrl = extractImageUrl(widget.item) ??
        extractImageUrl(est) ??
        extractImageUrl(liveEst) ??
        extractImageUrl(widget.home);
    final data = widget.offers.isNotEmpty ? widget.offers : widget.home;
    final promoItems = <PromoItem>[];
    for (final e in mapList(data['banners']).take(20)) {
      promoItems.add(PromoItem(
          tag: e['tag']?.toString() ?? 'акция',
          title: nonEmpty(e['title']) ?? 'Акция',
          subtitle: nonEmpty(e['subtitle']) ??
              nonEmpty(e['description']) ??
              'Предложение заведения',
          icon: Icons.local_fire_department_rounded,
          color: kLoginPink,
          imageUrl: extractImageUrl(e),
          rawData: e));
    }
    final draws = <Map<String, dynamic>>[];
    if (map(data['draw_banner']).isNotEmpty)
      draws.add(map(data['draw_banner']));
    draws.addAll(mapList(data['draws']));
    for (final e in draws.take(10)) {
      promoItems.add(PromoItem(
          tag: 'розыгрыш',
          title: nonEmpty(e['title']) ?? 'Розыгрыш',
          subtitle: nonEmpty(e['prize_text']) ??
              nonEmpty(e['description']) ??
              'Подробности розыгрыша',
          icon: Icons.emoji_events_rounded,
          color: FlowColors.violet,
          imageUrl: extractImageUrl(e),
          rawData: {
            ...e,
            'establishment_id': intOrNull(widget.item['establishment_id'])
          },
          isRaffle: true));
    }
    for (final e in mapList(data['rewards']).take(10)) {
      promoItems.add(PromoItem(
          tag: 'награда',
          title: nonEmpty(e['title']) ?? nonEmpty(e['name']) ?? 'Награда',
          subtitle: nonEmpty(e['description']) ?? 'Доступная награда',
          icon: Icons.workspace_premium_rounded,
          color: FlowColors.green,
          imageUrl: extractImageUrl(e),
          rawData: e));
    }

    var quests = _extractQuestItems(widget.home);
    if (quests.isEmpty) quests = _extractQuestItems(widget.offers);
    if (quests.isEmpty) quests = _extractQuestItems(widget.item);
    final address = nonEmpty(liveEst['address']) ??
        nonEmpty(contacts['address']) ??
        nonEmpty(est['address']) ??
        '';
    final phone = nonEmpty(contacts['phone']) ??
        nonEmpty(liveEst['phone']) ??
        nonEmpty(est['phone']) ??
        '';
    final hours = nonEmpty(contacts['working_hours']) ??
        nonEmpty(liveEst['working_hours']) ??
        '';
    final yandexUrl = nonEmpty(ratings['yandex_url']) ??
        nonEmpty(contacts['yandex_url']) ??
        '';
    final twoGisUrl = nonEmpty(ratings['two_gis_url']) ??
        nonEmpty(contacts['two_gis_url']) ??
        '';
    final yandexRatingText = nonEmpty(ratings['yandex_rating']) ?? '';
    final twoGisRatingText = nonEmpty(ratings['two_gis_rating']) ?? '';

    final pages = <Widget>[
      _establishmentBenefits(name, points, promoItems),
      _establishmentQuests(quests),
      _establishmentHistory(widget.history),
      _establishmentMenu(
          name,
          _resolveMenuPhotoUrl(
              est, widget.home, map(widget.profile['profile']))),
      _establishmentInfo(
          name,
          address,
          phone,
          hours,
          yandexUrl,
          twoGisUrl,
          yandexRatingText,
          twoGisRatingText,
          liveLoyaltyRules,
          points,
          sales,
          est),
      _establishmentProfile(
          name, points, visits, sales, lastVisit, client, loyalty),
    ];

    return AppFrame(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(18),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DailyPulse(home: widget.home),
              const SizedBox(height: 12),
              _EstablishmentOverviewCard(
                name: name,
                points: points,
                visits: visits,
                cashback: _resolveCashbackText(widget.home),
                imageUrl: establishmentImageUrl,
              ),
              const SizedBox(height: 14),
              EstablishmentTabSwitch(
                current: innerTab,
                onChanged: (v) => setState(() => innerTab = v),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final fade = CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic);
                  final slide = Tween<Offset>(
                          begin: const Offset(0.08, 0), end: Offset.zero)
                      .animate(fade);
                  final scale =
                      Tween<double>(begin: 0.985, end: 1.0).animate(fade);
                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: slide,
                      child: ScaleTransition(scale: scale, child: child),
                    ),
                  );
                },
                child: KeyedSubtree(
                    key: ValueKey(innerTab), child: pages[innerTab]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _establishmentBenefits(
      String name, int points, List<PromoItem> promoItems) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _EstablishmentSectionHero(
        icon: Icons.auto_awesome_rounded,
        title: 'Выгода',
        subtitle: 'Акции, розыгрыши и награды выбранного заведения',
        value: '',
        label: '',
        accent: FlowColors.acid,
      ),
      const SizedBox(height: 12),
      OfferTicker(items: promoItems, onJoin: widget.onJoinDraw),
    ]);
  }

  Widget _establishmentQuests(List<Map<String, dynamic>> quests) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _EstablishmentSectionHero(
        icon: Icons.flag_rounded,
        title: 'Квесты',
        subtitle: 'Задания, условия и награды выбранного заведения',
        value: '${quests.length}',
        label: 'квестов',
        accent: FlowColors.violet,
      ),
      const SizedBox(height: 12),
      if (quests.isEmpty)
        const EmptyState(
            icon: Icons.flag_rounded,
            title: 'Пока нет активных квестов',
            subtitle: 'Когда заведение включит задания, они появятся здесь.')
      else
        ...quests.map((quest) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfaceCard(
                radius: 28,
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            width: 54,
                            height: 54,
                            alignment: Alignment.center,
                            child: const Icon(Icons.emoji_events_rounded,
                                color: FlowColors.gold, size: 36)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                  nonEmpty(quest['title']) ??
                                      nonEmpty(quest['name']) ??
                                      'Активный квест',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: FlowColors.ink,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(_questProgressText(quest),
                                  style: const TextStyle(
                                      color: FlowColors.muted,
                                      height: 1.3,
                                      fontWeight: FontWeight.w800)),
                            ])),
                      ]),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: FlowColors.ink.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(18)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _QuestFactLine(
                                icon: Icons.schedule_rounded,
                                iconColor: const Color(0xFF0F766E),
                                text: _questPeriodText(quest),
                                weight: FontWeight.w800,
                              ),
                              const SizedBox(height: 8),
                              _QuestFactLine(
                                icon: Icons.rule_rounded,
                                iconColor: const Color(0xFF6D28D9),
                                text: _questConditionReadable(quest),
                                weight: FontWeight.w800,
                              ),
                              const SizedBox(height: 8),
                              _QuestFactLine(
                                icon: Icons.workspace_premium_rounded,
                                iconColor: const Color(0xFFB77900),
                                text: _questRewardReadable(quest),
                                weight: FontWeight.w900,
                              ),
                            ]),
                      ),
                    ]),
              ),
            )),
    ]);
  }

  Widget _establishmentHistory(List<Map<String, dynamic>> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _EstablishmentSectionHero(
        icon: Icons.receipt_long_rounded,
        title: 'История',
        subtitle: 'Начисления, списания и покупки только в этом заведении',
        value: '${items.length}',
        label: 'операций',
        accent: FlowColors.aqua,
      ),
      const SizedBox(height: 12),
      TimelineList(history: items, loading: false),
    ]);
  }

  Widget _establishmentMenu(String name, String? menuPhotoUrl) {
    final url = (menuPhotoUrl ?? '').trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _EstablishmentSectionHero(
        icon: Icons.restaurant_menu_rounded,
        title: 'Меню',
        subtitle: 'Фото меню, которое заведению загрузили в админке',
        value: url.isNotEmpty ? 'есть' : '—',
        label: 'фото',
        accent: FlowColors.gold,
      ),
      const SizedBox(height: 12),
      if (url.isEmpty)
        const EmptyState(
          icon: Icons.restaurant_menu_rounded,
          title: 'Меню пока не загружено',
          subtitle:
              'Когда заведение добавит фото меню в админке, оно появится здесь.',
        )
      else
        SurfaceCard(
          radius: 30,
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                color: Colors.white.withOpacity(0.30),
                child: Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 260,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.34),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 260,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.42),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Не удалось загрузить фото меню',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: FlowColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Меню $name',
              style: const TextStyle(
                color: FlowColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Актуальное изображение меню из админки заведения.',
              style: TextStyle(
                color: FlowColors.muted,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ]),
        ),
    ]);
  }

  Widget _establishmentInfo(
      String name,
      String address,
      String phone,
      String hours,
      String yandexUrl,
      String twoGisUrl,
      String yandexRatingText,
      String twoGisRatingText,
      Map<String, dynamic> liveLoyaltyRules,
      int points,
      double sales,
      Map<String, dynamic> est) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _EstablishmentSectionHero(
        icon: Icons.info_outline_rounded,
        title: 'Инфо',
        subtitle: 'Контакты, правила и полезная информация о заведении',
        value: phone.trim().isNotEmpty ? 'есть' : '—',
        label: 'контакты',
        accent: kLoginBlue,
      ),
      const SizedBox(height: 12),
      EstablishmentInfoPanel(
        establishmentName: name,
        address: address,
        phone: phone,
        workingHours: hours,
        yandexUrl: yandexUrl,
        twoGisUrl: twoGisUrl,
        yandexRatingText: yandexRatingText,
        twoGisRatingText: twoGisRatingText,
        menuPhotoUrl: _resolveMenuPhotoUrl(
            est, widget.home, map(widget.profile['profile'])),
        socialMedia: map(
            map(map(widget.profile['profile'])['contacts'])['social_media']),
        onShowRules: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: SingleChildScrollView(
                    child: LiveLoyaltyRulesCard(
                        rules: liveLoyaltyRules,
                        points: points,
                        sales: sales)))),
      ),
    ]);
  }

  Widget _establishmentProfile(
      String name,
      int points,
      int visits,
      double sales,
      String lastVisit,
      Map<String, dynamic> client,
      Map<String, dynamic> loyalty) {
    final hasWallet = ((widget.appleWalletUrl ?? '').trim().isNotEmpty ||
        (widget.googleWalletUrl ?? '').trim().isNotEmpty);
    final profileValue =
        hasWallet ? 'wallet' : (widget.referralProgramEnabled ? 'invite' : '—');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _EstablishmentSectionHero(
        icon: Icons.person_outline_rounded,
        title: 'Профиль',
        subtitle: 'Wallet и приглашения этого заведения',
        value: profileValue,
        label: 'сервисы',
        accent: kLoginPink,
      ),
      if (hasWallet) ...[
        const SizedBox(height: 12),
        WalletHubCard(
            establishmentName: name,
            appleWalletUrl: widget.appleWalletUrl,
            googleWalletUrl: widget.googleWalletUrl),
      ],
      if (widget.referralProgramEnabled) ...[
        const SizedBox(height: 12),
        ReferralInviteCard(
            referralLink: widget.referralLink,
            onRefresh: widget.onOpenReferral ?? () {}),
      ],
      if (!hasWallet && !widget.referralProgramEnabled) ...[
        const SizedBox(height: 12),
        const EmptyState(
            icon: Icons.person_outline_rounded,
            title: 'Пока пусто',
            subtitle:
                'Wallet и приглашения появятся здесь, когда заведение их включит.'),
      ],
    ]);
  }
}

class _QuestFactLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final FontWeight weight;

  const _QuestFactLine({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.76),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.92), width: 1),
          boxShadow: [
            BoxShadow(
              color: FlowColors.ink.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 17),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            text,
            style: TextStyle(
              color: FlowColors.ink,
              fontWeight: weight,
              height: 1.32,
            ),
          ),
        ),
      ),
    ]);
  }
}

class _EstablishmentOverviewCard extends StatelessWidget {
  final String name;
  final int points;
  final int visits;
  final String cashback;
  final String? imageUrl;

  const _EstablishmentOverviewCard({
    required this.name,
    required this.points,
    required this.visits,
    required this.cashback,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withOpacity(0.34),
        border: Border.all(color: Colors.white.withOpacity(0.66), width: 1.15),
        boxShadow: [
          BoxShadow(
            color: FlowColors.ink.withOpacity(0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 164,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FlowColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.45,
                      ),
                    ),
                    const Spacer(),
                    _TopStatLine(
                      label: 'Баланс бонусов',
                      value: formatMoney(points),
                      accent: FlowColors.ink,
                    ),
                    const SizedBox(height: 9),
                    _TopStatLine(
                      label: 'Посещения',
                      value: formatMoney(visits),
                      accent: FlowColors.ink,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 132,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: _EstablishmentPreviewImage(
                  imageUrl: imageUrl,
                  title: name,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopStatLine extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _TopStatLine(
      {required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FlowColors.ink.withOpacity(0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FlowColors.ink.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: FlowColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstablishmentSectionHero extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String label;
  final Color accent;

  const _EstablishmentSectionHero({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withOpacity(0.24),
        border: Border.all(color: Colors.white.withOpacity(0.56), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: FlowColors.ink.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FlowColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.55,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FlowColors.muted,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (value.trim().isNotEmpty || label.trim().isNotEmpty) ...[
            const SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FlowColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                if (label.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FlowColors.soft,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EstablishmentMetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EstablishmentMetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FlowColors.ink.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FlowColors.ink.withOpacity(0.06)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: FlowColors.ink, size: 16),
        const SizedBox(width: 7),
        Text(text,
            style: const TextStyle(
                color: FlowColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class EstablishmentTabSwitch extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  const EstablishmentTabSwitch(
      {super.key, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (Icons.local_offer_rounded, 'Выгода'),
      (Icons.flag_circle_rounded, 'Квесты'),
      (Icons.receipt_long_rounded, 'История'),
      (Icons.restaurant_menu_rounded, 'Меню'),
      (Icons.info_outline_rounded, 'Инфо'),
      (Icons.account_circle_outlined, 'Профиль'),
    ];

    return Row(
      children: List.generate(tabs.length, (i) {
        final active = i == current;
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    scale: active ? 1.10 : 0.96,
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: active ? 1 : 0,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: FlowColors.gold.withOpacity(0.70),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFFD700)
                                        .withOpacity(0.36),
                                    blurRadius: 34,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Icon(
                            tabs[i].$1,
                            size: active ? 34 : 30,
                            color: active ? FlowColors.gold : FlowColors.ink,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tabs[i].$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? FlowColors.ink : FlowColors.soft,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class CommandHeader extends StatelessWidget {
  final String name;
  final String establishment;
  final VoidCallback onLogout;
  const CommandHeader(
      {super.key,
      required this.name,
      required this.establishment,
      required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const AnimatedOrbitLogo(size: 86, variant: OrbitLogoVariant.orbit),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1)),
          const SizedBox(height: 8),
          Text('Ваш личный бонусный кабинет',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontWeight: FontWeight.w700)),
        ]),
      ),
      Container(
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withOpacity(0.48))),
        child: IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white)),
      ),
    ]);
  }
}

class ScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final OrbitLogoVariant variant;
  const ScreenHeader(
      {super.key,
      required this.title,
      required this.subtitle,
      this.accent = kLoginBlue,
      this.icon = Icons.auto_awesome_rounded,
      this.variant = OrbitLogoVariant.orbit});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const AnimatedOrbitLogo(size: 86, variant: OrbitLogoVariant.orbit),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1)),
          const SizedBox(height: 8),
          Text(subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontWeight: FontWeight.w700,
                  height: 1.25)),
        ]),
      ),
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withOpacity(0.38))),
        child: Icon(icon, color: Colors.white.withOpacity(0.92), size: 21),
      ),
    ]);
  }
}

class DailyPulse extends StatelessWidget {
  final Map<String, dynamic> home;
  const DailyPulse({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    final wish = map(home['daily_wish']);
    final text = nonEmpty(wish['text']) ??
        nonEmpty(home['daily_wish_text']) ??
        'Пусть сегодня ваши бонусы работают на вас.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.20),
            Colors.white.withOpacity(0.10)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.30)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          const DailyWishAnimation(size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Пожелание дня',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
                const SizedBox(height: 5),
                Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.28,
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommandBalancePanel extends StatelessWidget {
  final String establishment;
  final String clientName;
  final int points;
  final String code;
  final String phone;
  final int visits;
  final String lastVisit;
  final String loyaltyLevel;
  final String loyaltyModeLabel;
  final String pointsExpireText;
  final String? appleWalletUrl;
  final String? googleWalletUrl;
  final VoidCallback onQr;

  const CommandBalancePanel(
      {super.key,
      required this.establishment,
      required this.clientName,
      required this.points,
      required this.code,
      required this.phone,
      required this.visits,
      required this.lastVisit,
      required this.loyaltyLevel,
      required this.loyaltyModeLabel,
      required this.pointsExpireText,
      required this.appleWalletUrl,
      required this.googleWalletUrl,
      required this.onQr});

  @override
  Widget build(BuildContext context) {
    final qrData = code.trim().isNotEmpty ? code.trim() : phone;
    return PremiumAnimatedSurface(
      radius: 38,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const GuestCardSignalAnimation(size: 58),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Карта гостя',
                        style: TextStyle(
                            color: kLoginInk,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6)),
                    const SizedBox(height: 4),
                    Text(clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: kLoginInkSoft, fontWeight: FontWeight.w800)),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF9C14), Color(0xFFFFC83F)]),
                boxShadow: [
                  BoxShadow(
                      color: kLoginAccent.withOpacity(0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Text('${formatMoney(points)} б.',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ]),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onQr,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: const LinearGradient(colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF3FBFF),
                  Color(0xFFFFFFFF)
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: Colors.white.withOpacity(0.95)),
                boxShadow: [
                  BoxShadow(
                      color: kLoginBlue.withOpacity(0.14),
                      blurRadius: 28,
                      offset: const Offset(0, 14))
                ],
              ),
              child: Column(children: [
                AnimatedQrFrame(qrData: qrData, size: 220),
                const SizedBox(height: 12),
                const Text('Покажите QR на кассе',
                    style: TextStyle(
                        color: kLoginInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(phone,
                    style: TextStyle(
                        color: kLoginInkSoft.withOpacity(0.86),
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class DarkMetric extends StatelessWidget {
  final String label;
  final String value;
  const DarkMetric({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.12))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900)),
          ]),
    );
  }
}

class MiniCommandButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const MiniCommandButton(
      {super.key, required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.14))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: FlowColors.acid, size: 19),
          const SizedBox(width: 7),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900))
        ]),
      ),
    );
  }
}

class _MetaGlassChip extends StatelessWidget {
  final String title;
  final String value;
  final bool small;
  const _MetaGlassChip(
      {required this.title, required this.value, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.82),
        border: Border.all(color: Colors.white.withOpacity(0.92)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                color: kLoginInkSoft.withOpacity(0.82),
                fontSize: 12,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(value,
            maxLines: small ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: kLoginInk,
                fontSize: small ? 12 : 14,
                fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _WalletMiniButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _WalletMiniButton({required this.title, required this.onTap});

  IconData get icon => title.toLowerCase().contains('apple')
      ? Icons.phone_iphone_rounded
      : Icons.account_balance_wallet_rounded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.84),
                const Color(0xFFE8FBFF).withOpacity(0.72),
                Colors.white.withOpacity(0.64),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border:
                Border.all(color: Colors.white.withOpacity(0.95), width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: FlowColors.aqua.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 9))
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: FlowColors.ink, size: 19),
            const SizedBox(width: 8),
            Flexible(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: FlowColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 13))),
          ]),
        ),
      ),
    );
  }
}

class EstablishmentInfoPanel extends StatelessWidget {
  final String establishmentName;
  final String address;
  final String phone;
  final String workingHours;
  final String? yandexUrl;
  final String? twoGisUrl;
  final String yandexRatingText;
  final String twoGisRatingText;
  final String? menuPhotoUrl;
  final Map<String, dynamic> socialMedia;
  final VoidCallback onShowRules;

  const EstablishmentInfoPanel({
    super.key,
    required this.establishmentName,
    required this.address,
    required this.phone,
    required this.workingHours,
    required this.yandexUrl,
    required this.twoGisUrl,
    required this.yandexRatingText,
    required this.twoGisRatingText,
    required this.menuPhotoUrl,
    required this.socialMedia,
    required this.onShowRules,
  });

  @override
  Widget build(BuildContext context) {
    final socialEntries =
        socialMedia.entries.where((e) => nonEmpty(e.value) != null).toList();
    final hasRatings = yandexRatingText.trim().isNotEmpty ||
        twoGisRatingText.trim().isNotEmpty;
    final hasSocial = socialEntries.isNotEmpty;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SurfaceCard(
        radius: 34,
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                color: Colors.white.withOpacity(0.30),
                border: Border.all(
                    color: Colors.white.withOpacity(0.62), width: 1.1),
                boxShadow: [
                  BoxShadow(
                      color: FlowColors.ink.withOpacity(0.055),
                      blurRadius: 18,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(establishmentName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: FlowColors.ink,
                            fontSize: 24,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8)),
                    const SizedBox(height: 16),
                    Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          if (address.trim().isNotEmpty)
                            _QuickGlassPill(
                                icon: Icons.place_rounded, text: address),
                          if (workingHours.trim().isNotEmpty)
                            _QuickGlassPill(
                                icon: Icons.schedule_rounded,
                                text: workingHours),
                          if (phone.trim().isNotEmpty)
                            _QuickGlassPill(
                                icon: Icons.phone_rounded, text: phone),
                        ]),
                    const SizedBox(height: 16),
                    _ActionGradientButton(
                        icon: Icons.auto_awesome_rounded,
                        text: 'Правила лояльности',
                        onTap: onShowRules),
                  ]),
            ),
          ),
          if (hasRatings) ...[
            const SizedBox(height: 16),
            const Center(
                child: Text('Оценки на картах',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: kLoginInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3))),
            const SizedBox(height: 9),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                Expanded(
                    child: _RatingLinkTile(
                        title: 'Яндекс',
                        value: yandexRatingText,
                        subtitle: yandexUrl == null
                            ? 'Ссылка не указана'
                            : 'Открыть карту',
                        icon: Icons.star_rounded,
                        color: const Color(0xFFFFB020),
                        onTap: yandexUrl == null
                            ? null
                            : () => openExternalUrl(context, yandexUrl))),
                const SizedBox(width: 10),
                Expanded(
                    child: _RatingLinkTile(
                        title: '2ГИС',
                        value: twoGisRatingText,
                        subtitle: twoGisUrl == null
                            ? 'Ссылка не указана'
                            : 'Открыть карту',
                        icon: Icons.map_rounded,
                        color: const Color(0xFF16A34A),
                        onTap: twoGisUrl == null
                            ? null
                            : () => openExternalUrl(context, twoGisUrl))),
              ]),
            ),
          ],
          if (hasSocial) ...[
            const SizedBox(height: 16),
            const Center(
                child: Text('Социальные сети',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: kLoginInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3))),
            const SizedBox(height: 9),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: socialEntries
                      .map((e) => _SocialPill(
                          title: e.key.toString(), value: e.value.toString()))
                      .toList()),
            ),
          ],
          if ((menuPhotoUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Image.network(menuPhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: kLoginBlue.withOpacity(0.08),
                            alignment: Alignment.center,
                            child: const Text('Фото меню')))),
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ]),
      ),
    ]);
  }
}

class _AnimatedEstablishmentBadge extends StatefulWidget {
  final double size;
  const _AnimatedEstablishmentBadge({required this.size});

  @override
  State<_AnimatedEstablishmentBadge> createState() =>
      _AnimatedEstablishmentBadgeState();
}

class _AnimatedEstablishmentBadgeState
    extends State<_AnimatedEstablishmentBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController c;

  @override
  void initState() {
    super.initState();
    c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final pulse = 1 + math.sin(c.value * math.pi * 2) * 0.015;
        return Transform.scale(
          scale: pulse,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFE9AE),
                  Color(0xFFFFB347),
                  Color(0xFF22D3C5)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border:
                  Border.all(color: Colors.white.withOpacity(0.75), width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 10)),
                BoxShadow(
                    color: FlowColors.acid.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 10,
                  top: 12,
                  child: Container(
                    width: widget.size * 0.44,
                    height: widget.size * 0.44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.26),
                    ),
                  ),
                ),
                PremiumAssetIcon(
                  asset: kIconEstablishmentPremium,
                  size: widget.size * 0.82,
                  fallbackIcon: Icons.storefront_rounded,
                  fallbackColor: Colors.white,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: FlowColors.acid,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SoftGlowDot extends StatelessWidget {
  final Color color;
  final double size;
  const _SoftGlowDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }
}

class _ActionGradientButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _ActionGradientButton(
      {required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFFFE6A8)]),
            boxShadow: [
              BoxShadow(
                  color: FlowColors.acid.withOpacity(0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: FlowColors.ink, size: 19),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    color: FlowColors.ink, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}

class _RatingLinkTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _RatingLinkTile(
      {required this.title,
      required this.value,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rating = value.trim().isEmpty ? '—' : value.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          constraints: const BoxConstraints(minHeight: 154),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.92),
                color.withOpacity(0.12),
                Colors.white.withOpacity(0.78),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border:
                Border.all(color: Colors.white.withOpacity(0.99), width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 22,
                  offset: const Offset(0, 11))
            ],
          ),
          child: Stack(children: [
            Positioned(
                right: -18,
                bottom: -24,
                child: Icon(icon, color: color.withOpacity(0.08), size: 92)),
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.15),
                        border: Border.all(color: color.withOpacity(0.18))),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 11),
                  Text(title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: FlowColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 15)),
                  const SizedBox(height: 7),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(rating,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: FlowColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            letterSpacing: -0.8)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFB020), size: 20),
                  ]),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: FlowColors.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          height: 1.25)),
                ]),
          ]),
        ),
      ),
    );
  }
}

class _SocialPill extends StatelessWidget {
  final String title;
  final String value;
  const _SocialPill({required this.title, required this.value});

  String get _normalizedTitle => title.trim().toLowerCase();

  bool get isTelegram =>
      _normalizedTitle.contains('telegram') || _normalizedTitle.contains('тг');
  bool get isVk =>
      _normalizedTitle.contains('vk') ||
      _normalizedTitle.contains('вк') ||
      _normalizedTitle.contains('vkontakte');
  bool get isInstagram =>
      _normalizedTitle.contains('instagram') ||
      _normalizedTitle.contains('inst');
  bool get isWhatsapp =>
      _normalizedTitle.contains('whatsapp') || _normalizedTitle.contains('wa');
  bool get isWebsite =>
      _normalizedTitle.contains('site') ||
      _normalizedTitle.contains('сайт') ||
      _normalizedTitle.contains('web');

  Color get color {
    if (isTelegram) return const Color(0xFF229ED9);
    if (isVk) return const Color(0xFF0077FF);
    if (isInstagram) return const Color(0xFFE1306C);
    if (isWhatsapp) return const Color(0xFF25D366);
    if (isWebsite) return const Color(0xFF0F766E);
    return FlowColors.ink;
  }

  String get displayTitle {
    if (isTelegram) return 'Telegram';
    if (isVk) return 'ВКонтакте';
    if (isInstagram) return 'Instagram';
    if (isWhatsapp) return 'WhatsApp';
    if (isWebsite) return 'Сайт';
    return title;
  }

  Widget _brandIcon() {
    if (isVk) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: const Text('VK',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: -0.3)),
      );
    }
    if (isTelegram) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.telegram, color: Colors.white, size: 21),
      );
    }
    final icon = isInstagram
        ? Icons.camera_alt_rounded
        : isWhatsapp
            ? Icons.chat_rounded
            : isWebsite
                ? Icons.language_rounded
                : Icons.open_in_new_rounded;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: color, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openExternalUrl(context, value,
            emptyMessage: 'Ссылка $title не указана'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minWidth: 148),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            border: Border.all(color: color.withOpacity(0.16), width: 1.1),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _brandIcon(),
                const SizedBox(width: 10),
                Flexible(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Text(displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: FlowColors.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5)),
                      const SizedBox(height: 2),
                      const Text('Открыть',
                          style: TextStyle(
                              color: FlowColors.soft,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5)),
                    ])),
              ]),
        ),
      ),
    );
  }
}

class _QuickGlassPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _QuickGlassPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.58),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.82))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Color(0xFF7A4F00)),
        const SizedBox(width: 6),
        Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: FlowColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800))),
      ]),
    );
  }
}

class _ActionGhostButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _ActionGhostButton(
      {required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.86),
              border: Border.all(color: Colors.white.withOpacity(0.96))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: kLoginBlue, size: 18),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    color: kLoginInk, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoTile(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: kLoginBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: kLoginBlue)),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: kLoginInkSoft, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                color: kLoginInk, fontWeight: FontWeight.w900, height: 1.25)),
      ])),
    ]);
  }
}

class _LinkTile extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onTap;
  const _LinkTile(
      {required this.title, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.82),
            border: Border.all(color: Colors.white.withOpacity(0.92)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: kLoginInkSoft, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(value,
                style: const TextStyle(
                    color: kLoginInk, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}

class WalletInlineButtons extends StatelessWidget {
  final String? appleWalletUrl;
  final String? googleWalletUrl;

  const WalletInlineButtons(
      {super.key, required this.appleWalletUrl, required this.googleWalletUrl});

  void _handleTap(BuildContext context, String title, String? url) {
    final clean = (url ?? '').trim();
    if (clean.isEmpty && title == 'Google Wallet') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Google Wallet сейчас дорабатывается. Apple Wallet уже доступен.')));
      return;
    }
    openExternalUrl(context, clean,
        emptyMessage: '$title пока не подключён для выбранного заведения');
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: WalletPillButton(
          title: 'Apple Wallet',
          icon: Icons.phone_iphone_rounded,
          enabled: (appleWalletUrl ?? '').trim().isNotEmpty,
          onTap: () => _handleTap(context, 'Apple Wallet', appleWalletUrl),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: WalletPillButton(
          title: 'Google Wallet',
          icon: Icons.account_balance_wallet_rounded,
          enabled: true,
          onTap: () => _handleTap(context, 'Google Wallet', googleWalletUrl),
        ),
      ),
    ]);
  }
}

class WalletPillButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const WalletPillButton(
      {super.key,
      required this.title,
      required this.icon,
      required this.enabled,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: enabled
                  ? [
                      Colors.white.withOpacity(0.78),
                      const Color(0xFFE4FBFF).withOpacity(0.64),
                      Colors.white.withOpacity(0.54),
                    ]
                  : [
                      Colors.white.withOpacity(0.58),
                      Colors.white.withOpacity(0.44),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border:
                Border.all(color: Colors.white.withOpacity(0.94), width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: FlowColors.aqua.withOpacity(0.13),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FlowColors.ink.withOpacity(enabled ? 0.08 : 0.04)),
              child: Icon(icon,
                  color: enabled
                      ? FlowColors.ink
                      : FlowColors.soft.withOpacity(0.55),
                  size: 19),
            ),
            const SizedBox(width: 9),
            Flexible(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: enabled
                            ? FlowColors.ink
                            : FlowColors.soft.withOpacity(0.65),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900))),
          ]),
        ),
      ),
    );
  }
}

class WalletHubCard extends StatelessWidget {
  final String establishmentName;
  final String? appleWalletUrl;
  final String? googleWalletUrl;

  const WalletHubCard(
      {super.key,
      required this.establishmentName,
      required this.appleWalletUrl,
      required this.googleWalletUrl});

  @override
  Widget build(BuildContext context) {
    final hasApple = (appleWalletUrl ?? '').trim().isNotEmpty;
    final hasGoogle = (googleWalletUrl ?? '').trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withOpacity(0.24),
        border: Border.all(color: Colors.white.withOpacity(0.56), width: 1.1),
        boxShadow: [
          BoxShadow(
              color: FlowColors.ink.withOpacity(0.055),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wallet карта',
                      style: TextStyle(
                        color: FlowColors.ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Карты для «$establishmentName»',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FlowColors.muted,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.wallet_rounded,
                  color: FlowColors.gold, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          _WalletActionRow(
            title: 'Apple Wallet',
            subtitle: hasApple ? 'Открыть карту' : 'Скоро доступно',
            onTap: hasApple
                ? () => openExternalUrl(context, appleWalletUrl,
                    emptyMessage: 'Apple Wallet пока не подключён')
                : null,
          ),
          Divider(color: FlowColors.ink.withOpacity(0.08), height: 18),
          _WalletActionRow(
            title: 'Google Wallet',
            subtitle: hasGoogle ? 'Открыть карту' : 'Сейчас дорабатывается',
            onTap: hasGoogle
                ? () => openExternalUrl(context, googleWalletUrl,
                    emptyMessage: 'Google Wallet сейчас дорабатывается')
                : null,
          ),
          const SizedBox(height: 10),
          const Text(
            'Нажмите на нужную карту, чтобы открыть её.',
            style: TextStyle(
              color: FlowColors.muted,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletActionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _WalletActionRow(
      {required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final icon = title.toLowerCase().contains('apple')
        ? Icons.phone_iphone_rounded
        : Icons.account_balance_wallet_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon,
                  color: enabled ? FlowColors.gold : FlowColors.soft, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled ? FlowColors.ink : FlowColors.soft,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: FlowColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: enabled ? FlowColors.gold : FlowColors.soft, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletStatusPill extends StatelessWidget {
  final String title;
  final String subtitle;
  const _WalletStatusPill({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          color: Colors.white.withOpacity(0.16),
          border: Border.all(color: Colors.white.withOpacity(0.20))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_rounded,
            color: FlowColors.acid, size: 18),
        const SizedBox(width: 7),
        Flexible(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12)),
              Text(subtitle,
                  style: const TextStyle(
                      color: Color(0xEFFFFFFF),
                      fontWeight: FontWeight.w800,
                      fontSize: 10)),
            ])),
      ]),
    );
  }
}

class _DisabledWalletButton extends StatelessWidget {
  final String title;
  const _DisabledWalletButton({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.58),
          border: Border.all(color: Colors.white.withOpacity(0.95))),
      child: Center(
          child: Text(title,
              style: const TextStyle(
                  color: FlowColors.muted, fontWeight: FontWeight.w900))),
    );
  }
}

class BirthdayInfoCard extends StatelessWidget {
  final String? birthDate;
  final int bonusPoints;
  final VoidCallback onTap;
  const BirthdayInfoCard(
      {super.key,
      required this.birthDate,
      required this.bonusPoints,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cleanDate = (birthDate ?? '').trim();
    final hasDate = cleanDate.isNotEmpty;
    final bonusText =
        bonusPoints > 0 ? '$bonusPoints бонусов' : 'подарок от заведения';
    return ProfileFeatureShell(
      icon: Icons.cake_rounded,
      title: 'День рождения',
      subtitle: hasDate
          ? 'Дата указана: ${formatClientDateTime(cleanDate)}'
          : 'Укажите дату и получите $bonusText, если акция включена заведением.',
      color: FlowColors.amber,
      child: SizedBox(
        width: double.infinity,
        child: PrimaryButton(
            text: hasDate ? 'Изменить дату' : 'Указать дату',
            icon: Icons.edit_calendar_rounded,
            onTap: onTap),
      ),
    );
  }
}

class ReferralInviteCard extends StatelessWidget {
  final String? referralLink;
  final VoidCallback onRefresh;
  const ReferralInviteCard(
      {super.key, required this.referralLink, required this.onRefresh});

  void _showAppStoreSoon(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: SingleChildScrollView(
          child: ProfileFeatureShell(
            icon: Icons.rocket_launch_rounded,
            assetPath: kIconInvitePremium,
            title: 'Приглашение в приложение',
            subtitle: 'Ссылка будет вести на скачивание Flowru Client.',
            color: FlowColors.violet,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                'После публикации приложения в App Store и Google Play эта кнопка будет открывать страницу скачивания Flowru Client. Сейчас приложение ещё не опубликовано, поэтому ссылку на сайт владельцев здесь не используем.',
                style: TextStyle(
                    color: FlowColors.ink,
                    fontWeight: FontWeight.w800,
                    height: 1.35),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Понятно',
                  icon: Icons.check_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final link = (referralLink ?? '').trim();
    return ProfileFeatureShell(
      icon: Icons.group_add_rounded,
      assetPath: kIconInvitePremium,
      title: 'Пригласить друга',
      subtitle:
          'Позже здесь будет ссылка на скачивание клиентского приложения.',
      color: FlowColors.violet,
      child: Column(children: [
        if (link.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: FlowColors.ink.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18)),
            child: Text(
                'Реферальный код готов. Ссылка на скачивание появится после публикации приложения.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: FlowColors.ink,
                    fontWeight: FontWeight.w800,
                    height: 1.25)),
          ),
          const SizedBox(height: 10),
          SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                  text: 'Скоро в App Store и Google Play',
                  icon: Icons.storefront_rounded,
                  onTap: () => _showAppStoreSoon(context))),
        ] else
          SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                  text: 'Подготовить приглашение',
                  icon: Icons.refresh_rounded,
                  onTap: onRefresh)),
      ]),
    );
  }
}

class QuickCommandRail extends StatelessWidget {
  final VoidCallback onQr;
  final VoidCallback onPerks;
  final VoidCallback onHistory;
  const QuickCommandRail(
      {super.key,
      required this.onQr,
      required this.onPerks,
      required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: CommandTile(
              icon: Icons.qr_code_2_rounded,
              title: 'Сканер',
              subtitle: 'Показать QR',
              color: FlowColors.ink,
              onTap: onQr)),
      const SizedBox(width: 10),
      Expanded(
          child: CommandTile(
              icon: Icons.auto_awesome_rounded,
              title: 'Перки',
              subtitle: 'Выгода',
              color: FlowColors.violet,
              onTap: onPerks)),
      const SizedBox(width: 10),
      Expanded(
          child: CommandTile(
              icon: Icons.receipt_long_rounded,
              title: 'Лента',
              subtitle: 'История',
              color: FlowColors.aqua,
              onTap: onHistory)),
    ]);
  }
}

class CommandTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const CommandTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        radius: 26,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 13),
          Text(title,
              style: const TextStyle(
                  color: FlowColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(
                  color: FlowColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class OfferTicker extends StatelessWidget {
  final List<PromoItem> items;
  final bool joining;
  final Future<void> Function(Map<String, dynamic> draw)? onJoin;
  final Future<void> Function(int establishmentId)? onOpenEstablishment;
  const OfferTicker(
      {super.key,
      required this.items,
      this.joining = false,
      this.onJoin,
      this.onOpenEstablishment});

  void _openPromo(BuildContext context, PromoItem item) {
    if (item.isRaffle && (item.rawData ?? {}).isNotEmpty) {
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        builder: (_) => RaffleDetailsSheet(
          draw: item.rawData!,
          joining: joining,
          onJoin: onJoin == null ? null : () => onJoin!(item.rawData!),
        ),
      );
      return;
    }
    final estId = intOrNull(item.rawData?['establishment_id']);
    final estName = promoFirstText([item.rawData?['establishment_name']]);
    final cleanTitle = estName != null && item.title.startsWith('$estName · ')
        ? item.title.substring(estName.length + 3)
        : item.title;
    showPromoDetailsSheet(
      context,
      title: cleanTitle,
      subtitle: item.subtitle,
      icon: item.icon,
      color: item.color,
      establishmentName: estName,
      onOpenEstablishment: estId != null && onOpenEstablishment != null
          ? () async {
              Navigator.of(context).maybePop();
              await onOpenEstablishment!(estId);
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showcase = items
        .where((e) => e.isRaffle || !e.tag.toLowerCase().contains('купон'))
        .toList();
    final visibleItems = showcase.isEmpty
        ? const [
            PromoItem(
                tag: 'акция',
                title: 'Персональные предложения',
                subtitle: 'Здесь появятся ваши лучшие акции и спецпредложения.',
                icon: Icons.local_fire_department_rounded,
                color: FlowColors.amber),
            PromoItem(
                tag: 'розыгрыш',
                title: 'Розыгрыши',
                subtitle:
                    'Когда запустится розыгрыш, он отобразится в этой ленте.',
                icon: Icons.celebration_rounded,
                color: FlowColors.violet),
          ]
        : showcase.take(20).toList();

    return SizedBox(
      height: 246,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent
          ],
          stops: [0.0, 0.055, 0.945, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: visibleItems.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(
            width: 246,
            child: PromoShowcaseCard(
              item: visibleItems[i],
              onTap: () => _openPromo(context, visibleItems[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class BenefitOrbitPanel extends StatelessWidget {
  final List<PromoItem> items;
  final List<Map<String, dynamic>> coupons;
  final Map<String, dynamic> draw;
  final Future<void> Function(Map<String, dynamic> draw)? onJoin;
  final bool compactMode;

  const BenefitOrbitPanel({
    super.key,
    required this.items,
    required this.coupons,
    required this.draw,
    this.onJoin,
    this.compactMode = false,
  });

  List<PromoItem> get offerItems => items
      .where((e) => !e.isRaffle && !e.tag.toLowerCase().contains('купон'))
      .toList();
  List<PromoItem> get couponItems =>
      items.where((e) => e.tag.toLowerCase().contains('купон')).toList();

  void openOffers(BuildContext context) {
    final entries = offerItems.isEmpty
        ? [
            const BenefitEntry(
                'Акций пока нет',
                'Когда заведение добавит акции или квесты, они появятся здесь.',
                Icons.local_fire_department_rounded,
                FlowColors.amber)
          ]
        : offerItems
            .map((e) => BenefitEntry(e.title, e.subtitle, e.icon, e.color))
            .toList();
    showBenefitsList(context, 'Акции', entries);
  }

  void openCoupons(BuildContext context) {
    final entries = coupons.isNotEmpty
        ? coupons
            .map((c) => BenefitEntry(
                c['title']?.toString() ?? 'Купон',
                c['description']?.toString() ?? 'Специальное предложение',
                Icons.confirmation_number_rounded,
                FlowColors.aqua))
            .toList()
        : couponItems
            .map((e) => BenefitEntry(e.title, e.subtitle, e.icon, e.color))
            .toList();
    showBenefitsList(
      context,
      'Купоны',
      entries.isEmpty
          ? [
              const BenefitEntry(
                  'Купонов пока нет',
                  'Когда появятся подарки и купоны, они будут здесь.',
                  Icons.confirmation_number_outlined,
                  FlowColors.aqua)
            ]
          : entries,
    );
  }

  void openRaffle(BuildContext context) {
    if (draw.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        builder: (_) => RaffleDetailsSheet(
          draw: draw,
          joining: false,
          onJoin: onJoin == null ? null : () => onJoin!(draw),
        ),
      );
      return;
    }
    showBenefitsList(context, 'Розыгрыши', const [
      BenefitEntry(
          'Активных розыгрышей нет',
          'Когда заведение запустит розыгрыш, карточка появится здесь.',
          Icons.celebration_outlined,
          FlowColors.violet)
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final offerCount = offerItems.length;
    final couponCount = 0;
    final raffleCount =
        draw.isNotEmpty ? 1 : items.where((e) => e.isRaffle).length;
    final raffleTitle = nonEmpty(draw['title']) ?? 'Розыгрыши';
    final raffleSubtitle = draw.isNotEmpty
        ? (nonEmpty(draw['prize_text']) ??
            nonEmpty(draw['description']) ??
            'Открыть условия и детали')
        : 'Активных розыгрышей пока нет';
    final drawImage = draw.isEmpty ? null : extractImageUrl(draw);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BenefitHeroSummaryCard(
          totalItems: offerCount + raffleCount,
          offerCount: offerCount,
          couponCount: couponCount,
          raffleCount: raffleCount,
          featuredTitle: draw.isNotEmpty
              ? raffleTitle
              : (offerItems.isNotEmpty
                  ? offerItems.first.title
                  : 'Новые выгоды'),
          featuredSubtitle: draw.isNotEmpty
              ? raffleSubtitle
              : (offerItems.isNotEmpty
                  ? offerItems.first.subtitle
                  : 'Все акции и розыгрыши собраны в одном красивом экране.'),
        ),
        const SizedBox(height: 14),
        if (compactMode)
          OfferTicker(items: items)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 680;
              final firstRow = [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: BenefitActionCard(
                      title: 'Акции',
                      titleBadge: offerCount == 0 ? 'Скоро' : '$offerCount',
                      subtitle: offerCount == 0
                          ? 'Персональные предложения и выгодные акции появятся здесь.'
                          : '$offerCount активных предложений для вас',
                      accent: FlowColors.amber,
                      icon: Icons.local_fire_department_rounded,
                      imageUrl: offerItems.isNotEmpty
                          ? offerItems.first.imageUrl
                          : null,
                      previewTitle: offerItems.isNotEmpty
                          ? offerItems.first.title
                          : 'Лента акций',
                      onTap: () => openOffers(context),
                    ),
                  ),
                ),
              ];

              final raffleCard = AspectRatio(
                aspectRatio: 1,
                child: BenefitActionCard(
                  title: draw.isNotEmpty ? raffleTitle : 'Розыгрыши',
                  titleBadge: raffleCount == 0 ? 'Нет' : '$raffleCount',
                  subtitle: raffleSubtitle,
                  accent: FlowColors.violet,
                  icon: Icons.celebration_rounded,
                  imageUrl: drawImage,
                  previewTitle:
                      draw.isNotEmpty ? raffleTitle : 'Конкурсы и розыгрыши',
                  onTap: () => openRaffle(context),
                  darkMode: true,
                ),
              );

              if (wide) {
                return Column(
                  children: [
                    Row(children: firstRow),
                    const SizedBox(height: 12),
                    raffleCard,
                  ],
                );
              }

              return Column(
                children: [
                  Row(children: firstRow),
                  const SizedBox(height: 12),
                  raffleCard,
                ],
              );
            },
          ),
      ],
    );
  }
}

class PromoActionPill extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool loading;
  final double height;
  final double fontSize;
  final EdgeInsets padding;
  final double maxWidth;

  const PromoActionPill({
    super.key,
    required this.text,
    this.onTap,
    this.loading = false,
    this.height = 28,
    this.fontSize = 10.2,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.maxWidth = 118,
  });

  @override
  Widget build(BuildContext context) {
    final child = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF0A8), Color(0xFFFFD447), Color(0xFFFFA000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFFB020).withOpacity(0.34),
                blurRadius: 16,
                offset: const Offset(0, 8))
          ],
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
                width: height * 0.46,
                height: height * 0.46,
                child: const CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF1F2937)))
            : Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: const Color(0xFF1F2937),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900),
              ),
      ),
    );

    if (onTap == null || loading) return child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

class PromoShowcaseCard extends StatefulWidget {
  final PromoItem item;
  final VoidCallback onTap;
  const PromoShowcaseCard({super.key, required this.item, required this.onTap});

  @override
  State<PromoShowcaseCard> createState() => _PromoShowcaseCardState();
}

class _PromoShowcaseCardState extends State<PromoShowcaseCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final imageUrl = (item.imageUrl ?? '').trim();
    final hasImage = imageUrl.isNotEmpty;
    final title = item.title.trim();
    final subtitle = item.subtitle.trim();
    final establishmentName =
        promoFirstText([item.rawData?['establishment_name']]);
    final compactEstablishmentCard =
        establishmentName != null && establishmentName.trim().isNotEmpty;
    final cardTitle =
        compactEstablishmentCard ? establishmentName.trim() : title;
    final tagLower = item.tag.toLowerCase();
    final isImportant = tagLower.contains('важ') || tagLower.contains('flowru');
    final titleLower = title.toLowerCase();
    final showTitle = cardTitle.isNotEmpty &&
        !item.isRaffle &&
        !(isImportant && titleLower == 'важное');
    final showSubtitle =
        subtitle.isNotEmpty && !item.isRaffle && !compactEstablishmentCard;
    final tagLabel =
        item.isRaffle ? 'Розыгрыш' : (isImportant ? 'Важное' : item.tag);
    final actionText = item.actionText;
    final actionUrl = item.actionUrl;
    final hasActionButton = actionText != null && actionUrl != null;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        final glowShift = math.sin(t * math.pi * 2) * 8;
        return Transform.translate(
          offset: Offset(0, -2 + math.sin(t * math.pi) * 2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(32),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: hasImage ? Colors.transparent : null,
                    gradient: hasImage
                        ? null
                        : LinearGradient(
                            colors: [
                              item.color.withOpacity(0.96),
                              item.color.withOpacity(0.72),
                              const Color(0xFF0A2B47),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: Border.all(
                        color: hasImage
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.20),
                        width: 1.1),
                    boxShadow: hasImage
                        ? const []
                        : [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 18,
                                offset: const Offset(0, 10)),
                            BoxShadow(
                                color: item.color.withOpacity(0.28),
                                blurRadius: 26,
                                offset: const Offset(0, 14)),
                          ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.antiAlias,
                    children: [
                      if (!hasImage)
                        Positioned(
                          right: -20 + glowShift,
                          top: -26,
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                        ),
                      if (!hasImage)
                        Positioned(
                          left: -16,
                          bottom: -22 - glowShift,
                          child: Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.color.withOpacity(0.18),
                            ),
                          ),
                        ),
                      if (hasImage)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.10),
                                        Colors.black.withOpacity(0.44)
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SizedBox.shrink(),
                                const Spacer(),
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.black
                                        .withOpacity(hasImage ? 0.84 : 0.54),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.46)),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.34),
                                          blurRadius: 16,
                                          offset: const Offset(0, 7))
                                    ],
                                  ),
                                  child: Icon(
                                      item.isRaffle
                                          ? Icons.celebration_rounded
                                          : Icons.notifications_active_rounded,
                                      color: Colors.white,
                                      size: 21),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (showTitle || showSubtitle) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: hasImage
                                      ? Colors.black.withOpacity(0.54)
                                      : Colors.black.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white
                                        .withOpacity(hasImage ? 0.20 : 0.10),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (showTitle)
                                      Text(
                                        cardTitle,
                                        maxLines:
                                            compactEstablishmentCard ? 1 : 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 21,
                                            height: 1.02,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.7),
                                      ),
                                    if (showSubtitle) ...[
                                      const SizedBox(height: 7),
                                      Text(
                                        subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.92),
                                            height: 1.22,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            if (item.isRaffle || hasActionButton) ...[
                              if (showTitle || showSubtitle)
                                const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: PromoActionPill(
                                  text: hasActionButton
                                      ? actionText!
                                      : 'Участвовать',
                                  loading: item.isRaffle && !hasActionButton
                                      ? false
                                      : false,
                                  height: 26,
                                  fontSize: 9.6,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 9),
                                  maxWidth: 104,
                                  onTap: hasActionButton
                                      ? () => openExternalUrl(
                                          context, actionUrl,
                                          emptyMessage:
                                              'Ссылка кнопки не указана')
                                      : widget.onTap,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BenefitHeroSummaryCard extends StatefulWidget {
  final int totalItems;
  final int offerCount;
  final int couponCount;
  final int raffleCount;
  final String featuredTitle;
  final String featuredSubtitle;
  const BenefitHeroSummaryCard({
    super.key,
    required this.totalItems,
    required this.offerCount,
    required this.couponCount,
    required this.raffleCount,
    required this.featuredTitle,
    required this.featuredSubtitle,
  });

  @override
  State<BenefitHeroSummaryCard> createState() => _BenefitHeroSummaryCardState();
}

class _BenefitHeroSummaryCardState extends State<BenefitHeroSummaryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: const LinearGradient(
              colors: [Color(0xFF0A2B47), Color(0xFF0B5D78), Color(0xFF0FCAC5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border:
                Border.all(color: Colors.white.withOpacity(0.34), width: 1.1),
            boxShadow: [
              BoxShadow(
                  color: kLoginBlue.withOpacity(0.22),
                  blurRadius: 30,
                  offset: const Offset(0, 16)),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20 + math.sin(t * math.pi * 2) * 10,
                top: -28,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.10)),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -40 + math.cos(t * math.pi * 2) * 8,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kLoginAccent.withOpacity(0.16)),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.14),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Центр выгоды',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.7)),
                            const SizedBox(height: 4),
                            Text(
                                'Современный экран ваших предложений и розыгрышей',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.82),
                                    height: 1.25,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Сейчас в фокусе',
                            style: TextStyle(
                                color: FlowColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(widget.featuredTitle,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.35)),
                        const SizedBox(height: 4),
                        Text(widget.featuredSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.86),
                                height: 1.3,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class BenefitMiniMetric extends StatelessWidget {
  final String label;
  final String value;
  const BenefitMiniMetric(
      {super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.14),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.76),
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class BenefitActionCard extends StatefulWidget {
  final String title;
  final String titleBadge;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String? imageUrl;
  final String previewTitle;
  final VoidCallback onTap;
  final bool darkMode;

  const BenefitActionCard({
    super.key,
    required this.title,
    required this.titleBadge,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.previewTitle,
    required this.onTap,
    this.imageUrl,
    this.darkMode = false,
  });

  @override
  State<BenefitActionCard> createState() => _BenefitActionCardState();
}

class _BenefitActionCardState extends State<BenefitActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.darkMode;
    final titleColor = isDark ? Colors.white : kLoginInk;
    final subColor = isDark ? Colors.white.withOpacity(0.78) : kLoginInkSoft;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final dy = math.sin(controller.value * math.pi) * 2.5;
        return Transform.translate(
          offset: Offset(0, -dy),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(30),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: isDark
                      ? const LinearGradient(colors: [
                          Color(0xFF071F34),
                          Color(0xFF0A4059),
                          Color(0xFF0B7184)
                        ], begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.98),
                            Colors.white.withOpacity(0.90),
                            widget.accent.withOpacity(0.10)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.18)
                          : Colors.white.withOpacity(0.92),
                      width: 1.1),
                  boxShadow: [
                    BoxShadow(
                        color: widget.accent.withOpacity(0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 12)),
                    BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.antiAlias,
                  children: [
                    Positioned(
                      right: -22,
                      top: -26,
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? Colors.white : widget.accent)
                              .withOpacity(0.10),
                        ),
                      ),
                    ),
                    if ((widget.imageUrl ?? '').trim().isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    if ((widget.imageUrl ?? '').trim().isNotEmpty)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(isDark ? 0.12 : 0.08),
                                Colors.black.withOpacity(isDark ? 0.54 : 0.32)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        gradient: LinearGradient(
                                          colors: isDark
                                              ? [
                                                  Colors.white
                                                      .withOpacity(0.22),
                                                  Colors.white.withOpacity(0.10)
                                                ]
                                              : [
                                                  widget.accent,
                                                  widget.accent
                                                      .withOpacity(0.70)
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Icon(widget.icon,
                                          color: Colors.white, size: 26),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(widget.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: titleColor,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: -0.55)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 9, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white
                                                      .withOpacity(0.12)
                                                  : widget.accent
                                                      .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(widget.titleBadge,
                                                style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : widget.accent,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w900)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(widget.subtitle,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: subColor,
                                        height: 1.32,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: isDark
                                        ? Colors.white.withOpacity(0.10)
                                        : kLoginInk.withOpacity(0.05),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.flash_on_rounded,
                                          color: isDark
                                              ? Colors.white
                                              : widget.accent,
                                          size: 16),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(widget.previewTitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: titleColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        gradient: LinearGradient(colors: [
                                          widget.accent,
                                          widget.accent.withOpacity(0.24)
                                        ]),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.14)
                                            : kLoginInk.withOpacity(0.06),
                                      ),
                                      child: Icon(Icons.arrow_forward_rounded,
                                          color:
                                              isDark ? Colors.white : kLoginInk,
                                          size: 20),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PerksHub extends StatelessWidget {
  final Map<String, dynamic> home;
  final List<PromoItem> promoItems;
  final bool joining;
  final Future<void> Function(Map<String, dynamic> draw) onJoin;
  const PerksHub(
      {super.key,
      required this.home,
      required this.promoItems,
      required this.joining,
      required this.onJoin});

  @override
  Widget build(BuildContext context) {
    bool isDevBanner(PromoItem e) {
      final source = (e.rawData?['source'] ?? e.rawData?['banner_type'] ?? '')
          .toString()
          .toLowerCase();
      final tag = e.tag.toLowerCase();
      return source.contains('dev_app_banner') ||
          source == 'dev' ||
          tag.contains('flowru') ||
          tag.contains('важ');
    }

    final items = promoItems
        .where((e) => !e.tag.toLowerCase().contains('купон'))
        .where((e) => !isDevBanner(e))
        .toList();
    final raffles = items.where((e) => e.isRaffle).toList();
    final offers = items.where((e) => !e.isRaffle).toList();
    final mainOffer = offers.isNotEmpty ? offers.first : null;
    final mainRaffle = raffles.isNotEmpty ? raffles.first : null;
    final rest = items.where((e) => e != mainOffer && e != mainRaffle).toList();

    final liveBanners = mapList(home['banners']);
    final liveDraws = mapList(home['draws']);
    final liveDrawBanner = map(home['draw_banner']);
    final heroOffersCount = liveBanners.length;
    final heroRafflesCount = liveDraws.isNotEmpty
        ? liveDraws.length
        : (liveDrawBanner.isNotEmpty ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BenefitCleanHero(
            offersCount: heroOffersCount, rafflesCount: heroRafflesCount),
        const SizedBox(height: 18),
        if (mainOffer != null || mainRaffle != null) ...[
          const SectionTitle(
              title: 'Главное сейчас',
              subtitle: 'Самые заметные предложения выбранного заведения'),
          const SizedBox(height: 10),
          if (mainOffer != null)
            BenefitFeaturedCard(
              item: mainOffer,
              onTap: () => showBenefitSheet(context,
                  title: mainOffer.title,
                  subtitle: mainOffer.subtitle,
                  icon: mainOffer.icon,
                  color: mainOffer.color),
            ),
          if (mainOffer != null && mainRaffle != null)
            const SizedBox(height: 12),
          if (mainRaffle != null)
            BenefitFeaturedCard(
              item: mainRaffle,
              joining: joining,
              onTap: () {
                if ((mainRaffle.rawData ?? {}).isNotEmpty) {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(30))),
                    builder: (_) => RaffleDetailsSheet(
                        draw: mainRaffle.rawData!,
                        joining: joining,
                        onJoin: () => onJoin(mainRaffle.rawData!)),
                  );
                } else {
                  showBenefitSheet(context,
                      title: mainRaffle.title,
                      subtitle: mainRaffle.subtitle,
                      icon: mainRaffle.icon,
                      color: mainRaffle.color);
                }
              },
            ),
        ] else ...[
          const EmptyState(
            icon: Icons.auto_awesome_rounded,
            title: 'Пока нет активных предложений',
            subtitle:
                'Когда заведение добавит акцию или розыгрыш, они появятся здесь.',
          ),
        ],
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 18),
          const SectionTitle(
              title: 'Ещё доступно',
              subtitle: 'Дополнительные акции и активности'),
          const SizedBox(height: 10),
          ...rest.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BenefitSimpleCard(
                  item: item,
                  joining: joining && item.isRaffle,
                  onTap: () {
                    if (item.isRaffle && (item.rawData ?? {}).isNotEmpty) {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(30))),
                        builder: (_) => RaffleDetailsSheet(
                            draw: item.rawData!,
                            joining: joining,
                            onJoin: () => onJoin(item.rawData!)),
                      );
                    } else {
                      showBenefitSheet(context,
                          title: item.title,
                          subtitle: item.subtitle,
                          icon: item.icon,
                          color: item.color);
                    }
                  },
                ),
              )),
        ],
      ],
    );
  }
}

class BenefitCleanHero extends StatelessWidget {
  final int offersCount;
  final int rafflesCount;
  const BenefitCleanHero(
      {super.key, required this.offersCount, required this.rafflesCount});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF061B31), Color(0xFF0A7E91), Color(0xFF20D9C5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: 8,
              top: 8,
              child: IgnorePointer(
                child: Container(
                  width: 102,
                  height: 102,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -16,
              bottom: -20,
              child: IgnorePointer(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.08),
                  ),
                ),
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.18))),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 27),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Важное',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8)),
                      const SizedBox(height: 4),
                      Text('Акции, предложения и розыгрыши без лишнего шума.',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.78),
                              fontWeight: FontWeight.w700,
                              height: 1.25)),
                    ])),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _BenefitHeroMetric(
                        title: 'Акции', value: '$offersCount')),
                const SizedBox(width: 10),
                Expanded(
                    child: _BenefitHeroMetric(
                        title: 'Розыгрыши', value: '$rafflesCount')),
              ]),
            ]),
          ],
        ),
      ),
    );
  }
}

class _BenefitHeroMetric extends StatelessWidget {
  final String title;
  final String value;
  const _BenefitHeroMetric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.14))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1)),
        const SizedBox(height: 5),
        Text(title,
            style: TextStyle(
                color: Colors.white.withOpacity(0.76),
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class BenefitFeaturedCard extends StatelessWidget {
  final PromoItem item;
  final bool joining;
  final VoidCallback onTap;
  const BenefitFeaturedCard(
      {super.key,
      required this.item,
      required this.onTap,
      this.joining = false});

  @override
  Widget build(BuildContext context) {
    final tagLower = item.tag.toLowerCase();
    final label = item.isRaffle
        ? 'Розыгрыш'
        : (tagLower.contains('важ') || tagLower.contains('flowru')
            ? 'Важное'
            : 'Акция');
    final imageUrl = (item.imageUrl ?? '').trim();
    final hasImage = imageUrl.isNotEmpty;
    final title = item.title.trim();
    final subtitle = item.subtitle.trim();
    final isImportant = tagLower.contains('важ') || tagLower.contains('flowru');
    final titleLower = title.toLowerCase();
    final showTitle = title.isNotEmpty &&
        !item.isRaffle &&
        !(isImportant && titleLower == 'важное');
    final showSubtitle = subtitle.isNotEmpty && !item.isRaffle;
    final actionText = item.actionText;
    final actionUrl = item.actionUrl;
    final hasActionButton = actionText != null && actionUrl != null;

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasImage
                      ? const [
                          Color(0xFF081522),
                          Color(0xFF0A2034),
                          Color(0xFF071F34)
                        ]
                      : [
                          item.color.withOpacity(0.94),
                          item.color.withOpacity(0.58),
                          const Color(0xFF071F34)
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  if (hasImage)
                    Positioned.fill(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  if (hasImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.10),
                              Colors.black.withOpacity(0.46)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  if (!hasImage)
                    Positioned(
                      right: 12,
                      top: 10,
                      child: IgnorePointer(
                        child: Container(
                          width: 94,
                          height: 94,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.11),
                          ),
                        ),
                      ),
                    ),
                  if (!hasImage)
                    Positioned(
                      right: 20,
                      bottom: 18,
                      child: IgnorePointer(
                        child: Icon(item.icon,
                            color: Colors.white.withOpacity(0.10), size: 68),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Spacer(),
                            Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                    color: Colors.black
                                        .withOpacity(hasImage ? 0.84 : 0.54),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.46)),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.34),
                                          blurRadius: 16,
                                          offset: const Offset(0, 7))
                                    ]),
                                child: Icon(
                                    item.isRaffle
                                        ? Icons.celebration_rounded
                                        : Icons.notifications_active_rounded,
                                    color: Colors.white,
                                    size: 21)),
                          ]),
                          const Spacer(),
                          if (showTitle) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.black
                                    .withOpacity(hasImage ? 0.58 : 0.18),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white
                                      .withOpacity(hasImage ? 0.22 : 0.10),
                                ),
                              ),
                              child: Text(title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 23,
                                      height: 0.98,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.0)),
                            ),
                          ],
                          if (showSubtitle) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black
                                    .withOpacity(hasImage ? 0.48 : 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(subtitle,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.92),
                                      fontSize: 15,
                                      height: 1.22,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                          if (item.isRaffle || hasActionButton) ...[
                            if (showTitle || showSubtitle)
                              const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: PromoActionPill(
                                text: hasActionButton
                                    ? actionText!
                                    : 'Участвовать',
                                loading: item.isRaffle &&
                                    !hasActionButton &&
                                    joining,
                                height: 26,
                                fontSize: 9.6,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 9),
                                maxWidth: 106,
                                onTap: hasActionButton
                                    ? () => openExternalUrl(context, actionUrl,
                                        emptyMessage:
                                            'Ссылка кнопки не указана')
                                    : onTap,
                              ),
                            ),
                          ],
                        ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BenefitSimpleCard extends StatelessWidget {
  final PromoItem item;
  final bool joining;
  final VoidCallback onTap;
  const BenefitSimpleCard(
      {super.key,
      required this.item,
      required this.joining,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    color: item.color.withOpacity(0.13)),
                child: Icon(item.icon, color: item.color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: FlowColors.ink,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.25,
                            height: 1.08)),
                    const SizedBox(height: 4),
                    Text(item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: kLoginInkSoft,
                            fontWeight: FontWeight.w700,
                            height: 1.22)),
                  ])),
              const SizedBox(width: 8),
              if (joining)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                const Icon(Icons.chevron_right_rounded, color: FlowColors.ink),
            ]),
          ),
        ),
      ),
    );
  }
}

class PerkCommandGrid extends StatelessWidget {
  final List<PromoItem> promoItems;
  final List<Map<String, dynamic>> coupons;
  final Map<String, dynamic> draw;
  final bool joining;
  final Future<void> Function(Map<String, dynamic> draw) onJoin;
  const PerkCommandGrid(
      {super.key,
      required this.promoItems,
      required this.coupons,
      required this.draw,
      required this.joining,
      required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 650;
      final showcases = promoItems.where((e) => !e.isRaffle).toList();
      final cards = [
        PerkCommandCard(
            icon: Icons.local_fire_department_rounded,
            title: 'Акции',
            value: '${showcases.length}',
            subtitle: showcases.isEmpty ? 'Пока пусто' : 'Открыть предложения',
            color: FlowColors.amber,
            onTap: () => showBenefitsList(
                context,
                'Акции',
                showcases.isEmpty
                    ? [
                        const BenefitEntry(
                            'Акций пока нет',
                            'Когда заведение добавит предложения, они появятся здесь.',
                            Icons.inbox_rounded,
                            FlowColors.muted)
                      ]
                    : showcases
                        .map((e) =>
                            BenefitEntry(e.title, e.subtitle, e.icon, e.color))
                        .toList())),
        PerkCommandCard(
            icon: Icons.confirmation_number_rounded,
            title: 'Купоны',
            value: '${coupons.length}',
            subtitle: coupons.isEmpty ? 'Пока пусто' : 'Посмотреть купоны',
            color: FlowColors.aqua,
            onTap: () => showBenefitsList(
                context,
                'Купоны',
                coupons.isEmpty
                    ? [
                        const BenefitEntry(
                            'Купонов пока нет',
                            'Когда заведение добавит купоны, они появятся здесь.',
                            Icons.inbox_rounded,
                            FlowColors.muted)
                      ]
                    : coupons
                        .map((c) => BenefitEntry(
                            c['title']?.toString() ?? 'Купон',
                            c['description']?.toString() ?? '',
                            Icons.card_giftcard_rounded,
                            FlowColors.aqua))
                        .toList())),
        PerkCommandCard(
            icon: Icons.bolt_rounded,
            title: 'Важно',
            value: '${draw.isNotEmpty ? 1 : 0}',
            subtitle:
                draw.isNotEmpty ? 'Розыгрыш и активное' : 'Главные предложения',
            color: FlowColors.violet,
            onTap: () {
              final entries = <BenefitEntry>[];
              if (draw.isNotEmpty) {
                entries.add(BenefitEntry(
                    draw['title']?.toString() ?? 'Розыгрыш',
                    nonEmpty(draw['prize_text']) ??
                        nonEmpty(draw['description']) ??
                        'Приз от заведения',
                    Icons.celebration_rounded,
                    FlowColors.violet));
              }
              entries.addAll(showcases.take(4).map(
                  (e) => BenefitEntry(e.title, e.subtitle, e.icon, e.color)));
              showBenefitsList(
                  context,
                  'Важное',
                  entries.isEmpty
                      ? [
                          const BenefitEntry(
                              'Пока пусто',
                              'Когда заведение добавит важные предложения, они появятся здесь.',
                              Icons.inbox_rounded,
                              FlowColors.muted)
                        ]
                      : entries);
            }),
      ];
      if (compact)
        return Column(
            children: cards
                .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10), child: e))
                .toList());
      return Row(children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 10),
        Expanded(child: cards[1]),
        const SizedBox(width: 10),
        Expanded(child: cards[2])
      ]);
    });
  }
}

class PerkCommandCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const PerkCommandCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.value,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: FlowColors.paper,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 10))
            ]),
        child: Row(children: [
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(19)),
              child: Icon(icon, color: color)),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: kLoginInkSoft, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Row(children: [
                  Text(value,
                      style: const TextStyle(
                          color: FlowColors.ink,
                          fontSize: 30,
                          height: 0.95,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: kLoginInkSoft,
                              fontSize: 12,
                              height: 1.25,
                              fontWeight: FontWeight.w700)))
                ]),
              ])),
          Icon(Icons.chevron_right_rounded, color: color),
        ]),
      ),
    );
  }
}

class PerkLargeCard extends StatelessWidget {
  final PromoItem item;
  const PerkLargeCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showBenefitSheet(context,
          title: item.title,
          subtitle: item.subtitle,
          icon: item.icon,
          color: item.color),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [item.color.withOpacity(0.16), Colors.white]),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                  color: item.color.withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 10))
            ]),
        child: Row(children: [
          Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                  color: item.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(22)),
              child: Icon(item.icon, color: item.color, size: 29)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.tag.toUpperCase(),
                    style: TextStyle(
                        color: item.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8)),
                const SizedBox(height: 5),
                Text(item.title,
                    style: const TextStyle(
                        color: FlowColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4)),
                const SizedBox(height: 5),
                Text(item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: FlowColors.muted,
                        height: 1.3,
                        fontWeight: FontWeight.w600)),
              ])),
          const Icon(Icons.arrow_outward_rounded, color: FlowColors.muted),
        ]),
      ),
    );
  }
}

class CouponLine extends StatelessWidget {
  final String title;
  final String subtitle;
  const CouponLine({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      radius: 24,
      child: Row(children: [
        Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: FlowColors.aqua.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.card_giftcard_rounded,
                color: FlowColors.aqua)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: FlowColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: FlowColors.muted,
                  height: 1.3,
                  fontWeight: FontWeight.w600))
        ])),
      ]),
    );
  }
}

class RaffleCommandCard extends StatelessWidget {
  final Map<String, dynamic> draw;
  final bool joining;
  final VoidCallback onJoin;
  const RaffleCommandCard(
      {super.key,
      required this.draw,
      required this.joining,
      required this.onJoin});

  void openDetails(BuildContext context) {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        builder: (_) =>
            RaffleDetailsSheet(draw: draw, joining: joining, onJoin: onJoin));
  }

  @override
  Widget build(BuildContext context) {
    final title = nonEmpty(draw['title']) ?? 'Розыгрыш';
    final prize = nonEmpty(draw['prize_text']) ??
        nonEmpty(draw['description']) ??
        'Приз от заведения';
    final participants = toInt(draw['participants_count']);
    final isJoined = draw['is_joined'] == true;
    final buttonTitle = draw['join_button_title']?.toString() ??
        (isJoined ? 'Вы участвуете' : 'Участвовать');
    final drawAt = formatClientDateTime(draw['draw_at']);
    final imageUrl = extractImageUrl(draw);

    return GestureDetector(
      onTap: () => openDetails(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(colors: [
            kLoginCardStrong,
            kLoginCard,
            Colors.white.withOpacity(0.80)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: kLoginStroke, width: 1.15),
          boxShadow: [
            BoxShadow(
                color: kLoginViolet.withOpacity(0.16),
                blurRadius: 28,
                offset: const Offset(0, 16))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (imageUrl != null && imageUrl.trim().isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 156,
                width: double.infinity,
                child: Image.network(imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: kLoginViolet.withOpacity(0.10),
                        alignment: Alignment.center,
                        child: const Icon(Icons.celebration_rounded,
                            color: kLoginViolet, size: 42))),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(children: [
            Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: [kLoginBlue, kLoginPink]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: kLoginBlue.withOpacity(0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 9))
                    ]),
                child:
                    const Icon(Icons.celebration_rounded, color: Colors.white)),
            const SizedBox(width: 13),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Розыгрыш',
                      style: TextStyle(
                          color: kLoginInkSoft, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: kLoginInk,
                          fontSize: 21,
                          height: 1.05,
                          fontWeight: FontWeight.w900)),
                ])),
            const Icon(Icons.open_in_full_rounded, color: kLoginInkSoft),
          ]),
          const SizedBox(height: 14),
          Text(prize,
              style: const TextStyle(
                  color: kLoginInkSoft,
                  height: 1.35,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (participants > 0)
              LightChip(
                  icon: Icons.groups_rounded, text: '$participants участников'),
            if (drawAt.isNotEmpty)
              LightChip(icon: Icons.schedule_rounded, text: drawAt),
          ]),
          const SizedBox(height: 14),
          PrimaryButton(
              text: joining ? 'Отправляем...' : buttonTitle,
              loading: joining,
              onTap: joining || isJoined ? null : onJoin),
        ]),
      ),
    );
  }
}

class StatsConstellation extends StatelessWidget {
  final int points;
  final int visits;
  final double sales;
  final String lastVisit;
  const StatsConstellation(
      {super.key,
      required this.points,
      required this.visits,
      required this.sales,
      required this.lastVisit});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 650;
      final cards = [
        StatNode(
            title: 'Баллы',
            value: formatMoney(points),
            icon: Icons.stars_rounded,
            color: FlowColors.acid,
            dark: true),
        StatNode(
            title: 'Визиты',
            value: formatMoney(visits),
            icon: Icons.storefront_rounded,
            color: FlowColors.aqua),
        StatNode(
            title: 'Продажи',
            value: '${formatMoney(sales)} ₽',
            icon: Icons.payments_rounded,
            color: FlowColors.violet),
        StatNode(
            title: 'Последний',
            value: shortDate(lastVisit),
            icon: Icons.calendar_month_rounded,
            color: FlowColors.amber),
      ];
      if (compact) {
        return Column(children: [
          Row(children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 10),
            Expanded(child: cards[1])
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 10),
            Expanded(child: cards[3])
          ])
        ]);
      }
      return Row(children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 10),
        Expanded(child: cards[1]),
        const SizedBox(width: 10),
        Expanded(child: cards[2]),
        const SizedBox(width: 10),
        Expanded(child: cards[3])
      ]);
    });
  }
}

class StatNode extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool dark;
  const StatNode(
      {super.key,
      required this.title,
      required this.value,
      required this.icon,
      required this.color,
      this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: dark ? FlowColors.ink : FlowColors.paper,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: dark ? Colors.transparent : Colors.white),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 10))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withOpacity(0.12)
                    : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: dark ? FlowColors.acid : color)),
        const SizedBox(height: 15),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: dark ? Colors.white : FlowColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8)),
        const SizedBox(height: 3),
        Text(title,
            style: TextStyle(
                color: dark ? const Color(0xBFFFFFFF) : FlowColors.muted,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class EstablishmentCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int? activeId;
  final ValueChanged<Map<String, dynamic>> onSelect;
  const EstablishmentCarousel(
      {super.key,
      required this.items,
      required this.activeId,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = items[i];
          final active = intOrNull(item['establishment_id']) == activeId;
          return GestureDetector(
            onTap: () => onSelect(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                  color: active ? FlowColors.ink : FlowColors.paper,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: active ? FlowColors.ink : Colors.white)),
              child: Row(children: [
                Icon(Icons.storefront_rounded,
                    color: active ? FlowColors.acid : FlowColors.ink, size: 19),
                const SizedBox(width: 8),
                Text(item['establishment_name']?.toString() ?? 'Заведение',
                    style: TextStyle(
                        color: active ? Colors.white : FlowColors.ink,
                        fontWeight: FontWeight.w900)),
                const SizedBox(width: 10),
                Text('${formatMoney(item['points'])} б.',
                    style: TextStyle(
                        color: active ? FlowColors.acid : FlowColors.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12))
              ]),
            ),
          );
        },
      ),
    );
  }
}

class TimelineList extends StatefulWidget {
  final List<Map<String, dynamic>> history;
  final bool loading;
  const TimelineList({super.key, required this.history, required this.loading});

  @override
  State<TimelineList> createState() => _TimelineListState();
}

class _TimelineListState extends State<TimelineList> {
  String filter = 'all';

  List<Map<String, dynamic>> get filteredHistory {
    final visible = widget.history.where(isVisibleClientOperation).toList();
    if (filter == 'all') return visible;
    return visible
        .where((item) => operationFilterType(item) == filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    final items = filteredHistory;
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.history_toggle_off_rounded,
        title: 'Операций пока нет',
        subtitle:
            'Когда появятся начисления или списания, мы покажем их здесь.',
      );
    }

    final content = <Widget>[];
    String? lastGroup;
    for (var i = 0; i < items.length; i++) {
      final current = items[i];
      final group = operationDayLabel(current['created_at']?.toString() ?? '');
      if (group != lastGroup) {
        content.add(Padding(
          padding: EdgeInsets.only(top: lastGroup == null ? 6 : 10, bottom: 8),
          child: _TimelineDayHeader(label: group),
        ));
        lastGroup = group;
      }
      content.add(TimelineTile(item: current, isLast: i == items.length - 1));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HistoryFilterChip(
              label: 'Все',
              active: filter == 'all',
              onTap: () => setState(() => filter = 'all'),
            ),
            _HistoryFilterChip(
              label: 'Начисления',
              active: filter == 'accrual',
              onTap: () => setState(() => filter = 'accrual'),
            ),
            _HistoryFilterChip(
              label: 'Списания',
              active: filter == 'spend',
              onTap: () => setState(() => filter = 'spend'),
            ),
            _HistoryFilterChip(
              label: 'Покупки',
              active: filter == 'purchase',
              onTap: () => setState(() => filter = 'purchase'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...content,
      ],
    );
  }
}

class _HistoryFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _HistoryFilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? FlowColors.gold.withOpacity(0.22)
                : Colors.white.withOpacity(0.30),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? FlowColors.gold.withOpacity(0.70)
                  : Colors.white.withOpacity(0.55),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: FlowColors.gold.withOpacity(0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? FlowColors.ink : FlowColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineDayHeader extends StatelessWidget {
  final String label;
  const _TimelineDayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: FlowColors.gold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: FlowColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class AnimatedOperationBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool negative;
  const AnimatedOperationBadge(
      {super.key,
      required this.color,
      required this.icon,
      required this.negative});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.70),
              border: Border.all(color: color.withOpacity(0.62), width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 23),
          ),
        ],
      ),
    );
  }
}

class TimelineTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isLast;
  const TimelineTile({super.key, required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final type =
        (item['type'] ?? item['operation_type'] ?? 'operation').toString();
    final amount = item['amount']?.toString() ?? '0';
    final comment = item['comment']?.toString() ?? '';
    final createdAt = item['created_at']?.toString() ?? '';
    final view =
        buildOperationView(type: type, amountRaw: amount, comment: comment);
    final visual = operationVisual(type, amountRaw: amount, comment: comment);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedOperationBadge(
              color: visual.color,
              icon: visual.icon,
              negative: view.isNegative,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 72,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: FlowColors.ink.withOpacity(0.10),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.82),
                border: Border.all(color: FlowColors.ink.withOpacity(0.07)),
                boxShadow: [
                  BoxShadow(
                    color: visual.color.withOpacity(0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          view.title,
                          style: const TextStyle(
                            color: FlowColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (view.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            view.subtitle,
                            style: TextStyle(
                              color: FlowColors.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        view.amountText,
                        style: TextStyle(
                          color: visual.color,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        operationTimeText(createdAt),
                        style: TextStyle(
                          color: FlowColors.soft,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ScanModeSheet extends StatelessWidget {
  final String establishment;
  final String phone;
  final String qr;
  final int points;
  const ScanModeSheet(
      {super.key,
      required this.establishment,
      required this.phone,
      required this.qr,
      required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(colors: [
          Colors.white.withOpacity(0.96),
          Colors.white.withOpacity(0.90)
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: Colors.white.withOpacity(0.92)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 36,
              offset: const Offset(0, 20))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
              top: -100,
              right: -90,
              child:
                  GlowOrb(color: kLoginMintTop.withOpacity(0.18), size: 220)),
          Positioned(
              bottom: -110,
              left: -90,
              child: GlowOrb(color: kLoginAccent.withOpacity(0.16), size: 240)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                          color: kLoginInk.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999))),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(colors: [
                        Color(0xFF0A2B47),
                        Color(0xFF0B5D78),
                        Color(0xFF134C22)
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                    ),
                    child: Row(children: [
                      const AnimatedOrbitLogo(
                          size: 60, variant: OrbitLogoVariant.pulse),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('Режим сканирования',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.8)),
                            const SizedBox(height: 4),
                            Text(establishment,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.84),
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text('$points баллов · $phone',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.66),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ])),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.22))),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      color: Colors.white.withOpacity(0.78),
                      border: Border.all(color: Colors.white.withOpacity(0.94)),
                      boxShadow: [
                        BoxShadow(
                            color: kLoginBlue.withOpacity(0.10),
                            blurRadius: 24,
                            offset: const Offset(0, 12))
                      ],
                    ),
                    child: Column(children: [
                      AnimatedQrFrame(qrData: qr, size: 250),
                      const SizedBox(height: 14),
                      const Text('Покажите QR сотруднику',
                          style: TextStyle(
                              color: kLoginInk,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      const Text(
                          'Только красивый клиентский экран без лишних технических данных.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: kLoginInkSoft,
                              height: 1.4,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveEstablishmentProfileCard extends StatelessWidget {
  final String establishmentName;
  final String address;
  final String phone;
  final String workingHours;
  final Map<String, dynamic> ratings;
  final Map<String, dynamic> contacts;

  const LiveEstablishmentProfileCard(
      {super.key,
      required this.establishmentName,
      required this.address,
      required this.phone,
      required this.workingHours,
      required this.ratings,
      required this.contacts});

  @override
  Widget build(BuildContext context) {
    final yandex = map(ratings['yandex']);
    final twoGis = map(ratings['two_gis']);
    final social = map(contacts['social_media']);
    final yandexRating = toDouble(yandex['rating']);
    final twoGisRating = toDouble(twoGis['rating']);
    final hasAny = address.trim().isNotEmpty ||
        phone.trim().isNotEmpty ||
        workingHours.trim().isNotEmpty ||
        yandexRating > 0 ||
        twoGisRating > 0 ||
        social.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.98), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withOpacity(0.55),
                  border: Border.all(color: FlowColors.ink.withOpacity(0.08))),
              child:
                  const Icon(Icons.storefront_rounded, color: FlowColors.gold)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(establishmentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: FlowColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                const Text('Публичная карточка заведения',
                    style: TextStyle(
                        color: FlowColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ])),
        ]),
        const SizedBox(height: 14),
        if (!hasAny)
          const EmptyState(
              icon: Icons.info_outline_rounded,
              title: 'Данные заведения пока не заполнены',
              subtitle:
                  'Когда в базе появятся адрес, график и рейтинги, они отобразятся здесь.')
        else ...[
          if (address.trim().isNotEmpty)
            _LiveInfoLine(
                icon: Icons.place_rounded, title: 'Адрес', value: address),
          if (workingHours.trim().isNotEmpty)
            _LiveInfoLine(
                icon: Icons.schedule_rounded,
                title: 'График',
                value: workingHours),
          if (phone.trim().isNotEmpty)
            _LiveInfoLine(
                icon: Icons.phone_rounded, title: 'Телефон', value: phone),
          if (yandexRating > 0 || twoGisRating > 0) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (yandexRating > 0)
                _LiveChip(
                    icon: Icons.star_rounded,
                    text: 'Яндекс ${formatPercent(yandexRating)}'),
              if (twoGisRating > 0)
                _LiveChip(
                    icon: Icons.star_half_rounded,
                    text: '2ГИС ${formatPercent(twoGisRating)}'),
            ]),
          ],
          if (social.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Соцсети',
                style: TextStyle(
                    color: FlowColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: social.entries
                    .where((e) => nonEmpty(e.value) != null)
                    .map((e) => _LiveChip(
                        icon: Icons.link_rounded, text: e.key.toString()))
                    .toList()),
          ],
        ],
      ]),
    );
  }
}

class LiveLoyaltyRulesCard extends StatelessWidget {
  final Map<String, dynamic> rules;
  final int points;
  final double sales;

  const LiveLoyaltyRulesCard(
      {super.key,
      required this.rules,
      required this.points,
      required this.sales});

  @override
  Widget build(BuildContext context) {
    final mode = nonEmpty(rules['mode']) ?? 'loyalty';
    final maxRedeem = toDouble(rules['max_redeem_percent']);
    final redeemRate = toDouble(rules['redeem_rate']);
    final levels = mapList(rules['cashback_levels']);
    final expiration = map(rules['points_expiration']);
    final referral = map(rules['client_referral']);
    final birthday = map(rules['birthday_campaign']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.98), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle(
            title: 'Правила лояльности',
            subtitle: 'Что действует для выбранного заведения'),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _LiveChip(
              icon: Icons.auto_awesome_rounded,
              text: mode == 'cashback' ? 'Кэшбэк' : mode),
          if (maxRedeem > 0)
            _LiveChip(
                icon: Icons.payments_rounded,
                text: 'Списание до ${formatPercent(maxRedeem)}%'),
          if (redeemRate > 0)
            _LiveChip(
                icon: Icons.currency_ruble_rounded,
                text: '1 балл = ${formatPercent(redeemRate)} ₽'),
        ]),
        const SizedBox(height: 14),
        _LiveInfoLine(
            icon: Icons.stars_rounded,
            title: 'Ваш баланс',
            value: '${formatMoney(points)} б.'),
        _LiveInfoLine(
            icon: Icons.receipt_long_rounded,
            title: 'Сумма покупок',
            value: '${formatMoney(sales)} ₽'),
        if (expiration['enabled'] == true ||
            expiration['enabled']?.toString() == 'true')
          _LiveInfoLine(
              icon: Icons.hourglass_bottom_rounded,
              title: 'Срок жизни баллов',
              value: '${expiration['lifetime_days']} дней'),
        if (referral['enabled'] == true ||
            referral['enabled']?.toString() == 'true')
          _LiveInfoLine(
              icon: Icons.group_add_rounded,
              title: 'Реферальная программа',
              value:
                  '+${referral['inviter_points']} / +${referral['invited_points']} баллов'),
        if (birthday['enabled'] == true ||
            birthday['show_birthdate_block'] == true)
          _LiveInfoLine(
              icon: Icons.cake_rounded,
              title: 'День рождения',
              value: '${birthday['gift_points'] ?? 0} бонусных баллов'),
        if (levels.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Уровни гостей',
              style: TextStyle(
                  color: FlowColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...levels.map((level) {
            final name = nonEmpty(level['name']) ?? 'Уровень';
            final spent = toDouble(level['spent_required']);
            final percent = toDouble(level['cashback_percent']);
            final active = sales >= spent;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color:
                      active ? FlowColors.ink : Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: active ? FlowColors.ink : FlowColors.line)),
              child: Row(children: [
                Icon(
                    active
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: active ? FlowColors.acid : FlowColors.muted,
                    size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(name,
                        style: TextStyle(
                            color: active ? Colors.white : FlowColors.ink,
                            fontWeight: FontWeight.w900))),
                Text('${formatMoney(spent)} ₽ · ${formatPercent(percent)}%',
                    style: TextStyle(
                        color: active ? FlowColors.acid : FlowColors.muted,
                        fontWeight: FontWeight.w800)),
              ]),
            );
          }),
        ],
      ]),
    );
  }
}

class _LiveInfoLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _LiveInfoLine(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: FlowColors.ink.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: FlowColors.ink, size: 21)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: FlowColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: FlowColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.25)),
        ])),
      ]),
    );
  }
}

class _LiveChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _LiveChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: FlowColors.ink.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: FlowColors.line)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: FlowColors.ink),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: FlowColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

String formatPercent(dynamic value) {
  final n = toDouble(value);
  if ((n - n.round()).abs() < 0.000001) return n.round().toString();
  return n.toStringAsFixed(1);
}

class ProfileCommandCard extends StatelessWidget {
  final String name;
  final String phone;
  final int cardsCount;
  const ProfileCommandCard(
      {super.key,
      required this.name,
      required this.phone,
      this.cardsCount = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFEAF9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.96), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: FlowColors.blue.withOpacity(0.10),
              blurRadius: 22,
              offset: const Offset(0, 12))
        ],
      ),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.62),
            border: Border.all(color: FlowColors.ink.withOpacity(0.08)),
          ),
          child: Center(
              child: Text(initials(name),
                  style: const TextStyle(
                      color: FlowColors.gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 22))),
        ),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: FlowColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7)),
          const SizedBox(height: 5),
          Text(phone,
              style: const TextStyle(
                  color: kLoginInkSoft, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _MiniProfileBadge(
              icon: Icons.storefront_rounded, text: '$cardsCount заведений'),
        ])),
      ]),
    );
  }
}

class _MiniProfileBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniProfileBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: FlowColors.ink.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: FlowColors.ink, size: 14),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(
                color: FlowColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900))
      ]),
    );
  }
}

class ProfileQuickActionsGrid extends StatelessWidget {
  final List<Widget> children;
  const ProfileQuickActionsGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    });
  }
}

class ProfileQuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const ProfileQuickActionTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 104,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withOpacity(0.96),
            border: Border.all(color: Colors.white.withOpacity(0.98)),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 8))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15)),
                  child: Icon(icon, color: color, size: 20)),
              const Spacer(),
              Icon(Icons.arrow_forward_rounded,
                  color: FlowColors.soft.withOpacity(0.72), size: 18),
            ]),
            const Spacer(),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: FlowColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
            const SizedBox(height: 3),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: kLoginInkSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5)),
          ]),
        ),
      ),
    );
  }
}

class ProfileSettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback onTap;
  const ProfileSettingsRow(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      this.destructive = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFE85B63) : FlowColors.ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: kLoginInkSoft,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ])),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.50)),
          ]),
        ),
      ),
    );
  }
}

class ProfileFeatureShell extends StatelessWidget {
  final IconData icon;
  final String? assetPath;
  final String title;
  final String subtitle;
  final Color color;
  final Widget child;
  const ProfileFeatureShell(
      {super.key,
      required this.icon,
      this.assetPath,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 28,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18)),
              child: assetPath != null
                  ? PremiumAssetIcon(
                      asset: assetPath!,
                      size: 46,
                      fallbackIcon: icon,
                      fallbackColor: color)
                  : Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: FlowColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: kLoginInkSoft,
                        fontWeight: FontWeight.w700,
                        height: 1.25)),
              ])),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class LinkedEstablishmentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onDetails;
  const LinkedEstablishmentCard(
      {super.key,
      required this.item,
      required this.active,
      required this.onTap,
      required this.onDetails});

  @override
  Widget build(BuildContext context) {
    final points = formatMoney(item['points']);
    final name = item['establishment_name']?.toString() ??
        item['name']?.toString() ??
        'Заведение';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: active ? FlowColors.ink : Colors.white.withOpacity(0.94),
          border: Border.all(
              color: active
                  ? FlowColors.acid.withOpacity(0.36)
                  : Colors.white.withOpacity(0.98),
              width: 1.2),
          boxShadow: [
            BoxShadow(
                color: (active ? FlowColors.ink : FlowColors.aqua)
                    .withOpacity(active ? 0.18 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(children: [
          Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: active
                    ? Colors.white.withOpacity(0.12)
                    : FlowColors.ink.withOpacity(0.06),
              ),
              child: Icon(
                  active
                      ? Icons.check_circle_rounded
                      : Icons.storefront_rounded,
                  color: active ? FlowColors.acid : FlowColors.ink,
                  size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: active ? Colors.white : FlowColors.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                letterSpacing: -0.35))),
                    if (active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                            color: FlowColors.acid,
                            borderRadius: BorderRadius.circular(999)),
                        child: const Text('Выбрано',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900)),
                      ),
                  ]),
                  const SizedBox(height: 5),
                  Text('$points бонусов',
                      style: TextStyle(
                          color: active ? FlowColors.acid : kLoginInkSoft,
                          fontWeight: FontWeight.w900)),
                ])),
          ]),
          const SizedBox(height: 13),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: active
                        ? Colors.white.withOpacity(0.14)
                        : FlowColors.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17)),
                  ),
                  child: Text(active ? 'Открыто' : 'Открыть',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onDetails,
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('Подробнее'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: active ? Colors.white : FlowColors.ink,
                  side: BorderSide(
                      color: active
                          ? Colors.white.withOpacity(0.24)
                          : FlowColors.ink.withOpacity(0.10)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class EstablishmentDetailsSheet extends StatelessWidget {
  final String title;
  final String address;
  final String phone;
  final String workingHours;
  final int points;
  final bool active;
  final String? appleWalletUrl;
  final String? googleWalletUrl;
  final VoidCallback? onSelect;
  final VoidCallback? onShowRules;

  const EstablishmentDetailsSheet({
    super.key,
    required this.title,
    required this.address,
    required this.phone,
    required this.workingHours,
    required this.points,
    required this.active,
    this.appleWalletUrl,
    this.googleWalletUrl,
    this.onSelect,
    this.onShowRules,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 30,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 46,
              height: 5,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                  color: FlowColors.line,
                  borderRadius: BorderRadius.circular(999)),
            ),
          ),
          Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFD57A), Color(0xFF22D3C5)]),
              ),
              child: const Icon(Icons.storefront_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          color: FlowColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6)),
                  const SizedBox(height: 4),
                  Text('$points б. на карте',
                      style: const TextStyle(
                          color: FlowColors.soft, fontWeight: FontWeight.w800)),
                ])),
            if (active)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: FlowColors.acid,
                    borderRadius: BorderRadius.circular(999)),
                child: const Text('Выбрано',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12)),
              ),
          ]),
          const SizedBox(height: 16),
          if (address.trim().isNotEmpty)
            _SheetInfoRow(icon: Icons.place_rounded, text: address),
          if (workingHours.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _SheetInfoRow(icon: Icons.schedule_rounded, text: workingHours)
          ],
          if (phone.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _SheetInfoRow(icon: Icons.phone_rounded, text: phone)
          ],
          const SizedBox(height: 16),
          if (active &&
              ((appleWalletUrl ?? '').trim().isNotEmpty ||
                  (googleWalletUrl ?? '').trim().isNotEmpty)) ...[
            WalletInlineButtons(
                appleWalletUrl: appleWalletUrl,
                googleWalletUrl: googleWalletUrl),
            const SizedBox(height: 12),
          ],
          if (active && onShowRules != null) ...[
            SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                    text: 'Правила лояльности',
                    icon: Icons.auto_awesome_rounded,
                    onTap: onShowRules!)),
            const SizedBox(height: 10),
          ],
          if (!active && onSelect != null)
            SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                    text: 'Выбрать это заведение',
                    icon: Icons.check_rounded,
                    onTap: onSelect!)),
        ],
      ),
    );
  }
}

class _SheetInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SheetInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: FlowColors.aqua.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: FlowColors.ink, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: FlowColors.ink,
                    height: 1.35,
                    fontWeight: FontWeight.w800))),
      ],
    );
  }
}

class OrbitDock extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  final VoidCallback onScan;
  const OrbitDock(
      {super.key,
      required this.current,
      required this.onChanged,
      required this.onScan});

  @override
  Widget build(BuildContext context) {
    const items = [
      NavItem(Icons.home_rounded, 'Главная'),
      NavItem(Icons.person_rounded, 'Профиль')
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1930).withOpacity(0.70),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == current;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: active
                          ? Colors.white.withOpacity(0.08)
                          : Colors.transparent,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color:
                                    const Color(0xFF32C7FF).withOpacity(0.18),
                                blurRadius: 14,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].icon,
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.66),
                          size: 21,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : Colors.white.withOpacity(0.66),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const SectionTitle({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(
              color: FlowColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8)),
      const SizedBox(height: 4),
      Text(subtitle,
          style: const TextStyle(
              color: FlowColors.muted,
              height: 1.25,
              fontWeight: FontWeight.w600))
    ]);
  }
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const SurfaceCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.radius = 28});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: Colors.white.withOpacity(0.34),
          border:
              Border.all(color: Colors.white.withOpacity(0.62), width: 1.15),
          boxShadow: [
            BoxShadow(
                color: FlowColors.ink.withOpacity(0.055),
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
        ),
        child:
            Container(width: double.infinity, padding: padding, child: child),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onTap;
  const PrimaryButton(
      {super.key,
      required this.text,
      this.icon,
      this.loading = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(31),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B6E8D), Color(0xFF114A68), Color(0xFF0A2B47)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.72), width: 1.1),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0A7EA0).withOpacity(0.24),
              blurRadius: 24,
              offset: const Offset(0, 12)),
          BoxShadow(
              color: kLoginAccentSoft.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(31),
          child: Container(
            height: 60,
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white),
                        const SizedBox(width: 9)
                      ],
                      Text(text,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String text;
  const ErrorBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: FlowColors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FlowColors.red.withOpacity(0.18))),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, color: FlowColors.red),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: FlowColors.red,
                      fontWeight: FontWeight.w800,
                      height: 1.25)))
        ]));
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
        radius: 28,
        child: Column(children: [
          Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                  color: FlowColors.ink.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(22)),
              child: Icon(icon, color: FlowColors.ink, size: 30)),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: FlowColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: FlowColors.muted,
                  height: 1.35,
                  fontWeight: FontWeight.w600))
        ]));
  }
}

class NoCard extends StatelessWidget {
  final String phone;
  const NoCard({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
        icon: Icons.credit_card_off_rounded,
        title: 'Карта пока не найдена',
        subtitle:
            'Когда телефон $phone будет привязан в Telegram или MAX, карта появится здесь автоматически.');
  }
}

class ThemeFoundationCard extends StatelessWidget {
  final ThemePreset currentPreset;
  const ThemeFoundationCard({super.key, required this.currentPreset});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
        padding: const EdgeInsets.all(16),
        radius: 28,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle(
              title: 'Темы и шаблоны', subtitle: 'Основа будущих оформлений'),
          const SizedBox(height: 14),
          Row(children: [
            _ThemeDot(color: currentPreset.primary),
            const SizedBox(width: 8),
            _ThemeDot(color: currentPreset.secondary),
            const SizedBox(width: 8),
            _ThemeDot(color: currentPreset.accent),
            const SizedBox(width: 12),
            Expanded(
                child: Text(currentPreset.name,
                    style: const TextStyle(
                        color: FlowColors.ink, fontWeight: FontWeight.w900)))
          ])
        ]));
  }
}

class _ThemeDot extends StatelessWidget {
  final Color color;
  const _ThemeDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 5))
          ]));
}

class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const DangerButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            height: 56,
            decoration: BoxDecoration(
                color: FlowColors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: FlowColors.red.withOpacity(0.18))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.logout_rounded, color: FlowColors.red),
              const SizedBox(width: 9),
              Text(text,
                  style: const TextStyle(
                      color: FlowColors.red, fontWeight: FontWeight.w900))
            ])));
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) => const Center(
      child: SurfaceCard(
          padding: EdgeInsets.all(24),
          radius: 28,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: FlowColors.ink),
            SizedBox(height: 14),
            Text('Загружаем профиль...',
                style: TextStyle(
                    color: FlowColors.ink, fontWeight: FontWeight.w900))
          ])));
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child: SurfaceCard(
              padding: const EdgeInsets.all(22),
              radius: 30,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                        color: FlowColors.red.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(22)),
                    child: const Icon(Icons.wifi_off_rounded,
                        size: 32, color: FlowColors.red)),
                const SizedBox(height: 14),
                const Text('Ошибка загрузки',
                    style: TextStyle(
                        color: FlowColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 22)),
                const SizedBox(height: 8),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: FlowColors.muted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                PrimaryButton(
                    text: 'Повторить',
                    icon: Icons.refresh_rounded,
                    onTap: onRetry)
              ]))));
}

class RaffleDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> draw;
  final bool joining;
  final VoidCallback? onJoin;
  const RaffleDetailsSheet(
      {super.key,
      required this.draw,
      required this.joining,
      required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final title = nonEmpty(draw['title']) ?? 'Розыгрыш';
    final prize = nonEmpty(draw['prize_text']) ??
        nonEmpty(draw['description']) ??
        'Приз от заведения';
    final postText = nonEmpty(draw['post_text']) ??
        nonEmpty(draw['full_text']) ??
        nonEmpty(draw['rules']) ??
        'Подробности розыгрыша скоро появятся.';
    final participants = toInt(draw['participants_count']);
    final isJoined = draw['is_joined'] == true;
    final buttonTitle = draw['join_button_title']?.toString() ??
        (isJoined ? 'Вы участвуете' : 'Участвовать');
    final drawAt = formatClientDateTime(draw['draw_at']);
    final imageUrl = extractImageUrl(draw);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.trim().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: Image.network(imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: kLoginViolet.withOpacity(0.10),
                            alignment: Alignment.center,
                            child: const Icon(Icons.celebration_rounded,
                                color: kLoginViolet, size: 44))),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(children: [
                Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [kLoginBlue, kLoginPink]),
                        borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.celebration_rounded,
                        color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Розыгрыш',
                          style: TextStyle(
                              color: kLoginInkSoft,
                              fontWeight: FontWeight.w800)),
                      Text(title,
                          style: const TextStyle(
                              color: kLoginInk,
                              fontSize: 21,
                              height: 1.1,
                              fontWeight: FontWeight.w900)),
                    ])),
              ]),
              const SizedBox(height: 18),
              Text(prize,
                  style: const TextStyle(
                      color: kLoginInk,
                      fontWeight: FontWeight.w900,
                      height: 1.35)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (participants > 0)
                  LightChip(
                      icon: Icons.groups_rounded,
                      text: '$participants участников'),
                if (drawAt.isNotEmpty)
                  LightChip(icon: Icons.schedule_rounded, text: drawAt),
              ]),
              const SizedBox(height: 16),
              Flexible(
                  child: SingleChildScrollView(
                      child: Text(postText,
                          style: const TextStyle(
                              color: kLoginInkSoft,
                              height: 1.45,
                              fontWeight: FontWeight.w600)))),
              if (onJoin != null) ...[
                const SizedBox(height: 18),
                PrimaryButton(
                    text: joining ? 'Отправляем...' : buttonTitle,
                    loading: joining,
                    onTap: joining || isJoined
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            onJoin!();
                          }),
              ],
            ]),
      ),
    );
  }
}

class DarkChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const DarkChip({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: Colors.white),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))
      ]));
}

class LightChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const LightChip({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: FlowColors.paper2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: FlowColors.line)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: FlowColors.ink),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: FlowColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800))
      ]));
}

class BenefitEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const BenefitEntry(this.title, this.subtitle, this.icon, this.color);
}

void showPromoDetailsSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  String? establishmentName,
  Future<void> Function()? onOpenEstablishment,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FlowColors.paper,
        borderRadius: BorderRadius.circular(34),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: FlowColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((establishmentName ?? '').trim().isNotEmpty)
                          Text(
                            establishmentName!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FlowColors.gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FlowColors.ink,
                            fontSize: 22,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  subtitle.trim(),
                  style: const TextStyle(
                    color: FlowColors.muted,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (onOpenEstablishment != null) ...[
                const SizedBox(height: 18),
                PrimaryButton(
                  text: 'Перейти в заведение',
                  icon: Icons.arrow_forward_rounded,
                  onTap: () {
                    onOpenEstablishment();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

void showBenefitSheet(BuildContext context,
    {required String title,
    required String subtitle,
    required IconData icon,
    required Color color}) {
  showBenefitsList(
      context, title, [BenefitEntry(title, subtitle, icon, color)]);
}

void showBenefitsList(
    BuildContext context, String title, List<BenefitEntry> items) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: FlowColors.paper, borderRadius: BorderRadius.circular(34)),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  color: FlowColors.line,
                  borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 16),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(children: [
                const FlowMark(size: 48),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: FlowColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)))
              ])),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = items[i];
                return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: FlowColors.paper2,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: FlowColors.line)),
                    child: Row(children: [
                      Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: item.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16)),
                          child: Icon(item.icon, color: item.color)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(item.title,
                                style: const TextStyle(
                                    color: FlowColors.ink,
                                    fontWeight: FontWeight.w900)),
                            if (item.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(item.subtitle,
                                  style: const TextStyle(
                                      color: FlowColors.muted,
                                      height: 1.3,
                                      fontWeight: FontWeight.w600))
                            ]
                          ]))
                    ]));
              },
            ),
          ),
        ]),
      ),
    ),
  );
}

class FlowMark extends StatelessWidget {
  final double size;
  final bool dark;
  const FlowMark({super.key, required this.size, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final centerSize = size * 0.82;
    final badgeSize = size * 0.58;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: centerSize,
            height: centerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [
                Color(0xFFFFEE7B),
                Color(0xFFFFBD2E),
                Color(0xFFFFA51E)
              ], stops: [
                0.0,
                0.68,
                1.0
              ]),
              border:
                  Border.all(color: Colors.white.withOpacity(0.62), width: 1.1),
              boxShadow: [
                BoxShadow(
                    color: kLoginAccent.withOpacity(0.34),
                    blurRadius: size * 0.24,
                    offset: Offset(0, size * 0.10)),
                BoxShadow(
                    color: Colors.white.withOpacity(0.28),
                    blurRadius: size * 0.12),
              ],
            ),
          ),
          SizedBox(
            width: badgeSize,
            height: badgeSize,
            child: Image.asset(
              'assets/images/flowru_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const GlowOrb({super.key, required this.color, required this.size});
  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 46, sigmaY: 46),
          child: Container(
              width: size,
              height: size,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle))));
}

class MicroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.010)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 10) {
      for (double y = 0; y < size.height; y += 10) {
        if ((x.toInt() + y.toInt()) % 9 == 0)
          canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PromoItem {
  final String tag;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  final Map<String, dynamic>? rawData;
  final bool isRaffle;

  const PromoItem({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.imageUrl,
    this.rawData,
    this.isRaffle = false,
  });

  String? get actionText => promoFirstText([
        rawData?['button_text'],
        rawData?['buttonText'],
        rawData?['button_title'],
        rawData?['buttonTitle'],
        rawData?['button_label'],
        rawData?['buttonLabel'],
        rawData?['cta_text'],
        rawData?['ctaText'],
        rawData?['action_text'],
        rawData?['actionText'],
        rawData?['link_text'],
        rawData?['linkText'],
      ]);

  String? get actionUrl => promoFirstText([
        rawData?['button_url'],
        rawData?['buttonUrl'],
        rawData?['button_link'],
        rawData?['buttonLink'],
        rawData?['cta_url'],
        rawData?['ctaUrl'],
        rawData?['action_url'],
        rawData?['actionUrl'],
        rawData?['link_url'],
        rawData?['linkUrl'],
        rawData?['url'],
        rawData?['link'],
      ]);
}

class OperationViewData {
  final String title;
  final String subtitle;
  final String amountText;
  final bool isNegative;
  const OperationViewData(
      {required this.title,
      required this.subtitle,
      required this.amountText,
      required this.isNegative});
}

OperationViewData buildOperationView(
    {required String type,
    required String amountRaw,
    required String comment}) {
  final amount = toDouble(amountRaw);
  final formatted = formatAmount(amountRaw);
  switch (type) {
    case 'purchase_amount':
    case 'accrual':
    case 'manual_accrual':
      return OperationViewData(
          title: 'Начисление баллов',
          subtitle: cleanComment(comment),
          amountText: '+$formatted б.',
          isNegative: false);
    case 'spend':
    case 'manual_writeoff':
    case 'writeoff':
      return OperationViewData(
          title: 'Списание баллов',
          subtitle: cleanComment(comment),
          amountText: '-$formatted б.',
          isNegative: true);
    case 'visit':
      return OperationViewData(
          title: 'Покупка',
          subtitle: 'Сумма чека',
          amountText: '${formatMoney(amountRaw)} ₽',
          isNegative: false);
    case 'quest_cashback_boost':
      return OperationViewData(
          title: 'Бонус за квест',
          subtitle: cleanComment(comment),
          amountText: '+$formatted б.',
          isNegative: false);
    case 'birthday_bonus':
      return OperationViewData(
          title: 'Подарок на день рождения',
          subtitle: cleanComment(comment),
          amountText: '+$formatted б.',
          isNegative: false);
    case 'campaign_send':
      return const OperationViewData(
          title: 'Уведомление',
          subtitle: 'Сообщение от заведения',
          amountText: '',
          isNegative: false);
    default:
      return OperationViewData(
          title: cleanComment(comment).isEmpty
              ? 'Операция'
              : cleanComment(comment),
          subtitle: type,
          amountText: amount < 0
              ? '-${formatAmount(amount)} б.'
              : '+${formatAmount(amount)} б.',
          isNegative: amount < 0);
  }
}

class OperationVisualData {
  final IconData icon;
  final Color color;
  const OperationVisualData({required this.icon, required this.color});
}

String operationFilterType(Map<String, dynamic> item) {
  final type = (item['type'] ?? item['operation_type'] ?? '').toString();
  switch (type) {
    case 'purchase_amount':
    case 'accrual':
    case 'manual_accrual':
    case 'quest_cashback_boost':
    case 'birthday_bonus':
      return 'accrual';
    case 'spend':
    case 'manual_writeoff':
    case 'writeoff':
      return 'spend';
    case 'visit':
      return 'purchase';
    default:
      final amount = toDouble(item['amount']);
      if (amount < 0) return 'spend';
      return 'accrual';
  }
}

OperationVisualData operationVisual(String type,
    {required String amountRaw, required String comment}) {
  switch (type) {
    case 'purchase_amount':
    case 'accrual':
    case 'manual_accrual':
    case 'quest_cashback_boost':
    case 'birthday_bonus':
      return const OperationVisualData(
        icon: Icons.card_giftcard_rounded,
        color: Color(0xFF37D7FF),
      );
    case 'spend':
    case 'manual_writeoff':
    case 'writeoff':
      return const OperationVisualData(
        icon: Icons.remove_circle_rounded,
        color: Color(0xFFFFA52F),
      );
    case 'visit':
      return const OperationVisualData(
        icon: Icons.shopping_cart_rounded,
        color: Color(0xFF56B8FF),
      );
    default:
      final amount = toDouble(amountRaw);
      if (amount < 0) {
        return const OperationVisualData(
          icon: Icons.remove_circle_rounded,
          color: Color(0xFFFFA52F),
        );
      }
      return const OperationVisualData(
        icon: Icons.card_giftcard_rounded,
        color: Color(0xFF37D7FF),
      );
  }
}

String operationTimeText(String raw) {
  if (raw.trim().isEmpty) return '—';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  final local = dt.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String operationDayLabel(String raw) {
  if (raw.trim().isEmpty) return 'Без даты';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return shortDate(raw);
  final local = dt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  if (day == today) return 'Сегодня';
  if (day == today.subtract(const Duration(days: 1))) return 'Вчера';
  return '${local.day.toString().padLeft(2, '0')} ${_monthRu(local.month)}';
}

String _monthRu(int month) {
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря'
  ];
  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

String cleanComment(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return '';
  if (text.startsWith('staff_purchase:')) return 'Покупка в заведении';
  if (text.startsWith('tg_webapp_accrue:')) return 'Покупка через карту гостя';
  if (text.startsWith('campaign_id=')) return 'Сообщение от заведения';
  return text;
}

String? promoFirstText(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) continue;
    if (text.toLowerCase() == 'null') continue;
    return text;
  }
  return null;
}

String? normalizePublicImageUrl(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return null;

  value = value.replaceAll('\\', '/');

  if (value.startsWith('http://') || value.startsWith('https://')) return value;

  const projectPrefix = '/opt/detalika-bot/';
  if (value.startsWith(projectPrefix)) {
    value = value.substring(projectPrefix.length);
  }

  while (value.startsWith('./')) {
    value = value.substring(2);
  }

  if (value.startsWith('/')) return '${AppConfig.publicBase}$value';

  if (value.startsWith('static/')) return '${AppConfig.publicBase}/$value';
  if (value.startsWith('uploads/'))
    return '${AppConfig.publicBase}/static/$value';
  if (value.startsWith('raffle_media/'))
    return '${AppConfig.publicBase}/$value';
  if (value.startsWith('promotions/'))
    return '${AppConfig.publicBase}/static/uploads/$value';
  if (value.startsWith('dev_content/'))
    return '${AppConfig.publicBase}/static/uploads/$value';
  if (value.startsWith('wallet/'))
    return '${AppConfig.publicBase}/static/uploads/$value';
  if (value.startsWith('menu/'))
    return '${AppConfig.publicBase}/static/uploads/$value';

  return value;
}

String? extractImageUrl(Map<String, dynamic> data) {
  const directKeys = [
    'image_url',
    'image',
    'photo_url',
    'photo_path',
    'image_path',
    'cover_path',
    'media_path',
    'photoPath',
    'imagePath',
    'coverPath',
    'mediaPath',
    'filePath',
    'file_path',
    'photo',
    'picture',
    'cover_url',
    'cover',
    'banner_url',
    'banner',
    'imageUrl',
    'photoUrl',
    'coverUrl',
    'poster_url',
    'preview_url',
    'thumbnail_url',
    'media_url',
    'file_url',
    'attachments',
    'attachment',
    'media',
    'photos',
    'images',
    'files',
    'url',
  ];

  for (final key in directKeys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty)
      return normalizePublicImageUrl(value.trim());

    if (value is Map) {
      for (final nestedKey in const [
        'url',
        'image_url',
        'photo_url',
        'imageUrl',
        'photoUrl',
        'path',
        'src',
        'file_url',
        'fileUrl',
        'photo_path',
        'image_path',
        'photoPath',
        'imagePath'
      ]) {
        final nestedValue = value[nestedKey];
        if (nestedValue is String && nestedValue.trim().isNotEmpty)
          return normalizePublicImageUrl(nestedValue.trim());
      }
    }

    if (value is List) {
      for (final item in value) {
        if (item is String && item.trim().isNotEmpty)
          return normalizePublicImageUrl(item.trim());
        if (item is Map) {
          for (final nestedKey in const [
            'url',
            'image_url',
            'photo_url',
            'imageUrl',
            'photoUrl',
            'path',
            'src',
            'file_url',
            'fileUrl',
            'photo_path',
            'image_path',
            'photoPath',
            'imagePath'
          ]) {
            final nestedValue = item[nestedKey];
            if (nestedValue is String && nestedValue.trim().isNotEmpty)
              return normalizePublicImageUrl(nestedValue.trim());
          }
        }
      }
    }
  }
  return null;
}

Route<T> appRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
          opacity: curved,
          child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero)
                      .animate(curved),
              child: child));
    },
  );
}

Map<String, dynamic> map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  return {};
}

List<Map<String, dynamic>> mapList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => map(e)).toList();
}

String? nonEmpty(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

bool boolValue(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase() ?? '';
  return text == 'true' || text == '1' || text == 'yes' || text == 'да';
}

int toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.toInt();
  return double.tryParse(value.toString().replaceAll(',', '.'))?.round() ?? 0;
}

double toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
}

int? intOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString()) ??
      double.tryParse(value.toString())?.round();
}

String formatAmount(dynamic value) {
  final amount = toDouble(value).abs();
  if ((amount - amount.round()).abs() < 0.000001)
    return groupDigits(amount.round().toString());
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final fraction = parts[1].replaceFirst(RegExp(r'0+$'), '');
  return fraction.isEmpty
      ? groupDigits(parts[0])
      : '${groupDigits(parts[0])}.$fraction';
}

String formatMoney(dynamic value) =>
    groupDigits(toDouble(value).round().toString());

String groupDigits(String value) {
  final raw = value.replaceAll(' ', '');
  final sign = raw.startsWith('-') ? '-' : '';
  final digits = raw.replaceAll('-', '');
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final pos = digits.length - i;
    buffer.write(digits[i]);
    if (pos > 1 && pos % 3 == 1) buffer.write(' ');
  }
  return '$sign${buffer.toString()}';
}

String formatDateTime(String raw) {
  if (raw.trim().isEmpty) return '—';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  final local = dt.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}, ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String shortDate(String raw) {
  if (raw.trim().isEmpty) return '—';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  final local = dt.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}';
}

String initials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'F';
  if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
  return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
}

bool isVisibleClientOperation(Map<String, dynamic> item) {
  final type = (item['type'] ?? item['operation_type'] ?? '').toString();
  final comment = (item['comment'] ?? '').toString();
  if (type == 'campaign_send') return false;
  if (comment.startsWith('campaign_id=')) return false;
  if (type.trim().isEmpty && comment.trim().isEmpty) return false;
  return true;
}

List<Map<String, dynamic>> visibleClientHistory(
        List<Map<String, dynamic>> items) =>
    items.where(isVisibleClientOperation).toList();

List<Map<String, dynamic>> dedupeEstablishments(
    List<Map<String, dynamic>> items) {
  final Map<int, Map<String, dynamic>> bestByEstablishment = {};
  for (final item in items) {
    final estId = intOrNull(item['establishment_id']);
    if (estId == null) continue;
    final current = bestByEstablishment[estId];
    if (current == null) {
      bestByEstablishment[estId] = item;
      continue;
    }
    if (establishmentCardScore(item) > establishmentCardScore(current))
      bestByEstablishment[estId] = item;
  }
  final result = bestByEstablishment.values.toList();
  result.sort((a, b) => (a['establishment_name']?.toString() ?? '')
      .compareTo(b['establishment_name']?.toString() ?? ''));
  return result;
}

num establishmentCardScore(Map<String, dynamic> item) {
  final sales = toDouble(item['sales_total']);
  final visits = toInt(item['visits']);
  final points = toInt(item['points']);
  final qrCode = item['qr_code']?.toString() ?? '';
  num score = 0;
  score += sales * 100000;
  score += visits * 1000;
  score += points;
  if (qrCode.isNotEmpty) score += 100;
  return score;
}
