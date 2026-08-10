import 'package:super_chess_engine/super_chess_engine.dart';
import 'package:test/test.dart';

void main() {
  test('lobby time controls buckets', () {
    expect(TimeControl.byId('1+0')!.bucket, RatingBucket.bullet);
    expect(TimeControl.byId('3+0')!.bucket, RatingBucket.blitz);
    expect(TimeControl.byId('5+0')!.bucket, RatingBucket.blitz);
    expect(TimeControl.byId('15+10')!.bucket, RatingBucket.rapid);
  });

  test('pgn builds headers and moves', () {
    final pgn = buildPgn(
      headers: {'White': 'A', 'Black': 'B'},
      sans: ['e2e4', 'e7e5'],
      result: '1-0',
    );
    expect(pgn, contains('[White "A"]'));
    expect(pgn, contains('1. e2e4 e7e5'));
    expect(pgn, contains('1-0'));
  });

  test('server clock increments after move', () {
    final clock = ServerClock(TimeControl.byId('3+2')!);
    clock.start('white');
    clock.afterMove('white');
    expect(clock.blackMs, greaterThan(0));
    expect(clock.snapshot()['active'], 'black');
  });
}
