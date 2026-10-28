import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'main.dart' show AuthStorage, FlowApi;

const _navy = Color(0xFF14243C);
const _mint = Color(0xFFB9F5E4);
const _lilac = Color(0xFFD6C5FF);
const _paper = Color(0xFFF5F8FB);
const _muted = Color(0xFF748299);
const _asset = 'assets/flowru_raffle/prize_orbit.png';
String _text(Map<String, dynamic> d, String k, [String fallback = '']) {
  final v = '${d[k] ?? ''}'.trim();
  return v.isEmpty ? fallback : v;
}
bool _ended(Map<String, dynamic> d) => const [
  'drawn', 'finished', 'completed', 'closed', 'cancelled', 'canceled'
].contains(_text(d, 'status'));
bool _cancelled(Map<String, dynamic> d) => const ['cancelled', 'canceled'].contains(_text(d, 'status'));
String _host(Map<String, dynamic> d) => _text(d, 'establishment_name', 'Ваше заведение');
String _date(dynamic raw) {
  final v = DateTime.tryParse('$raw')?.toLocal();
  if (v == null) return 'Дата уточняется';
  const months = ['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];
  return '${v.day} ${months[v.month - 1]} · ${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';
}
bool _awaiting(Map<String, dynamic> d) {
  final time = DateTime.tryParse(_text(d, 'draw_at'));
  return !_ended(d) && time != null && !time.isAfter(DateTime.now());
}
String _shortRemaining(dynamic raw) {
  final target = DateTime.tryParse('$raw');
  if (target == null) return 'Итоги в приложении';
  final diff = target.difference(DateTime.now());
  if (diff.isNegative || diff.inSeconds == 0) return 'Подводим итоги';
  if (diff.inDays > 0) return 'Через ${diff.inDays} д ${diff.inHours % 24} ч';
  if (diff.inHours > 0) return 'Через ${diff.inHours} ч ${diff.inMinutes % 60} мин';
  return 'Через ${diff.inMinutes.toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// A crystal render plus procedural orbit lines; the asset retains its real alpha.
class _OrbitPainter extends CustomPainter {
  final double phase;
  final bool celebration;
  _OrbitPainter(this.phase, {this.celebration = false});
  @override void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .52);
    final w = size.width * .82;
    canvas.save(); canvas.translate(center.dx, center.dy); canvas.rotate(-.25);
    for (var i = 0; i < 3; i++) {
      final rect = Rect.fromCenter(center: Offset.zero, width: w + i * 24, height: w * .45 + i * 20);
      canvas.drawOval(rect, Paint()..color = Colors.white.withOpacity(.07 + i * .015)..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    canvas.restore();
    for (var i = 0; i < (celebration ? 23 : 9); i++) {
      final a = i * 2.399 + phase * (i.isEven ? .17 : -.11);
      final radius = size.width * (.26 + (i % 4) * .055);
      final point = center + Offset(math.cos(a) * radius, math.sin(a) * radius * .85);
      final paint = Paint()..color = (i.isEven ? _mint : _lilac).withOpacity(.3 + .4 * (.5 + .5 * math.sin(phase + i)));
      canvas.save(); canvas.translate(point.dx, point.dy); canvas.rotate(a + phase * .08);
      if (celebration && i % 3 == 0) {
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -4, 4, 8), const Radius.circular(1)), paint);
      } else {
        canvas.drawCircle(Offset.zero, i % 3 == 0 ? 2.2 : 1.1, paint);
      }
      canvas.restore();
    }
  }
  @override bool shouldRepaint(covariant _OrbitPainter old) => old.phase != phase || old.celebration != celebration;
}

