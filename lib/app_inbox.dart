import 'client_benefits.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'main.dart' show AuthStorage, FlowApi, ApiError;

final appInboxNavigatorKey=GlobalKey<NavigatorState>();
final _inboxSignal=ValueNotifier<int>(0);
void refreshAppInbox(){_inboxSignal.value++;}
const _ink=Color(0xFF22334D);
const _muted=Color(0xFF718098);
const _aqua=Color(0xFF78E5D4);
Future<Map<String,dynamic>> _call(String path,[String method='GET']) async {
 final token=await AuthStorage.access();
 if(token==null || token.isEmpty)throw StateError('Войдите в приложение');
 return FlowApi().orderPaymentRequest(path,method,null,token);
}
IconData _icon(String kind)=>switch(kind){'coupon'=>Icons.local_offer_rounded,'birthday'=>Icons.cake_rounded,'prize'=>Icons.emoji_events_rounded,'raffle'=>Icons.auto_awesome_rounded,'referral'=>Icons.favorite_rounded,_=>Icons.notifications_rounded};
String _when(dynamic raw){final d=DateTime.tryParse('$raw')?.toLocal();return d==null?'':'${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')} · ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';}

class AppInboxOverlay extends StatefulWidget {
 final Widget child;
 const AppInboxOverlay({super.key,required this.child});
 static Future<void> openInbox(BuildContext context) async {
  final nav=appInboxNavigatorKey.currentState;
  if(nav==null || (await AuthStorage.access())==null)return;
  await nav.push(MaterialPageRoute<void>(builder:(_)=>const AppInboxScreen()));
  _inboxSignal.value++;
 }
 @override State<AppInboxOverlay> createState()=>_AppInboxOverlayState();
}
class _AppInboxOverlayState extends State<AppInboxOverlay> with WidgetsBindingObserver {
 Timer? _timer;bool _busy=false,_hooks=false,_enabled=false;int _unread=0;String? _accountToken;
 StreamSubscription<RemoteMessage>? _foreground,_opened;
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);_inboxSignal.addListener(_refresh);_timer=Timer.periodic(const Duration(seconds:20),(_)=>_refresh());unawaited(_refresh());}
 @override void dispose(){_timer?.cancel();_foreground?.cancel();_opened?.cancel();_inboxSignal.removeListener(_refresh);WidgetsBinding.instance.removeObserver(this);super.dispose();}
 @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed)unawaited(_refresh());}
 Future<void> _hook() async {
  if(_hooks || Firebase.apps.isEmpty)return;
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert:true,badge:true,sound:true);
  _hooks=true;
  _foreground=FirebaseMessaging.onMessage.listen((m){if(m.data['type']=='app_inbox')unawaited(_refresh());});
  _opened=FirebaseMessaging.onMessageOpenedApp.listen((m){if(m.data['type']=='app_inbox')unawaited(_openPush(m));});
  final initial=await FirebaseMessaging.instance.getInitialMessage();
  if(initial?.data['type']=='app_inbox')unawaited(_openPush(initial!));
 }
 Future<void> _openPush(RemoteMessage message) async {
  await _refresh();
  final id=message.data['message_id'];
  final nav=appInboxNavigatorKey.currentState;
  if(nav==null || !mounted)return;
  await nav.push(MaterialPageRoute<void>(builder:(_)=>AppInboxScreen(initialId:id)));
  unawaited(_refresh());
 }
 Future<void> _refresh() async {
  if(_busy)return;_busy=true;
  try {
   final token=await AuthStorage.access();
   if(!mounted)return;
   if(token==null || token.isEmpty){setState((){_enabled=false;_unread=0;_accountToken=null;});return;}
   if(token!=_accountToken){setState((){_unread=0;_enabled=false;_accountToken=token;});}
   final data=await _call('/client/inbox/summary');
   final currentToken=await AuthStorage.access();
   if(mounted && token==currentToken)setState((){_enabled=true;_unread=(data['unread_count'] as num?)?.toInt() ?? 0;});
   await _hook();
  } catch (_) { /* Existing screens stay usable when inbox is temporarily offline. */ }
  finally {_busy=false;}
 }
 @override Widget build(BuildContext context)=>Stack(children:[widget.child,
  if(_enabled && _unread>0)Positioned(top:MediaQuery.paddingOf(context).top+70,right:16,
   child:Material(color:Colors.transparent,child:Tooltip(message:'Новые сообщения',child:InkWell(
    borderRadius:BorderRadius.circular(22),onTap:() async {await AppInboxOverlay.openInbox(context);unawaited(_refresh());},
    child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:11),decoration:BoxDecoration(
     gradient:const LinearGradient(colors:[Color(0xFFF0FFF9),Color(0xFFF1EDFF)]),border:Border.all(color:Colors.white,width:2),borderRadius:BorderRadius.circular(22),boxShadow:const [BoxShadow(color:Color(0x20364A6A),blurRadius:22,offset:Offset(0,7))]),
     child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.notifications_active_rounded,color:_ink,size:22),const SizedBox(width:7),Text(_unread>99?'99+':'$_unread',style:const TextStyle(color:_ink,fontWeight:FontWeight.w900,fontSize:14))]))))))]);
}

