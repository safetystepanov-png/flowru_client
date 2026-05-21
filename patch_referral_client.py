from pathlib import Path

path = Path("lib/main.dart")
text = path.read_text(encoding="utf-8")

marker = "CLIENT_REFERRAL_DEEPLINK_APPLY_20260521"

def fail(msg):
    raise SystemExit("ERROR: " + msg)

def find_matching_brace(s, open_pos):
    depth = 0
    in_single = False
    in_double = False
    in_line_comment = False
    in_block_comment = False
    escape = False

    for i in range(open_pos, len(s)):
        ch = s[i]
        nxt = s[i + 1] if i + 1 < len(s) else ""

        if in_line_comment:
            if ch == "\n":
                in_line_comment = False
            continue

        if in_block_comment:
            if ch == "*" and nxt == "/":
                in_block_comment = False
            continue

        if in_single:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == "'":
                in_single = False
            continue

        if in_double:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_double = False
            continue

        if ch == "/" and nxt == "/":
            in_line_comment = True
            continue

        if ch == "/" and nxt == "*":
            in_block_comment = True
            continue

        if ch == "'":
            in_single = True
            continue

        if ch == '"':
            in_double = True
            continue

        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i

    return -1

def replace_class(s, class_name, replacement):
    start = s.find(f"class {class_name}")
    if start < 0:
        fail(f"class not found: {class_name}")
    open_pos = s.find("{", start)
    if open_pos < 0:
        fail(f"opening brace not found for class: {class_name}")
    end = find_matching_brace(s, open_pos)
    if end < 0:
        fail(f"closing brace not found for class: {class_name}")
    return s[:start] + replacement + s[end + 1:]

def replace_function(s, signature, replacement):
    start = s.find(signature)
    if start < 0:
        fail(f"function not found: {signature}")
    open_pos = s.find("{", start)
    if open_pos < 0:
        fail(f"opening brace not found for function: {signature}")
    end = find_matching_brace(s, open_pos)
    if end < 0:
        fail(f"closing brace not found for function: {signature}")
    return s[:start] + replacement + s[end + 1:]

if marker in text:
    print("SKIP: referral deep link patch already installed")
