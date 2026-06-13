/// Lightweight bilingual UI strings (Arabic default, English toggle).
///
/// Learning CONTENT (clause text, explanations) is not translated here —
/// only the app chrome (titles, buttons, hints).
class AppStrings {
  final String locale; // 'ar' or 'en'
  const AppStrings(this.locale);

  bool get isArabic => locale == 'ar';

  String _t(String ar, String en) => isArabic ? ar : en;

  // General
  String get appTitle => _t('مدرّب عقود الإنجليزية', 'Contract English Trainer');
  String get back => _t('رجوع', 'Back');
  String get next => _t('التالي', 'Next');
  String get cancel => _t('إلغاء', 'Cancel');
  String get retry => _t('إعادة المحاولة', 'Retry');
  String get loading => _t('جارٍ التحميل...', 'Loading...');

  // Login
  String get signIn => _t('تسجيل الدخول', 'Sign In');
  String get signInGoogle => _t('الدخول عبر Google', 'Sign in with Google');
  String get signInApple => _t('الدخول عبر Apple', 'Sign in with Apple');
  String get continueGuest => _t('المتابعة كضيف', 'Continue as Guest');

  // Journey
  String get journeyTitle => _t('رحلتك', 'Your Journey');
  String get journeySubtitle =>
      _t('رحلتك في تعلّم الإنجليزية القانونية', 'Your legal English journey');
  String get todaysClause => _t('بند اليوم', "Today's clause");
  String get startLesson => _t('ابدأ الدرس', 'Start lesson');
  String get continueLesson => _t('أكمل الدرس', 'Continue lesson');
  String get completed => _t('مكتمل', 'Completed');
  String get locked => _t('مقفل', 'Locked');
  String get current => _t('الحالي', 'Current');
  String progressOf(int done, int total) => _t(
      '$done من $total بنداً مكتمل', '$done of $total clauses completed');
  String get noContract =>
      _t('ارفع عقدك الأول لتبدأ الرحلة', 'Upload your first contract to begin');
  String get uploadContract => _t('رفع عقد', 'Upload contract');
  String get contractTitleHint =>
      _t('عنوان العقد (مثل: اتفاقية خدمات)', 'Contract title (e.g., Service Agreement)');
  String get uploading => _t('جارٍ الرفع والمعالجة...', 'Uploading & processing...');
  String get uploadDone =>
      _t('تم رفع العقد! جارٍ الشرح...', 'Contract uploaded! Explaining...');
  String get processingTitle =>
      _t('جارٍ معالجة العقد', 'Processing contract');
  String get stageQueued => _t('في الانتظار...', 'Queued...');
  String get stageSplitting =>
      _t('تقسيم العقد إلى بنود...', 'Splitting into clauses...');
  String stageExplaining(int done, int total) => _t(
      'شرح البند $done من $total...', 'Explaining clause $done of $total...');
  String get stageSaving => _t('جارٍ الحفظ...', 'Saving...');
  String get processingFailed => _t(
      'فشلت معالجة العقد — حاول مجدداً', 'Processing failed — please retry');
  String get processingDone =>
      _t('اكتملت المعالجة!', 'Processing complete!');
  String get allDone =>
      _t('أكملت كل البنود! أحسنت', 'All clauses completed! Well done');

  // Clause study
  String get stageRead => _t('اقرأ', 'Read');
  String get stageUnderstand => _t('افهم', 'Understand');
  String get stageQuiz => _t('اختبر', 'Quiz');
  String get tapAnyWord =>
      _t('اضغط أي كلمة لمعرفة معناها وحفظها', 'Tap any word to see its meaning and save it');
  String get savedToVocab =>
      _t('حُفظت في مفرداتك — ستراجعها لاحقاً', 'Saved to your vocabulary — review it later');
  String get lookingUp => _t('جارٍ البحث عن المعنى...', 'Looking up...');
  String get lookupFailed =>
      _t('تعذّر جلب المعنى الآن', 'Could not look up the word right now');
  String get simpleExplanation => _t('الشرح المبسّط', 'Simple explanation');
  String get arabicExplanation => _t('الشرح بالعربية', 'Arabic explanation');
  String get keyTerms => _t('المصطلحات المهمة', 'Key terms');
  String get generateQuiz => _t('ابدأ الاختبار', 'Start quiz');
  String get generatingQuiz => _t('جارٍ توليد الأسئلة...', 'Generating questions...');
  String get submitAnswers => _t('سلّم الإجابات', 'Submit answers');
  String get quizPassed => _t('أحسنت! اكتمل البند', 'Well done! Clause completed');
  String get quizFailed =>
      _t('قريب! راجع البند وحاول مجدداً', 'Almost! Review the clause and retry');
  String yourScore(int pct) => _t('نتيجتك: $pct%', 'Your score: $pct%');
  String get nextClause => _t('البند التالي', 'Next clause');
  String get backToJourney => _t('العودة للرحلة', 'Back to journey');
  String clauseN(int n) => _t('البند $n', 'Clause $n');
  String get definitionTag => _t('تعريف', 'Definition');
  String get appearsIn =>
      _t('يرد هذا المصطلح في:', 'This term appears in:');
  String get listen => _t('استمع', 'Listen');
  String get meaningEnLabel => _t('المعنى بالإنجليزية', 'Meaning (English)');
  String get meaningArLabel => _t('المعنى بالعربية', 'Meaning (Arabic)');
  String get exampleLabel => _t('مثال', 'Example');
  String get stopListening => _t('إيقاف', 'Stop');

  // Vocabulary
  String get vocabTitle => _t('مفرداتي', 'My Vocabulary');
  String get noWordsDue => _t(
      'لا كلمات للمراجعة الآن — اقرأ بنوداً واضغط الكلمات الجديدة',
      'No words due — read clauses and tap new words');
  String get howWellKnew => _t('كيف كانت معرفتك بها؟', 'How well did you know it?');
  String get knewIt => _t('أعرفها', 'Knew it');
  String get fuzzy => _t('تقريباً', 'Fuzzy');
  String get forgot => _t('نسيتها', 'Forgot');

  // Tutor
  String get tutorTitle => _t('المعلّم الذكي', 'AI Tutor');
  String get tutorHint => _t('اكتب رسالتك...', 'Type a message...');
  String get tutorStarting => _t('جارٍ فتح الجلسة...', 'Starting session...');
  String levelN(int n) => _t('المستوى $n', 'Level $n');

  // Progress
  String get progressTitle => _t('تقدّمي', 'My Progress');
  String get cefrLevel => _t('مستوى اللغة', 'CEFR level');
  String get wordsSaved => _t('كلمات محفوظة', 'Words saved');
  String get wordsDue => _t('كلمات للمراجعة', 'Words due');
  String get clausesDone => _t('بنود مكتملة', 'Clauses completed');
  String get quizzesTaken => _t('اختبارات', 'Quizzes taken');
  String get dayStreak => _t('أيام متواصلة', 'Day streak');
  String get reviewWords => _t('راجع كلماتك', 'Review your words');
  String get askTutor => _t('اسأل المعلّم', 'Ask the tutor');

  // Navigation
  String get navJourney => _t('الرحلة', 'Journey');
  String get navVocab => _t('المفردات', 'Vocabulary');
  String get navTutor => _t('المعلّم', 'Tutor');
  String get navProgress => _t('التقدّم', 'Progress');
  String get logout => _t('تسجيل الخروج', 'Log out');
}
