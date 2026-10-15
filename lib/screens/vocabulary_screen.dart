import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../common.dart';
import '../services/storage.dart';
import '../services/notification_service.dart';

class Word {
  final String word;
  final String meaning;
  const Word(this.word, this.meaning);
  Map<String, dynamic> toJson() => {'word': word, 'meaning': meaning};
  factory Word.fromJson(Map<String, dynamic> json) =>
      Word(json['word'] as String, json['meaning'] as String);
}
class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});
  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}
class _VocabularyScreenState extends State<VocabularyScreen> {
  final wordController = TextEditingController();
  final meaningController = TextEditingController();
  List<Word> words = [];
  bool busy = true;
  bool loadFailed = false;
  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() {
    wordController.dispose(); meaningController.dispose(); super.dispose();
  }
  Future<void> load() async {
    try {
      final items = await Storage.loadJson('words.json');
      if (mounted) setState(() => words = items.map(Word.fromJson).toList());
    } catch (e) {
      loadFailed = true;
      if (mounted) message(context, 'Không đọc được từ vựng: $e', error: true);
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> save() async {
    final word = wordController.text.trim();
    final meaning = meaningController.text.trim();
    if (word.isEmpty || meaning.isEmpty) {
      message(context, 'Nhập đủ từ và nghĩa.', error: true); return;
    }
    if (words.any((e) => normalize(e.word) == normalize(word))) {
      message(context, 'Từ này đã có trong danh sách.', error: true); return;
    }
    setState(() => busy = true);
    final service = NotificationService.instance;
    int? id;
    bool scheduled = false;
    bool saved = false;
    try {
      await service.ensurePermission(exact: true);
      id = await service.newId();
      await service.schedule(id: id, title: 'Ôn từ vựng mới',
          body: '$word: $meaning', time: DateTime.now().add(const Duration(minutes: 10)),
          payload: 'vocab:$id');
      scheduled = true;
      final next = [...words, Word(word, meaning)];
      await Storage.saveJson('words.json', next.map((e) => e.toJson()).toList());
      saved = true;
      if (mounted) setState(() {
        words = next; wordController.clear(); meaningController.clear();
      });
      await service.show('Đã lưu từ vựng', 'Hãy ôn "$word" sau 10 phút.');
      if (mounted) message(context, 'Đã lưu và lên lịch nhắc học từ sau 10 phút.');
    } catch (e) {
      if (scheduled && !saved && id != null) {
        try { await service.cancel(id); } catch (_) {}
      }
      if (mounted) message(context,
        saved ? 'Đã lưu và đặt lịch, nhưng lỗi thông báo xác nhận: $e' : '$e',
        error: true);
    } finally { if (mounted) setState(() => busy = false); }
  }
  void openPage(int page) {
    Navigator.pop(context);
    if (page == 0) return;
    if (busy || loadFailed) {
      message(context, 'Chưa tải được dữ liệu từ vựng.', error: true); return;
    }
    if (page != 3 && words.isEmpty) {
      message(context, 'Hãy lưu ít nhất một từ trước.', error: true); return;
    }
    final screen = page == 1 ? LearnScreen(words: List.of(words))
        : page == 2 ? QuizScreen(words: List.of(words)) : const PendingScreen();
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ứng dụng học từ vựng')),
    drawer: Drawer(child: ListView(children: [
      const DrawerHeader(decoration: BoxDecoration(color: Colors.blue),
        child: Align(alignment: Alignment.bottomLeft,
          child: Text('Trợ lý học từ vựng', style: TextStyle(color: Colors.white)))),
      ListTile(leading: const Icon(Icons.home), title: const Text('Trang chính'),
        onTap: () => openPage(0)),
      ListTile(leading: const Icon(Icons.school), title: const Text('Học từ'),
        onTap: () => openPage(1)),
      ListTile(leading: const Icon(Icons.quiz), title: const Text('Kiểm tra từ'),
        onTap: () => openPage(2)),
      ListTile(leading: const Icon(Icons.notifications), title: const Text('Lịch nhắc'),
        onTap: () => openPage(3)),
    ])),
    body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(controller: wordController, enabled: !busy && !loadFailed,
        decoration: const InputDecoration(labelText: 'Từ')),
      TextField(controller: meaningController, enabled: !busy && !loadFailed,
        decoration: const InputDecoration(labelText: 'Nghĩa')),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: busy || loadFailed ? null : save,
        child: const Text('Lưu và Nhắc học sau 10 phút')),
      if (busy) const Center(child: CircularProgressIndicator()),
      if (loadFailed) const Text('Không đọc được file. Kiểm tra words.json.'),
    ])),
  );
}

class LearnScreen extends StatefulWidget {
  final List<Word> words;
  const LearnScreen({super.key, required this.words});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}
