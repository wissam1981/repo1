import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/contracts_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/tutor_provider.dart';
import '../theme.dart';

/// AI tutor chat. A session is created automatically on open — no dead
/// "no session" state. Pass [contractId] to anchor the tutor to a contract;
/// otherwise the user's first contract is used.
class TutorScreen extends StatefulWidget {
  final int? contractId;

  const TutorScreen({super.key, this.contractId});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  String? _startError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  Future<void> _ensureSession() async {
    final tutor = Provider.of<TutorProvider>(context, listen: false);
    var contractId = widget.contractId;
    if (contractId == null) {
      final active =
          Provider.of<ContractsProvider>(context, listen: false).activeContract;
      if (active == null) {
        final s = Provider.of<LocaleProvider>(context, listen: false).s;
        setState(() => _startError = s.noContract);
        return;
      }
      contractId = active.id;
    }
    try {
      await tutor.ensureSession(contractId);
    } catch (e) {
      if (mounted) setState(() => _startError = e.toString());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.tutorTitle),
        actions: [
          Consumer<TutorProvider>(
            builder: (_, tutor, __) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(s.levelN(tutor.difficulty),
                      style: const TextStyle(
                          color: AppColors.goldDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<TutorProvider>(
              builder: (context, tutor, _) {
                if (_startError != null) {
                  return Center(
                    child: Text(_startError!,
                        style: const TextStyle(color: AppColors.textMuted)),
                  );
                }
                final session = tutor.session;
                if (session == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(s.tutorStarting,
                            style:
                                const TextStyle(color: AppColors.textFaint)),
                      ],
                    ),
                  );
                }
                final messages = session.messages;
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length + (tutor.isSending ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == messages.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      );
                    }
                    final m = messages[i];
                    final isUser = m.role == 'user';
                    return Align(
                      alignment: isUser
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 480),
                        decoration: BoxDecoration(
                          color:
                              isUser ? AppColors.goldLight : AppColors.navy700,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m.content,
                          // Arabic answers render right-to-left, English
                          // left-to-right — detected per message.
                          textDirection: _isArabic(m.content)
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: TextStyle(
                            color: isUser
                                ? AppColors.goldDark
                                : AppColors.textLight,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: InputDecoration(hintText: s.tutorHint),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<TutorProvider>(
                    builder: (_, tutor, __) => IconButton(
                      icon: const Icon(Icons.send, color: AppColors.gold),
                      onPressed: tutor.isSending || tutor.session == null
                          ? null
                          : _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await Provider.of<TutorProvider>(context, listen: false)
          .sendMessage(text);
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ $e')));
    }
  }
}


/// True when [text] is predominantly Arabic (any Arabic letters present).
bool _isArabic(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);