class AppInboxScreen extends StatefulWidget {
 final String? initialId;
 const AppInboxScreen({super.key,this.initialId});
 @override State<AppInboxScreen> createState()=>_AppInboxScreenState();
}
class _AppInboxScreenState extends State<AppInboxScreen> {
 Timer? _refreshTimer;
 List<Map<String,dynamic>> _items=[];bool _loading=true,_more=false,_paging=false;String? _error;bool _openedInitial=false;
 @override void initState(){super.initState();unawaited(_load());_refreshTimer=Timer.periodic(const Duration(seconds:20),(_){if(mounted && ModalRoute.of(context)?.isCurrent==true && !_loading && !_paging)unawaited(_load());});}
 @override void dispose(){_refreshTimer?.cancel();super.dispose();}
 Future<void> _load({bool more=false}) async {
  if(more && (_paging || !_more))return;
  if(mounted)setState((){if(more)_paging=true;else {_loading=true;_error=null;}});
  try {
   final suffix=more && _items.isNotEmpty?'?before=${_items.last['id']}':'';
   final data=await _call('/client/inbox$suffix');
   final rows=(data['items'] as List? ?? []).map((x)=>Map<String,dynamic>.from(x as Map)).toList();
   if(!mounted)return;
   setState((){_items=more?[..._items,...rows]:rows;_more=data['has_more']==true;_loading=false;_paging=false;});
   if(!_openedInitial && widget.initialId!=null){
    Map<String,dynamic>? target;
    for(final item in _items){if('${item['id']}'==widget.initialId){target=item;break;}}
    if(target!=null){_openedInitial=true;await _open(target);}
    else if(_more)unawaited(_load(more:true));
   }
  } catch (_) {if(mounted)setState((){_error='Не удалось загрузить сообщения. Попробуйте ещё раз.';_loading=false;_paging=false;});}
 }
 Future<void> _open(Map<String,dynamic> item) async {
  await Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>_InboxDetail(item:item)));
  if(mounted)unawaited(_load());_inboxSignal.value++;
 }
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xFFF5F8FC),
  appBar:AppBar(backgroundColor:const Color(0xFFF5F8FC),title:const Text('Уведомления',style:TextStyle(color:_ink,fontWeight:FontWeight.w800))),
  body:_loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:()=>_load(),child:ListView(padding:const EdgeInsets.fromLTRB(20,12,20,40),children:[
   Container(padding:const EdgeInsets.all(26),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFE4FBF4),Color(0xFFEEE8FF)]),borderRadius:BorderRadius.circular(30)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.auto_awesome_rounded,color:_ink,size:30),SizedBox(height:18),Text('Всё важное —\nв одном месте.',style:TextStyle(color:_ink,fontSize:28,height:1.08,fontWeight:FontWeight.w900)),SizedBox(height:12),Text('Подарки, предложения и новости ваших заведений.',style:TextStyle(color:_muted,height:1.5))])),
   const SizedBox(height:22),
   if(_error!=null)TextButton(onPressed:()=>_load(),child:Text(_error!)),
   if(_items.isEmpty && _error==null)const Padding(padding:EdgeInsets.all(30),child:Text('Пока сообщений нет. Новые предложения появятся здесь.',textAlign:TextAlign.center,style:TextStyle(color:_muted,height:1.5))),
   for(final item in _items)Padding(padding:const EdgeInsets.only(bottom:12),child:Material(color:Colors.white,borderRadius:BorderRadius.circular(24),child:InkWell(borderRadius:BorderRadius.circular(24),onTap:()=>_open(item),child:Padding(padding:const EdgeInsets.all(18),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Container(width:46,height:46,decoration:BoxDecoration(color:item['read_at']==null?const Color(0xFFE2FAF1):const Color(0xFFF0F3F8),borderRadius:BorderRadius.circular(16)),child:Icon(_icon('${item['kind']}'),color:_ink)),const SizedBox(width:14),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${item['establishment_name'] ?? ''}',style:const TextStyle(color:_muted,fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(height:5),Text('${item['title']}',style:const TextStyle(color:_ink,fontWeight:FontWeight.w800,fontSize:16)),const SizedBox(height:7),Text('${item['body']}',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:_muted,height:1.4)),const SizedBox(height:10),Text(_when(item['created_at']),style:const TextStyle(color:_muted,fontSize:11))])),
    if(item['read_at']==null)Container(width:8,height:8,margin:const EdgeInsets.only(left:8,top:3),decoration:const BoxDecoration(color:Color(0xFFEC8758),shape:BoxShape.circle))]))))),
   if(_more)TextButton(onPressed:_paging?null:()=>_load(more:true),child:Text(_paging?'Загружаем…':'Показать ещё'))
  ])));
}
class _InboxDetail extends StatefulWidget {
 final Map<String,dynamic> item;
 const _InboxDetail({required this.item});
 @override State<_InboxDetail> createState()=>_InboxDetailState();
}
class _InboxDetailState extends State<_InboxDetail> {
 bool _saved=false,_deleted=false;late Map<String,dynamic> _data;Timer? _timer;
 @override void initState(){super.initState();_data=Map<String,dynamic>.from(widget.item);WidgetsBinding.instance.addPostFrameCallback((_){unawaited(_reload());unawaited(_markRead());});_timer=Timer.periodic(const Duration(seconds:15),(_)=>_reload());}
 @override void dispose(){_timer?.cancel();super.dispose();}
 Future<void> _reload() async {
  try{final data=await _call('/client/inbox/${widget.item['id']}');if(mounted)setState(()=>_data=data);}
  on ApiError catch(error){if(error.status==404 && mounted){setState(()=>_deleted=true);_inboxSignal.value++;}}
  catch(_){/* Connection failures must not be interpreted as deletion. */}
 }
 Future<void> _markRead() async {try {await _call('/client/inbox/${widget.item['id']}/read','POST');if(mounted)setState(()=>_saved=true);_inboxSignal.value++;}catch(_){}}
 @override Widget build(BuildContext context){
  if(_deleted)return Scaffold(appBar:AppBar(),body:Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.notifications_off_outlined,size:44,color:_muted),const SizedBox(height:18),const Text('Заведение удалило это сообщение.',textAlign:TextAlign.center,style:TextStyle(color:_ink,fontSize:20)),const SizedBox(height:18),FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('К уведомлениям'))]))));
  final item=_data;final payload=Map<String,dynamic>.from(item['payload'] as Map? ?? {});final prize=payload['prize_token'];
  return Scaffold(backgroundColor:const Color(0xFFF5F8FC),appBar:AppBar(backgroundColor:const Color(0xFFF5F8FC)),body:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(22,10,22,40),child:Container(padding:const EdgeInsets.all(26),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(32)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[_aqua,Color(0xFFD5C4FA)]),borderRadius:BorderRadius.circular(23)),child:Icon(_icon('${item['kind']}'),size:34,color:_ink)),const SizedBox(height:24),Text('${item['establishment_name'] ?? ''}',style:const TextStyle(color:_muted,fontWeight:FontWeight.w700)),const SizedBox(height:8),Text('${item['title']}',style:const TextStyle(fontSize:28,height:1.15,fontWeight:FontWeight.w900,color:_ink)),const SizedBox(height:20),SelectableText('${item['body']}',style:const TextStyle(color:_ink,fontSize:16,height:1.6)),const SizedBox(height:24),
   if(prize!=null)...[const Text('Покажите код сотруднику при получении приза.',style:TextStyle(color:_muted,height:1.5)),const SizedBox(height:12),Center(child:QrImageView(data:'${payload['redeem_url'] ?? prize}',size:220)),SelectableText('$prize',style:const TextStyle(fontSize:12,color:_muted))],
   if(payload['coupon_id']!=null)Padding(padding:const EdgeInsets.only(top:8),child:Text('Купон доступен в профиле, в разделе «Купоны и сертификаты». Заведение может изменить или отозвать предложение.',style:const TextStyle(color:_muted,height:1.5))),
   if(payload['run_id']!=null && prize==null)const Padding(padding:EdgeInsets.only(top:8),child:Text('Карточка розыгрыша находится в предложениях заведения на главном экране.',style:TextStyle(color:_muted,height:1.5))),
   if(!_saved)TextButton(onPressed:_markRead,child:const Text('Отметить прочитанным')),
   const SizedBox(height:18),Text(_when(item['created_at']),style:const TextStyle(color:_muted,fontSize:12))
  ]))));
 }
}