class _OrbitArt extends StatefulWidget {
  final bool celebration;
  final double height;
  const _OrbitArt({this.celebration = false, this.height = 260});
  @override State<_OrbitArt> createState() => _OrbitArtState();
}
class _OrbitArtState extends State<_OrbitArt> with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this, duration: const Duration(seconds: 9));
  @override void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) { _motion.stop(); } else { _motion.repeat(); }
  }
  @override void dispose() { _motion.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => RepaintBoundary(child: SizedBox(height: widget.height, child: AnimatedBuilder(
    animation: _motion,
    child: Image.asset(_asset, fit: BoxFit.contain, excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome_rounded, color: _mint, size: 100)),
    builder: (context, child) {
      final phase = _motion.value * math.pi * 2;
      return Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(colors: [
          (widget.celebration ? const Color(0xFFB59AD9) : const Color(0xFF74D8CD)).withOpacity(.20), Colors.transparent,
        ], radius: .65)))),
        Positioned.fill(child: CustomPaint(painter: _OrbitPainter(phase, celebration: widget.celebration))),
        Transform.translate(offset: Offset(0, math.sin(phase) * 5), child: Transform.rotate(angle: math.sin(phase) * .018, child: child)),
      ]);
    },
  )));
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool dark;
  const _Badge(this.label, this.icon, {this.dark = true});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: dark ? Colors.white.withOpacity(.09) : _mint.withOpacity(.6), borderRadius: BorderRadius.circular(30), border: Border.all(color: dark ? Colors.white.withOpacity(.12) : const Color(0xFFC0E7DD))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: dark ? _mint : _navy), const SizedBox(width: 5), Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? Colors.white : _navy, fontSize: 10, fontWeight: FontWeight.w800)))]),
  );
}

class _LiveCaption extends StatefulWidget {
  final dynamic date;
  final TextStyle style;
  const _LiveCaption({required this.date, required this.style});
  @override State<_LiveCaption> createState() => _LiveCaptionState();
}
class _LiveCaptionState extends State<_LiveCaption> {
  Timer? _timer;
  @override void initState() { super.initState(); _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); }); }
  @override void dispose() { _timer?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) => Text(_shortRemaining(widget.date), maxLines: 1, overflow: TextOverflow.ellipsis, style: widget.style);
}

class AppRaffleCard extends StatelessWidget {
  final Map<String, dynamic> draw;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool compact;
  const AppRaffleCard({super.key, required this.draw, required this.onTap, this.imageUrl, this.compact = false});
  @override Widget build(BuildContext context) {
    final ended = _ended(draw);
    final won = draw['is_winner'] == true;
    final joined = draw['is_joined'] == true;
    return Semantics(button: true, label: 'Розыгрыш от ${_host(draw)}. ${ended ? 'Итоги подведены' : _date(draw['draw_at'])}', child: Container(
      height: compact ? null : 292,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Color(0x30212B54), blurRadius: 25, offset: Offset(0, 12))]),
      child: Material(color: _navy, borderRadius: BorderRadius.circular(30), clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Stack(children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF223753), won ? const Color(0xFF443765) : const Color(0xFF17263E), const Color(0xFF25394F)])))),
        Positioned(right: compact ? -16 : -4, top: compact ? 61 : 43, width: compact ? 178 : 230, child: IgnorePointer(child: _OrbitArt(height: compact ? 174 : 230, celebration: won))),
        Padding(padding: EdgeInsets.all(compact ? 18 : 23), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 24, height: 24, alignment: Alignment.center, decoration: BoxDecoration(color: _mint.withOpacity(.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.storefront_rounded, color: _mint, size: 14)), const SizedBox(width: 8), Expanded(child: Text(_host(draw), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)))]),
          const SizedBox(height: 17),
          Text(won ? 'Ваша победа' : 'Розыгрыш', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: won ? _mint : Colors.white, fontSize: compact ? 27 : 34, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -1)),
          const SizedBox(height: 9),
          if (ended || joined) Align(alignment: Alignment.centerLeft, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 150), child: _Badge(won ? 'Поздравляем!' : ended ? 'Итоги подведены' : 'Вы участвуете', won ? Icons.auto_awesome_rounded : ended ? Icons.flag_rounded : Icons.check_rounded))),
          const Spacer(),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ended ? 'ИТОГИ' : 'ДО РЕЗУЛЬТАТОВ', style: const TextStyle(color: Color(0xFF9FADC3), fontSize: 8, letterSpacing: 1.1, fontWeight: FontWeight.w800)), const SizedBox(height: 5),
            if (ended) Text(_date(draw['draw_at']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))
            else _LiveCaption(date: draw['draw_at'], style: const TextStyle(color: _mint, fontSize: 12, fontWeight: FontWeight.w800)),
          ])), const SizedBox(width: 8), Container(width: 36, height: 36, decoration: const BoxDecoration(color: _mint, shape: BoxShape.circle), child: const Icon(Icons.north_east_rounded, color: _navy, size: 19))]),
        ])),
      ])))),
    );
  }
}

class _PrizeCover extends StatelessWidget {
  final String url;
  const _PrizeCover(this.url);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16), child: ClipRRect(borderRadius: BorderRadius.circular(22), child: AspectRatio(aspectRatio: 1.7, child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()))));
}

