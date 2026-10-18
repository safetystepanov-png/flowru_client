import 'flowru_future_ui.dart';
import 'flowru_order_design.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

typedef OrderPaymentRequest = Future<Map<String, dynamic>> Function(
    String, String, Map<String, dynamic>?);
const _cream = Color(0xFFF6FBFF);
const _terra = Color(0xFF7A4CFF);
const _ink = Color(0xFF0A2B47);
String paymentStateLabel(String s) => switch (s) {
      'creating' => 'Готовим оплату',
      'pending' => 'Ожидаем оплату',
      'waiting_for_capture' => 'Подтверждаем оплату',
      'succeeded' => 'Заказ оплачен',
      'cash_due' => 'Оплата при получении',
      'canceled' => 'Оплата отменена',
      'refund_pending' => 'Возврат выполняется',
      'refunded' => 'Деньги возвращены',
      'needs_review' => 'Нужна проверка владельцем',
      _ => 'Проверяем статус',
    };
String _uuid() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

class OrderPaymentScreen extends StatefulWidget {
  final int establishmentId;
  final String scope;
  final OrderPaymentRequest request;
  final Map<String, dynamic>? checkout;
  final Future<Map<String, dynamic>?> Function(String, BuildContext)?
      changeReceiving;
  final bool onlineAvailable;
  final String establishmentName;
  const OrderPaymentScreen(
      {super.key,
      required this.establishmentId,
      required this.scope,
      required this.request,
      this.checkout,
      this.changeReceiving,
      this.onlineAvailable = true,
      this.establishmentName = ''});
  @override
  State<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends State<OrderPaymentScreen> {
  static const _storage = FlutterSecureStorage(
      iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device),
      aOptions: AndroidOptions(encryptedSharedPreferences: true));
  Timer? _timer;
  final _receiptEmail = TextEditingController();
  bool _busy = false, _paymentOpened = false;
  String? _error;
  Map<String, dynamic>? _checkout;
  int _redeemPoints = 0;
  String _paymentMode = 'online';
  Map<String, dynamic>? _intent, _quote, _order;
  List<Map<String, dynamic>> _orders = [];
  String get _key => 'flowru_order_payment_v1:${widget.scope}';
  @override
  void initState() {
    super.initState();
    _checkout = widget.checkout == null
        ? null
        : Map<String, dynamic>.from(widget.checkout!);
    _paymentMode = widget.onlineAvailable ? 'online' : 'cash';
    _run(_initial);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_busy && _error == null && (_intent != null || _order != null))
        _run(_sync);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _receiptEmail.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _get(String p) => widget.request(p, 'GET', null);
  Future<Map<String, dynamic>> _post(String p, Map<String, dynamic> b) =>
      widget.request(p, 'POST', b);
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = _readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _readableError(Object error) {
    try {
      final dynamic e = error;
      if (e.status == 401 || e.status == 403)
        return 'Сессия истекла. Войдите в приложение заново и откройте заказ.';
      final message = e.message;
      if (message is String && message.trim().isNotEmpty) return message;
    } catch (_) {}
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.startsWith('Instance of')
        ? 'Не удалось обновить заказ. Проверьте соединение и повторите.'
        : message;
  }

