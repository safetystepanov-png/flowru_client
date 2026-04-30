from pathlib import Path
import re

path = Path("lib/main.dart")
s = path.read_text(encoding="utf-8")

def insert_once(source, marker, block, label, before=True):
    if block.strip() in source:
        print(f"SKIP: {label} already exists")
        return source
    if marker not in source:
        raise SystemExit(f"ERROR: marker not found for {label}: {marker}")
    if before:
        return source.replace(marker, block + marker, 1)
    return source.replace(marker, marker + block, 1)

# 1. API METHOD
api_method = r'''
  Future<Map<String, dynamic>> establishmentProfile(String token, int establishmentId) {
    return _request(
      path: '/client/establishment-profile',
      token: token,
      query: {'establishment_id': '$establishmentId'},
    );
  }

'''

if "Future<Map<String, dynamic>> establishmentProfile(" not in s:
    if "  Future<Map<String, dynamic>> rewards(" in s:
        s = s.replace("  Future<Map<String, dynamic>> rewards(", api_method + "  Future<Map<String, dynamic>> rewards(", 1)
    elif "  Future<Map<String, dynamic>> offers(" in s:
        end_marker = re.search(r"  Future<Map<String, dynamic>> offers\([\\s\\S]*?\\n  \\}\\n", s)
        if not end_marker:
            raise SystemExit("ERROR: cannot find offers method end")
        s = s[:end_marker.end()] + api_method + s[end_marker.end():]
    else:
        raise SystemExit("ERROR: cannot find place for establishmentProfile API method")
    print("OK: API method added")
else:
    print("SKIP: API method already exists")

# 2. STATE FIELD
if "Map<String, dynamic> establishmentProfile = {};" not in s:
    if "  Map<String, dynamic> offers = {};" in s:
        s = s.replace(
            "  Map<String, dynamic> offers = {};",
            "  Map<String, dynamic> offers = {};\n  Map<String, dynamic> establishmentProfile = {};",
            1,
        )
    elif "  Map<String, dynamic> home = {};" in s:
        s = s.replace(
            "  Map<String, dynamic> home = {};",
            "  Map<String, dynamic> home = {};\n  Map<String, dynamic> establishmentProfile = {};",
            1,
        )
    else:
        raise SystemExit("ERROR: cannot find state maps")
    print("OK: establishmentProfile state added")
else:
    print("SKIP: establishmentProfile state already exists")

# 3. LOAD PROFILE IN loadAll
if "var prof = <String, dynamic>{};" not in s:
    if "      var off = <String, dynamic>{};" in s:
        s = s.replace(
            "      var off = <String, dynamic>{};",
            "      var off = <String, dynamic>{};\n      var prof = <String, dynamic>{};",
            1,
        )
    elif "      var hist = <Map<String, dynamic>>[];" in s:
        s = s.replace(
            "      var hist = <Map<String, dynamic>>[];",
            "      var hist = <Map<String, dynamic>>[];\n      var prof = <String, dynamic>{};",
            1,
        )
    else:
        raise SystemExit("ERROR: cannot add prof variable in loadAll")
    print("OK: prof variable added in loadAll")
else:
    print("SKIP: prof variable already exists")

profile_fetch = r'''
        try {
          prof = await api.establishmentProfile(token, estId);
        } catch (_) {
          prof = {};
        }
'''

if "prof = await api.establishmentProfile(token, estId);" not in s:
    if """        try {
          off = await api.offers(token, estId);
        } catch (_) {
          off = {};
        }
""" in s:
        s = s.replace(
            """        try {
          off = await api.offers(token, estId);
        } catch (_) {
          off = {};
        }
""",
            """        try {
          off = await api.offers(token, estId);
        } catch (_) {
          off = {};
        }
""" + profile_fetch,
            1,
        )
    elif "        hist = visibleClientHistory(mapList(res['items']));" in s:
        s = s.replace(
            "        hist = visibleClientHistory(mapList(res['items']));",
            "        hist = visibleClientHistory(mapList(res['items']));" + profile_fetch,
            1,
        )
    elif "        hist = mapList(res['items']);" in s:
        s = s.replace(
            "        hist = mapList(res['items']);",
            "        hist = mapList(res['items']);" + profile_fetch,
            1,
        )
    else:
        raise SystemExit("ERROR: cannot find loadAll profile fetch place")
    print("OK: profile fetch added in loadAll")