class _InfoTile extends StatelessWidget {
  final String heading, value;
  final IconData icon;
  const _InfoTile(this.heading, this.value, this.icon);
  @override Widget build(BuildContext context) => Expanded(child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5EBF1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xFF8E78B4), size: 19), const SizedBox(height: 10), Text(heading, style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w600)), const SizedBox(height: 5), Text(value, style: const TextStyle(color: _navy, fontSize: 13, height: 1.35, fontWeight: FontWeight.w800))])));
}

class _PrimaryAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool busy;
  const _PrimaryAction({required this.label, required this.icon, this.onTap, this.busy = false});
  @override Widget build(BuildContext context) => Semantics(button: true, enabled: onTap != null, child: Container(
    decoration: BoxDecoration(gradient: LinearGradient(colors: onTap == null ? const [Color(0xFFE8EDF3), Color(0xFFE8EDF3)] : const [_mint, Color(0xFFC2E7EF), _lilac]), borderRadius: BorderRadius.circular(22), boxShadow: onTap == null ? [] : const [BoxShadow(color: Color(0x2867B8A5), blurRadius: 22, offset: Offset(0, 8))]),
    child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(22), onTap: busy ? null : onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (busy) const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: _navy)) else Icon(icon, color: onTap == null ? _muted : _navy, size: 20),
      const SizedBox(width: 10), Flexible(child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: onTap == null ? _muted : _navy, fontSize: 15, fontWeight: FontWeight.w900))),
    ])))),
  ));
}

class _RaffleDetailsView extends StatelessWidget {
  final Map<String, dynamic> draw;
  final bool joining;
  final VoidCallback? onJoin;
  final String? imageUrl, error;
  final VoidCallback onRetry;
  const _RaffleDetailsView({required this.draw, required this.joining, required this.onRetry, this.onJoin, this.imageUrl, this.error});