  Widget _detailRow(String label, String value, {bool total = false}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: total ? _ink : const Color(0xFF6F8397),
                        fontSize: total ? 17 : 13,
                        fontWeight:
                            total ? FontWeight.w800 : FontWeight.w500))),
            Text(value,
                style: TextStyle(
                    color: _ink,
                    fontSize: total ? 27 : 14,
                    fontWeight: FontWeight.w800)),
          ]));

  Future<void> _initial() async {
    final stored = await _storage.read(key: _key);
    if (stored != null && _checkout != null) {
      try {
        _intent = Map<String, dynamic>.from(jsonDecode(stored) as Map);
      } catch (_) {
        throw Exception(
            'Не удалось прочитать сохранённую попытку. Не создавайте новую: свяжитесь с заведением.');
      }
    }
    if (_intent != null) {
      final r = await _get(
          '/client/order-payments/by-request/${_intent!['request_id']}');
      if (r['order'] is Map)
        _order = Map<String, dynamic>.from(r['order'] as Map);
    }
    if (_checkout != null &&
        _order != null &&
        ['succeeded', 'cash_due', 'canceled', 'refunded']
            .contains(_order!['state'])) {
      // Only a server-confirmed finished payment attempt can be detached from a NEW checkout.
      await _storage.delete(key: _key);
      _intent = null;
      _order = null;
    }
    if (_intent != null)
      _receiptEmail.text = _intent!['receipt_email']?.toString() ?? '';
    if (_intent != null) {
      _paymentMode = _intent!['payment_mode']?.toString() ?? 'online';
      _redeemPoints = (_intent!['redeem_points'] as num? ?? 0).toInt();
    }
    if (_checkout != null && _order == null) await _refreshQuote();
    await _sync();
  }

  Future<void> _refreshQuote() async {
    _quote = null;
    final checkout = _checkout;
    if (checkout == null) return;
    if (checkout['fulfillment'] == 'delivery' &&
        checkout['address_token'] == null) return;
    final q = await _post('/client/order-commerce/quote', {
      'establishment_id': widget.establishmentId,
      'fulfillment': checkout['fulfillment'] ?? 'pickup',
      if (checkout['address_token'] != null)
        'address_token': checkout['address_token'],
      'lines': checkout['lines'],
      'redeem_points': _redeemPoints,
      'payment_mode': _paymentMode,
      'pickup_minutes': checkout['pickup_minutes'] ?? 15,
      'pickup_at': checkout['pickup_at'],
    });
    final total = num.tryParse('${q['total_kopeks']}');
    if (total == null || total < 0)
      throw Exception('Не удалось рассчитать заказ. Нажмите обновить расчёт.');
    _quote = {
      ...q,
      'amount': total / 100,
      'delivery_address': q['delivery_address'] ?? checkout['delivery_address']
    };
    if (mounted) setState(() {});
  }

  Future<void> _sync() async {
    final r = await _get(
        '/client/order-payments/list?establishment_id=${widget.establishmentId}');
    _orders = (r['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (_order != null) {
      _order = await _get('/client/order-payments/${_order!['id']}');
    } else if (_intent != null) {
      final found = await _get(
          '/client/order-payments/by-request/${_intent!['request_id']}');
      if (found['order'] is Map)
        _order = Map<String, dynamic>.from(found['order'] as Map);
    }
    if (_order != null &&
        _intent != null &&
        _intent!['request_id'] == _order!['request_id'] &&
        ['waiting_for_capture', 'succeeded', 'cash_due', 'canceled', 'refunded']
            .contains(_order!['state'])) await _storage.delete(key: _key);
    if (mounted) setState(() {});
  }

  Future<void> _pay() async {
    if (_intent == null) {
      if (_paymentMode == 'online' &&
          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
              .hasMatch(_receiptEmail.text.trim())) {
        final email = await showDialog<String>(context: context,
          barrierDismissible: false,
          builder: (_) => _ReceiptEmailDialog(initialEmail: _receiptEmail.text));
        if (!mounted || email == null) return;
        _receiptEmail.text = email;

      }
      if (_checkout == null || _quote == null)
        throw Exception('Сначала обновите расчёт');
      _intent = {
        ..._checkout!,
        'establishment_id': widget.establishmentId,
        'fulfillment': _checkout!['fulfillment'] ?? 'pickup',
        'confirmed_total_kopeks': _quote!['total_kopeks'],
        'redeem_points': _redeemPoints,
        'payment_mode': _paymentMode,
        if (_paymentMode == 'online')
          'receipt_email': _receiptEmail.text.trim(),
        'request_id': _uuid()
      };
      _intent!.remove('delivery_address');
      // Saving finishes before the first HTTP request. Every retry keeps this exact UUID/body.
      await _storage.write(key: _key, value: jsonEncode(_intent));
    }
    if (_order == null &&
        _checkout != null &&
        _intent != null &&
        (jsonEncode(_intent!['lines']) != jsonEncode(_checkout!['lines']) ||
            _intent!['address_token'] != _checkout!['address_token'] ||
            (_intent!['fulfillment'] ?? 'pickup') !=
                (_checkout!['fulfillment'] ?? 'pickup'))) {
      throw Exception(
          'Есть незавершённая оплата другого заказа. Проверьте её статус перед новой оплатой.');
    }
    _order = await _post('/client/order-payments/checkout', _intent!);
    await _sync();
    if (_order?['state'] == 'pending' && _order?['confirmation_url'] != null)
      await _openPayment();
  }

  Future<void> _openPayment() async {
    final uri = Uri.tryParse((_order?['confirmation_url'] ?? '').toString());
    if (uri == null || uri.scheme != 'https')
      throw Exception('Ссылка пока не получена. Обновите статус.');
    if (!await launchUrl(uri,
        mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank'))
      throw Exception(
          'Браузер не открыл оплату. Нажмите «Открыть страницу оплаты».');
    if (mounted) setState(() => _paymentOpened = true);
  }

  Future<void> _cancel() async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: _cream,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                title: const Text('Отменить заказ?'),
                content: const Text(
                    'Сообщим заведению об отмене. Если заказ оплачен, оформим возврат.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Оставить')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Отменить заказ'))
                ]));
    if (yes == true) {
      _order =
          await _post('/client/order-payments/${_order!['id']}/cancel', {});
      await _sync();
    }
  }

  String _money(Object? value) {
    final parsed = num.tryParse(value?.toString() ?? '');
    return parsed == null
        ? '—'
        : (parsed % 1 == 0
            ? parsed.toInt().toString()
            : parsed.toStringAsFixed(2).replaceAll('.', ','));
  }

  String _readyTime(Object? value) {
    if (value == null) return '';
    final parsed = DateTime.tryParse(value.toString())?.toLocal();
    if (parsed == null) return '';
    final clock =
        '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    return parsed.year == now.year &&
            parsed.month == now.month &&
            parsed.day == now.day
        ? clock
        : '${parsed.day}.${parsed.month} в $clock';
  }

  Widget _action(String text, VoidCallback action,
          {bool primary = true, bool enabled = true}) =>
      Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FutureAction(
              label: text,
              onTap: _busy || !enabled ? null : action,
              primary: primary));

  Widget _historyTile(Map<String, dynamic> order, int index) {
    final state = (order['state'] ?? '').toString();
    final status = (order['preorder_status'] ?? '').toString();
    final canceled =
        ['canceled', 'refunded', 'refund_pending'].contains(state) ||
            status == 'cancelled' ||
            order['desired_action'] == 'cancel';
    final done = !canceled && status == 'completed';
    final color = canceled
        ? const Color(0xFFE45866)
        : done
            ? const Color(0xFF0BADA0)
            : const Color(0xFFF29A26);
    final label = canceled
        ? (state == 'refunded' ? 'Возвращён' : 'Отменён')
        : done
            ? 'Завершён'
            : state == 'pending'
                ? 'Ожидает оплаты'
                : status == 'in_work'
                    ? 'Готовится'
                    : status == 'ready'
                        ? 'Готов'
                        : state == 'succeeded'
                            ? 'Оплачен · ожидает принятия'
                            : paymentStateLabel(state);
    return TweenAnimationBuilder<double>(
        key: ValueKey('history-${order['id']}-$state-$status'),
        tween: Tween(begin: 0, end: 1),
        duration:
            Duration(milliseconds: 320 + (index.clamp(0, 5).toInt() * 45)),
        builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)), child: child)),
        child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _busy ? null : () => setState(() => _order = order),
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: color.withOpacity(.055),
                            border: Border.all(color: color.withOpacity(.28))),
                        child: Row(children: [
                          Container(
                              width: 4,
                              height: 46,
                              decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4))),
                          const SizedBox(width: 13),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Заказ №${order['preorder_id']}',
                                    style: const TextStyle(
                                        color: _ink,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Text(label,
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700))
                              ])),
                          Text('${_money(order['amount'])} ₽',
                              style: const TextStyle(
                                  color: _ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded,
                              color: color, size: 22),
                        ]))))));
  }

  Future<void> _receiving() async {
    final mode = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text('Как получить заказ?'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Самовывоз'),
                  subtitle: const Text('Забрать в заведении'),
                  onTap: () => Navigator.pop(ctx, 'pickup')),
              ListTile(
                  leading: const Icon(Icons.delivery_dining_rounded),
                  title: const Text('Доставка'),
                  subtitle: const Text('Курьер привезёт по адресу'),
                  onTap: () => Navigator.pop(ctx, 'delivery'))
            ])));
    if (mode == null || widget.changeReceiving == null) return;
    await _changeReceiving(mode);
  }

  Future<void> _changeReceiving(String mode) async {
    final result = await widget.changeReceiving?.call(mode, context);
    if (result == null || !mounted) return;
    _checkout = Map<String, dynamic>.from(result);
    _redeemPoints = 0;
    if (mode == 'delivery') _paymentMode = 'online';
    await _run(_refreshQuote);
  }

  Future<void> _pickupInstead() async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Заберёте самостоятельно?'),
                content: const Text(
                    'Заказ будет ждать в заведении. Стоимость доставки вернём тем же способом оплаты.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Оставить доставку')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Выбрать самовывоз'))
                ]));
    if (yes != true) return;
    await _post('/client/order-payments/${_order!['id']}/pickup-instead', {});
    await _sync();
  }

  Future<void> _abandon() async {
    if (_intent == null) return;
    final result = await _post(
        '/client/order-payments/abandon/${_intent!['request_id']}', {});
    if (result['order'] is Map) {
      _order = Map<String, dynamic>.from(result['order'] as Map);
      await _sync();
      return;
    }
    if (result['abandoned'] == true) {
      await _storage.delete(key: _key);
      _intent = null;
      await _refreshQuote();
    }
  }

  Future<void> _decide(String choice, Map offer) async {
    await _post('/client/order-payments/${_order!['id']}/time-decision',
        {'choice': choice, 'revision': offer['revision']});
    await _sync();
  }

  Widget _checkoutControls(bool delivery) {
    final editable = !_busy && _intent == null;
    final maxPoints = (_quote?['max_points'] as num? ?? 0).toInt();
    final time = _quote == null
        ? ''
        : delivery
            ? '${_readyTime(_quote!['promised_delivery_from'])}–${_readyTime(_quote!['promised_delivery_to'])}'
            : _readyTime(_quote!['promised_ready_at']);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text(
                time.isEmpty
                    ? 'Уточним время после оформления'
                    : '${delivery ? 'Доставка' : 'Готовность'} · $time',
                style: const TextStyle(
                    color: _ink, fontSize: 14, fontWeight: FontWeight.w600))),
        TextButton(
            onPressed: editable ? _receiving : null,
            child: const Text('Изменить',
                style: TextStyle(color: Color(0xFF089A91)))),
      ]),
      if (delivery && _checkout?['address_token'] == null)
        TextButton.icon(
            onPressed: editable ? () => _changeReceiving('delivery') : null,
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Указать адрес доставки')),
      const SizedBox(height: 12),
      const Text('Оплата',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 4, children: [
        if (widget.onlineAvailable)
          _choice(
              'Онлайн · ЮKassa',
              _paymentMode == 'online',
              editable
                  ? () => _run(() async {
                        _paymentMode = 'online';
                        _redeemPoints = 0;
                        await _refreshQuote();
                      })
                  : null),
        if (!delivery)
          _choice(
              'Наличными в заведении',
              _paymentMode == 'cash',
              editable
                  ? () => _run(() async {
                        _paymentMode = 'cash';
                        _redeemPoints = 0;
                        await _refreshQuote();
                      })
                  : null),
      ]),
      if (_quote != null)
        Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 12),
              title: Text('Баллы · ${_quote!['balance']}',
                  style: const TextStyle(
                      color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
              subtitle: Text(
                  _redeemPoints > 0
                      ? 'Списываем $_redeemPoints · скидка ${_money((_quote!['discount_kopeks'] as num? ?? 0) / 100)} ₽'
                      : 'Копим за покупку · можно изменить',
                  style:
                      const TextStyle(color: Color(0xFF089A91), fontSize: 12)),
              children: [
                Wrap(spacing: 8, children: [
                  _choice(
                      'Копить',
                      _redeemPoints == 0,
                      editable
                          ? () => _run(() async {
                                _redeemPoints = 0;
                                await _refreshQuote();
                              })
                          : null),
                  _choice(
                      'Списать',
                      _redeemPoints > 0,
                      editable && maxPoints > 0
                          ? () => _run(() async {
                                _redeemPoints = maxPoints;
                                await _refreshQuote();
                              })
                          : null),
                ]),
                if (_redeemPoints > 0)
                  Slider(
                      activeColor: const Color(0xFF089A91),
                      value: _redeemPoints
                          .toDouble()
                          .clamp(0.0, maxPoints.toDouble())
                          .toDouble(),
                      max: maxPoints > 0 ? maxPoints.toDouble() : 1,
                      divisions: maxPoints > 0 ? maxPoints : null,
                      label: '$_redeemPoints баллов',
                      onChanged: editable
                          ? (v) => setState(() => _redeemPoints = v.round())
                          : null,
                      onChangeEnd:
                          editable ? (_) => _run(_refreshQuote) : null),
                if (maxPoints == 0)
                  const Text('Списание баллов для этого заказа недоступно',
                      style: TextStyle(color: Color(0xFF637C93), fontSize: 12)),
              ],
            )),
    ]);
  }

  Widget _choice(String label, bool selected, VoidCallback? onTap) =>
      OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
              foregroundColor: selected ? const Color(0xFF089A91) : _ink,
              side: BorderSide(
                  color: selected
                      ? const Color(0xFF089A91)
                      : const Color(0xFFD7E5EC)),
              backgroundColor:
                  selected ? const Color(0xFFE7F7F4) : Colors.transparent),
          child: Text('${selected ? '✓ ' : ''}$label'));
  Widget _timeline(bool delivery, int stage) {
    final labels = delivery
        ? ['Оформлен', 'Готовится', 'Готов', 'У курьера', 'Доставлен']
        : ['Оформлен', 'Готовится', 'Готов', 'Выдан'];
    return Row(
        children: List.generate(
            labels.length,
            (i) => Expanded(
                child: Padding(
                    padding:
                        EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 4,
                              decoration: BoxDecoration(
                                  color: i <= stage
                                      ? const Color(0xFF12B9AE)
                                      : const Color(0xFFDDE8F3),
                                  borderRadius: BorderRadius.circular(9))),
                          const SizedBox(height: 8),
                          Text(labels[i],
                              maxLines: 2,
                              style: TextStyle(
                                  color: i <= stage
                                      ? _ink
                                      : const Color(0xFF8799AA),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700))
                        ])))));
  }

  int _offerMinutes(Map offer, String field) {
    final a = DateTime.tryParse('${offer['ready_at']}');
    final b = DateTime.tryParse('${offer[field]}');
    return (offer['prepare_minutes'] as num? ?? 0).toInt() +
        (a == null || b == null ? 0 : b.difference(a).inMinutes);
  }

  Widget _timeOffer(Map offer, bool delivery) => Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Подтвердите новое время',
            style: TextStyle(
                color: _ink, fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text('Самовывоз: через ${offer['prepare_minutes']} мин.',
            style: const TextStyle(color: _ink, fontSize: 16)),
        if (delivery)
          Text(
              'Доставка: через ${_offerMinutes(offer, 'delivery_from')}–${_offerMinutes(offer, 'delivery_to')} мин.',
              style: const TextStyle(color: _ink, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Срок считаем после вашего подтверждения',
            style: TextStyle(color: Color(0xFF637C93), fontSize: 12)),
        const SizedBox(height: 12),
        _action(delivery ? 'Подтвердить доставку' : 'Подтвердить самовывоз',
            () => _run(() => _decide('confirm', offer))),
        if (delivery)
          TextButton(
              onPressed:
                  _busy ? null : () => _run(() => _decide('pickup', offer)),
              child: const Text('Заберу самостоятельно')),
        TextButton(
            onPressed: _busy ? null : () => _run(_cancel),
            child: const Text('Отменить заказ',
                style: TextStyle(color: Color(0xFFCF5260)))),
        const Divider(height: 24),
      ]));

  @override
  Widget build(BuildContext context) {
    if (_order == null &&
        _quote == null &&
        (_error ?? '').contains('Минимальная сумма')) {
      final match = RegExp(r'(\d+(?:[.,]\d+)?)\s*₽').firstMatch(_error!);
      final amount = match?.group(1)?.replaceAll(RegExp(r'[.,]00$'), '');
      return Scaffold(
          backgroundColor: _cream,
          appBar:
              AppBar(backgroundColor: _cream, title: const Text('Доставка')),
          body: SafeArea(
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Padding(
                          padding: const EdgeInsets.all(28),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.shopping_bag_outlined,
                                color: Color(0xFF7A4CFF), size: 48),
                            const SizedBox(height: 20),
                            Text(
                                amount == null
                                    ? 'Минимальная сумма заказа'
                                    : 'Заказ от $amount ₽',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Color(0xFF0A2B47),
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            Text(
                                amount == null
                                    ? _error!
                                    : 'Минимальная сумма для доставки по этому адресу — $amount ₽. Добавьте ещё что-нибудь в заказ.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Color(0xFF52758A))),
                            const SizedBox(height: 28),
                            FlowruGradientAction(
                                label: 'Вернуться к заказу',
                                onTap: () => Navigator.maybePop(context)),
                          ]))))));
    }
    final state = (_order?['state'] ?? '').toString();
    final cancelling = _order?['desired_action'] == 'cancel';
    final cashDue = state == 'cash_due';
    final paid = state == 'succeeded' && !cancelling;
    final preorderStatus = (_order?['preorder_status'] ?? '').toString();
    final readyTime = _readyTime(_order?['estimated_ready_at']);
    final refunded = state == 'refunded';
    final canceled = state == 'canceled';
    final hasOrder = _checkout != null || _intent != null || _order != null;
    final source = _order ?? _quote;
    final addressValue = source?['delivery_address'];
    final deliveryAddress =
        (addressValue is Map ? addressValue['address'] : addressValue) ??
            _checkout?['delivery_address'] ??
            '';
    final delivery =
        (source?['fulfillment'] ?? _checkout?['fulfillment']) == 'delivery';
    final items = (source?['items'] as List? ?? []).whereType<Map>().toList();
    final deliveryPhase = (_order?['delivery_phase'] ?? '').toString();
    final deliveryFrom = _readyTime(_order?['estimated_delivery_from']);
    final deliveryTo = _readyTime(_order?['estimated_delivery_to']);
    final deliveryTime =
        deliveryFrom.isEmpty ? '' : '$deliveryFrom–$deliveryTo';
    final title = cashDue && preorderStatus == 'new'
        ? 'Заказ оформлен'
        : refunded
            ? 'Оплата возвращена'
            : canceled
                ? 'Заказ отменён'
                : cancelling || state == 'refund_pending'
                    ? 'Оформляем возврат'
                    : (paid || cashDue)
                        ? (delivery && deliveryPhase == 'on_way'
                            ? 'Курьер в пути'
                            : preorderStatus == 'ready'
                                ? (delivery ? 'Заказ готов' : 'Можно забирать')
                                : preorderStatus == 'completed'
                                    ? (delivery
                                        ? 'Заказ доставлен'
                                        : 'Заказ выдан')
                                    : preorderStatus == 'in_work'
                                        ? 'Готовим ваш заказ'
                                        : 'Спасибо за заказ')
                        : state == 'pending'
                            ? (_paymentOpened
                                ? 'Проверяем оплату'
                                : 'Оплата заказа')
                            : state == 'needs_review'
                                ? 'Проверяем оплату'
                                : state == 'waiting_for_capture'
                                    ? 'Подтверждаем оплату'
                                    : delivery
                                        ? 'У вас доставка'
                                        : 'У вас самовывоз';
    final subtitle = cashDue
        ? 'Оплатите наличными при получении в заведении.'
        : refunded
            ? 'Возврат подтверждён. Срок зачисления зависит от вашего банка.'
            : canceled
                ? 'Этот заказ отменён.'
                : cancelling || state == 'refund_pending'
                    ? 'Отмена принята. Статус возврата обновится здесь.'
                    : (paid || cashDue)
                        ? (delivery && deliveryPhase == 'on_way'
                            ? (deliveryTime.isEmpty
                                ? 'Курьер везёт заказ к вам.'
                                : 'Ожидаем доставку $deliveryTime.')
                            : preorderStatus == 'ready'
                                ? (delivery
                                    ? (deliveryTime.isEmpty
                                        ? 'Заказ готов. Ожидаем курьера.'
                                        : 'Заказ готов. Ожидаем доставку $deliveryTime.')
                                    : 'Заказ готов и ждёт вас в заведении.')
                                : preorderStatus == 'completed'
                                    ? 'Спасибо за покупку!'
                                    : readyTime.isNotEmpty
                                        ? (delivery
                                            ? (deliveryTime.isEmpty
                                                ? 'Готовим заказ. Готовность $readyTime.'
                                                : 'Готовим заказ. Доставка $deliveryTime.')
                                            : 'Ожидаемая готовность — $readyTime.')
                                        : 'Заказ оплачен. Заведение подтвердит время приготовления.')
                        : state == 'needs_review'
                            ? 'Не оплачивайте повторно. Заведению нужно проверить платёж.'
                            : state == 'pending'
                                ? (_paymentOpened
                                    ? 'После оплаты вернитесь сюда. Статус обновится после подтверждения ЮKassa.'
                                    : 'Сейчас откроется защищённая страница ЮKassa.')
                                : delivery
                                    ? 'Курьер привезёт заказ по вашему адресу.'
                                    : 'Заказ нужно забрать в заведении.';
    final icon = refunded
        ? Icons.undo_rounded
        : canceled
            ? Icons.close_rounded
            : paid
                ? Icons.check_rounded
                : Icons.shopping_bag_outlined;
    final canReturn = (paid || cashDue) &&
        _checkout != null &&
        _intent?['request_id'] == _order?['request_id'];
    final terminal = canceled || refunded;
    final stage = preorderStatus == 'completed' || deliveryPhase == 'delivered'
        ? (delivery ? 4 : 3)
        : deliveryPhase == 'on_way'
            ? 3
            : preorderStatus == 'ready'
                ? 2
                : preorderStatus == 'in_work'
                    ? 1
                    : 0;
    final statusColor = paid
        ? const Color(0xFF089A91)
        : terminal
            ? const Color(0xFF78879A)
            : _terra;
    final editable = !_busy && _intent == null && _order == null;
    final maxPoints = (_quote?['max_points'] as num? ?? 0).toInt();
    final promised = delivery
        ? '${_readyTime(_quote?['promised_delivery_from'])}–${_readyTime(_quote?['promised_delivery_to'])}'
        : _readyTime(_quote?['promised_ready_at']);
    return Scaffold(
        backgroundColor: const Color(0xFFF2FAFF),
        body: FutureScene(
            child: SafeArea(
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(children: [
                                IconButton(
                                    onPressed: () =>
                                        Navigator.pop(context, canReturn),
                                    icon: const Icon(Icons.arrow_back_rounded,
                                        color: futureInk)),
                                Expanded(
                                    child: Text(
                                        _order == null
                                            ? 'FLOWRU'
                                            : 'Заказ №${_order!['preorder_id']}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: futureInk,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 2))),
                                IconButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _run(
                                            _order == null ? _initial : _sync),
                                    icon: const Icon(Icons.refresh_rounded,
                                        color: futureAqua)),
                              ])),
                          if (_busy)
                            const LinearProgressIndicator(
                                minHeight: 2, color: futureAqua),
                          Expanded(
                              child: ListView(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 0, 18, 20),
                                  children: [
                                FutureHero(
                                    imageAsset: 'assets/flowru_future/cart.png',
                                    title: _order == null
                                        ? (hasOrder
                                            ? 'Ваш заказ'
                                            : 'Мои заказы')
                                        : title,
                                    subtitle:
                                        widget.establishmentName.isNotEmpty
                                            ? widget.establishmentName
                                            : (_order == null
                                                ? 'Всё готово к оформлению'
                                                : subtitle)),
                                const SizedBox(height: 12),
                                if (hasOrder) ...[
                                  if (_order == null && _checkout != null) ...[
                                    Row(children: [
                                      Expanded(
                                          child: FutureOption(
                                              title: 'Самовывоз',
                                              subtitle: 'Забрать в заведении',
                                              icon: Icons.shopping_bag_outlined,
                                              selected: !delivery,
                                              onTap: editable
                                                  ? () =>
                                                      _changeReceiving('pickup')
                                                  : null)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: FutureOption(
                                              title: 'Доставка',
                                              subtitle: 'Привезём по адресу',
                                              icon:
                                                  Icons.delivery_dining_rounded,
                                              selected: delivery,
                                              onTap: editable
                                                  ? () => _changeReceiving(
                                                      'delivery')
                                                  : null)),
                                    ]),
                                    const SizedBox(height: 12),
                                    FutureGlass(
                                        child: Row(children: [
                                      const Icon(Icons.schedule_rounded,
                                          color: futureSoft, size: 28),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(
                                                promised == '–' ||
                                                        promised.isEmpty
                                                    ? 'Уточняем время'
                                                    : promised,
                                                style: const TextStyle(
                                                    color: futureInk,
                                                    fontSize: 27,
                                                    fontWeight:
                                                        FontWeight.w900)),
                                            Text(
                                                delivery
                                                    ? 'Доставка курьером'
                                                    : 'Забрать в заведении',
                                                style: const TextStyle(
                                                    color: futureSoft,
                                                    fontSize: 12))
                                          ])),
                                      if (delivery)
                                        IconButton(
                                            onPressed: editable
                                                ? () =>
                                                    _changeReceiving('delivery')
                                                : null,
                                            icon: const Icon(
                                                Icons
                                                    .edit_location_alt_outlined,
                                                color: futureAqua))
                                    ])),
                                    if (delivery)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: Text(
                                              deliveryAddress.toString().isEmpty
                                                  ? 'Выберите адрес доставки'
                                                  : deliveryAddress.toString(),
                                              style: const TextStyle(
                                                  color: futureInk,
                                                  fontSize: 13))),
                                    const SizedBox(height: 18),
                                    const Text('Способ оплаты',
                                        style: TextStyle(
                                            color: futureInk,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      if (widget.onlineAvailable)
                                        Expanded(
                                            child: FutureOption(
                                                title: 'Онлайн',
                                                subtitle: 'ЮKassa',
                                                icon: Icons.credit_card_rounded,
                                                selected:
                                                    _paymentMode == 'online',
                                                onTap: editable
                                                    ? () => _run(() async {
                                                          _paymentMode =
                                                              'online';
                                                          _redeemPoints = 0;
                                                          await _refreshQuote();
                                                        })
                                                    : null)),
                                      if (widget.onlineAvailable && !delivery)
                                        const SizedBox(width: 8),
                                      if (!delivery)
                                        Expanded(
                                            child: FutureOption(
                                                title: 'В заведении',
                                                subtitle: 'Наличными',
                                                icon: Icons.storefront_outlined,
                                                selected:
                                                    _paymentMode == 'cash',
                                                onTap: editable
                                                    ? () => _run(() async {
                                                          _paymentMode = 'cash';
                                                          _redeemPoints = 0;
                                                          await _refreshQuote();
                                                        })
                                                    : null)),
                                    ]),
                                    const SizedBox(height: 12),
                                    if (_quote != null)
                                      FutureGlass(
                                          padding: EdgeInsets.zero,
                                          child: Theme(
                                              data: Theme.of(context).copyWith(
                                                  dividerColor:
                                                      Colors.transparent),
                                              child: ExpansionTile(
                                                  leading: const Icon(Icons.auto_awesome_outlined,
                                                      color: Color(0xFF8B61EC)),
                                                  title: Text(
                                                      'Баллы · ${_quote!['balance']}',
                                                      style: const TextStyle(
                                                          color: futureInk,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w800)),
                                                  subtitle: Text(
                                                      _redeemPoints > 0
                                                          ? 'Списываем $_redeemPoints · −${_money((_quote!['discount_kopeks'] as num? ?? 0) / 100)} ₽'
                                                          : 'Копить или списать',
                                                      style: const TextStyle(
                                                          color: futureSoft,
                                                          fontSize: 12)),
                                                  childrenPadding:
                                                      const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                                  children: [
                                                    Wrap(spacing: 8, children: [
                                                      _choice(
                                                          'Копить',
                                                          _redeemPoints == 0,
                                                          editable
                                                              ? () => _run(
                                                                      () async {
                                                                    _redeemPoints =
                                                                        0;
                                                                    await _refreshQuote();
                                                                  })
                                                              : null),
                                                      _choice(
                                                          'Списать',
                                                          _redeemPoints > 0,
                                                          editable &&
                                                                  maxPoints > 0
                                                              ? () => _run(
                                                                      () async {
                                                                    _redeemPoints =
                                                                        maxPoints;
                                                                    await _refreshQuote();
                                                                  })
                                                              : null)
                                                    ]),
                                                    if (_redeemPoints > 0)
                                                      Slider(
                                                          activeColor:
                                                              futureAqua,
                                                          value: _redeemPoints
                                                              .toDouble()
                                                              .clamp(
                                                                  0.0,
                                                                  maxPoints
                                                                      .toDouble())
                                                              .toDouble(),
                                                          max: maxPoints > 0
                                                              ? maxPoints
                                                                  .toDouble()
                                                              : 1,
                                                          divisions:
                                                              maxPoints > 0
                                                                  ? maxPoints
                                                                  : null,
                                                          label:
                                                              '$_redeemPoints баллов',
                                                          onChanged: editable
                                                              ? (v) => setState(() =>
                                                                  _redeemPoints =
                                                                      v.round())
                                                              : null,
                                                          onChangeEnd: editable
                                                              ? (_) => _run(
                                                                  _refreshQuote)
                                                              : null),
                                                    if (maxPoints == 0)
                                                      const Text(
                                                          'Списание для этого заказа недоступно',
                                                          style: TextStyle(
                                                              color: futureSoft,
                                                              fontSize: 12)),
                                                  ]))),
                                  ] else ...[
                                    FutureGlass(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Row(children: [
                                            Icon(icon, color: statusColor),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Text(
                                                    paid
                                                        ? 'Оплачено'
                                                        : cashDue
                                                            ? 'Оплата в заведении'
                                                            : paymentStateLabel(
                                                                state),
                                                    style: const TextStyle(
                                                        color: futureInk,
                                                        fontWeight:
                                                            FontWeight.w800)))
                                          ]),
                                          const SizedBox(height: 10),
                                          Text(subtitle,
                                              style: const TextStyle(
                                                  color: futureSoft,
                                                  fontSize: 13,
                                                  height: 1.4)),
                                          if (paid || cashDue) ...[
                                            const SizedBox(height: 18),
                                            _timeline(delivery, stage)
                                          ],
                                          const SizedBox(height: 16),
                                          Text(
                                              delivery
                                                  ? 'Доставка · $deliveryTime'
                                                  : 'Самовывоз · ${readyTime.isEmpty ? 'время уточняется' : readyTime}',
                                              style: const TextStyle(
                                                  color: futureInk,
                                                  fontWeight: FontWeight.w700)),
                                          if (delivery &&
                                              paid &&
                                              ['in_work', 'ready']
                                                  .contains(preorderStatus) &&
                                              deliveryPhase != 'on_way')
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 6),
                                                child: Text(
                                                    preorderStatus == 'ready'
                                                        ? 'Самовывоз: можно забрать сейчас'
                                                        : 'Самовывоз: ${readyTime.isEmpty ? 'срок уточняется' : readyTime}',
                                                    style: const TextStyle(
                                                        color: futureAqua,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700))),
                                          if (deliveryAddress
                                              .toString()
                                              .isNotEmpty)
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 6),
                                                child: Text(
                                                    deliveryAddress.toString(),
                                                    style: const TextStyle(
                                                        color: futureSoft,
                                                        fontSize: 13))),
                                          if (delivery)
                                            Text(
                                                'Кв. ${source?['apartment'] ?? '—'} · подъезд ${source?['entrance'] ?? '—'} · этаж ${source?['floor'] ?? '—'}',
                                                style: const TextStyle(
                                                    color: futureSoft,
                                                    fontSize: 12)),
                                        ])),
                                    if (delivery &&
                                        _order?['time_offer'] is Map) ...[
                                      const SizedBox(height: 12),
                                      FutureGlass(
                                          child: _timeOffer(
                                              _order!['time_offer'] as Map,
                                              true))
                                    ],
                                    if (delivery &&
                                        paid &&
                                        ['in_work', 'ready']
                                            .contains(preorderStatus) &&
                                        deliveryPhase != 'on_way')
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: FutureAction(
                                              label: 'Заберу самостоятельно',
                                              primary: false,
                                              onTap: _busy
                                                  ? null
                                                  : () =>
                                                      _run(_pickupInstead))),
                                  ],
                                  const SizedBox(height: 12),
                                  FutureGlass(
                                      padding: EdgeInsets.zero,
                                      child: Theme(
                                          data: Theme.of(context).copyWith(
                                              dividerColor: Colors.transparent),
                                          child: ExpansionTile(
                                            leading: const Icon(
                                                Icons.shopping_bag_outlined,
                                                color: futureInk),
                                            title: Text(
                                                'Заказ · ${items.length} поз.',
                                                style: const TextStyle(
                                                    color: futureInk,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w800)),
                                            subtitle: Text(
                                                '${_money((source?['items_kopeks'] as num? ?? 0) / 100)} ₽',
                                                style: const TextStyle(
                                                    color: futureSoft,
                                                    fontSize: 12)),
                                            childrenPadding:
                                                const EdgeInsets.fromLTRB(
                                                    16, 0, 16, 12),
                                            children: [
                                              for (final item in items)
                                                Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 8),
                                                    child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                              '${item['quantity']}×',
                                                              style: const TextStyle(
                                                                  color:
                                                                      futureAqua,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800)),
                                                          const SizedBox(
                                                              width: 10),
                                                          Expanded(
                                                              child: Text(
                                                                  '${item['name'] ?? ''}${item['variant_name'] == null ? '' : ' · ${item['variant_name']}'}',
                                                                  style: const TextStyle(
                                                                      color:
                                                                          futureInk,
                                                                      fontSize:
                                                                          13))),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                              '${_money((num.tryParse('${item['total_kopeks']}') ?? 0) / 100)} ₽',
                                                              style: const TextStyle(
                                                                  color:
                                                                      futureInk,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700))
                                                        ]))
                                            ],
                                          ))),
                                  const SizedBox(height: 12),
                                  FutureGlass(
                                      child: Column(children: [
                                    if ((source?['discount_kopeks'] as num? ??
                                            0) >
                                        0)
                                      _detailRow(
                                          'Баллы · ${source?['redeem_points']}',
                                          '−${_money((source!['discount_kopeks'] as num) / 100)} ₽'),
                                    if (delivery)
                                      _detailRow(
                                          'Доставка',
                                          (source?['delivery_kopeks'] as num? ??
                                                      0) ==
                                                  0
                                              ? 'Бесплатно'
                                              : '${_money((source!['delivery_kopeks'] as num) / 100)} ₽'),
                                    if (_order?['handoff'] is Map &&
                                        ((_order!['handoff']
                                                        as Map)['extra_kopeks']
                                                    as num? ??
                                                0) >
                                            0) ...[
                                      _detailRow('Дополнительно в заведении',
                                          '${_money(((_order!['handoff'] as Map)['extra_kopeks'] as num) / 100)} ₽'),
                                      _detailRow('Всего за покупку',
                                          '${_money(((_order!['handoff'] as Map)['net_kopeks'] as num) / 100)} ₽'),
                                    ],
                                    _detailRow(
                                        paid ? 'Оплачено по заказу' : 'Итого',
                                        '${_money(source?['amount'])} ₽',
                                        total: true),
                                    if (_order?['delivery_refund_state'] !=
                                        null)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                              _order!['delivery_refund_state'] ==
                                                      'succeeded'
                                                  ? 'Стоимость доставки возвращена'
                                                  : 'Стоимость доставки возвращается',
                                              style: const TextStyle(
                                                  color: futureAqua,
                                                  fontSize: 12))),
                                  ])),
                                ] else ...[
                                  for (var index = 0;
                                      index < _orders.length;
                                      index++)
                                    _historyTile(_orders[index], index),
                                  if (_orders.isEmpty)
                                    const Text('Здесь появятся ваши заказы',
                                        style: TextStyle(color: futureSoft))
                                ],
                                if (_order == null &&
                                    _checkout != null &&
                                    _paymentMode == 'online')
                                  Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: TextField(
                                          controller: _receiptEmail,
                                          onChanged: (_) {
                                            if (_error != null)
                                              setState(() => _error = null);
                                          },
                                          enabled: !_busy && _intent == null,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          autocorrect: false,
                                          decoration: const InputDecoration(
                                              labelText: 'Email для чека',
                                              helperText:
                                                  'ЮKassa отправит электронный чек на эту почту',
                                              prefixIcon: Icon(Icons
                                                  .alternate_email_rounded)))),
                                if (_error != null)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: Text(_error!,
                                          style: const TextStyle(
                                              color: Color(0xFFD5556A),
                                              fontSize: 13))),
                              ])),
                          Padding(
                              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_order == null && _checkout != null)
                                      FutureAction(
                                          label: _quote == null
                                              ? 'Повторить расчёт'
                                              : _paymentMode == 'cash'
                                                  ? ((_quote?['total_kopeks']
                                                                  as num? ??
                                                              1) ==
                                                          0
                                                      ? 'Заказать за баллы'
                                                      : 'Оплатить в заведении · ${_money(source?['amount'])} ₽')
                                                  : 'Оплатить ${_money(source?['amount'])} ₽',
                                          onTap: _busy
                                              ? null
                                              : _quote == null
                                                  ? () => _run(_initial)
                                                  : _error == null &&
                                                          (_quote!['redeem_points']
                                                                          as num? ??
                                                                      0)
                                                                  .toInt() ==
                                                              _redeemPoints
                                                      ? () => _run(_pay)
                                                      : null),
                                    if (_intent != null &&
                                        _order == null &&
                                        _error != null)
                                      TextButton(
                                          onPressed: _busy
                                              ? null
                                              : () => _run(_abandon),
                                          child: const Text(
                                              'Изменить оформление')),
                                    if (state == 'pending' && !cancelling)
                                      FutureAction(
                                          label: 'Проверить оплату',
                                          onTap:
                                              _busy ? null : () => _run(_sync)),
                                    if (state == 'pending' &&
                                        !cancelling &&
                                        _order?['confirmation_url'] != null)
                                      TextButton(
                                          onPressed: _busy
                                              ? null
                                              : () => _run(_openPayment),
                                          child: const Text(
                                              'Открыть страницу оплаты')),
                                    if (terminal)
                                      FutureAction(
                                          label: 'Вернуться',
                                          onTap: () =>
                                              Navigator.maybePop(context)),
                                    if (_order?['can_cancel'] == true &&
                                        !cancelling &&
                                        !(delivery &&
                                            _order?['time_offer'] is Map))
                                      TextButton(
                                          onPressed: _busy
                                              ? null
                                              : () => _run(_cancel),
                                          child: const Text('Отменить заказ',
                                              style: TextStyle(
                                                  color: futureSoft))),
                                  ])),
                        ]))))));
  }
}

