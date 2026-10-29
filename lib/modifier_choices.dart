import 'package:flutter/material.dart';

/// A readable modifier group. Its natural height follows text and accessibility scaling.
class FlowruModifierChoices extends StatelessWidget {
  final String title;
  final String summary;
  final String rule;
  final bool expanded;
  final bool requiredChoice;
  final VoidCallback onExpand;
  final List<Widget> options;
  const FlowruModifierChoices({super.key, required this.title,
    required this.summary, required this.rule, required this.expanded,
    required this.requiredChoice, required this.onExpand, required this.options});
  static const ink = Color(0xFF172B3A);
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: expanded ? const Color(0xFF1796A2) : const Color(0xFFE0E8E9), width: expanded ? 1.5 : 1),
      boxShadow: const [BoxShadow(color: Color(0x09172B3A),blurRadius: 18,offset: Offset(0,6))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Material(color: Colors.transparent, child: InkWell(
        borderRadius: BorderRadius.circular(24), onTap: onExpand,
        child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,style: const TextStyle(color: ink,fontSize: 19,fontWeight: FontWeight.w800,height: 1.2)),
            const SizedBox(height: 7),
            Text(summary,style: const TextStyle(color: Color(0xFF45616B),fontSize: 15,height: 1.35)),
            if (requiredChoice) ...[const SizedBox(height: 7),
              const Text('Обязательный выбор',style: TextStyle(color: Color(0xFF9D4A20),fontSize: 13,fontWeight: FontWeight.w700))],
          ])),
          const SizedBox(width: 12),
          Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,color: ink,size: 28),
        ])))),
      if (expanded) Padding(padding: const EdgeInsets.fromLTRB(12,0,12,12),child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,children: [
          Padding(padding: const EdgeInsets.fromLTRB(4,0,4,10),child: Text(rule,
            style: const TextStyle(color: Color(0xFF45616B),fontSize: 14,height: 1.35))),
          ...options,
        ])),
    ]));
}

class FlowruModifierOption extends StatelessWidget {
  final String title;
  final String price;
  final bool selected;
  final bool multiple;
  final bool enabled;
  final VoidCallback onTap;
  const FlowruModifierOption({super.key,required this.title,required this.price,
    required this.selected,required this.multiple,required this.onTap,this.enabled=true});
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$title, $price',selected: selected,enabled: enabled,button: true,
    child: Padding(padding: const EdgeInsets.only(top: 6),child: Material(
      color: selected ? const Color(0xFFE3F6F3) : const Color(0xFFF4F7F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),side: BorderSide(
        color: selected ? const Color(0xFF148A87) : const Color(0xFFE7ECEA),width: selected ? 1.5 : 1)),
      child: InkWell(onTap: enabled ? onTap : null,borderRadius: BorderRadius.circular(18),
        child: Padding(padding: const EdgeInsets.all(15),child: Row(crossAxisAlignment: CrossAxisAlignment.start,children: [
          Icon(selected ? Icons.check_circle_rounded : multiple ? Icons.add_circle_outline_rounded : Icons.radio_button_unchecked_rounded,
            color: selected ? const Color(0xFF08766F) : const Color(0xFF637B80),size: 26),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
            Text(title,style: TextStyle(color: enabled || selected ? const Color(0xFF172B3A) : const Color(0xFF6A7D80),fontSize: 17,height: 1.3,fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            Text(price,style: const TextStyle(color: Color(0xFF08766F),fontSize: 16,height: 1.2,fontWeight: FontWeight.w800)),
            if (selected) ...[const SizedBox(height: 5),const Text('Выбрано',style: TextStyle(color: Color(0xFF08766F),fontSize: 13,fontWeight: FontWeight.w600))],
          ])),
        ]))))));
}
