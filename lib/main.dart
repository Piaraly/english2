import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notifications.init();
  runApp(const EnglishForgeApp());
}

class EnglishForgeApp extends StatelessWidget {
  const EnglishForgeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EnglishForge',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B5FEF), brightness: Brightness.light),
          scaffoldBackgroundColor: const Color(0xFFF6F7FB),
          cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B8FFF), brightness: Brightness.dark),
        ),
        themeMode: ThemeMode.system,
        home: const HomeShell(),
      );
}

class Store extends ChangeNotifier {
  Store._();
  static final Store i = Store._();
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  bool loaded = false;
  int xp = 0, streak = 0, debt = 0, absences = 0;
  String level = 'A1', focus = 'Fundação';
  List<Map<String, dynamic>> tasks = [], words = [], quizzes = [], materials = [], recordings = [];
  Set<String> completedUnits = {};
  DateTime? lastStudy;

  Future<void> load() async {
    xp = await prefs.getInt('xp') ?? 0;
    streak = await prefs.getInt('streak') ?? 0;
    debt = await prefs.getInt('debt') ?? 0;
    absences = await prefs.getInt('absences') ?? 0;
    level = await prefs.getString('level') ?? 'A1';
    focus = await prefs.getString('focus') ?? 'Fundação';
    tasks = _list(await prefs.getString('tasks'));
    words = _list(await prefs.getString('words'));
    quizzes = _list(await prefs.getString('quizzes'));
    materials = _list(await prefs.getString('materials'));
    recordings = _list(await prefs.getString('recordings'));
    completedUnits = (await prefs.getStringList('completedUnits') ?? []).toSet();
    final s = await prefs.getString('lastStudy');
    lastStudy = s == null ? null : DateTime.tryParse(s);
    loaded = true;
    notifyListeners();
  }

  List<Map<String, dynamic>> _list(String? raw) => raw == null ? [] : List<Map<String, dynamic>>.from(jsonDecode(raw));
  Future<void> save() async {
    await prefs.setInt('xp', xp); await prefs.setInt('streak', streak); await prefs.setInt('debt', debt); await prefs.setInt('absences', absences);
    await prefs.setString('level', level); await prefs.setString('focus', focus);
    await prefs.setString('tasks', jsonEncode(tasks)); await prefs.setString('words', jsonEncode(words)); await prefs.setString('quizzes', jsonEncode(quizzes));
    await prefs.setString('materials', jsonEncode(materials)); await prefs.setString('recordings', jsonEncode(recordings));
    await prefs.setStringList('completedUnits', completedUnits.toList()); if (lastStudy != null) await prefs.setString('lastStudy', lastStudy!.toIso8601String());
    notifyListeners();
  }

  Future<void> markStudy({int gain = 10}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final previous = lastStudy == null ? null : DateTime(lastStudy!.year, lastStudy!.month, lastStudy!.day);
    if (previous == null || today.difference(previous).inDays == 1) streak++;
    if (previous != null && today.difference(previous).inDays > 1) { absences += today.difference(previous).inDays - 1; debt += (today.difference(previous).inDays - 1) * 20; streak = 1; }
    xp += gain; debt = (debt - gain).clamp(0, 999999); lastStudy = now; await save();
  }
}

class Notifications {
  static final plugin = FlutterLocalNotificationsPlugin();
  static Future<void> init() async {
    tz.initializeTimeZones();
    await plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
  }
  static Future<void> schedule(DateTime at, String title) async {
    await Permission.notification.request();
    await plugin.zonedSchedule(at.millisecondsSinceEpoch ~/ 1000, 'EnglishForge', title, tz.TZDateTime.from(at, tz.local),
      const NotificationDetails(android: AndroidNotificationDetails('study', 'Sessões de estudo', importance: Importance.max, priority: Priority.high)),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, matchDateTimeComponents: null);
  }
}

