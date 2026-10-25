import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import 'main.dart' show AuthStorage, FlowApi;
import 'dart:math' as math;
import 'package:flutter/material.dart';

const _ink = Color(0xFF23354E);
const _muted = Color(0xFF6C7891);
String _text(Map<String,dynamic> d,String k,[String fallback='']) {
 final v='${d[k] ?? ''}'.trim();return v.isEmpty?fallback:v;
}
bool _ended(Map<String,dynamic> d)=>['drawn','finished','completed','closed','cancelled','canceled'].contains(_text(d,'status'));
String _date(dynamic raw) {
 final v=DateTime.tryParse('$raw')?.toLocal();if(v==null)return 'Дата уточняется';
 const months=['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];
 return '${v.day} ${months[v.month-1]} · ${v.hour.toString().padLeft(2,'0')}:${v.minute.toString().padLeft(2,'0')}';
}
String _host(Map<String,dynamic> d)=>_text(d,'establishment_name',d['establishment_id']==null?'Ваше заведение':'Заведение №${d['establishment_id']}');

// The illustration is drawn locally: no missing cover, network dependency or trophy placeholder.
class _LuckyTickets extends CustomPainter {
 final double phase;
 _LuckyTickets(this.phase);
 @override void paint(Canvas canvas,Size size) {
  final s=math.min(size.width,size.height);
  canvas.save();canvas.translate(size.width*.52,size.height*.49+math.sin(phase)*4);
  for(var i=0;i<2;i++) {
   canvas.save();canvas.rotate(i==0?-.3:.18);
   canvas.translate(i==0?-s*.09:s*.08,i==0?s*.02:-s*.01);
   final r=Rect.fromCenter(center:Offset.zero,width:s*.63,height:s*.39);
   final rr=RRect.fromRectAndRadius(r,Radius.circular(s*.07));
   canvas.drawRRect(rr.shift(Offset(0,s*.04)),Paint()..color=const Color(0x188478B5)..maskFilter=MaskFilter.blur(BlurStyle.normal,s*.06));
   canvas.drawRRect(rr,Paint()..shader=LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:i==0?[const Color(0xFFBAF1E3),const Color(0xFF94D9ED)]:[const Color(0xFFFDFBFF),const Color(0xFFD9C8FA),const Color(0xFFBDEFEA)]).createShader(r));
   canvas.drawRRect(rr,Paint()..color=Colors.white.withOpacity(.85)..style=PaintingStyle.stroke..strokeWidth=1.4);
   final x=r.right-s*.16;
   for(double y=r.top+s*.04;y<r.bottom-s*.02;y+=s*.035){canvas.drawLine(Offset(x,y),Offset(x,y+s*.013),Paint()..color=const Color(0x558373AA)..strokeWidth=1);}
   if(i==1){
    final c=Offset(-s*.07,0);final star=Path();
    for(var k=0;k<8;k++){final a=k*math.pi/4;final radius=k.isEven?s*.08:s*.026;final p=c+Offset(math.cos(a)*radius,math.sin(a)*radius);if(k==0){star.moveTo(p.dx,p.dy);}else{star.lineTo(p.dx,p.dy);}}
    star.close();canvas.drawPath(star,Paint()..shader=const LinearGradient(colors:[Color(0xFF9670CE),Color(0xFF679FAD)]).createShader(r));
   }
   canvas.restore();
  }
  canvas.restore();
  for(var i=0;i<6;i++){
   final angle=i*math.pi/3+phase*.06;final c=Offset(size.width*.52+math.cos(angle)*s*.43,size.height*.48+math.sin(angle)*s*.35);
   final p=Paint()..color=(i.isEven?const Color(0xFF9F8BD3):const Color(0xFF63BEB4)).withOpacity(.65);
   canvas.drawCircle(c,i.isEven?2.5:1.5,p);
  }
 }
 @override bool shouldRepaint(covariant _LuckyTickets old)=>old.phase!=phase;
}

