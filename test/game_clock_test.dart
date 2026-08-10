import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/l10n/models/piece.dart';
import 'package:super_chess/online/game_clock.dart';

void main() {
  test('deadline countdown only drains the active side', () {
    final clock = GameClock(initialMs: 60 * 1000);
    clock.applySync(
      whiteMs: 55 * 1000,
      blackMs: 60 * 1000,
      active: PieceColor.white,
    );
    // Passive side stays on the frozen snapshot; active reads the deadline.
    expect(clock.msFor(PieceColor.black), 60 * 1000);
    expect(clock.msFor(PieceColor.white), lessThanOrEqualTo(55 * 1000));
    expect(clock.msFor(PieceColor.white), greaterThan(54 * 1000));
  });

  test('pause freezes remaining from deadline', () async {
    final clock = GameClock(initialMs: 10 * 1000);
    clock.resume(PieceColor.black);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    clock.pause();
    final frozen = clock.blackMs;
    expect(frozen, lessThan(10 * 1000));
    expect(frozen, greaterThan(0));
    expect(clock.isRunning, isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(clock.msFor(PieceColor.black), frozen);
  });

  test('applySync with active starts matching deadlines on both clients', () {
    final a = GameClock(initialMs: 5 * 60 * 1000);
    final b = GameClock(initialMs: 5 * 60 * 1000);
    a.applySync(whiteMs: 123000, blackMs: 456000, active: PieceColor.black);
    b.applySync(whiteMs: 123000, blackMs: 456000, active: PieceColor.black);

    expect(a.msFor(PieceColor.white), 123000);
    expect(b.msFor(PieceColor.white), 123000);
    // Active sides share the same remaining snapshot at sync instant.
    expect(
      (a.msFor(PieceColor.black) - b.msFor(PieceColor.black)).abs(),
      lessThan(30),
    );
  });

  test('tick flags when deadline expires', () {
    final clock = GameClock(initialMs: 5 * 60 * 1000);
    clock.applySync(whiteMs: 0, blackMs: 1000, active: PieceColor.white);
    expect(clock.tick(PieceColor.white), isTrue);
    expect(clock.msFor(PieceColor.white), 0);
  });

  test('tick switches running side without draining the previous', () {
    final clock = GameClock(initialMs: 60 * 1000);
    clock.applySync(whiteMs: 40000, blackMs: 50000, active: PieceColor.white);
    expect(clock.tick(PieceColor.white), isFalse);
    clock.pause();
    final whiteFrozen = clock.whiteMs;

    clock.resume(PieceColor.black);
    expect(clock.tick(PieceColor.black), isFalse);
    clock.pause();

    expect(clock.whiteMs, whiteFrozen);
    expect(clock.blackMs, lessThanOrEqualTo(50000));
  });

  test('formatMs pads minutes and seconds', () {
    expect(GameClock.formatMs(0), '00:00');
    expect(GameClock.formatMs(1000), '00:01');
    expect(GameClock.formatMs(61 * 1000), '01:01');
  });
}