class AppRaffleDetails extends StatelessWidget {
 final Map<String,dynamic> draw;final bool joining;final VoidCallback? onJoin;final String? imageUrl;
 const AppRaffleDetails({super.key,required this.draw,required this.joining,this.onJoin,this.imageUrl});
 @override Widget build(BuildContext context){
  final joined=draw['is_joined']==true;
  final ended=['drawn','finished','completed','cancelled','canceled'].contains('${draw['status']}');
  return TweenAnimationBuilder<double>(tween:Tween(begin:0,end:1),duration:const Duration(milliseconds:450),curve:Curves.easeOutCubic,builder:(context,value,child)=>Opacity(opacity:value,child:Transform.translate(offset:Offset(0,18*(1-value)),child:child)),child:Container(
   height:MediaQuery.sizeOf(context).height*.86,
   decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFFF2FFF9),Color(0xFFF5F2FF),Color(0xFFFFF8F3)]),borderRadius:BorderRadius.vertical(top:Radius.circular(32))),
   child:SafeArea(top:false,child:Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(24,12,12,0),child:Row(children:[const Icon(Icons.auto_awesome_rounded,color:_ink,size:18),const SizedBox(width:8),const Text('FLOWRU · РОЗЫГРЫШ',style:TextStyle(color:_ink,fontSize:11,fontWeight:FontWeight.w900,letterSpacing:1.2)),const Spacer(),IconButton(onPressed:()=>Navigator.of(context).pop(),icon:const Icon(Icons.close_rounded,color:_ink))])),
    Expanded(child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(24,8,24,24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     if(imageUrl!=null && imageUrl!.isNotEmpty)ShaderMask(shaderCallback:(r)=>const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Colors.white,Colors.white,Colors.transparent],stops:[0,.15,.8,1]).createShader(r),blendMode:BlendMode.dstIn,child:ClipRRect(borderRadius:BorderRadius.circular(28),child:Image.network(imageUrl!,height:180,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink()))),
     const SizedBox(height:12),Text('${draw['title'] ?? 'Ваш следующий приятный сюрприз'}',style:const TextStyle(color:_ink,fontSize:30,fontWeight:FontWeight.w900,height:1.12)),const SizedBox(height:20),
     Container(width:double.infinity,padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:Colors.white.withOpacity(.85),border:Border.all(color:Colors.white,width:2),borderRadius:BorderRadius.circular(26),boxShadow:const [BoxShadow(color:Color(0x0D304065),blurRadius:24,offset:Offset(0,10))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.emoji_events_rounded,color:Color(0xFFDC9565),size:36),const SizedBox(height:12),const Text('ВАШ ВОЗМОЖНЫЙ ПРИЗ',style:TextStyle(color:_muted,fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1)),const SizedBox(height:8),Text('${draw['prize_text'] ?? draw['description'] ?? 'Подарок от заведения'}',style:const TextStyle(color:_ink,fontSize:21,fontWeight:FontWeight.w800,height:1.3))])),
     const SizedBox(height:20),Wrap(spacing:10,runSpacing:10,children:[_tag(Icons.groups_rounded,'${draw['participants_count'] ?? 0} участников'),_tag(Icons.schedule_rounded,_when(draw['draw_at']))]),const SizedBox(height:24),
     const Text('Как участвовать',style:TextStyle(color:_ink,fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:10),Text('${draw['post_text'] ?? draw['full_text'] ?? draw['rules'] ?? 'Нажмите кнопку участия. Результат появится в приложении после подведения итогов.'}',style:const TextStyle(color:_muted,fontSize:15,height:1.6)),
     if(draw['winner_user_name']!=null && '${draw['winner_user_name']}'.isNotEmpty)Padding(padding:const EdgeInsets.only(top:20),child:Text('Победитель: ${draw['winner_user_name']}',style:const TextStyle(color:_ink,fontWeight:FontWeight.w800))),
    ]))),
    Padding(padding:const EdgeInsets.fromLTRB(24,12,24,18),child:SizedBox(width:double.infinity,child:FilledButton.icon(
     style:FilledButton.styleFrom(backgroundColor:_ink,disabledBackgroundColor:const Color(0xFFE0E8EC),padding:const EdgeInsets.all(19),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22))),
     onPressed:joining||joined||ended||onJoin==null?null:(){Navigator.of(context).pop();onJoin!();},
     icon:Icon(joined?Icons.check_circle_rounded:Icons.auto_awesome_rounded),label:Text(joining?'Подключаем удачу…':ended?'Розыгрыш завершён':joined?'Вы в списке участников':'Участвовать в розыгрыше',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:15)))))
   ]))));
 }
 Widget _tag(IconData icon,String value)=>Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:10),decoration:BoxDecoration(color:Colors.white.withOpacity(.8),borderRadius:BorderRadius.circular(14)),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:17,color:_muted),const SizedBox(width:7),Text(value,style:const TextStyle(color:_ink,fontSize:12,fontWeight:FontWeight.w700))]));
}