class HomeShell extends StatefulWidget { const HomeShell({super.key}); @override State<HomeShell> createState()=>_HomeShellState(); }
class _HomeShellState extends State<HomeShell> {
  int index=0;
  @override void initState(){super.initState(); Store.i.load();}
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation: Store.i,builder:(context,_){
    if(!Store.i.loaded) return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final pages=[const Dashboard(),const Curriculum(),const PracticeHub(),const LibraryPage(),const MorePage()];
    return Scaffold(
      appBar: AppBar(title: const Text('EnglishForge',style:TextStyle(fontWeight:FontWeight.w800)),actions:[Padding(padding:const EdgeInsets.only(right:12),child:Chip(avatar:const Icon(Icons.local_fire_department,size:18),label:Text('${Store.i.streak} dias')))]),
      body: SafeArea(child:pages[index]),
      bottomNavigationBar: NavigationBar(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Hoje'),
        NavigationDestination(icon:Icon(Icons.map_outlined),selectedIcon:Icon(Icons.map),label:'Plano'),
        NavigationDestination(icon:Icon(Icons.mic_none),selectedIcon:Icon(Icons.mic),label:'Prática'),
        NavigationDestination(icon:Icon(Icons.folder_outlined),selectedIcon:Icon(Icons.folder),label:'Materiais'),
        NavigationDestination(icon:Icon(Icons.grid_view_outlined),selectedIcon:Icon(Icons.grid_view),label:'Mais'),
      ]),
    );
  });
}

class Dashboard extends StatelessWidget { const Dashboard({super.key});
  @override Widget build(BuildContext context){final s=Store.i; final today=DateFormat('EEEE, d MMM','pt').format(DateTime.now());
    return ListView(padding:const EdgeInsets.all(16),children:[
      Text(today,style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:6),Text('Seu próximo passo, não tudo de uma vez.',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:16),
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF5B5FEF),Color(0xFF8D5FEF)]),borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('MISSÃO DE HOJE',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text('${s.level} • ${s.focus}',style:const TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('20 min conteúdo + 20 min imersão + 2 min falando em voz alta.',style:TextStyle(color:Colors.white)),const SizedBox(height:14),FilledButton.tonal(onPressed:()=>s.markStudy(gain:20),child:const Text('Concluir sessão mínima +20 XP'))
      ])),const SizedBox(height:14),
      Row(children:[Expanded(child:_metric(context,'${s.xp}','XP',Icons.bolt)),const SizedBox(width:10),Expanded(child:_metric(context,'${s.debt} min','Dívida',Icons.pending_actions)),const SizedBox(width:10),Expanded(child:_metric(context,'${s.absences}','Faltas',Icons.event_busy))]),const SizedBox(height:18),
      const _Title('Ações rápidas'),Wrap(spacing:10,runSpacing:10,children:[
        ActionChip(avatar:const Icon(Icons.timer),label:const Text('Modo 2 minutos'),onPressed:()=>showDialog(context:context,builder:(_)=>const TwoMinuteDialog())),
        ActionChip(avatar:const Icon(Icons.alarm_add),label:const Text('Criar alarme'),onPressed:()=>pickAlarm(context)),
        ActionChip(avatar:const Icon(Icons.checklist),label:const Text('Adicionar tarefa'),onPressed:()=>addTask(context)),
      ]),const SizedBox(height:18),
      const _Title('Hoje'),...s.tasks.where((e)=>!(e['done']??false)).take(5).map((t)=>Card(child:CheckboxListTile(value:t['done']??false,title:Text(t['title']),subtitle:Text(t['type']??'Estudo'),onChanged:(v){t['done']=v; Store.i.markStudy(gain:10);}))),
      if(s.tasks.where((e)=>!(e['done']??false)).isEmpty) const Card(child:ListTile(leading:Icon(Icons.auto_awesome),title:Text('Nada pendente'),subtitle:Text('Crie uma tarefa pequena e concreta.'))),
      const SizedBox(height:18),const _Title('Regra antiabandono'),const Card(child:ListTile(leading:CircleAvatar(child:Text('2')),title:Text('Nunca falte 2 dias seguidos'),subtitle:Text('Um dia perdido é humano. O dia seguinte vira missão de retorno.')))
    ]);
  }
  Widget _metric(BuildContext c,String v,String l,IconData i)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[Icon(i),const SizedBox(height:6),Text(v,style:Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)),Text(l)])));
}

