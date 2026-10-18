import 'package:flutter/material.dart';

class FlowruOrderStyle {
  static const paper = Color(0xFFF6FBFF),
      ink = Color(0xFF0A2B47),
      muted = Color(0xFF50718B),
      aqua = Color(0xFF16D1DD),
      violet = Color(0xFF7A4CFF);
  static const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [aqua, Color(0xFF437CFF), violet, Color(0xFFB992FF)]);
  static BoxDecoration surface({double radius = 24}) => BoxDecoration(
          color: Colors.white.withOpacity(.93),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0C2655A8), blurRadius: 20, offset: Offset(0, 7))
          ]);
}

class FlowruOrderArt extends StatelessWidget {
  final String name;
  final double? width, height;
  final BoxFit fit;
  const FlowruOrderArt(this.name,
      {super.key, this.width, this.height, this.fit = BoxFit.contain});
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/flowru_order_design/$name.png',
          width: width,
          height: height,
          fit: fit,
          cacheWidth: 640,
          errorBuilder: (_, __, ___) => SizedBox(
              width: width,
              height: height,
              child: Icon(
                  name == 'pickup'
                      ? Icons.local_cafe_rounded
                      : name == 'membership'
                          ? Icons.coffee_rounded
                          : Icons.near_me_rounded,
                  size: 40,
                  color: FlowruOrderStyle.violet)));
}

class FlowruGradientAction extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final IconData icon;
  const FlowruGradientAction(
      {super.key,
      required this.label,
      required this.onTap,
      this.busy = false,
      this.icon = Icons.arrow_forward_rounded});
  @override
  Widget build(BuildContext context) => Opacity(
      opacity: onTap == null ? 0.5 : 1.0,
      child: Container(
          decoration: BoxDecoration(
              gradient: FlowruOrderStyle.gradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x237A4CFF),
                    blurRadius: 20,
                    offset: Offset(0, 8))
              ]),
          child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                  onTap: busy ? null : onTap,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 17),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (busy)
                              const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                            else ...[
                              Flexible(
                                  child: Text(label,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16))),
                              const SizedBox(width: 9),
                              Icon(icon, color: Colors.white, size: 20)
                            ]
                          ]))))));
}

class FlowruAddressTile extends StatelessWidget {
  final String address;
  final VoidCallback onTap;
  const FlowruAddressTile(
      {super.key, required this.address, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: FlowruOrderStyle.surface(radius: 20),
      child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: FlowruOrderStyle.violet, size: 27),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('Куда доставить?',
                              style: TextStyle(
                                  color: FlowruOrderStyle.ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                              address.isEmpty ? 'Укажите адрес и дом' : address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: FlowruOrderStyle.muted, fontSize: 12))
                        ])),
                    const SizedBox(width: 6),
                    const FlowruOrderArt('delivery', width: 65, height: 52),
                    const Icon(Icons.chevron_right_rounded,
                        color: FlowruOrderStyle.muted, size: 20)
                  ])))));
}
