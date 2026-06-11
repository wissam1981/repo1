import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contract.dart';
import '../providers/auth_provider.dart';
import '../providers/contracts_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/quizzes_provider.dart';
import '../services/file_pick_helper.dart';
import '../theme.dart';
import 'clause_study.dart';

/// The journey home: contract progress, today's clause, and the clause path.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContractsProvider>(context, listen: false)
          .loadContracts()
          .catchError((_) {});
      Provider.of<QuizzesProvider>(context, listen: false)
          .loadHistory()
          .catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.journeyTitle),
        leading: IconButton(
          tooltip: 'ع / EN',
          icon: const Icon(Icons.translate),
          onPressed: () =>
              Provider.of<LocaleProvider>(context, listen: false).toggle(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: s.navVocab,
            onPressed: () => Navigator.of(context).pushNamed('/vocabulary'),
          ),
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: s.navProgress,
            onPressed: () => Navigator.of(context).pushNamed('/dashboard'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: s.logout,
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Consumer<ContractsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.contracts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final contract = provider.activeContract;
          if (contract == null) {
            return _emptyState(context, s);
          }
          return _journey(context, s, contract);
        },
      ),
      floatingActionButton: Consumer<ContractsProvider>(
        builder: (context, provider, _) => provider.contracts.isEmpty
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                backgroundColor: AppColors.goldLight,
                foregroundColor: AppColors.goldDark,
                onPressed: () => _uploadContract(context, s),
                icon: const Icon(Icons.add),
                label: Text(s.uploadContract,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, dynamic s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.gavel, size: 56, color: AppColors.goldLight),
          const SizedBox(height: 16),
          Text(s.noContract,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _uploadContract(context, s),
            icon: const Icon(Icons.upload_file),
            label: Text(s.uploadContract),
          ),
        ],
      ),
    );
  }

  Widget _journey(BuildContext context, dynamic s, Contract contract) {
    final total = contract.clauses.length;
    final done = contract.clauses.where((c) => c.completed).length;
    final progress = total == 0 ? 0.0 : done / total;
    Clause? today;
    for (final c in contract.clauses) {
      if (!c.completed) {
        today = c;
        break;
      }
    }
    final streak = _streak(context);
    final currentOrder = today?.order ?? (total + 1);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _contractSwitcher(context, s, contract),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.local_fire_department,
                    size: 16, color: AppColors.goldMid),
                const SizedBox(width: 4),
                Text('$streak',
                    style: const TextStyle(
                        color: AppColors.goldDark,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(s.journeySubtitle,
            style: const TextStyle(color: AppColors.textFaint, fontSize: 13)),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.navy700,
          ),
        ),
        const SizedBox(height: 6),
        Text(s.progressOf(done, total),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 18),
        if (today != null)
          _todayCard(context, s, contract, today)
        else
          Card(
            color: AppColors.goldLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.emoji_events, color: AppColors.goldMid),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s.allDone,
                      style: const TextStyle(
                          color: AppColors.goldDark,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ),
        const SizedBox(height: 18),
        ...contract.clauses.map((c) =>
            _pathTile(context, s, contract, c, isCurrent: c.order == currentOrder)),
      ],
    );
  }

  /// The contract title doubles as a switcher between the user's contracts.
  Widget _contractSwitcher(BuildContext context, dynamic s, Contract active) {
    final provider = Provider.of<ContractsProvider>(context, listen: false);
    return PopupMenuButton<int>(
      tooltip: s.navJourney,
      color: AppColors.navy700,
      onSelected: (id) {
        if (id == -1) {
          _uploadContract(context, s);
          return;
        }
        for (final c in provider.contracts) {
          if (c.id == id) {
            provider.selectContract(c);
            break;
          }
        }
      },
      itemBuilder: (ctx) => [
        ...provider.contracts.map((c) => PopupMenuItem<int>(
              value: c.id,
              child: Row(children: [
                Icon(
                  c.id == active.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: AppColors.goldLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 14)),
                ),
              ]),
            )),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: -1,
          child: Row(children: [
            const Icon(Icons.add, size: 18, color: AppColors.goldLight),
            const SizedBox(width: 8),
            Text(s.uploadContract,
                style: const TextStyle(
                    color: AppColors.goldLight, fontSize: 14)),
          ]),
        ),
      ],
      child: Row(children: [
        Flexible(
          child: Text(active.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight)),
        ),
        const Icon(Icons.arrow_drop_down, color: AppColors.goldLight),
      ]),
    );
  }

  Widget _todayCard(
      BuildContext context, dynamic s, Contract contract, Clause clause) {
    final preview = clause.originalText.replaceAll('\n', ' ');
    return Card(
      color: AppColors.goldLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.todaysClause,
                style: const TextStyle(color: AppColors.goldMid, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              preview.length > 90 ? '${preview.substring(0, 90)}…' : preview,
              style: const TextStyle(
                  color: AppColors.goldDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy900,
                foregroundColor: AppColors.goldLight,
              ),
              onPressed: () => _openClause(context, contract, clause),
              icon: const Icon(Icons.play_arrow),
              label: Text(s.startLesson),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pathTile(BuildContext context, dynamic s, Contract contract,
      Clause clause, {required bool isCurrent}) {
    final locked = !clause.completed && !isCurrent;
    final preview = clause.originalText.replaceAll('\n', ' ');
    final label = preview.length > 60 ? '${preview.substring(0, 60)}…' : preview;

    IconData icon;
    Color iconColor;
    if (clause.completed) {
      icon = Icons.check_circle;
      iconColor = AppColors.gold;
    } else if (isCurrent) {
      icon = Icons.school;
      iconColor = AppColors.goldLight;
    } else {
      icon = Icons.lock_outline;
      iconColor = AppColors.textFaint;
    }

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Card(
        shape: isCurrent
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.gold),
              )
            : null,
        child: ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(
            '${s.clauseN(clause.order)} — $label',
            style: TextStyle(
              fontSize: 13,
              color: isCurrent ? AppColors.textLight : AppColors.textMuted,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
          ),
          onTap: locked ? null : () => _openClause(context, contract, clause),
        ),
      ),
    );
  }

  void _openClause(BuildContext context, Contract contract, Clause clause) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClauseStudyScreen(contract: contract, clause: clause),
    ));
  }

  int _streak(BuildContext context) {
    final history =
        Provider.of<QuizzesProvider>(context, listen: false).history;
    final days = <String>{};
    for (final a in history) {
      final d = a.createdAt;
      if (d != null && d.length >= 10) days.add(d.substring(0, 10));
    }
    var streak = 0;
    var day = DateTime.now();
    while (days.contains(day.toIso8601String().substring(0, 10))) {
      streak += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _uploadContract(BuildContext context, dynamic s) async {
    try {
      final titleController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.navy700,
          title: Text(s.uploadContract,
              style: const TextStyle(color: AppColors.textLight)),
          content: TextField(
            controller: titleController,
            autofocus: true,
            style: const TextStyle(color: AppColors.textLight),
            decoration: InputDecoration(hintText: s.contractTitleHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.next),
            ),
          ],
        ),
      );
      if (confirmed != true || titleController.text.isEmpty) {
        titleController.dispose();
        return;
      }
      final title = titleController.text;
      titleController.dispose();

      final picked = await pickContractFile();
      if (picked == null || !mounted) return;

      // Upload returns immediately; processing continues server-side.
      final contract =
          await Provider.of<ContractsProvider>(context, listen: false)
              .uploadContract(title: title, file: picked);

      if (!mounted) return;
      final ok = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => _ProcessingDialog(contractId: contract.id),
          ) ??
          false;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? s.processingDone : s.processingFailed),
      ));
      await Provider.of<ContractsProvider>(context, listen: false)
          .loadContracts();
    } catch (e) {
      if (!mounted) return;
      // Surface backend detail (e.g. unsupported file type) when available.
      var msg = e.toString();
      final m = RegExp(r'"detail"\s*:\s*"([^"]+)"').firstMatch(msg);
      if (m != null) msg = m.group(1)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ $msg')));
    }
  }
}

