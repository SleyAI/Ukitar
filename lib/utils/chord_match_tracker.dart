import 'dart:math';

/// Tracks matched strings within a rolling time window to determine whether a
/// chord has been recognised.
class ChordMatchTracker {
  ChordMatchTracker({
    required this.matchWindow,
    this.completionRatio = 1.0,
  }) : assert(
          completionRatio > 0 && completionRatio <= 1,
          'completionRatio must be between 0 and 1.',
        );

  final Duration matchWindow;
  final double completionRatio;

  final Map<int, DateTime> _matches = <int, DateTime>{};

  /// Records that [stringIndex] was detected at [timestamp]. Returns `true` if
  /// the string is considered a new match within the current window.
  bool registerMatch({
    required int stringIndex,
    required Set<int> requiredStrings,
    DateTime? timestamp,
  }) {
    final DateTime now = timestamp ?? DateTime.now();
    _prune(requiredStrings, now);
    if (!requiredStrings.contains(stringIndex)) {
      return false;
    }
    final bool isNew = !_matches.containsKey(stringIndex);
    _matches[stringIndex] = now;
    return isNew;
  }

  /// Returns the number of matched required strings currently tracked.
  int matchedCount(Set<int> requiredStrings, {DateTime? timestamp}) {
    final DateTime now = timestamp ?? DateTime.now();
    _prune(requiredStrings, now);
    return _matches.keys.where(requiredStrings.contains).length;
  }

  /// Returns the currently matched required strings.
  List<int> matchedStrings(Set<int> requiredStrings, {DateTime? timestamp}) {
    final DateTime now = timestamp ?? DateTime.now();
    _prune(requiredStrings, now);
    return _matches.keys
        .where(requiredStrings.contains)
        .toList(growable: false);
  }

  /// Whether any required string has been matched recently.
  bool hasMatches(Set<int> requiredStrings, {DateTime? timestamp}) {
    final DateTime now = timestamp ?? DateTime.now();
    _prune(requiredStrings, now);
    return _matches.keys.any(requiredStrings.contains);
  }

  /// Returns `true` when enough required strings have been detected within the
  /// rolling window according to [completionRatio].
  bool isComplete(Set<int> requiredStrings, {DateTime? timestamp}) {
    if (requiredStrings.isEmpty) {
      return false;
    }
    final DateTime now = timestamp ?? DateTime.now();
    _prune(requiredStrings, now);
    final int matched = _matches.keys.where(requiredStrings.contains).length;
    final int requiredCount = requiredStrings.length;
    final int requiredMatches = max(1, (requiredCount * completionRatio).ceil());
    return matched >= min(requiredMatches, requiredCount);
  }

  void reset() {
    _matches.clear();
  }

  void _prune(Set<int> requiredStrings, DateTime now) {
    _matches.removeWhere((int key, DateTime value) {
      if (!requiredStrings.contains(key)) {
        return true;
      }
      return now.difference(value) > matchWindow;
    });
  }
}
