import 'package:shared_preferences/shared_preferences.dart';

import '../models/instrument.dart';

abstract class PracticeProgressRepository {
  Future<int?> loadUnlockedChords(InstrumentType instrument);

  Future<void> saveUnlockedChords(InstrumentType instrument, int unlocked);

  Future<void> clearUnlockedChords(InstrumentType instrument);
}

class SharedPreferencesPracticeProgressRepository
    implements PracticeProgressRepository {
  SharedPreferencesPracticeProgressRepository(
      {Future<SharedPreferences>? preferences})
      : _preferencesFuture =
            preferences ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferencesFuture;

  static const String _storageKeyPrefix = 'practice_progress_';

  @override
  Future<int?> loadUnlockedChords(InstrumentType instrument) async {
    final SharedPreferences preferences = await _preferencesFuture;
    return preferences.getInt(_storageKey(instrument));
  }

  @override
  Future<void> saveUnlockedChords(
      InstrumentType instrument, int unlocked) async {
    final SharedPreferences preferences = await _preferencesFuture;
    await preferences.setInt(_storageKey(instrument), unlocked);
  }

  @override
  Future<void> clearUnlockedChords(InstrumentType instrument) async {
    final SharedPreferences preferences = await _preferencesFuture;
    await preferences.remove(_storageKey(instrument));
  }

  String _storageKey(InstrumentType instrument) =>
      '$_storageKeyPrefix${instrument.name}';
}
