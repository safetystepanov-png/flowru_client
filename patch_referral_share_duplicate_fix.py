from pathlib import Path

path = Path("lib/main.dart")
text = path.read_text(encoding="utf-8")

marker = "CLIENT_REFERRAL_SHARE_AND_DUPLICATE_FIX_20260521"

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
        fail(f"opening brace not found: {class_name}")
    end = find_matching_brace(s, open_pos)
    if end < 0:
        fail(f"closing brace not found: {class_name}")
    return s[:start] + replacement + s[end + 1:]

def remove_duplicate_functions(s, signature):
    positions = []
    start = 0

    while True:
        pos = s.find(signature, start)
        if pos < 0:
            break
        positions.append(pos)
        start = pos + 1

    print(f"{signature} FOUND:", len(positions))

    if len(positions) <= 1:
        return s

    # Оставляем первую функцию, остальные удаляем.
    for pos in reversed(positions[1:]):
        open_pos = s.find("{", pos)
        if open_pos < 0:
            fail(f"opening brace not found for duplicate {signature}")

        end = find_matching_brace(s, open_pos)
        if end < 0:
            fail(f"closing brace not found for duplicate {signature}")

        remove_end = end + 1
        while remove_end < len(s) and s[remove_end] in "\r\n":
            remove_end += 1

        s = s[:pos] + s[remove_end:]
        print("REMOVED duplicate:", signature, "at", pos)

    return s

if marker in text:
    print("SKIP: already installed")
else:
    # 1. Подключаем share_plus.
    if "package:share_plus/share_plus.dart" not in text:
        import_anchor = "import 'package:url_launcher/url_launcher.dart';"
        if import_anchor in text:
            text = text.replace(
                import_anchor,
                import_anchor + "\nimport 'package:share_plus/share_plus.dart';",
                1,
            )
        else:
            text = "import 'package:share_plus/share_plus.dart';\n" + text
        print("OK: share_plus import added")
    else:
        print("OK: share_plus import already exists")

    # 2. Убираем дубль _resolveMenuPhotoUrl.
    text = remove_duplicate_functions(text, "String? _resolveMenuPhotoUrl(")

    # 3. Заменяем карточку приглашения на одну кнопку «Поделиться».
    referral_card = r'''class ReferralInviteCard extends StatelessWidget {
  final String? referralLink;
  final VoidCallback onRefresh;

  const ReferralInviteCard(
      {super.key, required this.referralLink, required this.onRefresh});

  String _inviteText(String link) {
    return 'Привет! Я приглашаю тебя в Flowru.\n\n'
        'Открой ссылку, установи приложение и прими приглашение:\n$link';
  }

  Future<void> _shareInvite(BuildContext context, String link) async {
    final cleanLink = link.trim();

    if (cleanLink.isEmpty) {
      onRefresh();
      return;
    }

    final text = _inviteText(cleanLink);

    try {
      await Share.share(text);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ссылка скопирована. Отправьте её другу.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = (referralLink ?? '').trim();

    return ProfileFeatureShell(
      icon: Icons.group_add_rounded,
      assetPath: kIconInvitePremium,
      title: 'Пригласить друга',
      subtitle: 'Отправьте персональную реферальную ссылку другу.',
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
                  ? 'Персональная ссылка готова. Друг откроет её, установит Flowru и приглашение применится в приложении.'
                  : 'Сначала подготовьте персональную ссылку приглашения.',
              style: const TextStyle(
                  color: FlowColors.ink,
                  fontWeight: FontWeight.w800,
                  height: 1.25)),
        ),
        const SizedBox(height: 10),
        SizedBox(
            width: double.infinity,
            child: PrimaryButton(
                text: link.isNotEmpty
                    ? 'Поделиться приглашением'
                    : 'Подготовить приглашение',
                icon: link.isNotEmpty
                    ? Icons.ios_share_rounded
                    : Icons.refresh_rounded,
                onTap: link.isNotEmpty
                    ? () => _shareInvite(context, link)
                    : onRefresh)),
      ]),
    );
  }
}'''

    text = replace_class(text, "ReferralInviteCard", referral_card)
    print("OK: ReferralInviteCard changed to share-only")

    text += f"\n// {marker}\n"
    path.write_text(text, encoding="utf-8")
    print("OK: duplicate + share referral fix applied")