else:
    print("SKIP: profile fetch already exists")

if "        establishmentProfile = prof;" not in s:
    if "        offers = off;" in s:
        s = s.replace(
            "        offers = off;",
            "        offers = off;\n        establishmentProfile = prof;",
            1,
        )
    elif "        home = h;" in s:
        s = s.replace(
            "        home = h;",
            "        home = h;\n        establishmentProfile = prof;",
            1,
        )
    else:
        raise SystemExit("ERROR: cannot set establishmentProfile in loadAll")
    print("OK: establishmentProfile set in loadAll")
else:
    print("SKIP: establishmentProfile set already exists")

# 4. LOAD PROFILE IN selectEst, if selectEst does full reload
if "final prof = await api.establishmentProfile(token, id);" not in s and "Future<void> selectEst" in s:
    select_match = re.search(r"Future<void> selectEst\\([\\s\\S]*?\\n  \\}\\n\\n  Future<void> logout", s)
    if select_match:
        block = select_match.group(0)
        if "final h = await api.home(token, establishmentId: id);" in block:
            new_block = block
            if "Map<String, dynamic> prof = {};" not in new_block:
                new_block = new_block.replace(
                    "      Map<String, dynamic> off = {};",
                    "      Map<String, dynamic> off = {};\n      Map<String, dynamic> prof = {};",
                    1,
                ) if "      Map<String, dynamic> off = {};" in new_block else new_block.replace(
                    "      final res = await api.history(token, id);",
                    "      final res = await api.history(token, id);\n      Map<String, dynamic> prof = {};",
                    1,
                )
            if "prof = await api.establishmentProfile(token, id);" not in new_block:
                new_block = new_block.replace(
                    "      if (!mounted) return;",
                    """      try {
        prof = await api.establishmentProfile(token, id);
      } catch (_) {
        prof = {};
      }

      if (!mounted) return;""",
                    1,
                )
            if "establishmentProfile = prof;" not in new_block:
                new_block = new_block.replace(
                    "        home = h;",
                    "        home = h;\n        establishmentProfile = prof;",
                    1,
                )
            s = s[:select_match.start()] + new_block + s[select_match.end():]
            print("OK: profile fetch added in selectEst")
        else:
            print("SKIP: selectEst does not full reload, loadAll will handle profile")
    else:
        print("SKIP: selectEst block not found")
else:
    print("SKIP: selectEst profile fetch already exists or no selectEst")

# 5. GETTERS
getters = r'''
  Map<String, dynamic> get liveProfile => map(establishmentProfile['profile']);
  Map<String, dynamic> get liveProfileEstablishment => map(liveProfile['establishment']);
  Map<String, dynamic> get liveContacts => map(liveProfile['contacts']);
  Map<String, dynamic> get liveRatings => map(liveProfile['ratings']);
  Map<String, dynamic> get liveModules => map(liveProfile['modules']);
  Map<String, dynamic> get liveLoyaltyRules => map(liveModules['loyalty']);
  String get liveAddress => nonEmpty(liveContacts['address']) ?? '';
  String get liveWorkingHours => nonEmpty(liveContacts['working_hours']) ?? '';
  String get livePhone => nonEmpty(liveContacts['phone']) ?? '';
'''

if "Map<String, dynamic> get liveProfile =>" not in s:
    if "  Map<String, dynamic> get offerData =>" in s:
        line = re.search(r"  Map<String, dynamic> get offerData =>.*\\n", s)
        if not line:
            raise SystemExit("ERROR: offerData getter line not found")
        s = s[:line.end()] + getters + s[line.end():]
    elif "  Map<String, dynamic> get card =>" in s:
        line = re.search(r"  Map<String, dynamic> get card =>.*\\n", s)
        if not line:
            raise SystemExit("ERROR: card getter line not found")
        s = s[:line.end()] + getters + s[line.end():]
    else:
        raise SystemExit("ERROR: cannot insert live profile getters")
    print("OK: live profile getters added")
