from pathlib import Path
import re

path = Path("lib/main.dart")
text = path.read_text(encoding="utf-8")

marker = "CLIENT_APP_MENU_PHONE_INVITE_20260521"

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

def replace_function(s, signature, replacement):
    start = s.find(signature)
    if start < 0:
        fail(f"function signature not found: {signature}")
    open_pos = s.find("{", start)
    if open_pos < 0:
        fail(f"opening brace not found for: {signature}")
    end = find_matching_brace(s, open_pos)
    if end < 0:
        fail(f"closing brace not found for: {signature}")
    return s[:start] + replacement + s[end + 1:]

def replace_class(s, class_name, replacement):
    signature = f"class {class_name}"
    start = s.find(signature)
    if start < 0:
        fail(f"class not found: {class_name}")
    open_pos = s.find("{", start)
    if open_pos < 0:
        fail(f"opening brace not found for class: {class_name}")
    end = find_matching_brace(s, open_pos)
    if end < 0:
        fail(f"closing brace not found for class: {class_name}")
    return s[:start] + replacement + s[end + 1:]

if marker in text:
    print("SKIP: patch already installed")
else:
    # 1. Контроллеры телефона + helper-ы +7
    controllers_re = re.compile(
        r"  final loginPhone = TextEditingController\(\);\n"
        r"  final loginPassword = TextEditingController\(\);\n"
        r"  final regName = TextEditingController\(\);\n"
        r"  final regPhone = TextEditingController\(\);\n"
        r"  final regPassword = TextEditingController\(\);\n"
        r"  final regConfirm = TextEditingController\(\);\n"
    )

    controllers_new = r"""  final loginPhone = TextEditingController(text: '+7');
  final loginPassword = TextEditingController();
  final regName = TextEditingController();
  final regPhone = TextEditingController(text: '+7');
  final regPassword = TextEditingController();
  final regConfirm = TextEditingController();

  static const String _ruPhonePrefix = '+7';
  bool _normalizingPhone = false;

  String _normalizeRuPhone(String raw) {
    var value = raw.trim();

    if (value.isEmpty) return _ruPhonePrefix;

    value = value.replaceAll(RegExp(r'[^0-9+]'), '');

    if (value == '+') return _ruPhonePrefix;

    if (value.startsWith('8')) {
      value = '+7${value.substring(1)}';
    } else if (value.startsWith('7')) {
      value = '+$value';
    } else if (!value.startsWith('+7')) {
      value = '+7${value.replaceAll('+', '')}';
    }

    if (!value.startsWith(_ruPhonePrefix)) {
      value = _ruPhonePrefix;
    }

    if (value.length > 12) value = value.substring(0, 12);

    return value;
  }

  bool _hasFullRuPhone(String raw) {
    final value = _normalizeRuPhone(raw);
    return RegExp(r'^\+7\d{10}$').hasMatch(value);
  }

  void _ensureRuPhonePrefix(TextEditingController controller) {
    if (_normalizingPhone) return;

    final normalized = _normalizeRuPhone(controller.text);
    if (controller.text == normalized) return;

    _normalizingPhone = true;
    controller.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
    _normalizingPhone = false;
  }

  void _attachPhonePrefixGuards() {
    loginPhone.addListener(() => _ensureRuPhonePrefix(loginPhone));
    regPhone.addListener(() => _ensureRuPhonePrefix(regPhone));
  }

  Future<bool> _confirmRegistrationPhone(String phone) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: const Text(
          'Проверьте номер',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Аккаунт Flowru будет привязан к номеру:\n\n$phone\n\nПроверьте, что номер введён правильно.',
          style: const TextStyle(height: 1.35, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Изменить'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Всё верно'),
          ),
        ],
      ),
    );

    return ok == true;
  }
"""

    text, count = controllers_re.subn(lambda m: controllers_new, text, count=1)
    if count != 1:
        fail("controllers block not replaced")
    print("OK: phone controllers/helpers patched")

    # 2. initState: подключаем guards
    old = """    pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: pulseController, curve: Curves.easeInOut));
    _initSavedState();
"""
    new = """    pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: pulseController, curve: Curves.easeInOut));
    _attachPhonePrefixGuards();
    _ensureRuPhonePrefix(loginPhone);
    _ensureRuPhonePrefix(regPhone);
    _initSavedState();
"""
    if old not in text:
        fail("initState anchor not found")
    text = text.replace(old, new, 1)
    print("OK: initState phone guards patched")

    # 3. _initSavedState: нормализуем сохранённый номер
    old = """      if ((savedPhone ?? '').trim().isNotEmpty)
        loginPhone.text = savedPhone!.trim();
      if ((savedPassword ?? '').isNotEmpty) loginPassword.text = savedPassword!;
"""
    new = """      if ((savedPhone ?? '').trim().isNotEmpty) {
        loginPhone.text = _normalizeRuPhone(savedPhone!.trim());
      } else {
        loginPhone.text = _ruPhonePrefix;
      }
      if (regPhone.text.trim().isEmpty) {
        regPhone.text = _ruPhonePrefix;
      }
      if ((savedPassword ?? '').isNotEmpty) loginPassword.text = savedPassword!;
"""
    if old not in text:
        fail("_initSavedState saved phone block not found")
    text = text.replace(old, new, 1)
    print("OK: saved phone normalization patched")

    # 4. submitLogin
    submit_login_new = r"""  Future<void> submitLogin() async {
    final phone = _normalizeRuPhone(loginPhone.text);

    if (!_hasFullRuPhone(phone)) {
      setState(() => error = 'Введите полный номер телефона в формате +7XXXXXXXXXX');
      return;
    }
    if (loginPassword.text.isEmpty) {
      setState(() => error = 'Введите пароль');
      return;
    }

    loginPhone.text = phone;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await api.login(phone, loginPassword.text);
      await saveAndOpen(data,
          phone: phone, password: loginPassword.text);
      TextInput.finishAutofillContext(shouldSave: true);
    } on ApiError catch (e) {
      setState(() => error = e.message);
    } catch (_) {
      setState(() => error = 'Не удалось войти');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }"""
    text = replace_function(text, "  Future<void> submitLogin() async", submit_login_new)
    print("OK: submitLogin patched")

    # 5. submitRegister
    submit_register_new = r"""  Future<void> submitRegister() async {
    final phone = _normalizeRuPhone(regPhone.text);

    if (regName.text.trim().isEmpty) {
      setState(() => error = 'Введите имя');
      return;
    }
    if (!_hasFullRuPhone(phone)) {
      setState(() => error = 'Введите полный номер телефона в формате +7XXXXXXXXXX');
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
    if (!privacyAccepted || !personalDataAccepted) {
      setState(() => error =
          'Для регистрации нужно принять Политику конфиденциальности и дать согласие на обработку персональных данных');
      return;
    }

    regPhone.text = phone;

    final confirmedPhone = await _confirmRegistrationPhone(phone);
    if (!confirmedPhone) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await api.register(
          phone: phone,
          password: regPassword.text,
          passwordConfirm: regConfirm.text,
          fullName: regName.text.trim());
      await saveAndOpen(data,
          phone: phone, password: regPassword.text);
      TextInput.finishAutofillContext(shouldSave: true);
    } on ApiError catch (e) {
      setState(() => error = e.message);
    } catch (_) {
      setState(() => error = 'Не удалось зарегистрироваться');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }"""
    text = replace_function(text, "  Future<void> submitRegister() async", submit_register_new)
    print("OK: submitRegister patched")

    # 6. Модель: menuPhotoUrls
    old = """  String? get menuPhotoUrl => _firstText([
        establishment['menu_photo_url'],
        establishment['menu_image_url'],
        home['menu_photo_url'],
      ]);
"""
    new = """  List<String> get menuPhotoUrls => _resolveMenuPhotoUrls(establishment, home);

  String? get menuPhotoUrl => menuPhotoUrls.isNotEmpty ? menuPhotoUrls.first : null;
"""
    if old not in text:
        fail("menuPhotoUrl getter not found")
    text = text.replace(old, new, 1)
    print("OK: menuPhotoUrls getter patched")

    # 7. Resolver: список картинок
    resolver_new = r"""List<String> _resolveMenuPhotoUrls(
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

  final result = <String>[];
  final seen = <String>{};

  void addText(dynamic value) {
    final cleaned = nonEmpty(value);
    if (cleaned == null) return;
    if (seen.add(cleaned)) result.add(cleaned);
  }

  void collect(dynamic value) {
    if (value == null) return;

    if (value is String) {
      addText(value);
      return;
    }

    if (value is List) {
      for (final item in value) {
        collect(item);
      }
      return;
    }

    if (value is Map) {
      final m = Map<String, dynamic>.from(value);
      collect(m['photo_url']);
      collect(m['image_url']);
      collect(m['cover_url']);
      collect(m['url']);
      collect(m['src']);
      collect(m['file_url']);
      collect(m['menu_photo_url']);
      collect(m['menu_image_url']);
      collect(m['menu_cover_url']);
      collect(m['menu_cover_urls']);
      collect(m['menu_images']);
      collect(m['images']);
      collect(m['covers']);
      return;
    }

    addText(value);
  }

  for (final source in [
    home['menu_cover_urls'],
    home['menu_images'],
    home['menu_covers'],
    home['menu_photo_url'],
    home['menu_image_url'],
    home['menu_cover_url'],
    map(home['establishment'])['menu_cover_urls'],
    map(home['establishment'])['menu_images'],
    map(home['establishment'])['menu_photo_url'],
    homeMenu,
    homeModulesMenu,
    est['menu_cover_urls'],
    est['menu_images'],
    est['menu_covers'],
    est['menu_photo_url'],
    est['menu_image_url'],
    est['menu_cover_url'],
    estMenu,
    estModulesMenu,
    profileEst,
    profileMenu,
    profileModulesMenu,
  ]) {
    collect(source);
  }

  return result;
}

String? _resolveMenuPhotoUrl(
    Map<String, dynamic> est, Map<String, dynamic> home,
    [Map<String, dynamic>? profile]) {
  final urls = _resolveMenuPhotoUrls(est, home, profile);
  return urls.isNotEmpty ? urls.first : null;
}"""
    text = replace_function(text, "String? _resolveMenuPhotoUrl", resolver_new)
    print("OK: menu resolver patched")

    # 8. Вызов меню: передаём список
    old = """      _establishmentMenu(
          name,
          _resolveMenuPhotoUrl(
              est, widget.home, map(widget.profile['profile']))),
"""
    new = """      _establishmentMenu(
          name,
          _resolveMenuPhotoUrls(
              est, widget.home, map(widget.profile['profile']))),
"""
    if old not in text:
        fail("_establishmentMenu call not found")
    text = text.replace(old, new, 1)
    print("OK: menu call patched")

    # 9. Виджет меню: карусель
    menu_widget_new = r"""  Widget _establishmentMenu(String name, List<String> menuPhotoUrls) {
    final urls = menuPhotoUrls
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _EstablishmentSectionHero(
        icon: Icons.restaurant_menu_rounded,
        title: 'Меню',
        subtitle: 'Фото меню, которое заведению загрузили в админке',
        value: urls.isNotEmpty ? '${urls.length}' : '—',
        label: 'фото',
        accent: FlowColors.gold,
      ),
      const SizedBox(height: 12),
      if (urls.isEmpty)
        const EmptyState(
          icon: Icons.restaurant_menu_rounded,
          title: 'Меню пока не загружено',
          subtitle:
              'Когда заведение добавит фото меню в админке, оно появится здесь.',
        )
      else
        SizedBox(
          height: 430,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.92),
            itemCount: urls.length,
            padEnds: true,
            itemBuilder: (context, index) {
              final url = urls[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: FlowColors.ink.withOpacity(0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                      BoxShadow(
                        color: FlowColors.gold.withOpacity(0.16),
                        blurRadius: 38,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      color: Colors.white.withOpacity(0.18),
                      child: Image.network(
                        url,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            alignment: Alignment.center,
                            color: Colors.white.withOpacity(0.24),
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(22),
                          color: Colors.white.withOpacity(0.34),
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
                ),
              );
            },
          ),
        ),
      if (urls.length > 1) ...[
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Листайте меню влево и вправо',
            style: TextStyle(
              color: FlowColors.muted.withOpacity(0.90),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ]);
  }"""
    text = replace_function(text, "  Widget _establishmentMenu", menu_widget_new)
    print("OK: menu carousel widget patched")

    # 10. Убираем меню из вкладки Инфо
    text = re.sub(
        r"\n        menuPhotoUrl:\s*_resolveMenuPhotoUrl\(\s*est,\s*widget\.home,\s*map\(widget\.profile\['profile'\]\)\),",
        "",
        text,
        count=1,
    )

    text, field_count = re.subn(r"\n  final String\? menuPhotoUrl;", "", text, count=1)
    text, ctor_count = re.subn(r"\n    required this\.menuPhotoUrl,", "", text, count=1)

    block_re = re.compile(
        r"\n          if \(\(menuPhotoUrl \?\? ''\)\.isNotEmpty\) \.\.\.\[\n"
        r".*?"
        r"\n          \] else\n"
        r"            const SizedBox\(height: 14\),",
        re.S,
    )
    text, preview_count = block_re.subn("\n          const SizedBox(height: 14),", text, count=1)

    if field_count != 1 or ctor_count != 1 or preview_count != 1:
        fail(f"info menu cleanup incomplete: field={field_count}, ctor={ctor_count}, preview={preview_count}")
    print("OK: menu removed from info tab")

    # 11. Пригласить друга: App Store + referral
    referral_new = r"""class ReferralInviteCard extends StatelessWidget {
  static const String appStoreUrl =
      'https://apps.apple.com/us/app/flowru/id6765469553';

  final String? referralLink;
  final VoidCallback onRefresh;
  const ReferralInviteCard(
      {super.key, required this.referralLink, required this.onRefresh});

  String _inviteText(String link) {
    final cleanLink = link.trim().isNotEmpty ? link.trim() : appStoreUrl;
    return 'Присоединяйся к Flowru — карты лояльности, бонусы и предложения заведений в одном приложении:\n$cleanLink\n\nСкачать Flowru Client в App Store:\n$appStoreUrl';
  }

  Future<void> _copyInvite(BuildContext context, String link) async {
    await Clipboard.setData(ClipboardData(text: _inviteText(link)));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Приглашение скопировано')),
    );
  }

  Future<void> _openAppStore(BuildContext context) async {
    await openExternalUrl(context, appStoreUrl,
        emptyMessage: 'Ссылка App Store недоступна');
  }

  @override
  Widget build(BuildContext context) {
    final link = (referralLink ?? '').trim();
    return ProfileFeatureShell(
      icon: Icons.group_add_rounded,
      assetPath: kIconInvitePremium,
      title: 'Пригласить друга',
      subtitle: 'Отправьте ссылку на Flowru Client и приглашение в заведение.',
      color: FlowColors.violet,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: FlowColors.ink.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18)),
          child: Text(
              link.isNotEmpty
                  ? 'Персональная ссылка готова. Скопируйте приглашение и отправьте другу.'
                  : 'Сначала подготовьте персональную ссылку приглашения.',
              style: const TextStyle(
                  color: FlowColors.ink,
                  fontWeight: FontWeight.w800,
                  height: 1.25)),
        ),
        const SizedBox(height: 10),
        if (link.isNotEmpty) ...[
          SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                  text: 'Скопировать приглашение',
                  icon: Icons.ios_share_rounded,
                  onTap: () => _copyInvite(context, link))),
          const SizedBox(height: 10),
          SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                  text: 'Открыть App Store',
                  icon: Icons.storefront_rounded,
                  onTap: () => _openAppStore(context))),
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
}"""
    text = replace_class(text, "ReferralInviteCard", referral_new)
    print("OK: referral invite card patched")

    text += f"\n// {marker}\n"
    path.write_text(text, encoding="utf-8")
    print("OK: Flutter client patch applied")
