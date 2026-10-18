import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'flowru_order_design.dart';
import 'package:flutter/material.dart';
import 'order_payment_checkout.dart';

const _paper = Color(0xFFF6FBFF),
    _accent = Color(0xFF7A4CFF),
    _text = Color(0xFF0A2B47);

class DeliveryPlacesScreen extends StatefulWidget {
  final OrderPaymentRequest request;
  final Future<void> Function(Map<String, dynamic>) onSelect;
  const DeliveryPlacesScreen(
      {super.key, required this.request, required this.onSelect});
  @override
  State<DeliveryPlacesScreen> createState() => _DeliveryPlacesState();
}

class _DeliveryPlacesState extends State<DeliveryPlacesScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await widget.request(
          '/client/delivery/establishments?q=${Uri.encodeQueryComponent(_search.text.trim())}',
          'GET',
          null);
      if (mounted)
        setState(() => _items = (data['items'] as List? ?? [])
            .whereType<Map>()
            .map((r) => Map<String, dynamic>.from(r))
            .toList());
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _rub(dynamic n) => '${((n as num? ?? 0) / 100).toStringAsFixed(0)} ₽';
  Widget _tag(String text, IconData icon) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration:
          BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: _accent),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(
                fontSize: 12, color: _text, fontWeight: FontWeight.w600))
      ]));
  Widget _place(Map<String, dynamic> r) {
    final open = r['open'] == true;
    return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: open && !_busy
                    ? () async {
                        setState(() => _busy = true);
                        try {
                          await widget.onSelect(r);
                        } catch (e) {
                          if (mounted)
                            setState(() => _error =
                                e.toString().replaceFirst('Exception: ', ''));
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      }
                    : null,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height: 190,
                          child: Stack(fit: StackFit.expand, children: [
                            Container(
                                decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                  Color(0xFFE0F4F6),
                                  Color(0xFFECE5FF)
                                ])),
                                child: const Icon(Icons.restaurant_rounded,
                                    size: 58, color: _accent)),
                            if ((r['image_url'] ?? '').toString().isNotEmpty)
                              Image.network(r['image_url'].toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink()),
                            Positioned(
                                top: 14,
                                left: 14,
                                child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 11, vertical: 7),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Text(
                                        open
                                            ? 'Принимают заказы'
                                            : 'Сейчас закрыто',
                                        style: TextStyle(
                                            color: open
                                                ? const Color(0xFF078D75)
                                                : const Color(0xFF3F647A),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)))),
                          ])),
                      Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text((r['name'] ?? 'Заведение').toString(),
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: _text)),
                                const SizedBox(height: 5),
                                Text((r['address'] ?? '').toString(),
                                    style: const TextStyle(
                                        color: Color(0xFF3F647A),
                                        fontSize: 13)),
                                const SizedBox(height: 13),
                                Wrap(spacing: 7, runSpacing: 7, children: [
                                  _tag(
                                      'Доставка от ${_rub(r['fee_from_kopeks'])}',
                                      Icons.delivery_dining_rounded),
                                  if ((r['minimum_from_kopeks'] as num? ?? 0) >
                                      0)
                                    _tag(
                                        'Заказ от ${_rub(r['minimum_from_kopeks'])}',
                                        Icons.shopping_bag_outlined),
                                  if (r['free_from_kopeks'] != null)
                                    _tag(
                                        'Бесплатно от ${_rub(r['free_from_kopeks'])}',
                                        Icons.auto_awesome_rounded)
                                ]),
                                const SizedBox(height: 15),
                                Row(children: [
                                  Expanded(
                                      child: Text(
                                          open
                                              ? 'Открыть меню'
                                              : '${r['hours'] ?? ''}',
                                          style: const TextStyle(
                                              color: _accent,
                                              fontWeight: FontWeight.w700))),
                                  Icon(
                                      open
                                          ? Icons.arrow_forward_rounded
                                          : Icons.schedule_rounded,
                                      color: _accent,
                                      size: 22)
                                ]),
                              ])),
                    ]))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
          backgroundColor: _paper,
          surfaceTintColor: Colors.transparent,
          foregroundColor: _text,
          title: const Text('Доставка',
              style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            Padding(
                padding: const EdgeInsets.only(right: 14),
                child: IconButton(
                    tooltip: 'Обновить заведения',
                    onPressed: _busy ? null : _load,
                    icon: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF249FFF))))
          ]),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      children: [
                        Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color(0xFFEDE8FF),
                                  Color(0xFFDDFBFC)
                                ]),
                                borderRadius: BorderRadius.circular(26)),
                            child: Row(children: [
                              const Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('К вашей двери',
                                        style: TextStyle(
                                            fontSize: 26,
                                            height: 1.12,
                                            fontWeight: FontWeight.w800,
                                            color: _text)),
                                    SizedBox(height: 9),
                                    Text(
                                        'Меню любимых заведений.\nЗакажите с доставкой.',
                                        style: TextStyle(
                                            color: Color(0xFF50718B),
                                            fontSize: 13,
                                            height: 1.4))
                                  ])),
                              const SizedBox(width: 8),
                              const FlowruOrderArt('delivery',
                                  width: 115, height: 105)
                            ])),
                        const SizedBox(height: 16),
                        TextField(
                            controller: _search,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _load(),
                            style: const TextStyle(color: _text),
                            decoration: InputDecoration(
                                hintStyle: const TextStyle(
                                    color: FlowruOrderStyle.muted),
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Город, улица или заведение',
                                prefixIcon: const Icon(Icons.search_rounded,
                                    color: _accent),
                                suffixIcon: IconButton(
                                    onPressed: _busy ? null : _load,
                                    icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: _accent)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 18),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none))),
                        const SizedBox(height: 22),
                        if (_busy)
                          const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: LinearProgressIndicator(color: _accent)),
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Column(children: [
                                Text(_error!,
                                    style: const TextStyle(
                                        color: Color(0xFFE85B63))),
                                TextButton(
                                    onPressed: _load,
                                    child: const Text('Попробовать снова'))
                              ])),
                        if (!_busy && _error == null && _items.isEmpty)
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Column(children: [
                                Icon(Icons.delivery_dining_rounded,
                                    size: 52, color: _accent),
                                SizedBox(height: 14),
                                Text('Здесь появятся заведения с доставкой',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        color: _text)),
                                SizedBox(height: 8),
                                Text('Пока доступных заведений нет.',
                                    style: TextStyle(color: Color(0xFF3F647A)))
                              ])),
                        ..._items.map(_place),
                      ])))));
}