else:
    print("SKIP: live profile getters already exist")

# 6. INSERT UI IN profileTab
profile_ui = r'''
          EstablishmentLiveInfoCard(
            establishmentName: establishmentName,
            address: liveAddress,
            phone: livePhone,
            workingHours: liveWorkingHours,
            ratings: liveRatings,
            contacts: liveContacts,
          ),
          const SizedBox(height: 16),
          LoyaltyLiveRulesCard(
            rules: liveLoyaltyRules,
            currentPoints: points,
            salesTotal: sales,
          ),
          const SizedBox(height: 16),
'''

if "EstablishmentLiveInfoCard(" not in s:
    variants = [
        "          ProfileCommandCard(name: clientName, phone: phone),\n          const SizedBox(height: 16),\n",
        "          ProfileCard(name: clientName, phone: phone, source: home['source']?.toString() ?? 'core'),\n          const SizedBox(height: 16),\n",
    ]
    replaced = False
    for v in variants:
        if v in s:
            s = s.replace(v, v + profile_ui, 1)
            replaced = True
            break
    if not replaced:
        raise SystemExit("ERROR: cannot find profile card place for live info cards")
    print("OK: live profile cards inserted into profileTab")
else:
    print("SKIP: live profile cards already inserted")

# 7. WIDGETS
widgets = r'''

class EstablishmentLiveInfoCard extends StatelessWidget {
  final String establishmentName;
  final String address;
  final String phone;
  final String workingHours;
  final Map<String, dynamic> ratings;
  final Map<String, dynamic> contacts;

  const EstablishmentLiveInfoCard({
    super.key,
    required this.establishmentName,
    required this.address,
    required this.phone,
    required this.workingHours,
    required this.ratings,
    required this.contacts,
  });

  @override
  Widget build(BuildContext context) {
    final yandex = map(ratings['yandex']);
    final twoGis = map(ratings['two_gis']);
    final social = map(contacts['social_media']);

    final yandexRating = toDouble(yandex['rating']);
    final twoGisRating = toDouble(twoGis['rating']);

    return SoftCard(
      padding: const EdgeInsets.all(18),
      radius: 30,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle(title: 'Заведение', subtitle: 'Данные из базы: контакты, график и рейтинги'),
        const SizedBox(height: 14),
        _LiveInfoRow(icon: Icons.storefront_rounded, title: 'Название', value: establishmentName),
        if (address.isNotEmpty) _LiveInfoRow(icon: Icons.place_rounded, title: 'Адрес', value: address),
        if (workingHours.isNotEmpty) _LiveInfoRow(icon: Icons.schedule_rounded, title: 'График', value: workingHours),
        if (phone.isNotEmpty) _LiveInfoRow(icon: Icons.phone_rounded, title: 'Телефон', value: phone),
        if (yandexRating > 0 || twoGisRating > 0) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (yandexRating > 0) _LiveChip(icon: Icons.star_rounded, text: 'Яндекс ${formatRating(yandexRating)}'),
            if (twoGisRating > 0) _LiveChip(icon: Icons.star_half_rounded, text: '2ГИС ${formatRating(twoGisRating)}'),
          ]),
        ],
        if (social.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Соцсети', style: TextStyle(color: FlowColors.text, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: social.entries
                .where((e) => nonEmpty(e.value) != null)
                .map((e) => _LiveChip(icon: Icons.link_rounded, text: e.key.toString()))
                .toList(),
          ),
        ],
      ]),
    );
  }
}

class LoyaltyLiveRulesCard extends StatelessWidget {
  final Map<String, dynamic> rules;
  final int currentPoints;
  final double salesTotal;

  const LoyaltyLiveRulesCard({
    super.key,
    required this.rules,
    required this.currentPoints,
    required this.salesTotal,
  });

  @override
  Widget build(BuildContext context) {
    final mode = nonEmpty(rules['mode']) ?? 'loyalty';
    final cashback = toDouble(rules['cashback_percent']);
    final maxRedeem = toDouble(rules['max_redeem_percent']);
    final redeemRate = toDouble(rules['redeem_rate']);
    final levels = mapList(rules['cashback_levels']);
    final expiration = map(rules['points_expiration']);
    final referral = map(rules['client_referral']);
    final birthday = map(rules['birthday_campaign']);

    return SoftCard(
      padding: const EdgeInsets.all(18),
      radius: 30,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle(title: 'Правила лояльности', subtitle: 'То, что реально настроено в БД'),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _LiveChip(icon: Icons.local_fire_department_rounded, text: mode == 'cashback' ? 'Кэшбэк' : mode),
          if (cashback > 0) _LiveChip(icon: Icons.percent_rounded, text: '${formatRating(cashback)}% кэшбэк'),
          if (maxRedeem > 0) _LiveChip(icon: Icons.payments_rounded, text: 'Списание до ${formatRating(maxRedeem)}%'),
          if (redeemRate > 0) _LiveChip(icon: Icons.currency_ruble_rounded, text: '1 балл = ${formatRating(redeemRate)} ₽'),
        ]),
        const SizedBox(height: 14),
        _LiveInfoRow(icon: Icons.stars_rounded, title: 'Ваши баллы', value: '${formatMoney(currentPoints)} б.'),
        _LiveInfoRow(icon: Icons.receipt_long_rounded, title: 'Покупки', value: '${formatMoney(salesTotal)} ₽'),
        if (expiration['enabled'] == true) _LiveInfoRow(icon: Icons.hourglass_bottom_rounded, title: 'Срок жизни баллов', value: '${expiration['lifetime_days']} дней'),
        if (referral['enabled'] == true) _LiveInfoRow(icon: Icons.group_add_rounded, title: 'Реферальная программа', value: '+${referral['inviter_points']} / +${referral['invited_points']} баллов'),
        if (birthday['show_birthdate_block'] == true || birthday['enabled'] == true) _LiveInfoRow(icon: Icons.cake_rounded, title: 'День рождения', value: '${birthday['gift_points'] ?? 0} бонусных баллов'),
        if (levels.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Уровни гостей', style: TextStyle(color: FlowColors.text, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...levels.map((level) {
            final name = nonEmpty(level['name']) ?? 'Уровень';
            final spent = toDouble(level['spent_required']);
            final percent = toDouble(level['cashback_percent']);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FlowColors.stroke),
              ),
              child: Row(children: [
                Expanded(child: Text(name, style: const TextStyle(color: FlowColors.text, fontWeight: FontWeight.w900))),
                Text('${formatMoney(spent)} ₽ · ${formatRating(percent)}%', style: const TextStyle(color: FlowColors.muted, fontWeight: FontWeight.w800)),
              ]),
            );
          }),
        ],
      ]),
    );
  }
}

class _LiveInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _LiveInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

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
            color: FlowColors.dark.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: FlowColors.dark, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: FlowColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: FlowColors.text, fontSize: 15, fontWeight: FontWeight.w900, height: 1.25)),
        ])),
      ]),
    );
  }
}

class _LiveChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _LiveChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FlowColors.dark.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FlowColors.stroke),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: FlowColors.dark),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: FlowColors.text, fontSize: 12, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

String formatRating(dynamic value) {
  final n = toDouble(value);
  if ((n - n.round()).abs() < 0.000001) return n.round().toString();
  return n.toStringAsFixed(1);
}

'''

if "class EstablishmentLiveInfoCard extends StatelessWidget" not in s:
    if "class ThemeFoundationCard extends StatelessWidget" in s:
        s = s.replace("class ThemeFoundationCard extends StatelessWidget", widgets + "\nclass ThemeFoundationCard extends StatelessWidget", 1)
    elif "class DangerButton extends StatelessWidget" in s:
        s = s.replace("class DangerButton extends StatelessWidget", widgets + "\nclass DangerButton extends StatelessWidget", 1)
    else:
        raise SystemExit("ERROR: cannot find widget insert place")
    print("OK: live profile widgets added")
else:
    print("SKIP: live profile widgets already exist")

path.write_text(s, encoding="utf-8")
print("DONE")
