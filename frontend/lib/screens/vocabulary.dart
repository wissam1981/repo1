import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../providers/vocabulary_provider.dart';
import '../theme.dart';

/// Spaced-repetition review of saved words. Words arrive here automatically
/// when the user taps them while reading clauses.
class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VocabularyProvider>(context, listen: false)
          .loadDueWords()
          .catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().s;
    return Scaffold(
      appBar: AppBar(title: Text(s.vocabTitle)),
      body: Consumer<VocabularyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.dueWords.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book,
                        size: 52, color: AppColors.goldLight),
                    const SizedBox(height: 14),
                    Text(
                      s.noWordsDue,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 15),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: provider.dueWords.length,
            itemBuilder: (context, index) {
              final word = provider.dueWords[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word.term,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 18)),
                      const SizedBox(height: 6),
                      Text(word.meaning,
                          style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 14,
                              height: 1.6)),
                      if (word.example.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('"${word.example}"',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                                color: AppColors.textFaint,
                                fontSize: 13,
                                fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 10),
                      Text(s.howWellKnew,
                          style: const TextStyle(
                              color: AppColors.textFaint, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _gradeBtn(context, s.forgot, AppColors.danger,
                              () => _review(provider, word.id, 1)),
                          const SizedBox(width: 8),
                          _gradeBtn(context, s.fuzzy, AppColors.goldLight,
                              () => _review(provider, word.id, 3)),
                          const SizedBox(width: 8),
                          _gradeBtn(context, s.knewIt, AppColors.success,
                              () => _review(provider, word.id, 5)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _gradeBtn(
      BuildContext context, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.6)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  /// The backend creates exactly one review per word on save, so the word id
  /// doubles as the review id (1:1 mapping).
  Future<void> _review(
      VocabularyProvider provider, int wordId, int quality) async {
    try {
      await provider.recordReview(wordId, quality, wordId: wordId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ $e')));
    }
  }
}