Future<Map<String, dynamic>?> chooseDeliveryAddress(
        BuildContext context, OrderPaymentRequest request, int establishmentId,
        {Map<String, dynamic>? initialAddress}) =>
    showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: _paper,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => _DeliveryAddressSheet(
            request: request,
            establishmentId: establishmentId,
            initialAddress: initialAddress));

class _DeliveryAddressSheet extends StatefulWidget {
  final OrderPaymentRequest request;
  final int establishmentId;
  final Map<String, dynamic>? initialAddress;
  const _DeliveryAddressSheet(
      {required this.request,
      required this.establishmentId,
      this.initialAddress});
  @override
  State<_DeliveryAddressSheet> createState() => _DeliveryAddressState();
}

class _DeliveryAddressState extends State<_DeliveryAddressSheet> {
  final _address = TextEditingController(),
      _apartment = TextEditingController(),
      _entrance = TextEditingController(),
      _floor = TextEditingController(),
      _note = TextEditingController();
  final _mapController = MapController();
  final List<List<List<LatLng>>> _rings = [];
  List<Polygon> _zones = [];
  LatLng? _point, _center;
  LatLngBounds? _bounds;
  bool _loading = true, _saving = false, _locating = false, _inZone = false;
  String? _error;
  int _selection = 0;
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    final a = widget.initialAddress;
    if (a != null) {
      _address.text = (a['address'] ?? '').toString();
      _apartment.text = (a['apartment'] ?? '').toString();
      _entrance.text = (a['entrance'] ?? '').toString();
      _floor.text = (a['floor'] ?? '').toString();
      _note.text = (a['delivery_note'] ?? '').toString();
      final lat = num.tryParse('${a['latitude']}'),
          lon = num.tryParse('${a['longitude']}');
      if (lat != null && lon != null)
        _point = LatLng(lat.toDouble(), lon.toDouble());
    }
    _loadMap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_address, _apartment, _entrance, _floor, _note]) {
      c.dispose();
    }
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadMap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.request(
          '/client/order-commerce/delivery-map?establishment_id=${widget.establishmentId}',
          'GET',
          null);
      final rings = <List<List<LatLng>>>[];
      for (final z in (r['zones'] as List? ?? [])) {
        final g = z['geometry'];
        if (g is! Map || g['type'] != 'Polygon') continue;
        rings.add((g['coordinates'] as List)
            .map((ring) => (ring as List)
                .map((c) =>
                    LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
                .toList())
            .toList());
      }
      if (!mounted) return;
      setState(() {
        _rings.clear();
        _rings.addAll(rings);
        _zones = rings
            .map((r) => Polygon(
                points: r.first,
                holePointsList: r.length > 1 ? r.sublist(1) : null,
                color: _accent.withOpacity(.16),
                borderColor: _accent,
                borderStrokeWidth: 2.5))
            .toList();
        final points = rings.expand((r) => r.first).toList();
        _bounds = points.isEmpty ? null : LatLngBounds.fromPoints(points);
        _center = LatLng((r['latitude'] as num).toDouble(),
            (r['longitude'] as num).toDouble());
        if (_point != null)
          _inZone = _rings.any((r) =>
              _insideRing(_point!, r.first) &&
              !r.skip(1).any((h) => _insideRing(_point!, h)));
        if (points.isEmpty) _error = 'Заведение пока не указало зоны доставки';
      });
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Boundary counts as inside, matching server-side zone validation.
  bool _insideRing(LatLng p, List<LatLng> ring) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[j], b = ring[i];
      final cross = (p.longitude - a.longitude) * (b.latitude - a.latitude) -
          (p.latitude - a.latitude) * (b.longitude - a.longitude);
      if (cross.abs() < 1e-9 &&
          p.longitude >= math.min(a.longitude, b.longitude) - 1e-9 &&
          p.longitude <= math.max(a.longitude, b.longitude) + 1e-9 &&
          p.latitude >= math.min(a.latitude, b.latitude) - 1e-9 &&
          p.latitude <= math.max(a.latitude, b.latitude) + 1e-9) return true;
      if ((a.latitude > p.latitude) != (b.latitude > p.latitude) &&
          p.longitude <
              (b.longitude - a.longitude) *
                      (p.latitude - a.latitude) /
                      (b.latitude - a.latitude) +
                  a.longitude) inside = !inside;
    }
    return inside;
  }

  bool _contains(LatLng p) => _rings.any((r) =>
      _insideRing(p, r.first) && !r.skip(1).any((h) => _insideRing(p, h)));
  void _select(LatLng point) {
    if (_saving) return;
    _debounce?.cancel();
    final generation = ++_selection;
    final inside = _contains(point);
    setState(() {
      _point = point;
      _inZone = inside;
      _address.clear();
      _locating = inside;
      _error = inside
          ? null
          : 'Сюда пока не доставляем. Выберите дом в выделенной зоне.';
    });
    if (inside)
      _debounce = Timer(
          const Duration(milliseconds: 450), () => _reverse(point, generation));
  }

  Future<void> _reverse(LatLng p, int generation) async {
    try {
      final r = await widget
          .request('/client/order-commerce/delivery-map/reverse', 'POST', {
        'establishment_id': widget.establishmentId,
        'latitude': p.latitude,
        'longitude': p.longitude
      });
      if (!mounted || generation != _selection) return;
      setState(() {
        _address.text = (r['address'] ?? '').toString();
        _error =
            r['needs_house'] == true ? 'Уточните номер дома в адресе' : null;
      });
    } catch (e) {
      if (mounted && generation == _selection)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && generation == _selection)
        setState(() => _locating = false);
    }
  }

  Future<void> _confirm() async {
    if (_saving || _locating || !_inZone || _point == null) return;
    if (_address.text.trim().length < 5) {
      setState(() => _error = 'Уточните улицу и номер дома');
      return;
    }
    final p = _point!;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final r = await widget
          .request('/client/order-commerce/delivery-map/address', 'POST', {
        'establishment_id': widget.establishmentId,
        'address': _address.text.trim(),
        'latitude': p.latitude,
        'longitude': p.longitude
      });
      if (mounted)
        Navigator.pop(context, {
          ...r,
          'address': _address.text.trim(),
          'latitude': p.latitude,
          'longitude': p.longitude,
          'apartment': _apartment.text.trim(),
          'entrance': _entrance.text.trim(),
          'floor': _floor.text.trim(),
          'delivery_note': _note.text.trim()
        });
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController c, String label, {int limit = 40}) =>
      TextField(
          controller: c,
          maxLength: limit,
          enabled: !_saving,
          style: const TextStyle(color: _text, fontSize: 14),
          decoration: InputDecoration(
              labelText: label,
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              labelStyle:
                  const TextStyle(color: Color(0xFF718299), fontSize: 12),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _accent.withOpacity(.15))),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _accent, width: 2))));
  @override
  Widget build(BuildContext context) => SizedBox(
      height: MediaQuery.of(context).size.height * .88,
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(children: [
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Адрес доставки',
                        style: TextStyle(
                            color: _text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('Выберите дом в выделенной зоне',
                        style:
                            TextStyle(color: Color(0xFF718299), fontSize: 12))
                  ])),
              IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: _text)),
            ])),
        Expanded(
            child: SingleChildScrollView(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(children: [
                  if (_center != null && _bounds != null)
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: SizedBox(
                                height: math.min(330.0,
                                    MediaQuery.of(context).size.height * .39),
                                child: Stack(children: [
                                  FlutterMap(
                                      mapController: _mapController,
                                      options: MapOptions(
                                          initialCenter: _center!,
                                          initialCameraFit: CameraFit.bounds(
                                              bounds: _bounds!,
                                              padding:
                                                  const EdgeInsets.all(28)),
                                          maxZoom: 19,
                                          onTap: (_, p) => _select(p)),
                                      children: [
                                        TileLayer(
                                            urlTemplate:
                                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName:
                                                'ru.flowru.client'),
                                        PolygonLayer(polygons: [
                                          Polygon(
                                              points: [
                                                LatLng(_bounds!.south - 2,
                                                    _bounds!.west - 2),
                                                LatLng(_bounds!.south - 2,
                                                    _bounds!.east + 2),
                                                LatLng(_bounds!.north + 2,
                                                    _bounds!.east + 2),
                                                LatLng(_bounds!.north + 2,
                                                    _bounds!.west - 2)
                                              ],
                                              holePointsList: _rings
                                                  .map((r) => r.first)
                                                  .toList(),
                                              color: const Color(0x8893A2B1)),
                                          ..._rings
                                              .expand((r) => r.skip(1))
                                              .map((h) => Polygon(
                                                  points: h,
                                                  color:
                                                      const Color(0x8893A2B1))),
                                          ..._zones,
                                        ]),
                                        if (_point != null)
                                          MarkerLayer(markers: [
                                            Marker(
                                                point: _point!,
                                                width: 44,
                                                height: 48,
                                                alignment: Alignment.topCenter,
                                                child: Icon(
                                                    Icons.location_on_rounded,
                                                    color: _inZone
                                                        ? _accent
                                                        : const Color(
                                                            0xFFE75467),
                                                    size: 44))
                                          ]),
                                        Align(
                                            alignment: Alignment.bottomRight,
                                            child: Material(
                                                color: Colors.white
                                                    .withOpacity(.9),
                                                child: InkWell(
                                                    onTap: () => launchUrl(
                                                        Uri.parse(
                                                            'https://www.openstreetmap.org/copyright')),
                                                    child: const Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 6,
                                                                vertical: 3),
                                                        child: Text(
                                                            '© OpenStreetMap contributors',
                                                            style: TextStyle(
                                                                fontSize: 9,
                                                                color:
                                                                    _text)))))),
                                      ]),
                                  Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(.94),
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.circle,
                                                    color: _accent, size: 8),
                                                SizedBox(width: 6),
                                                Text('Зона доставки',
                                                    style: TextStyle(
                                                        color: _text,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700))
                                              ]))),
                                ])))),
                  if (_loading)
                    const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: _accent)),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_locating)
                              const Row(children: [
                                SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: _accent)),
                                SizedBox(width: 8),
                                Text('Определяем адрес…',
                                    style:
                                        TextStyle(color: _accent, fontSize: 12))
                              ]),
                            if (_error != null)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(_error!,
                                      style: TextStyle(
                                          color: _inZone
                                              ? const Color(0xFF718299)
                                              : const Color(0xFFD74C60),
                                          fontSize: 12))),
                            if (_center == null && !_loading)
                              TextButton(
                                  onPressed: _loadMap,
                                  child: const Text('Загрузить карту снова')),
                            _field(_address, 'Улица и дом', limit: 250),
                            const SizedBox(height: 14),
                            Row(children: [
                              Expanded(child: _field(_apartment, 'Квартира')),
                              const SizedBox(width: 16),
                              Expanded(child: _field(_entrance, 'Подъезд')),
                              const SizedBox(width: 16),
                              Expanded(child: _field(_floor, 'Этаж', limit: 20))
                            ]),
                            const SizedBox(height: 14),
                            _field(_note, 'Комментарий курьеру', limit: 300),
                          ])),
                ]))),
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: FlowruGradientAction(
                label: _saving ? 'Сохраняем…' : 'Доставить сюда',
                onTap: _point == null || !_inZone || _saving || _locating
                    ? null
                    : _confirm)),
      ]));
}