class _LearnScreenState extends State<LearnScreen> {
  final answer = TextEditingController();
  int index = 0, correct = 0, wrong = 0;
  bool busy = false;
  @override
  void dispose() { answer.dispose(); super.dispose(); }
  Future<void> check() async {
    if (answer.text.trim().isEmpty) {
      message(context, 'Nhập nghĩa trước khi kiểm tra.', error: true); return;
    }
    setState(() => busy = true);
    final current = widget.words[index];
    final ok = normalize(answer.text) == normalize(current.meaning);
    setState(() {
      if (ok) { correct++; } else { wrong++; }
      index = (index + 1) % widget.words.length;
      answer.clear();
    });
    message(context, ok ? 'Chính xác!' : 'Sai. Nghĩa đúng: ${current.meaning}',
        error: !ok);
    try {
      if (!ok && wrong > 0 && wrong % 3 == 0) {
        await NotificationService.instance.show('Cần ôn tập thêm',
          'Bạn đã trả lời sai $wrong lần. Hãy xem lại các từ đã học.');
      }
    } catch (e) {
      if (mounted) message(context, 'Không gửi được thông báo: $e', error: true);
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ôn tập từ mới')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
      children: [scoreRow(correct, wrong), const SizedBox(height: 24),
      Card(color: Colors.blue.shade100, child: Padding(
        padding: const EdgeInsets.all(20), child: Column(children: [
        Text(widget.words[index].word, style: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(controller: answer, enabled: !busy,
          decoration: const InputDecoration(hintText: 'Nhập nghĩa tiếng Việt',
            filled: true, fillColor: Colors.white, border: OutlineInputBorder())),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: busy ? null : check, child: const Text('Check')),
      ]))),
    ])),
  );
}

class Question {
  final Word word;
  final String shownMeaning;
  const Question(this.word, this.shownMeaning);
  bool get isTrue => normalize(word.meaning) == normalize(shownMeaning);
}
class QuizScreen extends StatefulWidget {
  final List<Word> words;
  const QuizScreen({super.key, required this.words});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}
class _QuizScreenState extends State<QuizScreen> {
  List<Question> questions = [];
  int index = 0, correct = 0, wrong = 0;
  bool finishing = false;
  @override
  void initState() { super.initState(); generate(); }
  void generate() {
    final random = Random();
    final words = List<Word>.of(widget.words)..shuffle(random);
    questions = words.map((word) {
      final other = words.where((e) => normalize(e.meaning) != normalize(word.meaning)).toList();
      final meaning = other.isNotEmpty && random.nextBool()
          ? other[random.nextInt(other.length)].meaning : word.meaning;
      return Question(word, meaning);
    }).toList();
    index = correct = wrong = 0;
    finishing = false;
  }
  Future<void> choose(bool chosen) async {
    if (finishing) return;
    final ok = chosen == questions[index].isTrue;
    setState(() { if (ok) { correct++; } else { wrong++; } });
    if (index < questions.length - 1) {
      setState(() => index++); return;
    }
    setState(() => finishing = true);
    final percent = correct / questions.length * 100;
    final retry = await showDialog<bool>(context: context, barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(title: const Text('Kết thúc bài kiểm tra'),
        content: Text('Tổng: ${questions.length} câu\nĐúng: $correct\nSai: $wrong\n'
          'Tỉ lệ đúng: ${percent.toStringAsFixed(1)}%'),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Làm lại')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Thoát'))]));
    if (!mounted) return;
    if (retry == true) { setState(generate); } else { Navigator.pop(context); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Trắc nghiệm Đúng / Sai')),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      scoreRow(correct, wrong),
      Text('Câu ${index + 1}/${questions.length}'),
      Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(questions[index].word.word, style: const TextStyle(
          fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Chip(label: Text(questions[index].shownMeaning)),
      ]))),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        ElevatedButton(onPressed: finishing ? null : () => choose(true),
          child: const Text('Đúng')),
        ElevatedButton(onPressed: finishing ? null : () => choose(false),
          child: const Text('Sai')),
      ]), const SizedBox(height: 24),
    ])),
  );
}

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});
  @override
  State<PendingScreen> createState() => _PendingScreenState();
}
class _PendingScreenState extends State<PendingScreen> with WidgetsBindingObserver {
  List<PendingNotificationRequest> items = [];
  bool busy = true;
  String? error;
  @override
  void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this); load();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) load();
  }
  Future<void> load() async {
    if (mounted) setState(() { busy = true; error = null; });
    try {
      final requests = await NotificationService.instance.pending();
      final filtered = requests.where((e) => e.payload?.startsWith('vocab:') == true).toList();
      if (mounted) setState(() => items = filtered);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> cancel(int id) async {
    setState(() => busy = true);
    try { await NotificationService.instance.cancel(id); }
    catch (e) { if (mounted) message(context, '$e', error: true); }
    await load();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lịch nhắc'), actions: [
      IconButton(onPressed: busy ? null : load, icon: const Icon(Icons.refresh))]),
    body: busy ? const Center(child: CircularProgressIndicator())
      : error != null ? Center(child: Text(error!))
      : items.isEmpty ? const Center(child: Text('Không có lịch nhắc đang chờ.'))
      : RefreshIndicator(onRefresh: load, child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(), itemCount: items.length,
        itemBuilder: (_, i) => ListTile(leading: const Icon(Icons.alarm),
          title: Text(items[i].title ?? ''), subtitle: Text(items[i].body ?? ''),
          trailing: IconButton(icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () => cancel(items[i].id))))),
  );
}