class _LuckySurface extends StatefulWidget {
 final Widget child;final String? imageUrl;final bool illustration;
 const _LuckySurface({required this.child,this.imageUrl,this.illustration=true});
 @override State<_LuckySurface> createState()=>_LuckySurfaceState();
}
class _LuckySurfaceState extends State<_LuckySurface> with SingleTickerProviderStateMixin {
 late final AnimationController _motion=AnimationController(vsync:this,duration:const Duration(seconds:8));
 @override void didChangeDependencies(){super.didChangeDependencies();if(MediaQuery.of(context).disableAnimations){_motion.stop();}else{_motion.repeat();}}
 @override void dispose(){_motion.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>AnimatedBuilder(animation:_motion,builder:(context,_)=>Stack(children:[
  Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:const [Color(0xFFF4F0FF),Color(0xFFE3F9F3),Color(0xFFE8EAFF)],stops:[0,.5+.08*math.sin(_motion.value*math.pi*2),1])))),
  Positioned(right:-65,top:-70,child:Container(width:230,height:230,decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[const Color(0xFFCBB5F3).withOpacity(.55),const Color(0x00CBB5F3)])))),
  if(widget.imageUrl!=null && widget.imageUrl!.isNotEmpty)Positioned.fill(child:ShaderMask(blendMode:BlendMode.dstIn,shaderCallback:(r)=>const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.white,Colors.transparent],stops:[0,1]).createShader(r),child:Opacity(opacity:.4,child:Image.network(widget.imageUrl!,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink())))),
  if(widget.illustration)Positioned(right:-20,top:18,width:170,height:150,child:IgnorePointer(child:CustomPaint(painter:_LuckyTickets(_motion.value*math.pi*2)))),
  widget.child,
 ]));
}

class AppRaffleCard extends StatelessWidget {
 final Map<String,dynamic> draw;final String? imageUrl;final VoidCallback onTap;final bool compact;
 const AppRaffleCard({super.key,required this.draw,required this.onTap,this.imageUrl,this.compact=false});
 @override Widget build(BuildContext context) {
  final ended=_ended(draw);final joined=draw['is_joined']==true;
  return Semantics(button:true,label:'Розыгрыш от ${_host(draw)}. Итоги ${_date(draw['draw_at'])}',child:Container(
   decoration:BoxDecoration(borderRadius:BorderRadius.circular(30),boxShadow:const [BoxShadow(color:Color(0x228C93CC),blurRadius:24,offset:Offset(0,10))]),
   child:Material(color:Colors.transparent,borderRadius:BorderRadius.circular(30),clipBehavior:Clip.antiAlias,child:InkWell(onTap:onTap,child:_LuckySurface(imageUrl:imageUrl,child:Padding(padding:EdgeInsets.all(compact?21:25),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
    Padding(padding:const EdgeInsets.only(right:52),child:Text(_host(draw),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:_ink,fontSize:13,fontWeight:FontWeight.w800))),
    SizedBox(height:compact?25:30),
    Text('Розыгрыш',style:TextStyle(color:_ink,fontSize:compact?28:34,height:1.08,fontWeight:FontWeight.w900,letterSpacing:-1)),
    if(compact)const Spacer() else const SizedBox(height:42),
    Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(ended?'ИТОГИ ПОДВЕДЕНЫ':joined?'ВЫ УЧАСТВУЕТЕ':'ИТОГИ',style:const TextStyle(color:Color(0xFF7C6AA0),fontSize:9,fontWeight:FontWeight.w900,letterSpacing:1.2)),
     const SizedBox(height:6),Text(_date(draw['draw_at']),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:_ink,fontSize:12,fontWeight:FontWeight.w700)),
    ])),const SizedBox(width:8),Container(width:38,height:38,decoration:BoxDecoration(color:Colors.white.withOpacity(.8),shape:BoxShape.circle,border:Border.all(color:Colors.white)),child:Icon(joined?Icons.check_rounded:Icons.north_east_rounded,color:const Color(0xFF8770B2),size:19))]),
   ])))))));
 }
}