class FlowruOrderEntry extends StatefulWidget {
  final bool delivery;
  final VoidCallback onTap;
  const FlowruOrderEntry(
      {super.key, required this.delivery, required this.onTap});
  @override
  State<FlowruOrderEntry> createState() => _FlowruOrderEntryState();
}

class _FlowruOrderEntryState extends State<FlowruOrderEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
      vsync: this, duration: Duration(seconds: widget.delivery ? 12 : 9));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
      aspectRatio: 1.12,
      child: LayoutBuilder(builder: (context, box) {
        final compact = box.maxWidth < 175;
        return Semantics(
            button: true,
            label: widget.delivery ? 'Доставка' : 'Самовывоз',
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(24),
                    highlightColor: Colors.white.withOpacity(.08),
                    splashColor: Colors.white.withOpacity(.16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 7, 12, 5),
                                  child: AnimatedBuilder(
                                      animation: _motion,
                                      builder: (context, child) {
                                        final t = _motion.value * math.pi * 2;
                                        return Transform.translate(
                                            offset: Offset(math.sin(t) * 1.5,
                                                math.cos(t) * 2),
                                            child: child);
                                      },
                                      child: FlowruOrderArt(
                                          widget.delivery
                                              ? 'delivery'
                                              : 'pickup',
                                          fit: BoxFit.contain)))),
                          Padding(
                              padding: EdgeInsets.fromLTRB(
                                  compact ? 9 : 13, 0, compact ? 9 : 13, 7),
                              child: Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                      Text(
                                          widget.delivery
                                              ? 'Доставка'
                                              : 'Самовывоз',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: FlowruOrderStyle.ink,
                                              fontWeight: FontWeight.w800,
                                              fontSize: compact ? 14 : 18)),
                                      const SizedBox(height: 3),
                                      Text(
                                          widget.delivery
                                              ? 'К вашей двери'
                                              : 'Забрать по пути',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: FlowruOrderStyle.ink
                                                  .withOpacity(.80),
                                              fontSize: compact ? 10 : 12))
                                    ])),
                                const SizedBox(width: 3),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: FlowruOrderStyle.ink, size: 18)
                              ])),
                        ]))));
      }));
}