class Curriculum extends StatelessWidget { const Curriculum({super.key});
  static const data={
    'A1':['Pronomes, be e cumprimentos','Artigos, plurais e objetos','Perguntas, países e família','Can/can’t, corpo e dias','Simple present, lugares e horas','Frequência, restaurante, cores e rotina'],
    'A2':['Be e números úteis','Artigos, família e personalidade','Simple present, datas e cidade','Frequência, direções e estilo de vida','There is/are, should, roupas','Present continuous, comida e pedidos','Can, advérbios e experiências','Demonstrativos e comparativos','Wh-questions, have to e informação','Contáveis, artigos, números e comunidade'],
    'B1':['Past simple/progressive','Comparativos, superlativos e artes','Possessivos, modais e viagens','Present perfect e experiências','Present perfect vs past e música','Objetos, phrasal verbs e casa','Quantificadores e alimentos','Preferências, dating e get','Futuro, possibilidade e clima','Futuro e eventos','Passiva e tecnologia','Condicionais e relações'],
    'B2':['Present perfect progressive e aprendizagem','Used to, so/such e memórias','Artigos e perguntas indiretas','Causative e produtos','Reported speech e comunicação','Second conditional, hope/wish','Dedução e cérebro','Past perfect e histórias','Regrets e saúde','Relative clauses e TV','Should have e comportamento','Gerúndio, phrasal verbs e trabalho','Too/enough e fases da vida'],
    'C1':['Inversão, ênfase e registro','Subjuntivo e escrita académica','Reported speech avançado','Noun clauses e third conditional','Passiva e ambiente','Gerund/infinitive e tradições','-ing e past perfect progressive','Quantificadores e justiça social','Artigos avançados e whoever','Ability e dedução passada','Conectores e verb patterns','Contraste, futuro e regrets'],
    'C2':['Adverb phrases e marketing','Future passive e espaço','Object complements e privacidade','Mixed conditionals','Passive modals','Future perfect','Reduced clauses e finanças','Arte e modifiers','Verb patterns e infância','Relative clauses e falsehood','Unreal time e cleft sentences','Infinitive clauses e geologia']};
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[const _Title('Roteiro A1 → C2'),const Text('O app transforma a grade do plano em unidades marcáveis. Toque no nível para defini-lo como foco.'),const SizedBox(height:12),...data.entries.map((e)=>Card(margin:const EdgeInsets.only(bottom:10),child:ExpansionTile(leading:CircleAvatar(child:Text(e.key)),title:Text('${e.key} • ${e.value.length} unidades'),subtitle:Text('${e.value.where((u)=>Store.i.completedUnits.contains('${e.key}:$u')).length} concluídas'),onExpansionChanged:(open){if(open){Store.i.level=e.key;Store.i.focus=e.key=='A1'?'Fundação':e.key=='A2'?'Rotina e confiança':e.key=='B1'?'Conversação do dia a dia':e.key=='B2'?'Autonomia':e.key=='C1'?'Fluência avançada':'Proficiência';Store.i.save();}},children:e.value.map((u){final id='${e.key}:$u';return CheckboxListTile(value:Store.i.completedUnits.contains(id),title:Text(u),onChanged:(v){v==true?Store.i.completedUnits.add(id):Store.i.completedUnits.remove(id);Store.i.markStudy(gain:v==true?15:0);});}).toList()))]);
}