class _RaffleDetailsView extends StatelessWidget {
 final Map<String,dynamic> draw;final bool joining;final VoidCallback? onJoin;final String? imageUrl;
 const _RaffleDetailsView({super.key,required this.draw,required this.joining,this.onJoin,this.imageUrl});
 @override Widget build(BuildContext context) {
  final joined=draw['is_joined']==true;final ended=_ended(draw);final reduce=MediaQuery.of(context).disableAnimations;
  final prize=_text(draw,'prize_text',_text(draw,'description','Подарок от заведения'));
  final title=_text(draw,'title');
  return TweenAnimationBuilder<double>(tween:Tween(begin:reduce?1.0:0.0,end:1),duration:Duration(milliseconds:reduce?0:420),curve:Curves.easeOutCubic,builder:(context,v,child)=>Opacity(opacity:v,child:Transform.translate(offset:Offset(0,20*(1-v)),child:child)),child:Container(
   height:MediaQuery.sizeOf(context).height*.89,clipBehavior:Clip.antiAlias,decoration:const BoxDecoration(color:Color(0xFFF8FAFC),borderRadius:BorderRadius.vertical(top:Radius.circular(32))),
   child:SafeArea(top:false,child:Column(children:[
    Expanded(child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     _LuckySurface(imageUrl:imageUrl,illustration:false,child:Padding(padding:const EdgeInsets.fromLTRB(24,8,14,28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text(_host(draw),style:const TextStyle(color:_ink,fontSize:14,fontWeight:FontWeight.w800))),IconButton(tooltip:'Закрыть',onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close_rounded,color:_ink))]),
      const SizedBox(height:10),
      Text(draw['is_winner']==true?'Поздравляем!':ended?'Розыгрыш завершён':'Розыгрыш',style:const TextStyle(color:_ink,fontSize:42,fontWeight:FontWeight.w900,height:1,letterSpacing:-1.7)),
      SizedBox(height:142,child:Center(child:AspectRatio(aspectRatio:1.65,child:CustomPaint(painter:_LuckyTickets(0))))),
      Container(width:double.infinity,padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:Colors.white.withOpacity(.78),border:Border.all(color:Colors.white,width:1.5),borderRadius:BorderRadius.circular(25),boxShadow:const [BoxShadow(color:Color(0x108D87C2),blurRadius:22,offset:Offset(0,9))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Text(draw['is_winner']==true?'ВЫ ВЫИГРАЛИ':'ПРИЗ ОТ ЗАВЕДЕНИЯ',style:const TextStyle(color:Color(0xFF8770B2),fontSize:9,fontWeight:FontWeight.w900,letterSpacing:1.5)),
       const SizedBox(height:10),Text(prize,style:const TextStyle(color:_ink,fontSize:27,fontWeight:FontWeight.w900,height:1.13,letterSpacing:-.7)),
       if(title.isNotEmpty && title!=prize)Padding(padding:const EdgeInsets.only(top:9),child:Text(title,style:const TextStyle(color:_muted,fontSize:13,height:1.4))),
      ])),
     ]))),
     Padding(padding:const EdgeInsets.fromLTRB(24,22,24,22),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('ИТОГИ',style:TextStyle(color:_muted,fontSize:9,fontWeight:FontWeight.w900,letterSpacing:1.2)),const SizedBox(height:7),Text(_date(draw['draw_at']),style:const TextStyle(color:_ink,fontSize:14,fontWeight:FontWeight.w800))])),const SizedBox(width:15),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[const Text('УЧАСТНИКОВ',style:TextStyle(color:_muted,fontSize:9,fontWeight:FontWeight.w900,letterSpacing:1.2)),const SizedBox(height:7),Text('${draw['participants_count'] ?? 0}',style:const TextStyle(color:_ink,fontSize:20,fontWeight:FontWeight.w900))])]),
      if(joined && !ended)const Padding(padding:EdgeInsets.only(top:18),child:Row(children:[Icon(Icons.check_circle_rounded,color:Color(0xFF38A48C),size:19),SizedBox(width:8),Expanded(child:Text('Вы участвуете. Удачи!',style:TextStyle(color:Color(0xFF25836E),fontWeight:FontWeight.w800)))])),
      const SizedBox(height:24),
      if(draw['is_winner']==true)...[
        Text(draw['prize_state']=='redeemed'?'Ваш приз уже получен':draw['prize_state']=='expired'?'Срок получения приза истёк':'Ваш приз ждёт вас в заведении',style:const TextStyle(color:_ink,fontWeight:FontWeight.w800,fontSize:18)),
        if(_text(draw,'prize_expires_at').isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text('Получить до ${_date(draw['prize_expires_at'])}',style:const TextStyle(color:_muted))),
        const SizedBox(height:20),
      ],
      const Text('Условия участия',style:TextStyle(color:_ink,fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:10),
      SelectableText(_text(draw,'post_text',_text(draw,'full_text',_text(draw,'rules','Нажмите кнопку участия. Итоги появятся в приложении.'))),style:const TextStyle(color:_muted,fontSize:14,height:1.6)),
      if(ended && draw['is_winner']!=true && _text(draw,'winner_user_name').isEmpty)const Padding(padding:EdgeInsets.only(top:16),child:Text('Розыгрыш завершён без победителя',style:TextStyle(color:_muted))),
      if(_text(draw,'winner_user_name').isNotEmpty)Padding(padding:const EdgeInsets.only(top:20),child:Container(width:double.infinity,padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFE9E1FA),Color(0xFFDBF6EA)]),borderRadius:BorderRadius.circular(20)),child:Text('Победитель: ${draw['winner_user_name']}',style:const TextStyle(color:_ink,fontSize:19,fontWeight:FontWeight.w800)))),
     ])),
    ]))),
    Padding(padding:const EdgeInsets.fromLTRB(24,10,24,16),child:Container(decoration:BoxDecoration(gradient:joined?null:const LinearGradient(colors:[Color(0xFFBAEEE1),Color(0xFFACDFEF),Color(0xFFD0BAF6)]),color:joined?const Color(0xFFDFF3EB):null,borderRadius:BorderRadius.circular(21),boxShadow:const [BoxShadow(color:Color(0x227AABC1),blurRadius:20,offset:Offset(0,7))]),child:SizedBox(width:double.infinity,child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:Colors.transparent,disabledBackgroundColor:Colors.transparent,foregroundColor:_ink,disabledForegroundColor:_muted,padding:const EdgeInsets.symmetric(vertical:18,horizontal:16),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(21))),onPressed:draw['is_winner']==true && _text(draw,'prize_qr').isNotEmpty?()=>showDialog<void>(context:context,builder:(c)=>AlertDialog(title:const Text('Покажите QR сотруднику'),content:SizedBox(width:240,child:Column(mainAxisSize:MainAxisSize.min,children:[LayoutBuilder(builder:(_,box)=>QrImageView(data:_text(draw,'prize_qr'),size:math.min(220.0,box.maxWidth))),const Text('Сотрудник сканирует QR в Flowru Business и подтверждает выдачу.',textAlign:TextAlign.center)])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Закрыть'))])):joining||joined||ended||onJoin==null?null:(){Navigator.pop(context);onJoin!();},icon:joining?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):Icon(joined?Icons.check_rounded:ended?Icons.flag_outlined:Icons.auto_awesome_rounded),label:Text(draw['is_winner']==true && _text(draw,'prize_qr').isNotEmpty?'Показать QR приза':joining?'Добавляем вас…':ended?'Розыгрыш завершён':joined?'Вы участвуете':'Хочу участвовать',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)))))),
   ])),
  ));
 }
}


