/// Guards async loads against out-of-order completion.
///
/// Call [next] before starting a load and check [isCurrent] with the returned
/// token before applying its result. A newer request (or [invalidate]) makes
/// older tokens stale, so a slow earlier load can't overwrite fresher state.
class RequestSequencer {
  int _latest = 0;

  int next() => ++_latest;

  bool isCurrent(int token) => token == _latest;

  void invalidate() => _latest++;
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
