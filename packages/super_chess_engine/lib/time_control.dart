/// Lobby / match time controls.
class TimeControl {
  const TimeControl({
    required this.id,
    required this.initialSec,
    required this.incrementSec,
  });

  final String id;
  final int initialSec;
  final int incrementSec;

  int get initialMs => initialSec * 1000;
  int get incrementMs => incrementSec * 1000;

  String get label =>
      incrementSec == 0 ? '$initialSec+0' : '$initialSec+$incrementSec';

  RatingBucket get bucket {
    final total = initialSec + 40 * incrementSec;
    if (total < 179) return RatingBucket.bullet;
    if (total < 479) return RatingBucket.blitz;
    return RatingBucket.rapid;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'initialSec': initialSec,
        'incrementSec': incrementSec,
        'initialMs': initialMs,
        'incrementMs': incrementMs,
        'bucket': bucket.name,
        'label': label,
      };

  static TimeControl? byId(String id) {
    for (final tc in kLobbyTimeControls) {
      if (tc.id == id) return tc;
    }
    return null;
  }
}

enum RatingBucket { bullet, blitz, rapid }

const List<TimeControl> kLobbyTimeControls = [
  TimeControl(id: '1+0', initialSec: 60, incrementSec: 0),
  TimeControl(id: '3+0', initialSec: 180, incrementSec: 0),
  TimeControl(id: '3+2', initialSec: 180, incrementSec: 2),
  TimeControl(id: '5+0', initialSec: 300, incrementSec: 0),
  TimeControl(id: '10+0', initialSec: 600, incrementSec: 0),
  TimeControl(id: '15+10', initialSec: 900, incrementSec: 10),
];

TimeControl get defaultTimeControl =>
    TimeControl.byId('5+0') ?? kLobbyTimeControls[3];
