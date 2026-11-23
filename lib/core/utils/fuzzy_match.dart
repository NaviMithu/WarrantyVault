import 'dart:math';

/// Levenshtein distance and smart ranking for company autocomplete.
class FuzzyMatch {
  /// Computes the Levenshtein edit distance between two strings.
  static int levenshteinDistance(String a, String b) {
    final s1 = a.toLowerCase();
    final s2 = b.toLowerCase();

    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        final cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  /// Filters and ranks company suggestions based on [query].
  ///
  /// Ordering:
  /// 1. Prefix matches (e.g. "Ex" -> "Exide")
  /// 2. Contains matches (e.g. "id" -> "Exide")
  /// 3. Fuzzy matches with Levenshtein distance <= 2 (e.g. "exid" -> "Exide", "amrn" -> "Amaron")
  ///
  /// If [query] is empty, returns [allCompanies] in their current order (e.g. sorted by usage frequency).
  static List<String> rankSuggestions({
    required String query,
    required List<String> allCompanies,
    int maxLevenshtein = 2,
  }) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return List<String>.from(allCompanies);
    }

    final prefixMatches = <String>[];
    final containsMatches = <String>[];
    final fuzzyMatches = <MapEntry<String, int>>[];

    for (final company in allCompanies) {
      final lower = company.toLowerCase();
      if (lower.startsWith(trimmed)) {
        prefixMatches.add(company);
      } else if (lower.contains(trimmed)) {
        containsMatches.add(company);
      } else {
        final dist = levenshteinDistance(trimmed, lower);
        if (dist <= maxLevenshtein) {
          fuzzyMatches.add(MapEntry(company, dist));
        } else {
          // Also check distance against words or prefixes if query is shorter
          final subDist = _minSubstringDistance(trimmed, lower);
          if (subDist <= maxLevenshtein) {
            fuzzyMatches.add(MapEntry(company, subDist));
          }
        }
      }
    }

    // Sort fuzzy matches by edit distance ascending
    fuzzyMatches.sort((a, b) => a.value.compareTo(b.value));

    final result = <String>[
      ...prefixMatches,
      ...containsMatches,
      ...fuzzyMatches.map((e) => e.key),
    ];

    // Remove duplicates while preserving rank order
    final seen = <String>{};
    return result.where((c) => seen.add(c.toLowerCase())).toList();
  }

  static int _minSubstringDistance(String pattern, String text) {
    if (pattern.length >= text.length) {
      return levenshteinDistance(pattern, text);
    }
    // Check pattern against first N characters
    return levenshteinDistance(pattern, text.substring(0, min(text.length, pattern.length + 1)));
  }
}
