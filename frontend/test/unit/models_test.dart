import 'package:contract_english_trainer/models/user.dart';
import 'package:contract_english_trainer/models/contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Models', () {
    test('User.fromJson parses correctly', () {
      final json = {
        'id': 1,
        'email': 'test@example.com',
        'auth_provider': 'google',
        'cefr_level': 'A1',
      };
      final user = User.fromJson(json);
      expect(user.id, 1);
      expect(user.email, 'test@example.com');
      expect(user.cerfLevel, 'A1');
    });

    test('Contract.fromJson with clauses parses correctly', () {
      final json = {
        'id': 1,
        'title': 'Test Contract',
        'file_url': 's3://x',
        'status': 'explained',
        'clauses': [
          {
            'id': 10,
            'order': 1,
            'original_text': 'Clause text.',
            'simple_en': 'Simple version.',
            'arabic': 'نسخة عربية.',
            'key_terms': [
              {'term': 'term1', 'meaning': 'def1'}
            ],
          }
        ],
      };
      final contract = Contract.fromJson(json);
      expect(contract.title, 'Test Contract');
      expect(contract.clauses.length, 1);
      expect(contract.clauses[0].keyTerms[0].term, 'term1');
    });
  });
}
