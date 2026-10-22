/// Remembers which incident ids were already shown so the siren only rings
/// for incidents that appear AFTER the first successful load.
class NewIncidentDetector {
  final Set<int> _seen = {};
  bool _primed = false;

  /// Returns true when [ids] contains an id that was never seen before.
  bool update(Iterable<int> ids) {
    final current = ids.toSet();
    final hasNew = _primed && current.difference(_seen).isNotEmpty;
    _seen.addAll(current);
    _primed = true;
    return hasNew;
  }
}
