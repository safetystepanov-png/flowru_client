import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart' show AuthStorage, FlowApi;

const _ink=Color(0xFF25354C);
const _muted=Color(0xFF748197);
String _date(dynamic value){final d=DateTime.tryParse('$value')?.toLocal();return d==null?'':'${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';}
String _value(Map<String,dynamic> c){
 final value='${c['value'] ?? ''}'.replaceFirst(RegExp(r'\.0$'),'');
 return switch('${c['coupon_type']}'){
 'discount_percent'||'percent'=>'−$value%',
 'discount_amount'||'amount'=>'−$value ₽',
 'points'||'bonus_points'=>'+$value баллов',
 _=>'Ваш подарок'};
}
class AppBenefitsScreen extends StatefulWidget {
 final Future<void> Function() onCertificates;
 const AppBenefitsScreen({super.key,required this.onCertificates});
 @override State<AppBenefitsScreen> createState()=>_AppBenefitsScreenState();
}
class _AppBenefitsScreenState extends State<AppBenefitsScreen> with WidgetsBindingObserver {
 List<Map<String,dynamic>> _items=[];bool _loading=true,_busy=false;String? _error;Timer? _timer;
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);unawaited(_load());_timer=Timer.periodic(const Duration(seconds:20),(_){if(mounted && ModalRoute.of(context)?.isCurrent==true)unawaited(_load(quiet:true));});}
 @override void dispose(){_timer?.cancel();WidgetsBinding.instance.removeObserver(this);super.dispose();}
 @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed)unawaited(_load(quiet:true));}
 Future<void> _load({bool quiet=false}) async {
  if(_busy)return;_busy=true;
  if(!quiet && mounted)setState((){_loading=true;_error=null;});
  try{
   final token=await AuthStorage.access();if(token==null)throw StateError('auth');
   final data=await FlowApi().orderPaymentRequest('/client/inbox/coupons','GET',null,token);
   final rows=(data['items'] as List? ?? []).map((x)=>Map<String,dynamic>.from(x as Map)).toList();
   if(mounted)setState((){_items=rows;_loading=false;_error=null;});
  }catch(_){if(mounted)setState((){_loading=false;_error='Не удалось обновить купоны. Попробуйте ещё раз.';});}
  finally{_busy=false;}
 }
 Future<void> _details(Map<String,dynamic> c) async {
  // Refresh immediately before opening: an administrator may have revoked the coupon.
  await _load(quiet:true);if(!mounted)return;
  Map<String,dynamic>? current;
  for(final item in _items){if(item['id']==c['id']){current=item;break;}}
  if(current==null || _error!=null){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(_error ?? 'Этот купон больше недоступен')));return;}
  final coupon=current;
  await showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(ctx)=>Container(
   padding:const EdgeInsets.fromLTRB(26,24,26,32),decoration:const BoxDecoration(color:Color(0xFFF8FAFF),borderRadius:BorderRadius.vertical(top:Radius.circular(32))),
   child:SafeArea(top:false,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Expanded(child:Text('Ваш купон',style:TextStyle(fontSize:14,color:_muted))),IconButton(onPressed:()=>Navigator.pop(ctx),icon:const Icon(Icons.close_rounded))]),
    Text(_value(coupon),style:const TextStyle(fontSize:44,fontWeight:FontWeight.w900,color:_ink)),const SizedBox(height:10),
    Text('${coupon['title'] ?? 'Подарок'}',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800,color:_ink)),const SizedBox(height:6),
    Text('${coupon['establishment_name'] ?? ''}',style:const TextStyle(color:_muted)),const SizedBox(height:24),
    const Text('Как использовать',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:_ink)),const SizedBox(height:8),
    const Text('Покажите купон сотруднику до оплаты. Сотрудник проверит условия и применит предложение.',style:TextStyle(height:1.5,color:_muted)),
    const SizedBox(height:18),
    if(coupon['valid_from']!=null)Text('Действует с ${_date(coupon['valid_from'])}',style:const TextStyle(color:_ink)),
    Text(coupon['valid_to']==null?'Без ограничения по дате':'Действует до ${_date(coupon['valid_to'])}',style:const TextStyle(color:_ink)),
    if('${coupon['conditions'] ?? ''}'.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text('${coupon['conditions']}',style:const TextStyle(color:_muted,height:1.5))),
    const SizedBox(height:10),Text('Осталось использований: ${(coupon['usage_limit'] as num? ?? 1).toInt()-(coupon['used_count'] as num? ?? 0).toInt()}',style:const TextStyle(color:_muted)),
    const SizedBox(height:12),Text('Купон №${coupon['id']}',style:const TextStyle(color:_muted,fontSize:12)),const SizedBox(height:20),
    SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Понятно')))
   ])))));
 }
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xFFF5F7FC),
 appBar:AppBar(backgroundColor:const Color(0xFFF5F7FC),title:const Text('Купоны и сертификаты',style:TextStyle(color:_ink,fontWeight:FontWeight.w800,fontSize:20))),
 body:RefreshIndicator(onRefresh:()=>_load(),child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(20,12,20,40),children:[
  Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFE0F9F0),Color(0xFFECE6FF)]),borderRadius:BorderRadius.circular(30)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.card_giftcard_rounded,size:32,color:_ink),SizedBox(height:16),Text('Приятное —\nдля вас.',style:TextStyle(fontSize:32,height:1.1,fontWeight:FontWeight.w900,color:_ink)),SizedBox(height:12),Text('Личные предложения ваших заведений.',style:TextStyle(color:_muted))])),
  const SizedBox(height:16),
  Card(elevation:0,color:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24)),child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:20,vertical:10),leading:const Icon(Icons.redeem_rounded,color:Color(0xFF8C6ADB)),title:const Text('Подарочные сертификаты',style:TextStyle(fontWeight:FontWeight.w800,color:_ink)),subtitle:const Text('Мои сертификаты и ввод кода'),trailing:const Icon(Icons.arrow_forward_rounded),onTap:() async {await widget.onCertificates();if(mounted)unawaited(_load(quiet:true));})),
  const Padding(padding:EdgeInsets.fromLTRB(4,24,4,12),child:Text('Мои купоны',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:_ink))),
  if(_loading)const Padding(padding:EdgeInsets.all(24),child:Center(child:CircularProgressIndicator())),
  if(_error!=null)Column(children:[Text(_error!,style:const TextStyle(color:_muted)),TextButton(onPressed:()=>_load(),child:const Text('Повторить'))]),
  if(!_loading && _error==null && _items.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Text('Активных купонов пока нет. Когда заведение подарит вам купон, он появится здесь.',textAlign:TextAlign.center,style:TextStyle(color:_muted,height:1.5))),
  for(final c in _items)Padding(padding:const EdgeInsets.only(bottom:12),child:Material(color:Colors.white,borderRadius:BorderRadius.circular(26),child:InkWell(borderRadius:BorderRadius.circular(26),onTap:()=>_details(c),child:Padding(padding:const EdgeInsets.all(22),child:Row(children:[Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFF0EAFF),borderRadius:BorderRadius.circular(18)),child:const Icon(Icons.local_offer_rounded,color:Color(0xFF9471DA))),const SizedBox(width:16),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(_value(c),style:const TextStyle(color:_ink,fontSize:27,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text('${c['title']}',style:const TextStyle(color:_ink,fontWeight:FontWeight.w700)),const SizedBox(height:5),Text('${c['establishment_name']}',style:const TextStyle(color:_muted,fontSize:12))])),const Icon(Icons.chevron_right_rounded,color:_muted)])))))
 ])));
}
