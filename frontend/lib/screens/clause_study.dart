import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../models/contract.dart';
import '../models/quiz.dart';
import '../providers/contracts_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/quizzes_provider.dart';
import '../providers/vocabulary_provider.dart';
import '../theme.dart';
import 'tutor.dart';

/// The core learning screen: Read (tappable words) → Understand → Quiz.
class ClauseStudyScreen extends StatefulWidget {
  final Contract contract;
  final Clause clause;

  const ClauseStudyScreen(
      {super.key, required this.contract, required this.clause});

  @override
  State<ClauseStudyScreen> createState() => _ClauseStudyScreenState();
}

class _ClauseStudyScreenState extends State<ClauseStudyScreen> {
  int _stage = 0; // 0 read, 1 understand, 2 quiz
  Quiz? _quiz;
  final Map<int, int> _answers = {}; // question index -> selected option
  bool _generating = false;
  bool _submitting = false;

  // Natural AI voice (backend OpenAI TTS) with the system voice as fallback.
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.45);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _speaking = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeak(String text) async {
    if (_speaking) {
      await _player.stop();
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    try {
      final url = await Provider.of<VocabularyProvider>(context, listen: false)
          .pronounceUrl(text);
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (_) {
      // Natural voice unavailable — fall back to the system voice.
      await _tts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.clauseN(widget.clause.order)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.goldLight,
        foregroundColor: AppColors.goldDark,
        tooltip: s.tutorTitle,
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TutorScreen(contractId: widget.contract.id),
          ));
        },
        child: const Icon(Icons.chat_bubble_outline),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _stageChips(s),
          const SizedBox(height: 16),
          if (_stage == 0) ..._readStage(s),
          if (_stage == 1) ..._understandStage(s),
          if (_stage == 2) ..._quizStage(s),
        ],
      ),
    );
  }

  Widget _stageChips(dynamic s) {
    final labels = [s.stageRead, s.stageUnderstand, s.stageQuiz];
    return Row(
      children: List.generate(3, (i) {
        final active = i == _stage;
        final done = i < _stage;
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: InkWell(
            onTap: i <= _stage ? () => setState(() => _stage = i) : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.gold : Colors.transparent,
                border: Border.all(
                    color: active ? AppColors.gold : AppColors.navy500),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                if (done)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: 4),
                    child: Icon(Icons.check,
                        size: 14, color: AppColors.goldLight),
                  ),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? AppColors.goldDark : AppColors.textFaint,
                  ),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }

  // ── Stage 0: Read ──────────────────────────────────────────────────────────

  List<Widget> _readStage(dynamic s) {
    return [
      Row(
        children: [
          if (widget.clause.isDefinition) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(s.definitionTag,
                  style: const TextStyle(
                      color: AppColors.goldDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(s.tapAnyWord,
                style:
                    const TextStyle(color: AppColors.textFaint, fontSize: 13)),
          ),
          IconButton(
            tooltip: _speaking ? s.stopListening : s.listen,
            icon: Icon(_speaking ? Icons.stop_circle : Icons.volume_up,
                color: AppColors.goldLight),
            onPressed: () => _toggleSpeak(widget.clause.originalText),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.reading,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: _tappableText(widget.clause.originalText),
        ),
      ),
      const SizedBox(height: 18),
      ElevatedButton(
        onPressed: () => setState(() => _stage = 1),
        child: Text('${s.next} — ${s.stageUnderstand}'),
      ),
    ];
  }

  Widget _tappableText(String text) {
    final words = text.split(RegExp(r'\s+'));
    return Wrap(
      spacing: 0,
      runSpacing: 4,
      children: words.map((w) {
        final clean = w.replaceAll(RegExp(r'''^[^A-Za-z]+|[^A-Za-z]+$'''), '');
        final tappable = clean.length > 2;
        return InkWell(
          onTap: tappable ? () => _onWordTap(clean) : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              w,
              style: const TextStyle(
                color: AppColors.navy900,
                fontSize: 15,
                height: 1.9,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _onWordTap(String word) async {
    final s = Provider.of<LocaleProvider>(context, listen: false).s;
    final vocab = Provider.of<VocabularyProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navy700,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _WordSheet(
        word: word,
        clauseId: widget.clause.id,
        strings: s,
        lookup: () => vocab.tapWord(word, clauseId: widget.clause.id),
        audioUrl: () => vocab.pronounceUrl(word),
      ),
    );
  }

  // ── Stage 1: Understand ────────────────────────────────────────────────────

  List<Widget> _understandStage(dynamic s) {
    final clause = widget.clause;
    return [
      if (clause.simpleEn != null) ...[
        Row(children: [
          Expanded(
            child: Text(s.simpleExplanation,
                style:
                    const TextStyle(color: AppColors.textFaint, fontSize: 13)),
          ),
          IconButton(
            tooltip: _speaking ? s.stopListening : s.listen,
            icon: Icon(_speaking ? Icons.stop_circle : Icons.volume_up,
                color: AppColors.goldLight, size: 20),
            onPressed: () => _toggleSpeak(clause.simpleEn!),
          ),
        ]),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(clause.simpleEn!,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                    color: AppColors.textLight, fontSize: 15, height: 1.7)),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (clause.arabic != null) ...[
        Text(s.arabicExplanation,
            style: const TextStyle(color: AppColors.textFaint, fontSize: 13)),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(clause.arabic!,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 15, height: 1.8)),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (clause.keyTerms.isNotEmpty) ...[
        Text(s.keyTerms,
            style: const TextStyle(color: AppColors.textFaint, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: clause.keyTerms
              .map((kt) => Tooltip(
                    message: kt.meaning,
                    triggerMode: TooltipTriggerMode.tap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(kt.term,
                          style: const TextStyle(
                              color: AppColors.goldDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
      ],
      if (clause.isDefinition && clause.relatedOrders.isNotEmpty) ...[
        Text(s.appearsIn,
            style: const TextStyle(color: AppColors.textFaint, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: clause.relatedOrders.take(12).map((order) {
            return ActionChip(
              backgroundColor: AppColors.navy700,
              side: const BorderSide(color: AppColors.navy500),
              label: Text(s.clauseN(order),
                  style: const TextStyle(
                      color: AppColors.goldLight, fontSize: 13)),
              onPressed: () => _openClauseByOrder(order),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 6),
      ElevatedButton(
        onPressed: () {
          setState(() => _stage = 2);
          if (_quiz == null) _generateQuiz();
        },
        child: Text('${s.next} — ${s.stageQuiz}'),
      ),
    ];
  }

  void _openClauseByOrder(int order) {
    Clause? target;
    for (final c in widget.contract.clauses) {
      if (c.order == order) {
        target = c;
        break;
      }
    }
    if (target == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          ClauseStudyScreen(contract: widget.contract, clause: target!),
    ));
  }

  // ── Stage 2: Quiz ──────────────────────────────────────────────────────────

  Future<void> _generateQuiz() async {
    setState(() => _generating = true);
    try {
      final quiz = await Provider.of<QuizzesProvider>(context, listen: false)
          .generateQuiz(clauseId: widget.clause.id, quizType: 'mcq', count: 3);
      if (!mounted) return;
      setState(() {
        _quiz = quiz;
        _generating = false;
        _answers.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ $e')));
    }
  }

  List<Widget> _quizStage(dynamic s) {
    if (_generating || _quiz == null) {
      return [
        const SizedBox(height: 40),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 12),
        Center(
          child: Text(s.generatingQuiz,
              style: const TextStyle(color: AppColors.textFaint)),
        ),
      ];
    }
    final quiz = _quiz!;
    return [
      ...quiz.questions.asMap().entries.map((entry) {
        final i = entry.key;
        final q = entry.value;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}. ${q.question}',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                        height: 1.5)),
                const SizedBox(height: 8),
                ...q.options.asMap().entries.map((opt) => RadioListTile<int>(
                      dense: true,
                      activeColor: AppColors.gold,
                      title: Text(opt.value,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 14)),
                      value: opt.key,
                      groupValue: _answers[i],
                      onChanged: (v) => setState(() => _answers[i] = v!),
                    )),
              ],
            ),
          ),
        );
      }),
      const SizedBox(height: 10),
      ElevatedButton(
        onPressed: _answers.length == quiz.questions.length && !_submitting
            ? _submitQuiz
            : null,
        child: _submitting
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text(s.submitAnswers),
      ),
    ];
  }

  Future<void> _submitQuiz() async {
    final s = Provider.of<LocaleProvider>(context, listen: false).s;
    final quiz = _quiz!;
    setState(() => _submitting = true);
    try {
      final answers =
          List.generate(quiz.questions.length, (i) => _answers[i]);
      final result = await Provider.of<QuizzesProvider>(context, listen: false)
          .submitQuiz(quiz.id, answers);
      if (!mounted) return;
      setState(() => _submitting = false);

      final pct = (result.score * 100).round();
      final passed = result.score >= 0.66;

      if (passed) {
        await Provider.of<ContractsProvider>(context, listen: false)
            .completeClause(widget.contract.id, widget.clause.id);
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.navy700,
            title: Row(children: [
              const Icon(Icons.emoji_events, color: AppColors.gold, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.quizPassed,
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 17)),
              ),
            ]),
            content: Text(s.yourScore(pct),
                style: const TextStyle(color: AppColors.textMuted)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.backToJourney),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${s.quizFailed} — ${s.yourScore(pct)}'),
        ));
        setState(() {
          _quiz = null;
          _stage = 1;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ $e')));
    }
  }
}

/// Bottom sheet shown when a word is tapped: pronounces it with the natural
/// AI voice, looks up its meaning, and confirms it was saved.
class _WordSheet extends StatefulWidget {
  final String word;
  final int clauseId;
  final dynamic strings;
  final Future<dynamic> Function() lookup;
  final Future<String> Function() audioUrl;

  const _WordSheet({
    required this.word,
    required this.clauseId,
    required this.strings,
    required this.lookup,
    required this.audioUrl,
  });

  @override
  State<_WordSheet> createState() => _WordSheetState();
}

class _WordSheetState extends State<_WordSheet> {
  String? _meaningEn;
  String? _meaningAr;
  String? _example;
  String? _error;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _run();
    _pronounce(); // speak the word immediately, in parallel with the lookup
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _pronounce() async {
    try {
      final url = await widget.audioUrl();
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (_) {
      // Pronunciation is best-effort; the meaning still shows.
    }
  }

  Future<void> _run() async {
    try {
      final word = await widget.lookup();
      if (!mounted) return;
      setState(() {
        _meaningEn = word.meaningEn ?? word.meaning;
        _meaningAr = word.meaningAr;
        _example = word.example;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = widget.strings.lookupFailed as String);
    }
  }

  /// A labelled section with its own text direction so English and Arabic
  /// never get mixed into one garbled line.
  Widget _section(String label, String text, TextDirection dir,
      {FontStyle? style}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.navy900.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(text,
              textDirection: dir,
              textAlign:
                  dir == TextDirection.rtl ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 15,
                  height: 1.6,
                  fontStyle: style)),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(widget.word,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            IconButton(
              tooltip: s.listen as String,
              icon: const Icon(Icons.volume_up,
                  color: AppColors.goldLight, size: 22),
              onPressed: _pronounce,
            ),
          ]),
          const Divider(color: AppColors.navy500, height: 20),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.danger))
          else if (_meaningEn == null)
            Row(children: [
              const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 10),
              Text(s.lookingUp as String,
                  style: const TextStyle(color: AppColors.textFaint)),
            ])
          else ...[
            _section(s.meaningEnLabel as String, _meaningEn!,
                TextDirection.ltr),
            if (_meaningAr != null && _meaningAr!.isNotEmpty)
              _section(s.meaningArLabel as String, _meaningAr!,
                  TextDirection.rtl),
            if (_example != null && _example!.isNotEmpty)
              _section(s.exampleLabel as String, _example!, TextDirection.ltr,
                  style: FontStyle.italic),
            Row(children: [
              const Icon(Icons.check_circle,
                  size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(s.savedToVocab as String,
                    style: const TextStyle(
                        color: AppColors.success, fontSize: 13)),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
