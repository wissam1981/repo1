#!/bin/zsh
# convert_contract.sh — أداة تحويل العقود للرفع في التطبيق
#
# الاستخدام:  ./convert_contract.sh "ملف العقد.pdf" [مجلد الإخراج]
#
# تكتشف تلقائياً نوع الملف:
#   - PDF رقمي (فيه طبقة نص)  → استخراج مباشر فائق الدقة
#   - PDF مسحوب سكانر         → OCR بمحرك Tesseract (عربي + إنجليزي)
#   - Word (.doc/.docx)        → تحويل نصي مباشر
# الناتج: ملف .txt نظيف بحجم أصغر بمئات المرات، جاهز للرفع في التطبيق.

set -e
INPUT="$1"
OUTDIR="${2:-$HOME/Desktop/عقود_جاهزة_للرفع}"
[ -z "$INPUT" ] && { echo "الاستخدام: $0 <ملف العقد> [مجلد الإخراج]"; exit 1; }
mkdir -p "$OUTDIR"

BASE="${INPUT:t:r}"
OUT="$OUTDIR/$BASE.txt"

case "${INPUT:l}" in
  *.doc|*.docx)
    textutil -convert txt -stdout "$INPUT" > "$OUT"
    ;;
  *.pdf)
    # هل توجد طبقة نص؟ (نفحص أول 5 صفحات)
    CHARS=$(pdftotext -l 5 "$INPUT" - 2>/dev/null | tr -d '[:space:]' | wc -c | tr -d ' ')
    if [ "$CHARS" -gt 500 ]; then
      echo "✓ PDF رقمي — استخراج مباشر"
      pdftotext "$INPUT" "$OUT"
    else
      echo "⚙ PDF مسحوب سكانر — جارٍ الـ OCR (قد يستغرق دقائق حسب عدد الصفحات)..."
      TMP="$(mktemp -t ocr).pdf"
      ocrmypdf --language ara+eng --force-ocr --optimize 0 --output-type pdf \
               --jobs 4 "$INPUT" "$TMP" 2>/dev/null
      pdftotext "$TMP" "$OUT"
      rm -f "$TMP"
    fi
    ;;
  *)
    echo "نوع غير مدعوم: $INPUT"; exit 1
    ;;
esac

ORIG_SIZE=$(du -h "$INPUT" | cut -f1)
NEW_SIZE=$(du -h "$OUT" | cut -f1)
WORDS=$(wc -w < "$OUT" | tr -d ' ')
echo "✅ $BASE: $ORIG_SIZE ← $NEW_SIZE | $WORDS كلمة"
echo "   الناتج: $OUT"