/// Modal shown while the backend splits and explains the uploaded contract.
/// Polls /contracts/{id}/progress and renders a live percentage bar.
class _ProcessingDialog extends StatefulWidget {
  final int contractId;

  const _ProcessingDialog({required this.contractId});

  @override
  State<_ProcessingDialog> createState() => _ProcessingDialogState();
}

class _ProcessingDialogState extends State<_ProcessingDialog> {
  int _percent = 0;
  String _stage = 'queued';
  int _done = 0;
  int _total = 0;
  bool _polling = true;

  @override
  void initState() {
    super.initState();
    _poll();
  }

  @override
  void dispose() {
    _polling = false;
    super.dispose();
  }

  Future<void> _poll() async {
    final contracts = Provider.of<ContractsProvider>(context, listen: false);
    var failures = 0;
    while (_polling && mounted) {
      try {
        final p = await contracts.getProgress(widget.contractId);
        failures = 0;
        if (!mounted) return;
        setState(() {
          _percent = (p['percent'] as num?)?.toInt() ?? 0;
          _stage = p['stage'] as String? ?? 'queued';
          _done = (p['done'] as num?)?.toInt() ?? 0;
          _total = (p['total'] as num?)?.toInt() ?? 0;
        });
        final status = p['status'] as String?;
        if (_stage == 'failed' || status == 'failed') {
          Navigator.of(context).pop(false);
          return;
        }
        if (_stage == 'done' ||
            status == 'explained' ||
            status == 'parsed') {
          Navigator.of(context).pop(true);
          return;
        }
      } catch (_) {
        // Tolerate a few transient polling errors before giving up.
        failures += 1;
        if (failures >= 5 && mounted) {
          Navigator.of(context).pop(false);
          return;
        }
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  String _stageLabel(dynamic s) {
    switch (_stage) {
      case 'splitting':
        return s.stageSplitting as String;
      case 'explaining':
        return s.stageExplaining(_done + 1, _total) as String;
      case 'saving':
        return s.stageSaving as String;
      default:
        return s.stageQueued as String;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().s;
    return AlertDialog(
      backgroundColor: AppColors.navy700,
      title: Text(s.processingTitle,
          style: const TextStyle(color: AppColors.textLight, fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _percent / 100,
              minHeight: 10,
              backgroundColor: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(_stageLabel(s),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
              ),
              Text('$_percent%',
                  style: const TextStyle(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
