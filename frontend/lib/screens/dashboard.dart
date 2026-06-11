import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/contracts_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/quizzes_provider.dart';
import '../providers/vocabulary_provider.dart';
import '../services/file_pick_helper.dart';
import '../theme.dart';
import 'tutor.dart';

/// Progress overview: real journey numbers with tappable next actions.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VocabularyProvider>(context, listen: false)
          .loadDueWords()
          .catchError((_) {});
      Provider.of<QuizzesProvider>(context, listen: false)
          .loadHistory()
          .catchError((_) {});
      Provider.of<ContractsProvider>(context, listen: false)
          .loadContracts()
          .catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().s;
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ContractsProvider>(
          builder: (context, contractsProvider, _) {
            final contractsList = contractsProvider.contracts;
            if (contractsList.isEmpty) return Text(s.progressTitle);

            return DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: contractsProvider.activeContract?.id,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
                dropdownColor: AppColors.navy700,
                style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    final selected =
                        contractsList.firstWhere((c) => c.id == newValue);
                    contractsProvider.selectContract(selected);
                  }
                },
                items: contractsList.map<DropdownMenuItem<int>>((c) {
                  return DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(c.title.length > 18
                        ? '${c.title.substring(0, 18)}...'
                        : c.title),
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: AppColors.goldLight),
            onPressed: () => _uploadContract(context),
            tooltip: s.uploadContract,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer3<ContractsProvider, VocabularyProvider, QuizzesProvider>(
        builder: (context, contractsProvider, vocab, quizzes, _) {
          final contract = contractsProvider.activeContract;
          final total = contract?.clauses.length ?? 0;
          final done =
              contract?.clauses.where((c) => c.completed).length ?? 0;
          final wordsDue = vocab.dueWords.length;
          final attempts = quizzes.history.length;
          final accuracy = attempts == 0
              ? 0
              : (quizzes.history.map((a) => a.score).reduce((a, b) => a + b) /
                      attempts *
                      100)
                  .round();
          final streak = _streak(quizzes);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                _stat(s.clausesDone, '$done / $total', Icons.flag),
                const SizedBox(width: 10),
                _stat(s.dayStreak, '$streak', Icons.local_fire_department),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _stat(s.wordsDue, '$wordsDue', Icons.menu_book),
                const SizedBox(width: 10),
                _stat(s.quizzesTaken, '$attempts ($accuracy%)', Icons.quiz),
              ]),
              const SizedBox(height: 22),
              Text(s.navJourney,
                  style:
                      const TextStyle(color: AppColors.textFaint, fontSize: 13)),
              const SizedBox(height: 8),
              _action(
                icon: Icons.school,
                label: s.startLesson,
                onTap: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              _action(
                icon: Icons.menu_book,
                label: s.reviewWords,
                onTap: () => Navigator.of(context).pushNamed('/vocabulary'),
              ),
              _action(
                icon: Icons.chat_bubble_outline,
                label: s.askTutor,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TutorScreen(contractId: contract?.id),
                )),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.goldLight, size: 22),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold),
        title: Text(label,
            style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textFaint),
        onTap: onTap,
      ),
    );
  }

  int _streak(QuizzesProvider quizzes) {
    final days = <String>{};
    for (final a in quizzes.history) {
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

  Future<void> _uploadContract(BuildContext context) async {
    final s = Provider.of<LocaleProvider>(context, listen: false).s;
    try {
      final picked = await pickContractFile();
      if (picked == null) return;

      if (!context.mounted) return;

      final title = picked.name;

      final provider = Provider.of<ContractsProvider>(context, listen: false);
      await provider.uploadContract(title: title, file: picked);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.uploadDone)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ $e')));
    }
  }
}