class _ReceiptEmailDialog extends StatefulWidget {
 final String initialEmail;
 const _ReceiptEmailDialog({required this.initialEmail});
 @override State<_ReceiptEmailDialog> createState() => _ReceiptEmailDialogState();
}
class _ReceiptEmailDialogState extends State<_ReceiptEmailDialog> {
 final _form=GlobalKey<FormState>();
 late final TextEditingController _email;
 @override void initState(){super.initState();_email=TextEditingController(text:widget.initialEmail);}
 @override void dispose(){_email.dispose();super.dispose();}
 void _confirm(){if(_form.currentState!.validate())Navigator.of(context).pop(_email.text.trim());}
 @override Widget build(BuildContext context) => AlertDialog(
  scrollable:true,backgroundColor:const Color(0xFFF6FBFF),
  shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(28)),
  icon:const Icon(Icons.mark_email_read_rounded,color:Color(0xFF087F83),size:38),
  title:const Text('Куда отправить чек?',style:TextStyle(color:_ink,fontWeight:FontWeight.w800)),
  content:Form(key:_form,child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
   const Text('Введите почту для получения электронного чека. После этого продолжим оплату.',style:TextStyle(color:_ink,height:1.45)),
   const SizedBox(height:20),
   TextFormField(controller:_email,autofocus:true,keyboardType:TextInputType.emailAddress,
    textInputAction:TextInputAction.done,autofillHints:const [AutofillHints.email],autocorrect:false,
    textCapitalization:TextCapitalization.none,onFieldSubmitted:(_)=>_confirm(),
    validator:(value)=>RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((value??'').trim())?null:'Введите корректную почту, например name@mail.ru',
    decoration:InputDecoration(labelText:'Почта для чека',hintText:'name@mail.ru',errorMaxLines:3,
     prefixIcon:const Icon(Icons.alternate_email_rounded),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16)))),
  ])),
  actions:[TextButton(onPressed:()=>Navigator.of(context).pop(),child:const Text('Вернуться')),
   FilledButton(onPressed:_confirm,style:FilledButton.styleFrom(backgroundColor:const Color(0xFF087F83)),child:const Text('Продолжить оплату'))]);
}
