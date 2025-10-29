import 'package:hive/hive.dart';

class SessionService {
  static const String _boxName = 'session';
  static const String _keyLoggedUserId = 'loggedUserId';

  Future<Box> _box() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<void> setLoggedIn({required String userId}) async {
    final box = await _box();
    await box.put(_keyLoggedUserId, userId);
  }

  Future<String?> getLoggedInUserId() async {
    final box = await _box();
    final v = box.get(_keyLoggedUserId);
    if (v is String && v.isNotEmpty) return v;
    return null;
  }

  Future<void> logout() async {
    final box = await _box();
    await box.delete(_keyLoggedUserId);
  }
}