class FlowruReceiveOption extends StatelessWidget {
  final bool delivery, selected;
  final VoidCallback onTap;
  const FlowruReceiveOption(
      {super.key,
      required this.delivery,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
          color: selected ? null : Colors.white.withOpacity(.7),
          gradient: selected ? FlowruOrderStyle.gradient : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? const [
                  BoxShadow(
                      color: Color(0x187A4CFF),
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ]
              : null),
      child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            delivery
                                ? Icons.delivery_dining_rounded
                                : Icons.shopping_bag_outlined,
                            color: selected ? Colors.white : _text,
                            size: 20),
                        const SizedBox(width: 7),
                        Flexible(
                            child: Text(delivery ? 'Доставка' : 'Самовывоз',
                                style: TextStyle(
                                    color: selected ? Colors.white : _text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)))
                      ])))));
}

class FlowruReceiveSwitch extends StatelessWidget {
  final bool pickup, delivery;
  final String value;
  final ValueChanged<String> onChanged;
  const FlowruReceiveSwitch(
      {super.key,
      required this.pickup,
      required this.delivery,
      required this.value,
      required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final both = pickup && delivery;
    return LayoutBuilder(
        builder: (context, box) => SizedBox(
            height: 52,
            child: Stack(children: [
              AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  left: both && value == 'delivery' ? box.maxWidth / 2 : 0,
                  top: 0,
                  bottom: 0,
                  width: both ? box.maxWidth / 2 : box.maxWidth,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: _accent.withOpacity(.09),
                          borderRadius: BorderRadius.circular(14)))),
              AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: both && value == 'delivery' ? box.maxWidth / 2 : 0,
                  bottom: 0,
                  width: both ? box.maxWidth / 2 : box.maxWidth,
                  child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                          gradient: FlowruOrderStyle.gradient,
                          borderRadius: BorderRadius.circular(3)))),
              Row(children: [
                if (pickup) Expanded(child: _tab(false)),
                if (delivery) Expanded(child: _tab(true))
              ]),
            ])));
  }

  Widget _tab(bool d) {
    final selected = value == (d ? 'delivery' : 'pickup');
    return Semantics(
        selected: selected,
        button: true,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(d ? 'delivery' : 'pickup'),
                child: SizedBox(
                    height: 52,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                              scale: selected ? 1.08 : 1,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                  d
                                      ? Icons.delivery_dining_rounded
                                      : Icons.shopping_bag_outlined,
                                  size: 22,
                                  color: selected
                                      ? _accent
                                      : const Color(0xFF85929F))),
                          const SizedBox(width: 8),
                          if (selected)
                            const Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: Icon(Icons.check_rounded,
                                    color: _accent, size: 15)),
                          Text(d ? 'Доставка' : 'Самовывоз',
                              style: TextStyle(
                                  color: selected
                                      ? _text
                                      : const Color(0xFF85929F),
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w500)),
                        ])))));
  }
}

