class Square {
  const Square(this.file, this.rank);

  /// 0 = a-file, 7 = h-file
  final int file;

  /// 0 = first rank (white back rank), 7 = eighth rank
  final int rank;

  bool get isValid =>
      file >= 0 && file < 8 && rank >= 0 && rank < 8;

  String get algebraic {
    return '${String.fromCharCode(97 + file)}${rank + 1}';
  }

  @override
  bool operator ==(Object other) {
    return other is Square && other.file == file && other.rank == rank;
  }

  @override
  int get hashCode => Object.hash(file, rank);

  @override
  String toString() => algebraic;
}
