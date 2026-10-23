import 'package:flutter/material.dart';

const _ink = Color(0xFF213149);
const _muted = Color(0xFF66758B);
String _text(Map<String, dynamic> d, String k, [String fallback = '']) {
  final v = '${d[k] ?? ''}'.trim();
  return v.isEmpty ? fallback : v;
}
bool _ended(Map<String, dynamic> d) => ['drawn', 'finished', 'completed', 'cancelled', 'canceled'].contains(_text(d, 'status'));
String _date(dynamic raw) {
  final v = DateTime.tryParse('$raw')?.toLocal();
  if (v == null) return 'Дата уточняется';
  const months = ['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];
  return '${v.day} ${months[v.month - 1]} · ${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';
}
String _host(Map<String, dynamic> d) => _text(d, 'establishment_name', d['establishment_id'] == null ? 'Розыгрыш заведения' : 'Заведение №${d['establishment_id']}');

class _RaffleArt extends StatelessWidget {
  final String? url;
  final double height;
  const _RaffleArt({this.url, required this.height});
  @override
  Widget build(BuildContext context) {
    final fallback = Container(height: height, alignment: Alignment.center, decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFFE5DAFF), Color(0xFFF5F5FA)])), child: Container(width: 112, height: 112, decoration: BoxDecoration(color: Colors.white.withOpacity(.72), borderRadius: BorderRadius.circular(36), boxShadow: const [BoxShadow(color: Color(0x22A393CC), blurRadius: 44, offset: Offset(0, 16))]), child: const Icon(Icons.emoji_events_rounded, size: 65, color: Color(0xFF8C70BC))));
    return ShaderMask(blendMode: BlendMode.dstIn, shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent], stops: [0, .15, .68, 1]).createShader(r), child: url == null || url!.isEmpty ? fallback : Image.network(url!, width: double.infinity, height: height, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback));
  }
}

class AppRaffleCard extends StatelessWidget {
  final Map<String, dynamic> draw;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool compact;
  const AppRaffleCard({super.key, required this.draw, required this.onTap, this.imageUrl, this.compact = false});
  @override
  Widget build(BuildContext context) {
    final joined = draw['is_joined'] == true;
    final ended = _ended(draw);
    if(compact) return Material(color: const Color(0xFFF5F5FA), borderRadius: BorderRadius.circular(28), clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Stack(children: [
      Positioned(right: -20, top: -15, width: 175, child: Opacity(opacity: .3, child: _RaffleArt(url: imageUrl, height: 150))),
      Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_host(draw), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_text(draw, 'title', 'Ваш шанс на приз'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontSize: 23, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -.6)), const SizedBox(height: 9), Text(_text(draw, 'prize_text', _text(draw, 'description', 'Подарок от заведения')), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 13, height: 1.35))]))),
        const SizedBox(height: 10),
        Text(_date(draw['draw_at']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 13),
        Row(children: [Expanded(child: Text(ended ? 'Итоги' : joined ? 'Вы участвуете' : 'Открыть розыгрыш', style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w900))), Icon(joined ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, size: 20, color: const Color(0xFF7E65AA))]),
      ])),
    ])));
    return Semantics(button: true, label: 'Розыгрыш. ${_host(draw)}. ${_text(draw, 'title')}', child: Material(color: const Color(0xFFF5F5FA), borderRadius: BorderRadius.circular(30), clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Stack(children: [
        _RaffleArt(url: imageUrl, height: 176),
        Positioned(left: 18, top: 16, right: 18, child: Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(.92), borderRadius: BorderRadius.circular(30)), child: const Text('ШАНС НА ПРИЗ', style: TextStyle(color: _ink, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))), const Spacer(), const Icon(Icons.north_east_rounded, color: _ink)])),
      ]),
      Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_host(draw), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 9),
        Text(_text(draw, 'title', 'Ваша следующая удача'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontSize: 25, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -.7)),
        const SizedBox(height: 10),
        Text(_text(draw, 'prize_text', _text(draw, 'description', 'Подарок от заведения')), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, height: 1.4, fontSize: 14)),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [_RafflePill(icon: Icons.schedule_rounded, text: _date(draw['draw_at'])), if(joined) const _RafflePill(icon: Icons.check_circle_rounded, text: 'Вы участвуете')]),
        const SizedBox(height: 18),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16), decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(17)), child: Row(children: [Expanded(child: Text(ended ? 'Посмотреть итоги' : joined ? 'Ваше участие и условия' : 'Открыть розыгрыш', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))), const Icon(Icons.arrow_forward_rounded, color: Color(0xFFADFAE7), size: 20)])),
      ])),
    ])))) ;
  }
}

class _RafflePill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RafflePill({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9), decoration: BoxDecoration(color: Colors.white.withOpacity(.88), borderRadius: BorderRadius.circular(13)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: _muted), const SizedBox(width: 6), Flexible(child: Text(text, style: const TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w700)))]));
}