class AppRaffleDetails extends StatefulWidget {
 final Map<String,dynamic> draw;final bool joining;final VoidCallback? onJoin;final String? imageUrl;
 const AppRaffleDetails({super.key,required this.draw,required this.joining,this.onJoin,this.imageUrl});
 @override State<AppRaffleDetails> createState()=>_AppRaffleDetailsState();
}
class _AppRaffleDetailsState extends State<AppRaffleDetails> {
 late Map<String,dynamic> _draw;Timer? _timer;bool _fetching=false;String? _error;
 @override void initState(){super.initState();_draw={...widget.draw};_refresh();_timer=Timer.periodic(const Duration(seconds:10),(_)=>_refresh());}
 @override void dispose(){_timer?.cancel();super.dispose();}
 Future<void> _refresh() async {
  if(_fetching || int.tryParse('${widget.draw['run_id']}')==null)return;
  _fetching=true;
  try {
   final token=await AuthStorage.access();if(token==null)return;
   final result=await FlowApi().orderPaymentRequest('/client/raffles/${widget.draw['run_id']}/result','GET',null,token);
   if(mounted)setState((){_draw.remove('prize_qr');_draw.remove('prize_state');_draw.remove('prize_expires_at');_draw={..._draw,...result};_error=null;});
  }catch(_){if(mounted)setState(()=>_error='Не удалось обновить результат. Повторяем проверку…');}
  finally{_fetching=false;}
 }
 @override Widget build(BuildContext context)=>Column(mainAxisSize:MainAxisSize.min,children:[
  if(_error!=null)Padding(padding:const EdgeInsets.all(8),child:Text(_error!,style:const TextStyle(color:_muted,fontSize:12))),
  Flexible(child:_RaffleDetailsView(draw:_draw,joining:widget.joining,onJoin:widget.onJoin,imageUrl:widget.imageUrl)),
 ]);
}
