import 'dart:async';

import 'package:flutter/material.dart';

import '../chess/chess_game.dart';
import '../l10n/app_strings.dart';
import '../l10n/models/piece.dart';
import '../l10n/models/square.dart';
import '../online/game_clock.dart';
import '../online/online_game_replayer.dart';
import '../online/online_game_service.dart';
import '../theme/balatro_theme.dart';
import '../widgets/chess_piece_widget.dart';

/// Read-only live spectating via event log + ongoing relays.
class SpectateScreen extends StatefulWidget {
  const SpectateScreen({
    super.key,
    required this.service,
    required this.payload,
  });

  final OnlineGameService service;
  final OnlineSpectateOk payload;

  @override
  State<SpectateScreen> createState() => _SpectateScreenState();
}

class _SpectateScreenState extends State<SpectateScreen> {
  late ChessGame _game;
  final GameClock _clock = GameClock();
  StreamSubscription<OnlineEvent>? _sub;
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    final replayed = OnlineGameReplayer.replay(widget.payload.eventLog);
    _game = replayed.game;
    if (replayed.whiteMs != null && replayed.blackMs != null) {
      _clock.applySync(
        whiteMs: replayed.whiteMs!,
        blackMs: replayed.blackMs!,
        active: _game.isGameOver ? null : _game.turn,
      );
    }
    _sub = widget.service.events.listen(_onEvent);
    _uiTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || _game.isGameOver) return;
      if (_game.enginePhase == GameEnginePhase.play) {
        _clock.tick(_game.turn);
        setState(() {});
      }
    });
  }

  void _onEvent(OnlineEvent event) {
    switch (event) {
      case OnlineOpponentMove():
        setState(() {
          if (event.whiteMs != null && event.blackMs != null) {
            _clock.applySync(
              whiteMs: event.whiteMs!,
              blackMs: event.blackMs!,
            );
          }
          _game.applyRemoteMove(event.move);
          if (!_game.isGameOver &&
              _game.enginePhase == GameEnginePhase.play) {
            _clock.resume(_game.turn);
          }
        });
      case OnlineOpponentStartAbility():
        setState(() {
          _game.applyRemoteStartAbility(
            event.color,
            event.ability,
            lavaRank: event.lavaRank,
            offer: event.offer,
          );
        });
      case OnlineOpponentAbility():
        setState(() {
          _game.applyRemoteAbility(event.ability, offer: event.offer);
        });
      case OnlineOpponentAbilityTarget():
        setState(() {
          if (event.removeAbility != null) {
            _game.chooseAbilityToRemove(event.removeAbility!);
          } else {
            _game.chooseAbilityTarget(
              pieceId: event.pieceId,
              square: event.square,
              index: event.index,
            );
          }
        });
      case OnlineOpponentReaction():
        setState(() {
          if (event.accepted && event.ability != null) {
            _game.acceptRansom(event.ability!);
          } else if (!event.accepted) {
            _game.declineRansom();
          }
        });
      case OnlineOpponentReroll():
        setState(() => _game.rerollPendingOffers(event.color));
      case OnlineOpponentSkipTurn():
        setState(() => _game.skipTurn());
      case OnlineClockSync():
        setState(() {
          _clock.applySync(
            whiteMs: event.whiteMs,
            blackMs: event.blackMs,
            active: _game.isGameOver ? null : _game.turn,
          );
        });
      case OnlineGameOver():
        setState(() {
          _clock.pause();
          GameEndReason? reason;
          final raw = event.reason;
          if (raw != null) {
            for (final v in GameEndReason.values) {
              if (v.name == raw) {
                reason = v;
                break;
              }
            }
          }
          _game.applyRemoteEnd(
            winner: event.winner,
            reason: reason,
            detail: event.detail,
          );
        });
      case OnlineResign():
        // Opponent of the resigning seat — unknown; ignore if already over.
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _sub?.cancel();
    widget.service.leaveSpectate(gameId: widget.payload.gameId);
    widget.service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final files = _game.fileCount;
    final ranks = _game.rankCount;

    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          '${s.observeMode}'
          '${widget.payload.roomCode != null ? ' · ${widget.payload.roomCode}' : ''}',
          style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.payload.blackName ?? s.black}  '
                    '${GameClock.formatMs(_clock.msFor(PieceColor.black))}',
                    style: BalatroTheme.statusStyle,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${widget.payload.whiteName ?? s.white}  '
                    '${GameClock.formatMs(_clock.msFor(PieceColor.white))}',
                    textAlign: TextAlign.end,
                    style: BalatroTheme.statusStyle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: files / ranks,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: files,
                  ),
                  itemCount: files * ranks,
                  itemBuilder: (context, index) {
                    final file = index % files;
                    final rank = ranks - 1 - index ~/ files;
                    final square = Square(file, rank);
                    final light = (file + rank).isEven;
                    final piece = _game.pieceAt(square);
                    return ColoredBox(
                      color: light
                          ? const Color(0xFFC8B896)
                          : const Color(0xFF6B8F71),
                      child: piece == null
                          ? null
                          : ChessPieceWidget(piece: piece, size: 36),
                    );
                  },
                ),
              ),
            ),
          ),
          if (_game.isGameOver)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _game.winnerColor == null
                    ? s.draw
                    : (_game.winnerColor == PieceColor.white
                        ? s.white
                        : s.black),
                style: BalatroTheme.titleStyle.copyWith(fontSize: 20),
              ),
            ),
        ],
      ),
    );
  }
}