class PracticeHub extends StatefulWidget { const PracticeHub({super.key}); @override State<PracticeHub> createState()=>_PracticeHubState(); }
class _PracticeHubState extends State<PracticeHub>{ final recorder=AudioRecorder(); bool recording=false; final player=AudioPlayer();
  Future<void> toggle() async {if(recording){final path=await recorder.stop();if(path!=null){Store.i.recordings.insert(0,{'path':path,'date':DateTime.now().toIso8601String(),'title':'Speaking ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}'});await Store.i.markStudy(gain:20);}setState(()=>recording=false);}else{if(await Permission.microphone.request().isGranted){final d=await getApplicationDocumentsDirectory();final path=p.join(d.path,'speaking_${DateTime.now().millisecondsSinceEpoch}.m4a');await recorder.start(const RecordConfig(encoder:AudioEncoder.aacLc),path:path);setState(()=>recording=true);}}}
  @override void dispose(){recorder.dispose();player.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[const _Title('Laboratório de speaking'),const Text('Escada de confiança: falar sozinho → gravar → shadowing → conversa.'),const SizedBox(height:14),Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[Icon(recording?Icons.graphic_eq:Icons.mic,size:56),const SizedBox(height:10),Text(recording?'Gravando… fale sem parar':'Gravação semanal de 30–60 s',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:10),FilledButton.icon(onPressed:toggle,icon:Icon(recording?Icons.stop:Icons.fiber_manual_record),label:Text(recording?'Parar e guardar':'Começar gravação'))]))),const SizedBox(height:16),
    const _Title('Gravações'),...Store.i.recordings.map((r)=>Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(leading:IconButton(icon:const Icon(Icons.play_arrow),onPressed:()async{await player.setFilePath(r['path']);player.play();}),title:Text(r['title']),subtitle:Text('Compare com a gravação de 4 semanas atrás.'),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:(){try{File(r['path']).deleteSync();}catch(_){ } Store.i.recordings.remove(r);Store.i.save();}))),const SizedBox(height:16),
    const _Title('Banco de palavras e frases'),FilledButton.tonalIcon(onPressed:()=>addWord(context),icon:const Icon(Icons.add),label:const Text('Adicionar palavra/frase')),const SizedBox(height:8),...Store.i.words.map((w)=>Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(title:Text(w['term']),subtitle:Text('${w['meaning']}\nEx.: ${w['example']}'),isThreeLine:true,trailing:Text('×${w['reviews']??0}'),onTap:(){w['reviews']=(w['reviews']??0)+1;Store.i.markStudy(gain:3);}))),const SizedBox(height:16),
    const _Title('Quiz offline'),FilledButton.tonalIcon(onPressed:()=>createQuiz(context),icon:const Icon(Icons.quiz),label:const Text('Criar quiz')),const SizedBox(height:8),...Store.i.quizzes.map((q)=>Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(leading:const Icon(Icons.play_circle),title:Text(q['title']),subtitle:Text('${(q['questions'] as List).length} questões'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>QuizRunner(quiz:q))))))]);
}

class LibraryPage extends StatelessWidget { const LibraryPage({super.key});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[const _Title('Biblioteca sem acúmulo'),const Card(child:ListTile(leading:Icon(Icons.filter_1),title:Text('Um recurso principal por habilidade'),subtitle:Text('Novo material entra em espera; só substitui, nunca soma sem propósito.'))),const SizedBox(height:12),FilledButton.icon(onPressed:()async{final result=await FilePicker.platform.pickFiles(allowMultiple:true);if(result!=null){for(final f in result.files){Store.i.materials.add({'name':f.name,'path':f.path??'','status':'espera','type':f.extension??'arquivo'});}Store.i.save();}},icon:const Icon(Icons.add_to_drive),label:const Text('Importar materiais do telefone')),const SizedBox(height:12),...Store.i.materials.map((m)=>Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(leading:const Icon(Icons.insert_drive_file),title:Text(m['name']),subtitle:Text('${m['type']} • ${m['status']}'),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='delete')Store.i.materials.remove(m);else m['status']=v;Store.i.save();},itemBuilder:(_)=>const[PopupMenuItem(value:'ativo',child:Text('Definir como ativo')),PopupMenuItem(value:'espera',child:Text('Mover para espera')),PopupMenuItem(value:'concluído',child:Text('Marcar concluído')),PopupMenuItem(value:'delete',child:Text('Remover'))]))),if(Store.i.materials.isEmpty)const Card(child:ListTile(title:Text('Biblioteca vazia'),subtitle:Text('Importe PDFs, áudios, vídeos e textos. O app apenas cataloga; os ficheiros permanecem offline no telefone.')))]);
}