  void _showQr(BuildContext context) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (sheet) => _PrizePass(draw: draw));
  }
  @override Widget build(BuildContext context) {
    final ended = _ended(draw), won = draw['is_winner'] == true, joined = draw['is_joined'] == true;
    final pending = _awaiting(draw), cancelled = _cancelled(draw);
    final state = _text(draw, 'prize_state');
    final qr = _text(draw, 'prize_qr');
    final canQr = won && state == 'available' && qr.isNotEmpty;
    final prize = _text(draw, 'prize_text', _text(draw, 'description', 'Подарок от заведения'));
    final rules = _text(draw, 'post_text', _text(draw, 'full_text', _text(draw, 'rules', 'Нажмите кнопку участия. Результат появится здесь и в уведомлениях.')));
    final winner = _text(draw, 'winner_user_name');
    final canJoin = !joining && !joined && !ended && !pending && onJoin != null;
    final label = canQr ? 'Показать QR приза' : won && state == 'redeemed' ? 'Приз уже получен' : won && state == 'expired' ? 'Срок получения истёк' : cancelled ? 'Розыгрыш отменён' : ended ? 'Розыгрыш завершён' : pending ? 'Подводим итоги' : joined ? 'Вы участвуете' : joining ? 'Добавляем вас…' : 'Участвовать';
    final reduce = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(tween: Tween(begin: reduce ? 1.0 : 0.0, end: 1.0), duration: Duration(milliseconds: reduce ? 0 : 480), curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child)),
      child: SizedBox(height: MediaQuery.sizeOf(context).height * .91, child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(34)), child: Material(color: _paper, child: SafeArea(top: false, child: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF203650), won ? const Color(0xFF46345E) : const Color(0xFF18253F), const Color(0xFF284153)])), child: Column(children: [
            const SizedBox(height: 9), Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(.22), borderRadius: BorderRadius.circular(10))),
            Padding(padding: const EdgeInsets.fromLTRB(22, 9, 10, 0), child: Row(children: [Expanded(child: Text(_host(draw), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))), IconButton(tooltip: 'Закрыть', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white, size: 23))])),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
              _Badge(won ? 'ЭТО ВАША ПОБЕДА' : cancelled ? 'ОТМЕНЁН' : ended ? 'РЕЗУЛЬТАТЫ' : joined ? 'ВЫ В ИГРЕ' : 'ПОДАРКИ ОТ ЛЮБИМЫХ МЕСТ', won ? Icons.auto_awesome_rounded : ended ? Icons.flag_rounded : Icons.favorite_border_rounded),
              const SizedBox(height: 16),
              Text(won ? 'Поздравляем!' : cancelled ? 'Розыгрыш\nотменён' : ended ? 'Итоги\nрозыгрыша' : 'Ваш следующий\nприятный сюрприз', textAlign: TextAlign.center, style: TextStyle(color: won ? _mint : Colors.white, fontSize: won ? 38 : 34, height: 1.04, letterSpacing: -1.25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(won ? 'Этот приз — ваш. Заберите его в заведении.' : ended ? winner.isEmpty ? 'Розыгрыш завершён без победителя' : 'Спасибо, что были с нами' : joined ? 'Вы участвуете. Результат сообщим в приложении.' : 'Один шаг — и вы участвуете в розыгрыше.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 12, height: 1.45)),
            ])),
            _OrbitArt(height: won ? 236 : 216, celebration: won),
            if (!ended) Padding(padding: const EdgeInsets.only(bottom: 22), child: _LiveCaption(date: draw['draw_at'], style: const TextStyle(color: _mint, fontSize: 16, fontWeight: FontWeight.w900))),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: Container(padding: const EdgeInsets.all(21), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFFE0E9ED)), boxShadow: const [BoxShadow(color: Color(0x0B324B65), blurRadius: 24, offset: Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (imageUrl != null && imageUrl!.isNotEmpty) _PrizeCover(imageUrl!),
            Row(children: [const Icon(Icons.card_giftcard_rounded, color: Color(0xFF9275BA), size: 17), const SizedBox(width: 7), Text(won ? 'ВАШ ПРИЗ' : 'НА КОНУ', style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2))]),
            const SizedBox(height: 10), Text(prize, style: const TextStyle(color: _navy, fontSize: 27, height: 1.15, letterSpacing: -.6, fontWeight: FontWeight.w900)),
            if (_text(draw, 'title').isNotEmpty && _text(draw, 'title') != prize) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_text(draw, 'title'), style: const TextStyle(color: _muted, fontSize: 13, height: 1.5))),
          ]))),
          if (ended && winner.isNotEmpty && !won) Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEAE3FB), Color(0xFFE1F5EC)]), borderRadius: BorderRadius.circular(24)), child: Row(children: [Container(width: 46, height: 46, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF9777B9))), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Победитель', style: TextStyle(color: _muted, fontSize: 11)), const SizedBox(height: 4), Text(winner, style: const TextStyle(color: _navy, fontSize: 21, fontWeight: FontWeight.w900))]))]))),
          if (won) Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFE4F5EF), borderRadius: BorderRadius.circular(24)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(state == 'redeemed' ? Icons.verified_rounded : state == 'expired' ? Icons.schedule_rounded : Icons.qr_code_2_rounded, color: const Color(0xFF378471), size: 27), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(state == 'redeemed' ? 'Приятно дарить радость' : state == 'expired' ? 'Срок получения истёк' : 'Ваш пропуск к подарку', style: const TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(state == 'redeemed' ? 'Приз уже выдан. До встречи в новых розыгрышах!' : state == 'expired' ? 'Для уточнения обратитесь в заведение.' : 'Откройте QR и покажите сотруднику. Он подтвердит выдачу.', style: const TextStyle(color: Color(0xFF567C73), fontSize: 12, height: 1.5)), if (_text(draw, 'prize_expires_at').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('До ${_date(draw['prize_expires_at'])}', style: const TextStyle(color: Color(0xFF378471), fontSize: 12, fontWeight: FontWeight.w800)))]))]))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [_InfoTile('Подведение итогов', _date(draw['draw_at']), Icons.event_available_rounded), const SizedBox(width: 10), _InfoTile('Участников', '${draw['participants_count'] ?? 0}', Icons.people_outline_rounded)])),
          Padding(padding: const EdgeInsets.all(20), child: Material(color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFE5EBF1))), clipBehavior: Clip.antiAlias, child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3), childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18), iconColor: _muted, collapsedIconColor: _muted, title: const Text('Условия участия', style: TextStyle(color: _navy, fontSize: 14, fontWeight: FontWeight.w800)), children: [Align(alignment: Alignment.centerLeft, child: SelectableText(rules, style: const TextStyle(color: _muted, fontSize: 13, height: 1.65)))])))),
        ]))),
        if (error != null) Padding(padding: const EdgeInsets.fromLTRB(20, 6, 20, 0), child: Row(children: [const Icon(Icons.wifi_off_rounded, color: _muted, size: 15), const SizedBox(width: 8), const Expanded(child: Text('Не удалось обновить результат', style: TextStyle(color: _muted, fontSize: 11))), TextButton(onPressed: onRetry, child: const Text('Повторить'))])),
        Container(padding: const EdgeInsets.fromLTRB(20, 12, 20, 16), decoration: const BoxDecoration(color: _paper, border: Border(top: BorderSide(color: Color(0xFFE4EBF0)))), child: _PrimaryAction(label: label, icon: canQr ? Icons.qr_code_2_rounded : joined ? Icons.check_rounded : ended ? Icons.flag_rounded : Icons.auto_awesome_rounded, busy: joining, onTap: canQr ? () => _showQr(context) : canJoin ? () { Navigator.pop(context); onJoin!(); } : null)),
      ]))))),
    );
  }
}