class AppRaffleDetails extends StatelessWidget {
  final Map<String, dynamic> draw;
  final bool joining;
  final VoidCallback? onJoin;
  final String? imageUrl;
  const AppRaffleDetails({super.key, required this.draw, required this.joining, this.onJoin, this.imageUrl});
  @override
  Widget build(BuildContext context) {
    final joined = draw['is_joined'] == true;
    final ended = _ended(draw);
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(tween: Tween(begin: reducedMotion ? 1.0 : 0.0, end: 1.0), duration: Duration(milliseconds: reducedMotion ? 0 : 420), curve: Curves.easeOutCubic, builder: (context, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 24 * (1-v)), child: child)), child: Container(
      height: MediaQuery.sizeOf(context).height * .89,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(32)), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF8F6FF), Color(0xFFF0FCF8), Color(0xFFFFFAF3)])),
      child: SafeArea(top: false, child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(22, 8, 10, 0), child: Row(children: [const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF8C70BC)), const SizedBox(width: 9), const Text('FLOWRU / РОЗЫГРЫШ', style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4)), const Spacer(), IconButton(tooltip: 'Закрыть', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: _ink))])),
        Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _RaffleArt(url: imageUrl, height: 220),
          Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.storefront_outlined, size: 17, color: _muted), const SizedBox(width: 7), Expanded(child: Text(_host(draw), style: const TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w700)))]),
            const SizedBox(height: 13),
            Text(_text(draw, 'title', 'Пусть повезёт именно вам'), style: const TextStyle(color: _ink, fontSize: 32, fontWeight: FontWeight.w900, height: 1.08, letterSpacing: -1.1)),
            const SizedBox(height: 24),
            Container(width: double.infinity, padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(25), boxShadow: const [BoxShadow(color: Color(0x20213149), blurRadius: 25, offset: Offset(0, 10))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.emoji_events_outlined, color: Color(0xFFBEF6DC), size: 21), SizedBox(width: 9), Text('НА КОНУ', style: TextStyle(color: Color(0xFFBEF6DC), fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w900))]), const SizedBox(height: 12), Text(_text(draw, 'prize_text', _text(draw, 'description', 'Подарок от заведения')), style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800, height: 1.25))])),
            const SizedBox(height: 20),
            Wrap(spacing: 8, runSpacing: 8, children: [_RafflePill(icon: Icons.schedule_rounded, text: _date(draw['draw_at'])), _RafflePill(icon: Icons.people_outline_rounded, text: 'Участников: ${draw['participants_count'] ?? 0}')]),
            if(joined) Padding(padding: const EdgeInsets.only(top: 18), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFDFF5EA), borderRadius: BorderRadius.circular(18)), child: const Row(children: [Icon(Icons.check_circle_rounded, color: Color(0xFF258363)), SizedBox(width: 10), Expanded(child: Text('Вы в розыгрыше. Результат появится в приложении.', style: TextStyle(color: Color(0xFF25684F), height: 1.4, fontWeight: FontWeight.w700)))]))),
            const SizedBox(height: 26),
            const Text('Всё, что нужно знать', style: TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 13),
            Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(.8), borderRadius: BorderRadius.circular(22)), child: SelectableText(_text(draw, 'post_text', _text(draw, 'full_text', _text(draw, 'rules', 'Нажмите кнопку участия. Итоги появятся здесь после завершения розыгрыша.'))), style: const TextStyle(color: _muted, fontSize: 15, height: 1.65))),
            if(_text(draw, 'winner_user_name').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 22), child: Text('Победитель: ${draw['winner_user_name']}', style: const TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w800))),
          ])),
        ]))),
        Container(padding: const EdgeInsets.fromLTRB(24, 12, 24, 16), decoration: BoxDecoration(color: Colors.white.withOpacity(.9), border: const Border(top: BorderSide(color: Color(0x0D213149)))), child: Column(children: [
          if(!joined && !ended) const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Ознакомьтесь с условиями перед участием', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 11))),
          SizedBox(width: double.infinity, child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: _ink, disabledBackgroundColor: joined ? const Color(0xFFDFF5EA) : const Color(0xFFE5E8EE), disabledForegroundColor: joined ? const Color(0xFF25684F) : _muted, padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19))), onPressed: joining || joined || ended || onJoin == null ? null : () {Navigator.pop(context); onJoin!();}, icon: joining ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(joined ? Icons.check_circle_rounded : ended ? Icons.flag_outlined : Icons.auto_awesome_rounded), label: Text(joining ? 'Добавляем вас…' : ended ? 'Розыгрыш завершён' : joined ? 'Вы участвуете' : 'Хочу участвовать', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)))),
        ])),
      ])),
    ));
  }
}