class MorePage extends StatelessWidget { const MorePage({super.key});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[const _Title('Ferramentas'),_tile(context,Icons.calendar_month,'Plano semanal','Crie blocos mínimos/ideais e acompanhe faltas.',()=>addTask(context)),_tile(context,Icons.alarm,'Alarmes inteligentes','Lembrete local mesmo sem internet.',()=>pickAlarm(context)),_tile(context,Icons.headphones,'Player de imersão','Reproduza áudio local com velocidade ajustável.',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const PlayerPage()))),_tile(context,Icons.payments_outlined,'Dívida de estudo','Minutos não feitos viram dívida flexível, nunca punição.',()=>showInfo(context,'Dívida atual','${Store.i.debt} minutos. Cada sessão concluída reduz a dívida automaticamente.')),_tile(context,Icons.psychology,'Modo anti-procrastinação','Entrega apenas uma microação de 2 minutos.',()=>showDialog(context:context,builder:(_)=>const TwoMinuteDialog())),_tile(context,Icons.ios_share,'Backup manual','Exporta os dados do app em JSON.',()=>exportBackup(context)),const SizedBox(height:18),const _Title('Diferenciais'),const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('• Radar de abandono: faltas e dívida sem quebrar a sequência.\n• Escada de speaking com arquivo cronológico.\n• Curadoria antiacúmulo: ativo, espera e concluído.\n• Missão mínima diária e modo de 2 minutos.\n• Progresso por CEFR A1–C2 e XP.\n• Dados locais, sem conta e sem internet.')))]);
  Widget _tile(BuildContext c,IconData i,String t,String s,VoidCallback f)=>Card(margin:const EdgeInsets.only(bottom:9),child:ListTile(leading:Icon(i),title:Text(t),subtitle:Text(s),trailing:const Icon(Icons.chevron_right),onTap:f));
}

class PlayerPage extends StatefulWidget { const PlayerPage({super.key}); @override State<PlayerPage> createState()=>_PlayerPageState(); }
class _PlayerPageState extends State<PlayerPage>{final player=AudioPlayer();String? name;double speed=1;@override void dispose(){player.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Player de imersão')),body:Padding(padding:const EdgeInsets.all(20),child:Column(children:[const Spacer(),const Icon(Icons.headphones,size:100),const SizedBox(height:20),Text(name??'Escolha um áudio local',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:18),StreamBuilder<PlayerState>(stream:player.playerStateStream,builder:(_,snap)=>IconButton.filled(iconSize:44,onPressed:name==null?null:()=>player.playing?player.pause():player.play(),icon:Icon(player.playing?Icons.pause:Icons.play_arrow))),Slider(value:speed,min:.5,max:2,divisions:6,label:'${speed}x',onChanged:(v){setState(()=>speed=v);player.setSpeed(v);}),Text('Velocidade ${speed}x • ideal para shadowing'),const SizedBox(height:20),FilledButton.icon(onPressed:()async{final r=await FilePicker.platform.pickFiles(type:FileType.audio);final path=r?.files.single.path;if(path!=null){await player.setFilePath(path);setState(()=>name=r!.files.single.name);}},icon:const Icon(Icons.audio_file),label:const Text('Abrir áudio')),const Spacer(),const Text('Técnica: ouça uma frase, pause, repita imitando ritmo e entonação. Depois aumente gradualmente a velocidade.')])));
}

class QuizRunner extends StatefulWidget {final Map<String,dynamic> quiz;const QuizRunner({super.key,required this.quiz});@override State<QuizRunner> createState()=>_QuizRunnerState();}
class _QuizRunnerState extends State<QuizRunner>{int index=0,score=0;String? selected;@override Widget build(BuildContext context){final qs=widget.quiz['questions'] as List;if(index>=qs.length)return Scaffold(appBar:AppBar(),body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text('$score/${qs.length}',style:Theme.of(context).textTheme.displayMedium),const Text('Resultado final'),const SizedBox(height:12),FilledButton(onPressed:(){Store.i.markStudy(gain:score*5);Navigator.pop(context);},child:const Text('Guardar e sair'))])));final q=qs[index] as Map<String,dynamic>;return Scaffold(appBar:AppBar(title:Text(widget.quiz['title'])),body:ListView(padding:const EdgeInsets.all(20),children:[Text('Questão ${index+1}/${qs.length}',style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:8),Text(q['question'],style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:18),...(q['options'] as List).map((o)=>RadioListTile<String>(value:o,groupValue:selected,title:Text(o),onChanged:(v)=>setState(()=>selected=v))),FilledButton(onPressed:selected==null?null:(){if(selected==q['answer'])score++;setState((){index++;selected=null;});},child:const Text('Responder'))]));}}

