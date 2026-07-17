import 'package:flutter/foundation.dart';
import 'parent_repository.dart';

class SelectedChildProvider extends ChangeNotifier {
  final _repo = ParentRepository();
  List<Map<String, dynamic>> children = [];
  int? selectedChildId;
  bool loading = true;
  bool _initialized = false;

  Map<String, dynamic>? get selectedChild => children.where((c) => c['id'] == selectedChildId).firstOrNull;

  /// Fetches the children list once per app session — safe to call from
  /// every Parent screen's initState without re-fetching on every navigation.
  Future<void> ensureLoaded() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final list = await _repo.getChildren();
      children = list;
      if (selectedChildId == null || !list.any((c) => c['id'] == selectedChildId)) {
        selectedChildId = list.isNotEmpty ? list.first['id'] as int : null;
      }
    } catch (_) {
      children = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void select(int childId) {
    selectedChildId = childId;
    notifyListeners();
  }

  Future<void> linkChild(int childId) async {
    final updated = await _repo.linkChild(childId);
    children = updated;
    selectedChildId = childId;
    notifyListeners();
  }
}
