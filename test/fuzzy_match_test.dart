import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/utils/fuzzy_match.dart';

void main() {
  group('Levenshtein Distance', () {
    test('Exact match has distance 0', () {
      expect(FuzzyMatch.levenshteinDistance('Exide', 'exide'), 0);
    });

    test('Single character difference has distance 1', () {
      expect(FuzzyMatch.levenshteinDistance('exid', 'exide'), 1);
      expect(FuzzyMatch.levenshteinDistance('amaron', 'amarn'), 1);
    });

    test('Two character differences have distance 2', () {
      expect(FuzzyMatch.levenshteinDistance('exd', 'exide'), 2);
    });
  });

  group('Fuzzy Company Autocomplete Ranking', () {
    final companies = ['Exide', 'Surya', 'Amaron', 'Star', 'Power', 'AVM', 'ABM'];

    test('Empty query returns original list', () {
      final suggestions = FuzzyMatch.rankSuggestions(query: '', allCompanies: companies);
      expect(suggestions, companies);
    });

    test('Prefix match ranks highest', () {
      final suggestions = FuzzyMatch.rankSuggestions(query: 'ex', allCompanies: companies);
      expect(suggestions.first, 'Exide');
    });

    test('Contains match ranks after prefix', () {
      final suggestions = FuzzyMatch.rankSuggestions(query: 'ide', allCompanies: companies);
      expect(suggestions.contains('Exide'), isTrue);
    });

    test('Tolerates typo: "exid" matches "Exide" within distance 2', () {
      final suggestions = FuzzyMatch.rankSuggestions(query: 'exid', allCompanies: companies);
      expect(suggestions.contains('Exide'), isTrue);
    });

    test('Tolerates typo: "amrn" matches "Amaron" within distance 2', () {
      final suggestions = FuzzyMatch.rankSuggestions(query: 'amrn', allCompanies: companies);
      expect(suggestions.contains('Amaron'), isTrue);
    });

    test('Tolerates typo: "suria" matches "Surya" within distance 2', () {
      final suggestions = FuzzyMatch.rankSuggestions(query: 'suria', allCompanies: companies);
      expect(suggestions.contains('Surya'), isTrue);
    });
  });
}