class TwoMinuteDialog extends StatelessWidget {const TwoMinuteDialog({super.key});@override Widget build(BuildContext context){const actions=['Abra uma unidade e leia apenas um exemplo.','Fale 3 frases sobre o que está fazendo agora.','Revise 5 palavras do banco.','Ouça 60 segundos de um áudio e repita uma frase.'];final a=actions[DateTime.now().second%actions.length];return AlertDialog(icon:const Icon(Icons.rocket_launch),title:const Text('Só 2 minutos'),content:Text(a),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Depois')),FilledButton(onPressed:(){Store.i.markStudy(gain:5);Navigator.pop(context);},child:const Text('Fiz'))]);}}
class _Title extends StatelessWidget {final String text;const _Title(this.text);@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Text(text,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)));}

Future<void> addTask(BuildContext context) async {final c=TextEditingController();String type='Conteúdo';final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,set)=>AlertDialog(title:const Text('Nova tarefa'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:c,decoration:const InputDecoration(labelText:'Próxima ação concreta')),const SizedBox(height:10),DropdownButtonFormField(value:type,items:['Conteúdo','Imersão','Speaking','Revisão','Ensinar amigo'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>set(()=>type=v!),decoration:const InputDecoration(labelText:'Tipo'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Guardar'))])));if(ok==true&&c.text.trim().isNotEmpty){Store.i.tasks.add({'title':c.text.trim(),'type':type,'done':false,'date':DateTime.now().toIso8601String()});Store.i.save();}}
Future<void> addWord(BuildContext context) async {final t=TextEditingController(),m=TextEditingController(),e=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Nova palavra/frase'),content:SingleChildScrollView(child:Column(children:[TextField(controller:t,decoration:const InputDecoration(labelText:'Inglês')),const SizedBox(height:8),TextField(controller:m,decoration:const InputDecoration(labelText:'Significado')),const SizedBox(height:8),TextField(controller:e,decoration:const InputDecoration(labelText:'Frase de exemplo'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Guardar'))]));if(ok==true&&t.text.isNotEmpty){Store.i.words.insert(0,{'term':t.text,'meaning':m.text,'example':e.text,'reviews':0});Store.i.save();}}
Future<void> createQuiz(BuildContext context) async {final title=TextEditingController(),q=TextEditingController(),opts=TextEditingController(),ans=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Criar quiz rápido'),content:SingleChildScrollView(child:Column(children:[TextField(controller:title,decoration:const InputDecoration(labelText:'Título')),const SizedBox(height:8),TextField(controller:q,decoration:const InputDecoration(labelText:'Pergunta')),const SizedBox(height:8),TextField(controller:opts,decoration:const InputDecoration(labelText:'Opções separadas por ;')),const SizedBox(height:8),TextField(controller:ans,decoration:const InputDecoration(labelText:'Resposta exata'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Criar'))]));if(ok==true&&q.text.isNotEmpty){Store.i.quizzes.insert(0,{'title':title.text.isEmpty?'Meu quiz':title.text,'questions':[{'question':q.text,'options':opts.text.split(';').map((x)=>x.trim()).where((x)=>x.isNotEmpty).toList(),'answer':ans.text.trim()}]});Store.i.save();}}
Future<void> pickAlarm(BuildContext context) async {final d=await showDatePicker(context:context,firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:365)),initialDate:DateTime.now());if(d==null)return;final t=await showTimePicker(context:context,initialTime:TimeOfDay.now());if(t==null)return;final at=DateTime(d.year,d.month,d.day,t.hour,t.minute);await Notifications.schedule(at,'Hora da sua sessão mínima de inglês.');if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Alarme marcado para ${DateFormat('dd/MM HH:mm').format(at)}')));}
Future<void> exportBackup(BuildContext context) async {final d=await getApplicationDocumentsDirectory();final f=File(p.join(d.path,'english_forge_backup_${DateTime.now().millisecondsSinceEpoch}.json'));await f.writeAsString(jsonEncode({'xp':Store.i.xp,'streak':Store.i.streak,'debt':Store.i.debt,'absences':Store.i.absences,'tasks':Store.i.tasks,'words':Store.i.words,'quizzes':Store.i.quizzes,'materials':Store.i.materials,'recordings':Store.i.recordings,'completedUnits':Store.i.completedUnits.toList()}));if(context.mounted)showInfo(context,'Backup criado',f.path);}
void showInfo(BuildContext context,String title,String text)=>showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text(title),content:SelectableText(text),actions:[FilledButton(onPressed:()=>Navigator.pop(ctx),child:const Text('OK'))]));
