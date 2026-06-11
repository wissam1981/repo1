import 'package:flutter/material.dart';
import '../l10n/strings.dart';

/// Owns the UI language ('ar' default, 'en' toggle) and exposes [AppStrings].
class LocaleProvider extends ChangeNotifier {
  String _locale = 'ar';

  String get locale => _locale;
  bool get isArabic => _locale == 'ar';
  AppStrings get s => AppStrings(_locale);
  TextDirection get direction =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  void toggle() {
    _locale = isArabic ? 'en' : 'ar';
    notifyListeners();
  }
}