class _PrizePass extends StatelessWidget {
  final Map<String, dynamic> draw;
  const _PrizePass({required this.draw});
  @override Widget build(BuildContext context) => SafeArea(child: Padding(padding: const EdgeInsets.all(18), child: ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9), child: Material(color: _navy, borderRadius: BorderRadius.circular(30), clipBehavior: Clip.antiAlias, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Padding(padding: const EdgeInsets.fromLTRB(22, 16, 10, 0), child: Row(children: [const Expanded(child: Text('Ваш приз', style: TextStyle(color: _mint, fontSize: 12, fontWeight: FontWeight.w800))), IconButton(tooltip: 'Закрыть QR', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white))])),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Text(_text(draw, 'prize_text', 'Подарок от заведения'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, height: 1.15, fontWeight: FontWeight.w900))),
    Padding(padding: const EdgeInsets.only(top: 8), child: Text(_host(draw), style: const TextStyle(color: Color(0xFFA3B0C3), fontSize: 12))),
    Padding(padding: const EdgeInsets.all(22), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: LayoutBuilder(builder: (_, box) => QrImageView(data: _text(draw, 'prize_qr'), size: math.min(240.0, box.maxWidth), padding: EdgeInsets.zero)))),
    const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 24), child: Column(children: [Text('Покажите QR сотруднику', textAlign: TextAlign.center, style: TextStyle(color: _mint, fontSize: 18, fontWeight: FontWeight.w900)), SizedBox(height: 8), Text('Он отсканирует код в Flowru Business и подтвердит выдачу. Повторно получить приз нельзя.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFA3B0C3), fontSize: 12, height: 1.6))])),
  ]))))));
}

class AppRaffleDetails extends StatefulWidget {
  final Map<String, dynamic> draw;
  final bool joining;
  final VoidCallback? onJoin;
  final String? imageUrl;
  const AppRaffleDetails({super.key, required this.draw, required this.joining, this.onJoin, this.imageUrl});
  @override State<AppRaffleDetails> createState() => _AppRaffleDetailsState();
}
class _AppRaffleDetailsState extends State<AppRaffleDetails> {
  late Map<String, dynamic> _draw;
  Timer? _timer;
  bool _fetching = false;
  String? _error;
  @override void initState() { super.initState(); _draw = {...widget.draw}; _refresh(); _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh()); }
  @override void dispose() { _timer?.cancel(); super.dispose(); }
  @override void didUpdateWidget(covariant AppRaffleDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draw['run_id'] != widget.draw['run_id']) { _draw = {...widget.draw}; _error = null; _refresh(); }
  }
  Future<void> _refresh() async {
    final run = int.tryParse('${widget.draw['run_id']}');
    if (_fetching || run == null) return;
    _fetching = true;
    try {
      final token = await AuthStorage.access();
      if (token == null) return;
      final result = await FlowApi().orderPaymentRequest('/client/raffles/$run/result', 'GET', null, token);
      if (mounted && '${widget.draw['run_id']}' == '$run') setState(() {
        _draw.remove('prize_qr'); _draw.remove('prize_state'); _draw.remove('prize_expires_at');
        _draw = {..._draw, ...result}; _error = null;
      });
    } catch (_) {
      if (mounted) setState(() { _draw.remove('prize_qr'); _error = 'refresh_failed'; });
    } finally { _fetching = false; }
  }
  @override Widget build(BuildContext context) => _RaffleDetailsView(draw: _draw, joining: widget.joining, onJoin: widget.onJoin, imageUrl: widget.imageUrl, error: _error, onRetry: _refresh);
}
