from pathlib import Path

path = Path("lib/main.dart")
text = path.read_text(encoding="utf-8")

marker = "CLIENT_MENU_REFERRAL_CARD_FIX_20260521"

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
        fail(f"function not found: {signature}")
    open_pos = s.find("{", start)
    if open_pos < 0:
        fail(f"opening brace not found: {signature}")
    end = find_matching_brace(s, open_pos)
    if end < 0:
        fail(f"closing brace not found: {signature}")
    return s[:start] + replacement + s[end + 1:]

def replace_class(s, class_name, replacement):
    start = s.find(f"class {class_name}")
    if start < 0:
        fail(f"class not found: {class_name}")
    open_pos = s.find("{", start)
    if open_pos < 0:
        fail(f"opening brace not found: {class_name}")
    end = find_matching_brace(s, open_pos)
    if end < 0:
        fail(f"closing brace not found: {class_name}")
    return s[:start] + replacement + s[end + 1:]

if marker in text:
    print("SKIP: fix already installed")
else:
    menu_resolver = r'''List<String> _resolveMenuPhotoUrls(
    Map<String, dynamic> est, Map<String, dynamic> home,
    [Map<String, dynamic>? profile]) {
  final result = <String>[];
  final seen = <String>{};

  void add(dynamic value) {
    final cleaned = nonEmpty(value);
    if (cleaned == null) return;
    if (seen.add(cleaned)) result.add(cleaned);
  }

  void collect(dynamic value) {
    if (value == null) return;

    if (value is String) {
      add(value);
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
      collect(m['menu_cover_urls']);
      collect(m['menu_images']);
      collect(m['menu_covers']);
      collect(m['images']);
      collect(m['covers']);
      collect(m['photo_url']);
      collect(m['image_url']);
      collect(m['cover_url']);
      collect(m['url']);
      collect(m['src']);
      collect(m['file_url']);
      collect(m['menu_photo_url']);
      collect(m['menu_image_url']);
      collect(m['menu_cover_url']);
      return;
    }

    add(value);
  }

  // ВАЖНО:
  // Для клиентского приложения источник истины — /client/home.
  // Не берём legacy/profile-источники, иначе подтягиваются старые фото и вместо 2 получаем 3.
  final homeEstablishment = map(home['establishment']);
  final homeModules = map(home['modules']);
  final homeMenuModule = map(homeModules['menu']);

  for (final source in [
    home['menu_cover_urls'],
    home['menu_images'],
    home['menu_covers'],
    home['menu_photo_url'],
    home['menu_image_url'],
    home['menu_cover_url'],
    homeEstablishment['menu_cover_urls'],
    homeEstablishment['menu_images'],
    homeEstablishment['menu_covers'],
    homeEstablishment['menu_photo_url'],
    homeEstablishment['menu_image_url'],
    homeEstablishment['menu_cover_url'],
    homeMenuModule['menu_cover_urls'],
    homeMenuModule['menu_images'],
    homeMenuModule['menu_covers'],
    homeMenuModule['images'],
    homeMenuModule['covers'],
    homeMenuModule['menu_photo_url'],
    homeMenuModule['menu_image_url'],
    homeMenuModule['menu_cover_url'],
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
}'''

    text = replace_function(text, "List<String> _resolveMenuPhotoUrls", menu_resolver)
    print("OK: menu resolver now uses only /client/home menu fields")

    referral_card = r'''class ReferralInviteCard extends StatelessWidget {
  final String? referralLink;
  final VoidCallback onRefresh;
  const ReferralInviteCard(
      {super.key, required this.referralLink, required this.onRefresh});

  String _inviteText(String link) {
    final cleanLink = link.trim();
    return 'Присоединяйся ко мне в Flowru. По этой ссылке можно установить приложение и применить приглашение:\n$cleanLink';
  }

  Future<void> _copyInvite(BuildContext context, String link) async {
    final cleanLink = link.trim();
    if (cleanLink.isEmpty) {
      onRefresh();
      return;
    }

    await Clipboard.setData(ClipboardData(text: _inviteText(cleanLink)));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Реферальное приглашение скопировано')),
    );
  }

  Future<void> _openInvite(BuildContext context, String link) async {
    final cleanLink = link.trim();
    if (cleanLink.isEmpty) {
      onRefresh();
      return;
    }

    await openExternalUrl(context, cleanLink,
        emptyMessage: 'Ссылка приглашения недоступна');
  }

  @override
  Widget build(BuildContext context) {
    final link = (referralLink ?? '').trim();

    return ProfileFeatureShell(
      icon: Icons.group_add_rounded,
      assetPath: kIconInvitePremium,
      title: 'Пригласить друга',
      subtitle: 'Отправьте персональную реферальную ссылку.',
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
                  ? 'Персональная ссылка готова. Через неё друг установит Flowru и приглашение применится в приложении.'
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
                  text: 'Открыть приглашение',
                  icon: Icons.open_in_new_rounded,
                  onTap: () => _openInvite(context, link))),
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
}'''

    text = replace_class(text, "ReferralInviteCard", referral_card)
    print("OK: referral card now opens/copies referral landing link, not direct App Store")

    text += f"\n// {marker}\n"
    path.write_text(text, encoding="utf-8")
    print("OK: menu/referral card fix applied")