class FlowruAddressAction extends StatelessWidget {
  final String? address;
  final VoidCallback onTap;
  const FlowruAddressAction({super.key, this.address, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Row(children: [
                Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        gradient: FlowruOrderStyle.gradient,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.near_me_rounded,
                        color: Colors.white, size: 18)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          address == null
                              ? 'Куда доставить?'
                              : 'Адрес доставки',
                          style: TextStyle(
                              color: address == null
                                  ? _text
                                  : const Color(0xFF85929F),
                              fontSize: address == null ? 14 : 11,
                              fontWeight: FontWeight.w700)),
                      if (address != null)
                        Text(address!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                    ])),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: _accent, size: 22),
              ]))));
}

class FlowruQuickOrder extends StatefulWidget {
  final VoidCallback onTap;
  const FlowruQuickOrder({super.key, required this.onTap});
  @override
  State<FlowruQuickOrder> createState() => _FlowruQuickOrderState();
}

class _FlowruQuickOrderState extends State<FlowruQuickOrder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  @override
  void initState() {
    super.initState();
    _motion =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      label: 'Заказать онлайн. Выбрать заведение и открыть меню',
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    AnimatedBuilder(
                        animation: _motion,
                        builder: (context, child) => Transform.translate(
                            offset: Offset(
                                0, -5 * math.sin(_motion.value * math.pi)),
                            child: child),
                        child: const FlowruOrderArt('pickup',
                            width: 66, height: 64)),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Заказать онлайн',
                              style: TextStyle(
                                  color: _text,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -.5)),
                          SizedBox(height: 4),
                          Text('Меню · самовывоз · доставка',
                              style: TextStyle(
                                  color: _text,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500))
                        ])),
                    const SizedBox(width: 8),
                    Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: FlowruOrderStyle.gradient),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 22)),
                  ])))));
}