else:
    new_deeplink_class = r'''class FlowReferralDeepLink {
  final int establishmentId;
  final String referralCode;

  const FlowReferralDeepLink({
    required this.establishmentId,
    required this.referralCode,
  });
}

class FlowInviteDeepLinks {
  static final AppLinks _appLinks = AppLinks();

  static String? pendingInviteToken;
  static FlowReferralDeepLink? pendingReferral;

  static int? _toInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value.trim());
  }

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

    // https://mapi.flowru.ru/join/e/TOKEN
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

  static FlowReferralDeepLink? parseReferral(Uri? uri) {
    if (uri == null) return null;

    // flowru://referral/e/2/CODE
    if (uri.scheme == 'flowru' && uri.host == 'referral') {
      final segments = uri.pathSegments;
      if (segments.length >= 3 && segments[0] == 'e') {
        final establishmentId = _toInt(segments[1]);
        final code = segments[2].trim();
        if (establishmentId != null && establishmentId > 0 && code.isNotEmpty) {
          return FlowReferralDeepLink(
            establishmentId: establishmentId,
            referralCode: code,
          );
        }
      }

      // fallback: flowru://referral/2/CODE
      if (segments.length >= 2) {
        final establishmentId = _toInt(segments[0]);
        final code = segments[1].trim();
        if (establishmentId != null && establishmentId > 0 && code.isNotEmpty) {
          return FlowReferralDeepLink(
            establishmentId: establishmentId,
            referralCode: code,
          );
        }
      }
    }

    // https://mapi.flowru.ru/api/v1/client/referral/open/2/CODE
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == 'mapi.flowru.ru') {
      final segments = uri.pathSegments;
      final idx = segments.indexOf('referral');
      if (idx >= 0 &&
          segments.length > idx + 3 &&
          segments[idx + 1] == 'open') {
        final establishmentId = _toInt(segments[idx + 2]);
        final code = segments[idx + 3].trim();
        if (establishmentId != null && establishmentId > 0 && code.isNotEmpty) {
          return FlowReferralDeepLink(
            establishmentId: establishmentId,
            referralCode: code,
          );
        }
      }
    }

    return null;
  }

  static Future<void> initInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();

      final referral = parseReferral(uri);
      if (referral != null) {
        pendingReferral = referral;
        return;
      }

      final token = parseInviteToken(uri);
      if (token != null && token.isNotEmpty) {
        pendingInviteToken = token;
      }
    } catch (_) {
      // Не блокируем запуск приложения из-за ошибки deep link.
    }
  }

  static Stream<Uri> get stream => _appLinks.uriLinkStream;
}'''

    text = replace_class(text, "FlowInviteDeepLinks", new_deeplink_class)
    print("OK: FlowInviteDeepLinks now supports referral links")

    old_join = r'''  Future<Map<String, dynamic>> joinEstablishment(
      String token, String inviteToken) {
    return _request(
        path: '/client/establishments/join',
        method: 'POST',
        token: token,
        body: {'invite_token': inviteToken});
  }
'''
    new_join = r'''  Future<Map<String, dynamic>> joinEstablishment(
      String token, String inviteToken) {
    return _request(
        path: '/client/establishments/join',
        method: 'POST',
        token: token,
        body: {'invite_token': inviteToken});
  }

  Future<Map<String, dynamic>> applyReferral(
      String token, int establishmentId, String referralCode) {
    return _request(
        path: '/client/referral/apply/$establishmentId/$referralCode',
        method: 'POST',
        token: token);
  }
'''
    if old_join not in text:
        fail("joinEstablishment block not found")
    text = text.replace(old_join, new_join, 1)
    print("OK: FlowApi.applyReferral added")

    old_flags = '''  bool joiningDraw = false;
  bool joiningInvite = false;
  StreamSubscription<Uri>? inviteDeepLinkSub;
'''
    new_flags = '''  bool joiningDraw = false;
  bool joiningInvite = false;
  bool applyingReferral = false;
  StreamSubscription<Uri>? inviteDeepLinkSub;
'''
    if old_flags not in text:
        fail("ClientShell flags block not found")
    text = text.replace(old_flags, new_flags, 1)
    print("OK: applyingReferral flag added")

    new_init_links = r'''  void initInviteDeepLinks() {
    inviteDeepLinkSub = FlowInviteDeepLinks.stream.listen((uri) {
      final referral = FlowInviteDeepLinks.parseReferral(uri);
      if (referral != null) {
        handleReferralLink(referral);
        return;
      }

      final token = FlowInviteDeepLinks.parseInviteToken(uri);
      if (token != null && token.isNotEmpty) {
        handleInviteToken(token);
      }
    });
  }'''
    text = replace_function(text, "  void initInviteDeepLinks()", new_init_links)
    print("OK: deep link listener handles referral")

    new_consume_invite = r'''  Future<void> consumePendingInviteToken() async {
    final token = FlowInviteDeepLinks.pendingInviteToken;
    if (token == null || token.trim().isEmpty) return;

    FlowInviteDeepLinks.pendingInviteToken = null;
    await handleInviteToken(token.trim());
  }

  Future<void> consumePendingReferralLink() async {
    final referral = FlowInviteDeepLinks.pendingReferral;
    if (referral == null) return;

    FlowInviteDeepLinks.pendingReferral = null;
    await handleReferralLink(referral);
  }'''
    text = replace_function(text, "  Future<void> consumePendingInviteToken() async", new_consume_invite)
    print("OK: pending referral consumer added")

    handle_referral = r'''
  Future<void> handleReferralLink(FlowReferralDeepLink referral) async {
    final establishmentId = referral.establishmentId;
    final referralCode = referral.referralCode.trim();

    if (establishmentId <= 0 || referralCode.isEmpty || applyingReferral) return;

    setState(() {
      applyingReferral = true;
      error = null;
    });

    try {
      final token = await getFreshAccessToken();
      if (token == null || token.isEmpty) {
        FlowInviteDeepLinks.pendingReferral = referral;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Войдите в Flowru, чтобы применить приглашение')),
        );
        return;
      }

      final res = await api.applyReferral(token, establishmentId, referralCode);

      if (!mounted) return;

      final alreadyApplied = res['already_applied'] == true;
      final inviterPoints = intOrNull(res['inviter_points']) ?? 0;
      final invitedPoints = intOrNull(res['invited_points']) ?? 0;

      String message = (res['message'] ?? '').toString().trim();
      if (message.isEmpty) {
        message = alreadyApplied
            ? 'Реферальное приглашение уже было применено'
            : 'Реферальное приглашение применено';
      }

      if (!alreadyApplied && invitedPoints > 0) {
        message = '$message. Вам начислено $invitedPoints баллов';
      } else if (!alreadyApplied && inviterPoints > 0) {
        message = '$message. Пригласившему начислено $inviterPoints баллов';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      selectedEstablishmentId = establishmentId;
      await loadAll();
    } on ApiError catch (e) {
      if (!mounted) return;

      if (e.status == 401) {
        FlowInviteDeepLinks.pendingReferral = referral;
        return logout();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Не удалось применить реферальное приглашение')),
      );
    } finally {
      if (mounted) {
        setState(() => applyingReferral = false);
      }
    }
  }

'''
    anchor = "  Future<void> handleInviteToken(String inviteToken) async {"
    if anchor not in text:
        fail("handleInviteToken anchor not found")
    text = text.replace(anchor, handle_referral + anchor, 1)
    print("OK: handleReferralLink added")

    if "consumePendingReferralLink();" not in text:
        old_pending = '''    WidgetsBinding.instance.addPostFrameCallback((_) {
      consumePendingInviteToken();
    });'''
        new_pending = '''    WidgetsBinding.instance.addPostFrameCallback((_) {
      consumePendingInviteToken();
      consumePendingReferralLink();
    });'''
        if old_pending not in text:
            fail("postFrame pending invite block not found")
        text = text.replace(old_pending, new_pending, 1)
        print("OK: pending referral consumed after app open")
    else:
        print("SKIP: consumePendingReferralLink already called")

    text += f"\n// {marker}\n"
    path.write_text(text, encoding="utf-8")
    print("OK: client referral deep link patch applied")
