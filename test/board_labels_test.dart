import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/chess/board_labels.dart';
import 'package:super_chess/l10n/models/square.dart';

void main() {
  test('squareLabel respects left extra file placement', () {
    expect(
      squareLabel(
        const Square(0, 0),
        fileCount: 9,
        extraFile: ExtraFilePlacement.left,
      ),
      'z1',
    );
    expect(
      squareLabel(
        const Square(8, 0),
        fileCount: 9,
        extraFile: ExtraFilePlacement.left,
      ),
      'h1',
    );
  });
}
