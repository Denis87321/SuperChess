import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_service.dart';
import '../chess/chess_game.dart';
import '../chess/move.dart';
import '../chess/stockfish_player.dart';
import '../l10n/app_strings.dart';
import '../l10n/models/game_ability.dart';
import '../l10n/models/piece.dart';
import '../l10n/models/square.dart';
import '../l10n/models/stockfish_ability_filter.dart';
import '../online/game_clock.dart';
import '../online/online_game_service.dart';
import '../theme/balatro_theme.dart';
import '../widgets/chess_piece_widget.dart';
import '../widgets/lava_death_overlay.dart';
import '../widgets/online_chat_panel.dart';
import '../widgets/online_game_menu.dart';
import '../widgets/online_player_bar.dart';
import '../widgets/online_side_panel.dart';
import '../widgets/skill_choice_sheet.dart';

const _prefsRotateForBlackKey = 'rotate_for_black';
const _onlineWideBreakpoint = 800.0;
/// Web desktop: mods list beside the board instead of a button.
const _webModsSideBreakpoint = 800.0;

String _pieceTypeRu(PieceType type) {
  return switch (type) {
    PieceType.pawn => 'Пешка',
    PieceType.knight => 'Конь',
    PieceType.bishop => 'Слон',
    PieceType.rook => 'Ладья',
    PieceType.queen => 'Ферзь',
    PieceType.king => 'Король',
  };
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.localColor,
    this.onlineService,
    this.opponentName,
    this.gameId,
    this.auth,
    this.rated = false,
    this.yourRating,
    this.opponentRating,
    this.vsComputer = false,
  });

  final PieceColor? localColor;
  final OnlineGameService? onlineService;
  final String? opponentName;
  final String? gameId;
  final AuthService? auth;
  final bool rated;
  final int? yourRating;
  final int? opponentRating;

  /// Local game vs Stockfish (no mods for the bot; human still picks mods).
  final bool vsComputer;

  bool get isOnline => onlineService != null && localColor != null;

  /// One human seat (online or vs computer); not hot-seat local.
  bool get hasFixedSeat => isOnline || vsComputer;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final ChessGame _game;
  late final StockfishPlayer? _stockfish;
  Square? _selectedSquare;
  int _selectedPieceIndex = 0;
  List<Move> _availableMoves = [];
  StreamSubscription<OnlineEvent>? _onlineSub;
  bool _opponentChoosingSkill = false;
  bool _startFlowDone = false;
  List<LavaDeathEvent> _animatingLavaDeaths = const [];
  VoidCallback? _lavaDeathFinishCallback;
  bool _skillChoicePeek = false;
  Timer? _skillChoiceTimer;
  int _skillChoiceSecondsLeft = 30;
  _PieceFlight? _pieceFlight;
  bool _botThinking = false;
  int _botMoveGen = 0;
  /// Sticky issue after Stockfish fails to move / load (vs-computer only).
  StockfishIssue _stockfishIssue = StockfishIssue.none;

  /// Локальная игра: при ходе чёрных переворачивать фигуры и текст на 180°.
  bool _rotateForBlack = false;

  final GameClock _clock = GameClock();
  Timer? _clockTimer;
  final List<ChatLine> _chat = [];
  int _unreadChat = 0;
  String? _chatToastText;
  Timer? _chatToastTimer;
  bool _awaitingDrawResponse = false;
  bool _awaitingTakebackResponse = false;
  bool _gameResultReported = false;

  PieceColor? get _botColor {
    if (!widget.vsComputer || widget.localColor == null) return null;
    return widget.localColor == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;
  }

  @override
  void initState() {
    super.initState();
    if (widget.vsComputer && widget.localColor != null) {
      _game = ChessGame(
        abilityChoosingColors: {widget.localColor!},
        excludedAbilities: stockfishExcludedAbilities,
      );
      final stockfish = StockfishPlayer();
      _stockfish = stockfish;
      _stockfishIssue = StockfishIssue.loading;
      unawaited(() async {
        await stockfish.ensureReady();
        if (!mounted) return;
        setState(() {
          _stockfishIssue = stockfish.isStockfishActive
              ? StockfishIssue.none
              : StockfishIssue.engineUnavailable;
        });
      }());
    } else {
      _game = ChessGame();
      _stockfish = null;
    }
    if (widget.isOnline) {
      _onlineSub = widget.onlineService!.events.listen(_onOnlineEvent);
    }
    unawaited(_loadRotatePreference());
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartFlow());
  }

  Future<void> _loadRotatePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefsRotateForBlackKey) ?? false;
    if (!mounted) return;
    setState(() => _rotateForBlack = value);
  }

  Future<void> _setRotateForBlack(bool value) async {
    setState(() => _rotateForBlack = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsRotateForBlackKey, value);
  }

  @override
  void dispose() {
    _skillChoiceTimer?.cancel();
    _clockTimer?.cancel();
    _chatToastTimer?.cancel();
    _onlineSub?.cancel();
    _stockfish?.dispose();
    if (widget.isOnline) {
      widget.onlineService!.dispose();
    }
    super.dispose();
  }

  Future<void> _runStartFlow() async {
    if (widget.vsComputer && widget.localColor != null) {
      if (_game.isAwaitingStartChoice(widget.localColor!)) {
        await _showStartPicker(widget.localColor!);
      }
    } else if (widget.localColor == null) {
      if (_game.isAwaitingStartChoice(PieceColor.white)) {
        await _showStartPicker(PieceColor.white);
      }
      if (mounted && _game.isAwaitingStartChoice(PieceColor.black)) {
        await _showStartPicker(PieceColor.black);
      }
    } else if (_game.isAwaitingStartChoice(widget.localColor!)) {
      await _showStartPicker(widget.localColor!);
    }

    if (mounted) {
      setState(() => _startFlowDone = true);
      _ensureClockRunning();
      _maybeScheduleComputerMove();
    }
  }

  Future<void> _showStartPicker(PieceColor color) async {
    final offers = _game.startOffersFor(color);
    final flipPicker =
        !widget.isOnline && _rotateForBlack && color == PieceColor.black;
    var chosen = await SkillChoiceSheet.show(
      context,
      title: 'ДОСКА',
      subtitle: color == PieceColor.white
          ? 'Белые — выбери мод доски'
          : 'Чёрные — выбери мод доски',
      offers: offers,
      seconds: _game.skillChoiceSeconds,
      rotate180: flipPicker,
    );

    if (!mounted) return;

    // На всякий случай, если диалог закрылся без выбора.
    chosen ??= offers.isEmpty
        ? null
        : offers[math.Random().nextInt(offers.length)].ability;
    if (chosen == null) return;

    final offer = offers.firstWhere((o) => o.ability == chosen);
    setState(() {
      _game.applyStartAbility(
        color,
        chosen!,
        lavaRank: offer.lavaRank,
        remoteOffer: offer,
      );
    });
    widget.onlineService?.sendStartAbility(
      color,
      chosen,
      lavaRank: offer.lavaRank,
      offer: offer,
    );
  }

  void _onOnlineEvent(OnlineEvent event) {
    switch (event) {
      case OnlineOpponentMove():
        unawaited(_executeRemoteMove(event.move));
      case OnlineOpponentAbility():
        _skillChoiceTimer?.cancel();
        setState(() {
          _game.applyRemoteAbility(event.ability, offer: event.offer);
          _opponentChoosingSkill = false;
          _skillChoicePeek = false;
        });
        _checkStateHash(event.stateHash, 'ability');
      case OnlineOpponentStartAbility():
        setState(() {
          _game.applyRemoteStartAbility(
            event.color,
            event.ability,
            lavaRank: event.lavaRank,
            offer: event.offer,
          );
        });
        if (_game.isReadyToPlay) _ensureClockRunning();
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
        _checkStateHash(event.stateHash, 'ability_target');
      case OnlineOpponentReaction():
        if (event.accepted) {
          setState(() {
            if (event.ability != null) {
              _game.acceptRansom(event.ability!);
            }
          });
        } else {
          final result = _game.declineRansom();
          setState(() {
            _selectedSquare = null;
            _selectedPieceIndex = 0;
            _availableMoves = [];
          });
          if (result != null) {
            unawaited(_finishRemoteDeclineRansom(result));
          }
        }
        _checkStateHash(event.stateHash, 'reaction');
      case OnlineOpponentReroll():
        setState(() {
          _game.rerollPendingOffers(event.color);
        });
        _checkStateHash(event.stateHash, 'reroll');
      case OnlineOpponentSkipTurn():
        setState(() {
          _game.skipTurn();
        });
        _checkStateHash(event.stateHash, 'skip_turn');
      case OnlineGameOver():
        _applyRemoteGameOver(event);
      case OnlineStateResync():
        developer.log(
          'Online state_resync received (${event.snapshot.keys.length} keys)',
          name: 'online',
        );
      case OnlineChatMessage():
        setState(() {
          _chat.add(ChatLine(text: event.text, mine: !event.fromOpponent));
          if (event.fromOpponent) {
            _unreadChat++;
            _showChatToast(event.text);
          }
        });
      case OnlineResign():
        // Opponent resigned → we win.
        setState(() {
          _clock.pause();
          _clockTimer?.cancel();
          _game.resign(_other(widget.localColor!));
        });
        unawaited(_reportGameResultIfNeeded());
      case OnlineDrawOffer():
        unawaited(_onIncomingDrawOffer());
      case OnlineDrawResponse():
        _awaitingDrawResponse = false;
        if (event.accepted) {
          setState(() {
            _clock.pause();
            _clockTimer?.cancel();
            _game.agreeDraw();
          });
          unawaited(_reportGameResultIfNeeded());
        } else {
          _showMessage('Соперник отклонил ничью');
        }
      case OnlineTakebackOffer():
        unawaited(_onIncomingTakebackOffer());
      case OnlineTakebackResponse():
        _awaitingTakebackResponse = false;
        if (event.accepted) {
          setState(() {
            _game.takeback();
            _selectedSquare = null;
            _selectedPieceIndex = 0;
            _availableMoves = [];
          });
          _showMessage('Ход возвращён');
        } else {
          _showMessage('Соперник отклонил возврат хода');
        }
      case OnlineClockSync():
        setState(() {
          _clock.applySync(
            whiteMs: event.whiteMs,
            blackMs: event.blackMs,
          );
        });
      case OnlineOpponentDisconnected():
        _showMessage('Соперник отключился');
      case OnlineError():
        _showMessage(event.message);
      case OnlineSearching():
      case OnlineMatched():
        break;
    }
  }

  void _applyRemoteGameOver(OnlineGameOver event) {
    _checkStateHash(event.stateHash, 'game_over');
    if (_game.isGameOver) return;
    GameEndReason? reason;
    final raw = event.reason;
    if (raw != null) {
      for (final value in GameEndReason.values) {
        if (value.name == raw) {
          reason = value;
          break;
        }
      }
    }
    setState(() {
      _clock.pause();
      _clockTimer?.cancel();
      _game.applyRemoteEnd(winner: event.winner, reason: reason);
    });
    unawaited(_reportGameResultIfNeeded());
  }

  void _ensureClockRunning() {
    if (!widget.isOnline) return;
    if (!_game.isReadyToPlay || _game.isGameOver) return;
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || _game.isGameOver || !_game.isReadyToPlay) {
        _clockTimer?.cancel();
        return;
      }
      // Pause clock during skill/target/reaction phases.
      if (_game.enginePhase != GameEnginePhase.play) {
        _clock.pause();
        return;
      }
      final active = _game.turn;
      final before = GameClock.formatMs(_clock.msFor(active));
      final flagged = _clock.tick(active);
      if (!mounted) return;
      final after = GameClock.formatMs(_clock.msFor(active));
      if (flagged || before != after) {
        setState(() {});
      }
      if (flagged) {
        _onFlagTimeout(active);
      }
    });
  }

  void _onFlagTimeout(PieceColor color) {
    if (_game.isGameOver) return;
    _clockTimer?.cancel();
    _clock.pause();
    setState(() {
      _game.flagTimeout(color);
    });
    _maybeSendGameOver();
  }

  void _syncClockAfterMove() {
    if (!widget.isOnline) return;
    widget.onlineService?.sendClockSync(
      whiteMs: _clock.whiteMs,
      blackMs: _clock.blackMs,
    );
  }

  Future<void> _onIncomingDrawOffer() async {
    if (!mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: BalatroTheme.felt,
          title: Text(
            'Ничья?',
            style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
          ),
          content: Text(
            'Соперник предлагает ничью',
            style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Отклонить',
                style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Принять',
                style: BalatroTheme.statusStyle.copyWith(
                  fontSize: 13,
                  color: BalatroTheme.gold,
                ),
              ),
            ),
          ],
        );
      },
    );
    final ok = accepted == true;
    widget.onlineService?.sendDrawResponse(accepted: ok);
    if (ok && mounted) {
      setState(() {
        _clock.pause();
        _clockTimer?.cancel();
        _game.agreeDraw();
      });
      unawaited(_reportGameResultIfNeeded());
    }
  }

  Future<void> _onIncomingTakebackOffer() async {
    if (!mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: BalatroTheme.felt,
          title: Text(
            'Вернуть ход?',
            style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
          ),
          content: Text(
            'Соперник просит вернуть последний ход',
            style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Отклонить',
                style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Принять',
                style: BalatroTheme.statusStyle.copyWith(
                  fontSize: 13,
                  color: BalatroTheme.gold,
                ),
              ),
            ),
          ],
        );
      },
    );
    final ok = accepted == true;
    widget.onlineService?.sendTakebackResponse(accepted: ok);
    if (ok && mounted) {
      setState(() {
        _game.takeback();
        _selectedSquare = null;
        _selectedPieceIndex = 0;
        _availableMoves = [];
      });
    }
  }

  Future<void> _offerDraw() async {
    if (!widget.isOnline || _game.isGameOver) return;
    if (_awaitingDrawResponse) {
      _showMessage('Ожидаем ответ на ничью');
      return;
    }
    _awaitingDrawResponse = true;
    widget.onlineService?.sendDrawOffer();
    _showMessage('Предложение ничьи отправлено');
  }

  Future<void> _offerTakeback() async {
    if (!widget.isOnline || _game.isGameOver) return;
    if (!_game.canTakeback) {
      _showMessage('Нечего возвращать');
      return;
    }
    if (_awaitingTakebackResponse) {
      _showMessage('Ожидаем ответ на возврат хода');
      return;
    }
    _awaitingTakebackResponse = true;
    widget.onlineService?.sendTakebackOffer();
    _showMessage('Запрос возврата хода отправлен');
  }

  Future<void> _resignLocal() async {
    if (!widget.isOnline || _game.isGameOver) return;
    final ok = await OnlineGameMenu.confirmResign(context);
    if (!ok || !mounted) return;
    widget.onlineService?.sendResign();
    setState(() {
      _clock.pause();
      _clockTimer?.cancel();
      _game.resign(widget.localColor!);
    });
    _maybeSendGameOver();
  }

  Future<void> _openMobileMenu() async {
    final action = await OnlineGameMenu.showActions(context);
    if (action == null || !mounted) return;
    switch (action) {
      case OnlineMenuAction.takeback:
        await _offerTakeback();
      case OnlineMenuAction.draw:
        await _offerDraw();
      case OnlineMenuAction.resign:
        await _resignLocal();
    }
  }

  void _sendChat(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _chat.add(ChatLine(text: trimmed, mine: true));
    });
    widget.onlineService?.sendChat(trimmed);
  }

  void _showChatToast(String text) {
    _chatToastTimer?.cancel();
    _chatToastText = text;
    _chatToastTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _chatToastText = null);
    });
  }

  Future<void> _openChatSheet() async {
    setState(() {
      _unreadChat = 0;
      _chatToastText = null;
    });
    _chatToastTimer?.cancel();
    await OnlineChatPanel.showSheet(
      context: context,
      messages: _chat,
      onSend: _sendChat,
    );
    if (mounted) {
      setState(() {
        _unreadChat = 0;
        _chatToastText = null;
      });
    }
  }

  void _checkStateHash(String? remoteHash, String source) {
    if (remoteHash == null) return;
    final local = _game.stateHash;
    if (local != remoteHash) {
      developer.log(
        'stateHash mismatch after $source: local=$local remote=$remoteHash',
        name: 'online',
      );
    }
  }

  void _maybeSendGameOver() {
    if (!_game.isGameOver) return;
    widget.onlineService?.sendGameOver(
      winner: _game.winnerColor,
      reason: _game.endReason?.name,
      stateHash: _game.stateHash,
    );
    unawaited(_reportGameResultIfNeeded());
  }

  Future<void> _reportGameResultIfNeeded() async {
    if (_gameResultReported) return;
    if (!widget.isOnline) return;
    final auth = widget.auth;
    final gameId = widget.gameId;
    final color = widget.localColor;
    if (auth == null || !auth.isLoggedIn || gameId == null || color == null) {
      return;
    }
    _gameResultReported = true;

    final snapshot = _game.activeAbilitiesSnapshot();
    final abilities = <String>{};
    if (color == PieceColor.white) {
      if (snapshot.whiteStart != null) {
        abilities.add(snapshot.whiteStart!.ability.name);
      }
      for (final c in snapshot.whiteChosen) {
        abilities.add(c.ability.name);
      }
    } else {
      if (snapshot.blackStart != null) {
        abilities.add(snapshot.blackStart!.ability.name);
      }
      for (final c in snapshot.blackChosen) {
        abilities.add(c.ability.name);
      }
    }

    await auth.reportGameResult(
      gameId: gameId,
      color: color == PieceColor.white ? 'white' : 'black',
      winner: _game.winnerColor == null
          ? null
          : (_game.winnerColor == PieceColor.white ? 'white' : 'black'),
      reason: _game.endReason?.name,
      abilities: abilities.toList(),
      opponentName: widget.opponentName,
    );
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _maybeScheduleComputerMove() {
    if (!widget.vsComputer) return;
    final stockfish = _stockfish;
    final bot = _botColor;
    if (stockfish == null || bot == null) return;
    if (!_startFlowDone || _game.isGameOver || _botThinking) return;
    if (_game.isAwaitingSkillChoice && _canPickSkill) return;
    if (_game.isAwaitingAbilityTarget && _canPickAbilityTarget) return;
    if (_game.isAwaitingReaction && _canReact) return;

    // Bot-side reactions / gallops / stray targets.
    if (_resolveComputerPhases()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
        _maybeScheduleComputerMove();
      });
      return;
    }

    if (_game.enginePhase != GameEnginePhase.play) return;
    if (_game.turn != bot) return;

    final gen = ++_botMoveGen;
    setState(() {
      _botThinking = true;
      if (!stockfish.isStockfishActive) {
        _stockfishIssue = stockfish.issue == StockfishIssue.loading
            ? StockfishIssue.loading
            : StockfishIssue.engineUnavailable;
      }
    });
    Future<void>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted || gen != _botMoveGen) return;
      final move = await stockfish.chooseMove(_game, forColor: bot);
      if (!mounted || gen != _botMoveGen) return;
      setState(() {
        _botThinking = false;
        if (move == null) {
          _stockfishIssue = stockfish.issue == StockfishIssue.none
              ? StockfishIssue.noMove
              : stockfish.issue;
        } else {
          _stockfishIssue = StockfishIssue.none;
        }
      });
      if (move == null) return;
      await _executeMove(move);
    });
  }

  bool _resolveComputerPhases() {
    if (_botColor == null) return false;
    var changed = false;
    var guard = 0;
    while (!_game.isGameOver && guard++ < 24) {
      if (_game.isAwaitingSkillChoice &&
          _game.pendingSkillColor == _botColor) {
        _game.skipPendingAbility();
        changed = true;
        continue;
      }
      if (_game.isAwaitingReaction &&
          _game.pendingRansomColor == _botColor) {
        final result = _game.declineRansom();
        changed = true;
        if (result != null) {
          unawaited(_finishRemoteDeclineRansom(result));
        }
        break;
      }
      if (_game.isAwaitingGallop && _game.turn == _botColor) {
        _game.skipGallop();
        changed = true;
        continue;
      }
      if (_game.isAwaitingAbilityTarget &&
          _game.pendingTargetColor == _botColor) {
        _game.autoResolveAbilityTarget();
        changed = true;
        continue;
      }
      break;
    }
    return changed;
  }

  bool get _isMyTurn {
    if (!widget.hasFixedSeat) return true;
    return _game.turn == widget.localColor;
  }

  bool get _canPickSkill {
    if (!_game.isAwaitingSkillChoice) return false;
    if (!widget.hasFixedSeat) return true;
    return _game.pendingSkillColor == widget.localColor;
  }

  bool get _canPickAbilityTarget {
    if (!_game.isAwaitingAbilityTarget) return false;
    if (!widget.hasFixedSeat) return true;
    return _game.pendingTargetColor == widget.localColor;
  }

  bool get _canReact {
    if (!_game.isAwaitingReaction) return false;
    if (!widget.hasFixedSeat) return true;
    return _game.pendingRansomColor == widget.localColor;
  }

  bool get _canRerollSkill {
    final color = widget.hasFixedSeat
        ? widget.localColor
        : _game.pendingSkillColor;
    if (color == null) return false;
    return _canPickSkill && _game.canRerollPendingOffers(color);
  }

  bool get _canLocalSkipTurn {
    if (!_game.canSkipTurn) return false;
    return _isMyTurn;
  }

  bool _canControlPiece(Piece piece) {
    return _game.canControlPiece(piece);
  }

  bool get _showEndOverlay =>
      _game.isGameOver ||
      _game.status == GameStatus.checkmate ||
      _game.status == GameStatus.stalemate;

  String? get _stockfishIssueBanner {
    if (!widget.vsComputer) return null;
    final s = AppStrings.of(context);
    return switch (_stockfishIssue) {
      StockfishIssue.none => null,
      StockfishIssue.loading => s.computerLoading,
      StockfishIssue.engineUnavailable => s.computerUnavailable,
      StockfishIssue.unsupportedPosition => s.computerUnsupportedPosition,
      StockfishIssue.noMove => s.computerNoMove,
    };
  }

  bool get _stockfishIssueIsError =>
      _stockfishIssue == StockfishIssue.engineUnavailable ||
      _stockfishIssue == StockfishIssue.unsupportedPosition ||
      _stockfishIssue == StockfishIssue.noMove;

  Color get _phaseBannerColor {
    if (_stockfishIssueIsError) {
      return const Color(0xFFFF6B6B);
    }
    return BalatroTheme.gold;
  }

  String? get _phaseBannerText {
    if (_showEndOverlay) return 'Игра окончена';
    final stockfishBanner = _stockfishIssueBanner;
    if (stockfishBanner != null && _stockfishIssueIsError) {
      return stockfishBanner;
    }
    if (_botThinking) {
      if (_stockfishIssue == StockfishIssue.loading) {
        return AppStrings.of(context).computerLoading;
      }
      return AppStrings.of(context).computerThinking;
    }
    if (_stockfishIssue == StockfishIssue.loading && widget.vsComputer) {
      return AppStrings.of(context).computerLoading;
    }
    if ((widget.isOnline || widget.vsComputer) && !_game.isReadyToPlay) {
      final waitingOpp = widget.localColor != null &&
          !_game.isAwaitingStartChoice(widget.localColor!) &&
          (_game.isAwaitingStartChoice(PieceColor.white) ||
              _game.isAwaitingStartChoice(PieceColor.black));
      if (waitingOpp && widget.isOnline) {
        return 'Ожидание выбора соперника';
      }
      return 'Выбор стартовых модов';
    }
    if (_game.isAwaitingReaction) return 'Выкуп · реакция на взятие';
    if (_game.isAwaitingAbilityTarget) {
      final prompt = _game.pendingAbilityPrompt;
      return prompt.isEmpty ? 'Выбор цели способности' : prompt;
    }
    if (_game.isAwaitingSkillChoice) {
      final chooser = _game.pendingSkillColor;
      final bonus = _game.isBonusSkillChoice ? ' · бонус' : '';
      if (chooser == PieceColor.white) {
        return 'Выбор мода · белые$bonus';
      }
      if (chooser == PieceColor.black) {
        return 'Выбор мода · чёрные$bonus';
      }
      return 'Выбор мода$bonus';
    }
    return null;
  }

  String get _endOverlayTitle {
    final s = AppStrings.of(context);
    final winner = _game.winnerColor;
    if (winner == null) return s.draw;
    if (widget.isOnline) {
      return winner == widget.localColor ? s.victory : s.defeat;
    }
    return s.victory;
  }

  String get _endOverlaySubtitle {
    switch (_game.endReason) {
      case GameEndReason.checkmate:
        return 'мат';
      case GameEndReason.stalemate:
        return 'пат';
      case GameEndReason.draw:
      case GameEndReason.drawAgreed:
        return 'ничья';
      case GameEndReason.resign:
        if (widget.isOnline && widget.localColor != null) {
          final s = AppStrings.of(context);
          return _game.winnerColor == widget.localColor
              ? s.opponentResigned
              : s.youResigned;
        }
        return 'сдача';
      case GameEndReason.timeout:
        return 'время вышло';
      case GameEndReason.kingDestroyed:
        return 'король уничтожен';
      case GameEndReason.baskerville:
        return 'Баскервиль';
      case GameEndReason.exterminatus:
        return 'Экстерминатус';
      case GameEndReason.alternativeVictory:
        if (_game.kingOfHillActive) {
          return 'альтернативная победа · территория';
        }
        if (_game.winnerColor != null &&
            _game.secretRouteFor(_game.winnerColor!) != null) {
          return 'альтернативная победа · маршрут';
        }
        if (_game.royalPilgrimageActive) {
          return 'альтернативная победа · паломничество';
        }
        if (_game.passiveAggressionActive) {
          return 'альтернативная победа · пассивная агрессия';
        }
        return 'альтернативная победа';
      case null:
        if (_game.status == GameStatus.checkmate) return 'мат';
        if (_game.status == GameStatus.stalemate) return 'пат';
        return '';
    }
  }

  void _onSquareTap(Square square) {
    if (_pieceFlight != null) return;
    if (!_startFlowDone || !_game.isReadyToPlay) return;
    if (_showEndOverlay) return;

    if (_game.isAwaitingReaction) return;

    if (_game.isAwaitingAbilityTarget) {
      if (_canPickAbilityTarget) {
        unawaited(_localChooseAbilityTarget(square));
      }
      return;
    }

    if (!_isMyTurn ||
        _opponentChoosingSkill ||
        _game.isAwaitingSkillChoice) {
      return;
    }

    final pieces = _game.piecesAt(square);

    if (_selectedSquare != null) {
      final move = _findMove(_selectedSquare!, square);
      if (move != null) {
        _executeMove(move);
        return;
      }
    }

    final controllable = <int>[];
    for (var i = 0; i < pieces.length; i++) {
      if (_canControlPiece(pieces[i])) controllable.add(i);
    }
    if (controllable.isEmpty) {
      setState(() {
        _selectedSquare = null;
        _selectedPieceIndex = 0;
        _availableMoves = [];
      });
      return;
    }

    if (controllable.length == 1) {
      _selectPiece(square, controllable.first);
      return;
    }

    unawaited(_pickStackedPiece(square, controllable, pieces));
  }

  Future<void> _pickStackedPiece(
    Square square,
    List<int> indices,
    List<Piece> pieces,
  ) async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: BalatroTheme.felt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _flipOverlay(
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'КАКУЮ ФИГУРУ?',
                    style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final index in indices)
                        InkWell(
                          onTap: () => Navigator.pop(context, index),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: ChessPieceWidget(
                              piece: pieces[index],
                              size: 56,
                              displayAs: _displayTypeFor(pieces[index]),
                              isZebra:
                                  _game.zebrasActive &&
                                  pieces[index].type == PieceType.knight,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (chosen != null && mounted) {
      _selectPiece(square, chosen);
    }
  }

  void _selectPiece(Square square, int pieceIndex) {
    setState(() {
      _selectedSquare = square;
      _selectedPieceIndex = pieceIndex;
      _availableMoves = _game
          .getLegalMoves(from: square)
          .where((m) => m.pieceIndex == pieceIndex)
          .toList();
    });
  }

  PieceType? _displayTypeFor(Piece piece) {
    if (_game.hasDoppelganger(piece.color) &&
        (piece.type == PieceType.pawn || piece.type == PieceType.queen)) {
      return PieceType.king;
    }
    return null;
  }

  Move? _findMove(Square from, Square to) {
    final matching = _availableMoves
        .where(
          (m) =>
              m.from == from &&
              m.to == to &&
              m.pieceIndex == _selectedPieceIndex,
        )
        .toList();
    if (matching.isEmpty) return null;

    final promotionMoves = matching
        .where((move) => move.promotion != null)
        .toList();
    if (promotionMoves.isNotEmpty) {
      _showPromotionDialog(from, to, promotionMoves);
      return null;
    }

    final strip = matching.where((m) => m.isInquisitorStrip).toList();
    final capture = matching.where((m) => !m.isInquisitorStrip).toList();
    if (strip.isNotEmpty && capture.isNotEmpty) {
      _showInquisitorDialog(capture.first, strip.first);
      return null;
    }

    return matching.first;
  }

  Future<void> _showInquisitorDialog(Move captureMove, Move stripMove) async {
    final chosen = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: BalatroTheme.felt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _flipOverlay(
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ИНКВИЗИТОР',
                    style: BalatroTheme.titleStyle.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Съесть фигуру или снять с неё мод?',
                    textAlign: TextAlign.center,
                    style: BalatroTheme.statusStyle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BalatroTheme.cream,
                            side: BorderSide(
                              color: BalatroTheme.cream.withValues(alpha: 0.4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'СНЯТЬ МОД',
                            style: BalatroTheme.statusStyle.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BalatroTheme.gold,
                            foregroundColor: BalatroTheme.felt,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'СЪЕСТЬ',
                            style: BalatroTheme.statusStyle.copyWith(
                              fontSize: 13,
                              color: BalatroTheme.felt,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || chosen == null) return;
    await _executeMove(chosen ? captureMove : stripMove);
  }

  Future<void> _showPromotionDialog(
    Square from,
    Square to,
    List<Move> moves,
  ) async {
    final piece = _game.pieceAt(from)!;
    final chosen = await showModalBottomSheet<PieceType>(
      context: context,
      backgroundColor: BalatroTheme.felt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _flipOverlay(
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ПРЕВРАЩЕНИЕ',
                    style: BalatroTheme.titleStyle.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: moves.map((move) {
                      final promoPiece = Piece(
                        type: move.promotion!,
                        color: piece.color,
                      );
                      return InkWell(
                        onTap: () => Navigator.pop(context, move.promotion),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: ChessPieceWidget(piece: promoPiece, size: 56),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (chosen != null && mounted) {
      final move = moves.firstWhere((m) => m.promotion == chosen);
      await _executeMove(move);
    }
  }

  bool get _showSkillChoiceOverlay =>
      _game.isAwaitingSkillChoice && _canPickSkill && !_skillChoicePeek;

  void _beginSkillChoice() {
    _skillChoicePeek = false;
    _skillChoiceSecondsLeft = _game.skillChoiceSeconds;
    _skillChoiceTimer?.cancel();
    _skillChoiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _skillChoiceSecondsLeft--;
        if (_skillChoiceSecondsLeft <= 0) {
          timer.cancel();
          _autoPickSkill();
        }
      });
    });
  }

  void _autoPickSkill() {
    if (!_game.isAwaitingSkillChoice || !_canPickSkill) return;
    final offers = _game.pendingCaptureOffers;
    if (offers.isEmpty) return;
    final pick = offers[math.Random().nextInt(offers.length)];
    _completeSkillChoice(pick.ability);
  }

  void _completeSkillChoice(GameAbility ability) {
    _skillChoiceTimer?.cancel();
    final offer = _game.pendingCaptureOffers.cast<AbilityOffer?>().firstWhere(
      (o) => o!.ability == ability,
      orElse: () => null,
    );
    setState(() {
      _game.applyAbility(ability);
      _skillChoicePeek = false;
    });
    widget.onlineService?.sendAbility(
      ability,
      offer: offer,
      stateHash: _game.stateHash,
    );
    _maybeSendGameOver();
    if (!mounted) return;
    if (_game.isAwaitingAbilityTarget && _canPickAbilityTarget) {
      if (_game.legalCapturedAbilityTargets.isNotEmpty) {
        unawaited(_promptCapturedAbilityTarget());
      } else if (_game.legalAbilityOptions.isNotEmpty) {
        unawaited(_promptAbilityToRemove());
      }
    } else if (_game.isAwaitingSkillChoice && _canPickSkill) {
      setState(_beginSkillChoice);
    } else {
      _maybeScheduleComputerMove();
    }
  }

  void _localRerollOffers() {
    final color = widget.hasFixedSeat
        ? widget.localColor
        : _game.pendingSkillColor;
    if (color == null || !_game.canRerollPendingOffers(color)) return;
    setState(() {
      _game.rerollPendingOffers(color);
    });
    widget.onlineService?.sendReroll(color, stateHash: _game.stateHash);
  }

  void _localSkipTurn() {
    if (!_canLocalSkipTurn) return;
    setState(() {
      _game.skipTurn();
      _selectedSquare = null;
      _selectedPieceIndex = 0;
      _availableMoves = [];
    });
    widget.onlineService?.sendSkipTurn(stateHash: _game.stateHash);
    _maybeSendGameOver();
    _maybeScheduleComputerMove();
  }

  Future<void> _localChooseAbilityTarget(Square square) async {
    if (!_canPickAbilityTarget) return;
    if (_game.legalAbilityOptions.isNotEmpty) {
      await _promptAbilityToRemove();
      return;
    }
    if (_game.legalCapturedAbilityTargets.isNotEmpty &&
        _game.legalAbilityTargetPieceIds.isEmpty) {
      await _promptCapturedAbilityTarget();
      return;
    }

    String? pieceId;
    var index = 0;
    final pieces = _game.piecesAt(square);
    final pieceTargets = _game.legalAbilityTargetPieceIds;
    final cellTargets = _game.legalAbilityTargetSquares;
    if (pieceTargets.isNotEmpty) {
      final matches = <int>[];
      for (var i = 0; i < pieces.length; i++) {
        if (pieceTargets.contains(pieces[i].pieceId)) matches.add(i);
      }
      if (matches.isEmpty) return;
      index = matches.first;
      if (matches.length > 1) {
        final chosen = await showModalBottomSheet<int>(
          context: context,
          backgroundColor: BalatroTheme.felt,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return _flipOverlay(
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'КАКУЮ ФИГУРУ?',
                        style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final i in matches)
                            InkWell(
                              onTap: () => Navigator.pop(context, i),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: ChessPieceWidget(
                                  piece: pieces[i],
                                  size: 56,
                                  displayAs: _displayTypeFor(pieces[i]),
                                  isZebra:
                                      _game.zebrasActive &&
                                      pieces[i].type == PieceType.knight,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
        if (chosen == null || !mounted) return;
        index = chosen;
      }
      pieceId = pieces[index].pieceId;
    } else if (cellTargets.isNotEmpty) {
      if (!cellTargets.contains(square)) return;
    } else {
      return;
    }

    final ok = _game.chooseAbilityTarget(
      pieceId: pieceId,
      square: square,
      index: index,
    );
    if (!ok) return;

    setState(() {
      _selectedSquare = null;
      _selectedPieceIndex = 0;
      _availableMoves = [];
    });
    widget.onlineService?.sendAbilityTarget(
      pieceId: pieceId,
      square: square,
      index: index,
      stateHash: _game.stateHash,
    );

    if (_game.legalAbilityOptions.isNotEmpty) {
      await _promptAbilityToRemove();
    } else if (_game.legalCapturedAbilityTargets.isNotEmpty &&
        _canPickAbilityTarget) {
      await _promptCapturedAbilityTarget();
    } else if (_game.isAwaitingSkillChoice && _canPickSkill) {
      setState(_beginSkillChoice);
    } else {
      _maybeScheduleComputerMove();
    }
    _maybeSendGameOver();
  }

  Future<void> _promptCapturedAbilityTarget() async {
    if (!_canPickAbilityTarget) return;
    final options = _game.legalCapturedAbilityTargets;
    if (options.isEmpty) return;
    final chosen = await showModalBottomSheet<GraveyardRecord>(
      context: context,
      backgroundColor: BalatroTheme.felt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _flipOverlay(
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ОБМЕН ПЛЕННЫМИ',
                    style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _game.pendingAbilityPrompt,
                    textAlign: TextAlign.center,
                    style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  for (final record in options)
                    ListTile(
                      leading: ChessPieceWidget(piece: record.piece, size: 36),
                      title: Text(
                        _pieceTypeRu(record.piece.type),
                        style: BalatroTheme.statusStyle.copyWith(fontSize: 14),
                      ),
                      onTap: () => Navigator.pop(context, record),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (chosen == null || !mounted) return;
    final ok = _game.chooseAbilityTarget(
      pieceId: chosen.piece.pieceId,
      index: chosen.sequence,
    );
    if (!ok) return;
    setState(() {});
    widget.onlineService?.sendAbilityTarget(
      pieceId: chosen.piece.pieceId,
      index: chosen.sequence,
      stateHash: _game.stateHash,
    );
    if (_game.legalCapturedAbilityTargets.isNotEmpty && _canPickAbilityTarget) {
      await _promptCapturedAbilityTarget();
    } else if (_game.isAwaitingSkillChoice && _canPickSkill) {
      setState(_beginSkillChoice);
    } else {
      _maybeScheduleComputerMove();
    }
    _maybeSendGameOver();
  }

  Future<void> _promptAbilityToRemove() async {
    if (!_canPickAbilityTarget || _game.legalAbilityOptions.isEmpty) return;
    final options = _game.legalAbilityOptions;
    final chosen = await showModalBottomSheet<GameAbility>(
      context: context,
      backgroundColor: BalatroTheme.felt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _flipOverlay(
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'СНЯТЬ МОДИФИКАЦИЮ',
                    style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  for (final ability in options)
                    ListTile(
                      title: Text(
                        ability.title,
                        style: BalatroTheme.statusStyle.copyWith(fontSize: 14),
                      ),
                      onTap: () => Navigator.pop(context, ability),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (chosen == null || !mounted) return;
    _localChooseAbilityToRemove(chosen);
  }

  void _localChooseAbilityToRemove(GameAbility ability) {
    if (!_game.chooseAbilityToRemove(ability)) return;
    setState(() {});
    widget.onlineService?.sendAbilityTarget(
      removeAbility: ability,
      stateHash: _game.stateHash,
    );
    _maybeSendGameOver();
    if (_game.isAwaitingSkillChoice && _canPickSkill) {
      setState(_beginSkillChoice);
    } else {
      _maybeScheduleComputerMove();
    }
  }

  void _localAcceptRansom(GameAbility ability) {
    if (!_game.acceptRansom(ability)) return;
    setState(() {});
    widget.onlineService?.sendReaction(
      accepted: true,
      ability: ability,
      stateHash: _game.stateHash,
    );
    _maybeSendGameOver();
    _maybeScheduleComputerMove();
  }

  Future<void> _localDeclineRansom() async {
    final result = _game.declineRansom();
    if (result == null) return;
    setState(() {
      _selectedSquare = null;
      _selectedPieceIndex = 0;
      _availableMoves = [];
    });
    widget.onlineService?.sendReaction(
      accepted: false,
      stateHash: _game.stateHash,
    );
    await _playLavaDeaths(_game.consumeLavaDeaths());
    if (!mounted) return;
    await _handleMoveResult(result);
  }

  Future<void> _finishRemoteDeclineRansom(MoveResult result) async {
    await _playLavaDeaths(_game.consumeLavaDeaths());
    if (!mounted) return;
    await _handleMoveResult(result);
  }

  Future<void> _handleMoveResult(MoveResult result) async {
    if (!mounted) return;
    if (result.wasCancelled) {
      _maybeSendGameOver();
      return;
    }
    if (_game.isAwaitingReaction || result.isAwaitingReaction) {
      _maybeSendGameOver();
      return;
    }
    if (_game.isAwaitingAbilityTarget ||
        result.outcome == MoveOutcome.awaitingTarget) {
      if (_canPickAbilityTarget) {
        if (_game.legalCapturedAbilityTargets.isNotEmpty) {
          await _promptCapturedAbilityTarget();
        } else if (_game.legalAbilityOptions.isNotEmpty) {
          await _promptAbilityToRemove();
        }
      }
      _maybeSendGameOver();
      _maybeScheduleComputerMove();
      return;
    }
    if ((result.requiresSkillChoice || _game.isAwaitingSkillChoice) &&
        _canPickSkill) {
      // Let the last opponent move stay visible before the mods sheet.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (!_game.isAwaitingSkillChoice || !_canPickSkill) {
        _maybeSendGameOver();
        _maybeScheduleComputerMove();
        return;
      }
      setState(_beginSkillChoice);
      _maybeSendGameOver();
      return;
    }
    _maybeSendGameOver();
    _maybeScheduleComputerMove();
  }

  void _toggleSkillChoicePeek() {
    if (!_game.isAwaitingSkillChoice || !_canPickSkill) return;
    setState(() => _skillChoicePeek = !_skillChoicePeek);
  }

  Future<void> _playLavaDeaths(List<LavaDeathEvent> events) async {
    if (events.isEmpty || !mounted) return;

    final completer = Completer<void>();
    var remaining = events.length;

    setState(() {
      _animatingLavaDeaths = events;
      _lavaDeathFinishCallback = () {
        remaining--;
        if (remaining <= 0 && !completer.isCompleted) {
          completer.complete();
        }
      };
    });

    await completer.future.timeout(
      const Duration(milliseconds: 900),
      onTimeout: () {},
    );

    _lavaDeathFinishCallback = null;
    if (mounted) {
      setState(() => _animatingLavaDeaths = const []);
    }
  }

  void _onLavaDeathFinished() {
    _lavaDeathFinishCallback?.call();
  }

  Future<void> _executeMove(Move move) async {
    if (_pieceFlight != null) return;

    final movers = _game.piecesAt(move.from);
    if (movers.isEmpty) return;
    final moverIndex = move.pieceIndex.clamp(0, movers.length - 1);
    final flyingPiece = movers[moverIndex];

    if (!move.isInquisitorStrip) {
      await _playPieceFlight(move, flyingPiece);
      if (!mounted) return;
      setState(() => _pieceFlight = null);
    }

    final result = _game.makeMove(move);
    if (result == null) return;

    widget.onlineService?.sendMove(move);
    _syncClockAfterMove();
    _ensureClockRunning();

    if (mounted) {
      if (_game.isAwaitingGallop) {
        final from = _game.awaitingGallopFrom!;
        setState(() {
          _selectedSquare = from;
          _selectedPieceIndex = 0;
          _availableMoves = _game.getLegalMoves(from: from);
        });
      } else {
        setState(() {
          _selectedSquare = null;
          _selectedPieceIndex = 0;
          _availableMoves = [];
        });
      }
    }

    final lavaDeaths = _game.consumeLavaDeaths();
    await _playLavaDeaths(lavaDeaths);

    if (!mounted) return;
    await _handleMoveResult(result);
  }

  void _skipGallop() {
    if (!_game.isAwaitingGallop) return;
    setState(() {
      _game.skipGallop();
      _selectedSquare = null;
      _selectedPieceIndex = 0;
      _availableMoves = [];
    });
  }

  Future<void> _executeRemoteMove(Move move) async {
    if (_pieceFlight != null) {
      await _pieceFlight!.completer.future;
    }

    final movers = _game.piecesAt(move.from);
    final flyingPiece = movers.isEmpty
        ? null
        : movers[move.pieceIndex.clamp(0, movers.length - 1)];

    if (flyingPiece != null && !move.isInquisitorStrip) {
      await _playPieceFlight(move, flyingPiece);
    }

    if (!mounted) return;
    setState(() {
      _pieceFlight = null;
      _game.applyRemoteMove(move);
      _opponentChoosingSkill = _game.isAwaitingSkillChoice;
      if (_game.isAwaitingGallop) {
        final from = _game.awaitingGallopFrom!;
        _selectedSquare = from;
        _selectedPieceIndex = 0;
        _availableMoves = _game.getLegalMoves(from: from);
      } else {
        _selectedSquare = null;
        _selectedPieceIndex = 0;
        _availableMoves = [];
      }
    });
    _ensureClockRunning();

    await _playLavaDeaths(_game.consumeLavaDeaths());
  }

  Future<void> _playPieceFlight(Move move, Piece piece) async {
    final dist = math.max(
      (move.to.file - move.from.file).abs(),
      (move.to.rank - move.from.rank).abs(),
    );
    // Slightly longer on web so the flight is readable at lower browser FPS.
    final ms = kIsWeb
        ? (260 + dist * 60).clamp(300, 560)
        : (160 + dist * 45).clamp(180, 360);
    final completer = Completer<void>();
    final flight = _PieceFlight(
      from: move.from,
      to: move.to,
      piece: piece,
      displayAs: _displayTypeFor(piece),
      isZebra: _game.zebrasActive && piece.type == PieceType.knight,
      duration: Duration(milliseconds: ms),
      completer: completer,
    );

    setState(() {
      _pieceFlight = flight;
      _selectedSquare = null;
      _selectedPieceIndex = 0;
      _availableMoves = [];
    });

    await completer.future.timeout(
      Duration(milliseconds: ms + (kIsWeb ? 500 : 120)),
      onTimeout: () {},
    );
  }

  void _onPieceFlightFinished() {
    final flight = _pieceFlight;
    if (flight == null || flight.completer.isCompleted) return;
    flight.completer.complete();
  }

  /// Переворот UI для локальной hot-seat игры, когда ход чёрных.
  bool get _uiFlipped =>
      !widget.hasFixedSeat &&
      _rotateForBlack &&
      _game.turn == PieceColor.black;

  /// Онлайн за чёрных: 8-я горизонталь снизу (как на Lichess).
  bool get _boardPerspectiveFlipped =>
      widget.isOnline && widget.localColor == PieceColor.black;

  Widget _flipOverlay(Widget child) {
    if (!_uiFlipped) return child;
    return Transform.rotate(angle: math.pi, child: child);
  }

  void _openSettings() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return _flipOverlay(
          AlertDialog(
            backgroundColor: BalatroTheme.felt,
            title: Text(
              'НАСТРОЙКИ',
              style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
            ),
            content: StatefulBuilder(
              builder: (context, setLocal) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.hasFixedSeat)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Поворот для чёрных',
                          style: BalatroTheme.statusStyle.copyWith(
                            fontSize: 13,
                            color: BalatroTheme.cream,
                          ),
                        ),
                        subtitle: Text(
                          'При ходе чёрных фигуры и текст переворачиваются на 180°, доска остаётся на месте',
                          style: BalatroTheme.statusStyle.copyWith(
                            fontSize: 11,
                            color: BalatroTheme.cream.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        value: _rotateForBlack,
                        activeThumbColor: BalatroTheme.gold,
                        activeTrackColor: BalatroTheme.accent.withValues(
                          alpha: 0.55,
                        ),
                        onChanged: (value) {
                          unawaited(_setRotateForBlack(value));
                          setLocal(() {});
                        },
                      )
                    else
                      Text(
                        'Нет доступных настроек',
                        style: BalatroTheme.statusStyle.copyWith(
                          fontSize: 13,
                          color: BalatroTheme.cream.withValues(alpha: 0.65),
                        ),
                      ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ЗАКРЫТЬ',
                  style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modsButton() {
    return _flipOverlay(
      IconButton.filledTonal(
        tooltip: 'Активные моды',
        onPressed: _showActiveAbilities,
        style: IconButton.styleFrom(
          backgroundColor: BalatroTheme.felt,
          foregroundColor: BalatroTheme.gold,
          padding: const EdgeInsets.all(14),
        ),
        icon: const Icon(Icons.auto_awesome_rounded, size: 26),
      ),
    );
  }

  /// Wide web only: list mods beside the board (phones keep the button).
  bool _webModsBesideBoard(double width) =>
      kIsWeb && width >= _webModsSideBreakpoint;

  Widget _buildActiveModsSidePanel() {
    return SizedBox(
      width: 300,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BalatroTheme.felt.withValues(alpha: 0.97),
          border: Border(
            left: BorderSide(
              color: BalatroTheme.cream.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'АКТИВНЫЕ МОДЫ',
                style: BalatroTheme.titleStyle.copyWith(fontSize: 14),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _activeModsBody(hideOpponent: widget.vsComputer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final modsOnTop = _uiFlipped;
    final width = MediaQuery.sizeOf(context).width;
    final onlineWide = widget.isOnline && width >= _onlineWideBreakpoint;
    final webModsBeside = _webModsBesideBoard(width);

    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          widget.isOnline
              ? AppStrings.of(context).onlineTitle('5+0')
              : 'SUPERCHESS',
          style: BalatroTheme.titleStyle.copyWith(
            fontSize: widget.isOnline ? 16 : 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Настройки',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: SafeArea(
        left: false,
        right: false,
        bottom: false,
        child: onlineWide
            ? Row(
                children: [
                  SizedBox(
                    width: 240,
                    child: OnlineChatPanel(
                      messages: _chat,
                      onSend: _sendChat,
                    ),
                  ),
                  Expanded(
                    child: _buildGameStack(
                      bottomPad: bottomPad,
                      modsOnTop: modsOnTop,
                      showMobileChrome: false,
                      showModsButton: false,
                    ),
                  ),
                  if (webModsBeside) _buildActiveModsSidePanel(),
                  OnlineSidePanel(
                    opponentName: widget.opponentName ??
                        AppStrings.of(context).anonymous,
                    localName: AppStrings.of(context).you,
                    opponentMs: _clock.msFor(_other(widget.localColor!)),
                    localMs: _clock.msFor(widget.localColor!),
                    opponentRating: widget.opponentRating,
                    localRating: widget.yourRating,
                    opponentActive: _game.isReadyToPlay &&
                        !_game.isGameOver &&
                        _game.turn == _other(widget.localColor!) &&
                        _game.enginePhase == GameEnginePhase.play,
                    localActive: _game.isReadyToPlay &&
                        !_game.isGameOver &&
                        _game.turn == widget.localColor &&
                        _game.enginePhase == GameEnginePhase.play,
                    canTakeback: _game.canTakeback,
                    onTakeback: () => unawaited(_offerTakeback()),
                    onDraw: () => unawaited(_offerDraw()),
                    onResign: () => unawaited(_resignLocal()),
                  ),
                ],
              )
            : webModsBeside
                ? Row(
                    children: [
                      Expanded(
                        child: _buildGameStack(
                          bottomPad: bottomPad,
                          modsOnTop: modsOnTop,
                          showMobileChrome: false,
                          showModsButton: false,
                        ),
                      ),
                      _buildActiveModsSidePanel(),
                    ],
                  )
                : _buildGameStack(
                    bottomPad: bottomPad,
                    modsOnTop: modsOnTop,
                    showMobileChrome: widget.isOnline,
                    showModsButton: true,
                  ),
      ),
    );
  }

  Widget _buildBoard(double maxWidth, double maxHeight) {
    return _ChessBoard(
      game: _game,
      selectedSquare: _selectedSquare,
      availableMoves: _availableMoves,
      animatingLavaDeaths: _animatingLavaDeaths,
      onLavaDeathFinished: _onLavaDeathFinished,
      onSquareTap: _onSquareTap,
      viewerColor: _viewerColor,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      pieceFlight: _pieceFlight,
      onPieceFlightFinished: _onPieceFlightFinished,
      rotatePieces: _uiFlipped,
      flipBoard: _boardPerspectiveFlipped,
    );
  }

  Widget _buildGameStack({
    required double bottomPad,
    required bool modsOnTop,
    required bool showMobileChrome,
    required bool showModsButton,
  }) {
    final youAre = widget.localColor == null
        ? null
        : widget.localColor == PieceColor.white
            ? 'Белые'
            : 'Чёрные';
    final oppColor =
        widget.localColor == null ? null : _other(widget.localColor!);
    final localColor = widget.localColor;

    return Stack(
      children: [
        Positioned.fill(
          child: showMobileChrome
              ? Column(
                  children: [
                    OnlinePlayerBar(
                      name: widget.opponentName ??
                          AppStrings.of(context).anonymous,
                      clockMs: oppColor == null ? 0 : _clock.msFor(oppColor),
                      rating: widget.opponentRating,
                      active: oppColor != null &&
                          _game.isReadyToPlay &&
                          !_game.isGameOver &&
                          _game.turn == oppColor &&
                          _game.enginePhase == GameEnginePhase.play,
                      compact: true,
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Center(
                            child: _buildBoard(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                          );
                        },
                      ),
                    ),
                    OnlinePlayerBar(
                      name: AppStrings.of(context).you,
                      clockMs:
                          localColor == null ? 0 : _clock.msFor(localColor),
                      rating: widget.yourRating,
                      active: localColor != null &&
                          _game.isReadyToPlay &&
                          !_game.isGameOver &&
                          _game.turn == localColor &&
                          _game.enginePhase == GameEnginePhase.play,
                      compact: true,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 4,
                        right: 4,
                        bottom: math.max(4, bottomPad),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Меню',
                                onPressed: _game.isGameOver
                                    ? null
                                    : () => unawaited(_openMobileMenu()),
                                icon: const Icon(
                                  Icons.menu_rounded,
                                  color: BalatroTheme.cream,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Чат',
                                onPressed: () => unawaited(_openChatSheet()),
                                icon: Badge(
                                  isLabelVisible: _unreadChat > 0,
                                  backgroundColor: const Color(0xFFE53935),
                                  smallSize: 10,
                                  child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: BalatroTheme.cream,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (_game.isAwaitingGallop && _isMyTurn)
                                TextButton(
                                  onPressed: _skipGallop,
                                  child: Text(
                                    'Галоп',
                                    style: BalatroTheme.statusStyle.copyWith(
                                      fontSize: 12,
                                      color: BalatroTheme.gold,
                                    ),
                                  ),
                                ),
                              if (showModsButton) _modsButton(),
                            ],
                          ),
                          if (_chatToastText != null)
                            Positioned(
                              left: 52,
                              bottom: 48,
                              child: IgnorePointer(
                                child: AnimatedOpacity(
                                  opacity: 1,
                                  duration: const Duration(milliseconds: 200),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 220,
                                    ),
                                    child: Material(
                                      color: BalatroTheme.felt,
                                      elevation: 6,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          _chatToastText!,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              BalatroTheme.statusStyle.copyWith(
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: _buildBoard(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                    );
                  },
                ),
        ),
        if (!showMobileChrome &&
            (widget.isOnline ||
                widget.vsComputer ||
                _phaseBannerText != null))
          Positioned(
            top: modsOnTop ? 64 : 8,
            left: 12,
            right: 12,
            child: _flipOverlay(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isOnline || widget.vsComputer)
                    Text(
                      'vs ${widget.opponentName ?? 'Соперник'} · вы: $youAre',
                      textAlign: TextAlign.center,
                      style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
                    ),
                  if (_phaseBannerText != null && !widget.isOnline) ...[
                    Text(
                      _phaseBannerText!,
                      textAlign: TextAlign.center,
                      style: BalatroTheme.statusStyle.copyWith(
                        fontSize: 13,
                        color: _phaseBannerColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (!showMobileChrome)
          Positioned(
            top: modsOnTop ? 8 : null,
            bottom: modsOnTop ? null : math.max(12, bottomPad + 8),
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_game.isAwaitingGallop && _isMyTurn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _flipOverlay(
                        ElevatedButton(
                          onPressed: _skipGallop,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BalatroTheme.felt,
                            foregroundColor: BalatroTheme.cream,
                            side: BorderSide(
                              color: BalatroTheme.gold.withValues(alpha: 0.6),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'ПРОПУСТИТЬ ГАЛОП',
                            style: BalatroTheme.statusStyle.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_canLocalSkipTurn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _flipOverlay(
                        ElevatedButton(
                          onPressed: _localSkipTurn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BalatroTheme.felt,
                            foregroundColor: BalatroTheme.cream,
                            side: BorderSide(
                              color: BalatroTheme.gold.withValues(alpha: 0.6),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'ПРОПУСТИТЬ ХОД',
                            style: BalatroTheme.statusStyle.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_canPickAbilityTarget &&
                      _game.legalCapturedAbilityTargets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _flipOverlay(
                        ElevatedButton(
                          onPressed: _promptCapturedAbilityTarget,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BalatroTheme.gold,
                            foregroundColor: BalatroTheme.felt,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'ВЫБРАТЬ ИЗ КЛАДБИЩА',
                            style: BalatroTheme.statusStyle.copyWith(
                              fontSize: 13,
                              color: BalatroTheme.felt,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (showModsButton) _modsButton(),
                ],
              ),
            ),
          ),
        if (_canReact)
          Positioned.fill(
            child: ColoredBox(
              color: BalatroTheme.background.withValues(alpha: 0.72),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _flipOverlay(
                    Material(
                      color: BalatroTheme.felt,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ВЫКУП',
                              style: BalatroTheme.titleStyle.copyWith(
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Отдайте мод или разрешите взятие',
                              textAlign: TextAlign.center,
                              style: BalatroTheme.statusStyle.copyWith(
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (final ability
                                in _game.pendingRansomAbilities)
                              ListTile(
                                title: Text(
                                  ability.title,
                                  style: BalatroTheme.statusStyle.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () => _localAcceptRansom(ability),
                              ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _localDeclineRansom,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: BalatroTheme.cream,
                                side: BorderSide(
                                  color: BalatroTheme.cream.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Text(
                                'ОТКЛОНИТЬ',
                                style: BalatroTheme.statusStyle.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_showSkillChoiceOverlay)
          Positioned.fill(
            child: ColoredBox(
              color: BalatroTheme.background.withValues(alpha: 0.72),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _flipOverlay(
                    SkillChoiceSheet(
                      title: 'МОДИФИКАЦИЯ',
                      subtitle: () {
                        final offers = _game.pendingCaptureOffers;
                        if (offers.isNotEmpty &&
                            offers.every(
                              (o) =>
                                  o.applyMode == AbilityApplyMode.playerKing,
                            )) {
                          return 'Золотой трон — мод для короля';
                        }
                        final chooser = _game.pendingSkillColor;
                        if (chooser == PieceColor.white) {
                          return 'Волна модов — ход белых: выбери 1 из ${offers.length}';
                        }
                        if (chooser == PieceColor.black) {
                          return 'Волна модов — ход чёрных: выбери 1 из ${offers.length}';
                        }
                        return 'Выбери 1 из ${offers.length}';
                      }(),
                      offers: _game.pendingCaptureOffers,
                      secondsLeft: _skillChoiceSecondsLeft,
                      onSelected: _completeSkillChoice,
                      canReroll: _canRerollSkill,
                      permanentReroll: _game.hasPermanentRerollForPending,
                      onReroll: _localRerollOffers,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_game.isAwaitingSkillChoice && _canPickSkill)
          Positioned(
            left: 0,
            right: 0,
            top: modsOnTop ? 64 : null,
            bottom: modsOnTop ? null : math.max(64, bottomPad + 56),
            child: Center(
              child: _flipOverlay(
                FloatingActionButton.extended(
                  heroTag: 'skill_peek',
                  backgroundColor: BalatroTheme.felt,
                  foregroundColor: BalatroTheme.gold,
                  onPressed: _toggleSkillChoicePeek,
                  icon: Icon(
                    _skillChoicePeek
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  label: Text(
                    _skillChoicePeek ? 'ВЫБРАТЬ' : 'ДОСКА',
                    style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        if (_phaseBannerText != null && !_showEndOverlay)
          Positioned(
            top: showMobileChrome
                ? 4
                : widget.isOnline
                    ? (modsOnTop ? 96 : 36)
                    : (modsOnTop ? 56 : 8),
            left: 16,
            right: 16,
            child: _flipOverlay(
              Material(
                color: BalatroTheme.felt.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: _stockfishIssueIsError
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFF6B6B).withValues(alpha: 0.7),
                          ),
                        )
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    _phaseBannerText!,
                    textAlign: TextAlign.center,
                    style: BalatroTheme.statusStyle.copyWith(
                      fontSize: 13,
                      color: _phaseBannerColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_showEndOverlay)
          Positioned.fill(
            child: ColoredBox(
              color: BalatroTheme.background.withValues(alpha: 0.82),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _flipOverlay(
                    Material(
                      color: BalatroTheme.felt,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _endOverlayTitle,
                              textAlign: TextAlign.center,
                              style: BalatroTheme.titleStyle.copyWith(
                                fontSize: 28,
                              ),
                            ),
                            if (_endOverlaySubtitle.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                _endOverlaySubtitle,
                                textAlign: TextAlign.center,
                                style: BalatroTheme.statusStyle.copyWith(
                                  fontSize: 14,
                                  color: BalatroTheme.cream.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ],
                            if (!widget.isOnline &&
                                _game.winnerColor != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _game.winnerColor == PieceColor.white
                                    ? 'Белые'
                                    : 'Чёрные',
                                style: BalatroTheme.statusStyle.copyWith(
                                  fontSize: 13,
                                  color: BalatroTheme.gold,
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BalatroTheme.gold,
                                foregroundColor: BalatroTheme.felt,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                AppStrings.of(context).back,
                                style: BalatroTheme.statusStyle.copyWith(
                                  fontSize: 14,
                                  color: BalatroTheme.felt,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  PieceColor get _viewerColor => widget.localColor ?? _game.turn;

  PieceColor _other(PieceColor color) =>
      color == PieceColor.white ? PieceColor.black : PieceColor.white;

  void _showActiveAbilities() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return _flipOverlay(
          AlertDialog(
            backgroundColor: BalatroTheme.felt,
            title: Text(
              'АКТИВНЫЕ МОДИФИКАЦИИ',
              style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: _activeModsBody(hideOpponent: widget.vsComputer),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ЗАКРЫТЬ',
                  style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _activeModsBody({required bool hideOpponent}) {
    final snapshot = _game.activeAbilitiesSnapshot();
    final youColor = widget.localColor ?? PieceColor.white;
    final oppColor = youColor == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;
    final youLabel = widget.localColor != null ? 'ВЫ' : 'БЕЛЫЕ';
    final oppLabel = widget.localColor != null ? 'СОПЕРНИК' : 'ЧЁРНЫЕ';

    final youStart = youColor == PieceColor.white
        ? snapshot.whiteStart
        : snapshot.blackStart;
    final oppStart = oppColor == PieceColor.white
        ? snapshot.whiteStart
        : snapshot.blackStart;
    final youChosen = youColor == PieceColor.white
        ? snapshot.whiteChosen
        : snapshot.blackChosen;
    final oppChosen = oppColor == PieceColor.white
        ? snapshot.whiteChosen
        : snapshot.blackChosen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hideOpponent) ...[
          _AbilitySectionHeader(label: oppLabel),
          if (oppChosen.isEmpty)
            const _AbilityEmptyHint('Пока ничего не выбирал')
          else if (_game.blindSpotActive)
            ...oppChosen.map(
              (a) => _AbilityInfoTile(
                info: ChosenAbilityInfo(
                  ability: a.ability,
                  title: '???',
                  description: 'Мод скрыта слепой зоной',
                ),
              ),
            )
          else
            ...oppChosen.map((a) => _AbilityInfoTile(info: a)),
          const SizedBox(height: 12),
          Divider(color: BalatroTheme.cream.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
        ],
        Text(
          'ДОСКА',
          textAlign: TextAlign.center,
          style: BalatroTheme.statusStyle.copyWith(
            fontSize: 11,
            color: BalatroTheme.gold.withValues(alpha: 0.75),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        if (hideOpponent)
          _AbilityStartCard(sideLabel: youLabel, info: youStart)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AbilityStartCard(
                  sideLabel: youLabel,
                  info: youStart,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AbilityStartCard(
                  sideLabel: oppLabel,
                  info: oppStart,
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Divider(color: BalatroTheme.cream.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        _AbilitySectionHeader(label: youLabel),
        if (youChosen.isEmpty)
          const _AbilityEmptyHint('Пока ничего не выбирали')
        else
          ...youChosen.map((a) => _AbilityInfoTile(info: a)),
      ],
    );
  }
}

class _PieceFlight {
  _PieceFlight({
    required this.from,
    required this.to,
    required this.piece,
    required this.displayAs,
    required this.isZebra,
    required this.duration,
    required this.completer,
  });

  final Square from;
  final Square to;
  final Piece piece;
  final PieceType? displayAs;
  final bool isZebra;
  final Duration duration;
  final Completer<void> completer;
}

class _ChessBoard extends StatelessWidget {
  const _ChessBoard({
    required this.game,
    required this.selectedSquare,
    required this.availableMoves,
    required this.animatingLavaDeaths,
    required this.onLavaDeathFinished,
    required this.onSquareTap,
    required this.viewerColor,
    required this.maxWidth,
    required this.maxHeight,
    this.pieceFlight,
    this.onPieceFlightFinished,
    this.rotatePieces = false,
    this.flipBoard = false,
  });

  final ChessGame game;
  final Square? selectedSquare;
  final List<Move> availableMoves;
  final List<LavaDeathEvent> animatingLavaDeaths;
  final VoidCallback onLavaDeathFinished;
  final ValueChanged<Square> onSquareTap;
  final PieceColor viewerColor;
  final double maxWidth;
  final double maxHeight;
  final _PieceFlight? pieceFlight;
  final VoidCallback? onPieceFlightFinished;
  final bool rotatePieces;
  final bool flipBoard;

  bool _isHighlighted(Square square) {
    return availableMoves.any((move) => move.to == square);
  }

  bool _isCapture(Square square) {
    return availableMoves.any(
      (move) =>
          move.to == square &&
          move.isKnightRearSwap == false &&
          move.isRookPush == false &&
          game.piecesAt(square).isNotEmpty,
    );
  }

  bool _isLavaRank(int rank) => game.lavaRanks.contains(rank);

  bool _isKingInCheck(Square square, Piece? piece) {
    if (piece?.type != PieceType.king) return false;
    return game.isInCheck(piece!.color);
  }

  LavaDeathEvent? _lavaDeathAt(Square square) {
    for (final death in animatingLavaDeaths) {
      if (death.square == square) return death;
    }
    return null;
  }

  PieceType? _displayTypeFor(Piece piece) {
    if (game.hasDoppelganger(piece.color) &&
        (piece.type == PieceType.pawn || piece.type == PieceType.queen)) {
      return PieceType.king;
    }
    return null;
  }

  Widget _pieceVisual({
    required Piece piece,
    required double size,
    required Set<String> sanctuaryProtected,
    required Set<String> curfewIds,
    required Map<String, int> siegeByTarget,
    String? visibleEnemyTurncoatId,
  }) {
    final visited = game.knightTourVisited(piece.pieceId);
    final showTour = visited.isNotEmpty && !game.knightTourRewardUsed(piece.pieceId);
    final child = ChessPieceWidget(
      piece: piece,
      size: size,
      displayAs: _displayTypeFor(piece),
      isZebra: game.zebrasActive && piece.type == PieceType.knight,
      inDuel: game.duelPartnerOf(piece.pieceId) != null,
      hasSanctuaryWard: sanctuaryProtected.contains(piece.pieceId),
      underCurfew: curfewIds.contains(piece.pieceId),
      siegeCounter: siegeByTarget[piece.pieceId],
      tourBadge: showTour ? '${visited.length}/8' : null,
      hasTorch: game.hasTorch(piece.pieceId),
      isFrozen: game.isFrozenPiece(piece.pieceId),
      isEnemyTurncoat: visibleEnemyTurncoatId == piece.pieceId,
      showFrostCounter:
          game.frostMapActive &&
          !game.hasTorch(piece.pieceId) &&
          piece.type != PieceType.king,
    );
    if (!rotatePieces) return child;
    return Transform.rotate(angle: math.pi, child: child);
  }

  Widget _buildCell({
    required double cellSize,
    required Square square,
    required bool isLight,
    required bool isVisible,
    required Set<Square> abilityTargets,
    required Set<Square> guardSquares,
    required Set<Square> secretRouteSquares,
    required Set<Square> customsSquares,
    required Set<String> sanctuaryProtected,
    required Set<String> curfewIds,
    required Map<String, int> siegeByTarget,
    String? fileCoord,
    String? rankCoord,
  }) {
    final pieces = game.piecesAt(square);
    final visiblePieces = [
      for (final p in pieces)
        if (!game.isPieceHiddenFrom(p, viewerColor)) p,
    ];
    final piece = visiblePieces.isEmpty ? null : visiblePieces.first;
    final isSelected = selectedSquare == square;
    final isMoveTarget = _isHighlighted(square);
    final isCapture = _isCapture(square);
    final inCheck = _isKingInCheck(square, piece);
    final isLava = _isLavaRank(square.rank);
    final isQuarantine = game.isQuarantined(square);
    final isWormhole = game.wormholes.contains(square);
    final isGhost = game.isGhostCell(square);
    final isTeleport = game.isTeleportSquare(square);
    final isDust = game.isDustSquare(square);
    final isLaser = game.isLaserFile(square.file);
    final isSilent = game.isSilentFile(square.file);
    final isAbilityTarget = abilityTargets.contains(square);
    final isGuard = guardSquares.contains(square);
    final isSecretRoute = secretRouteSquares.contains(square);
    final isCustoms = customsSquares.contains(square);
    final territoryOwner = game.territory[square];
    final lavaDeath = _lavaDeathAt(square);
    final hidingForFlight = pieceFlight != null && square == pieceFlight!.from;
    final showPieces =
        visiblePieces.isNotEmpty &&
        lavaDeath == null &&
        isVisible &&
        !hidingForFlight;
    final showLavaDeath = lavaDeath != null && isVisible;

    Color backgroundColor;
    if (inCheck && isVisible) {
      backgroundColor = BalatroTheme.checkHighlight;
    } else if (isSelected && isVisible) {
      backgroundColor = BalatroTheme.selectedSquare;
    } else if (isWormhole && isVisible) {
      backgroundColor = isLight
          ? const Color(0xFF2A1840)
          : const Color(0xFF160C28);
    } else if (isTeleport && isVisible) {
      backgroundColor = isLight
          ? const Color(0xFF1E4D5C)
          : const Color(0xFF0F2E38);
    } else if (isGhost && isVisible) {
      backgroundColor = isLight
          ? const Color(0xFFB8C4D4)
          : const Color(0xFF6A7585);
    } else if (isQuarantine && isVisible) {
      backgroundColor = isLight
          ? const Color(0xFF4A5568)
          : const Color(0xFF2D3748);
    } else if (isDust && isVisible) {
      backgroundColor = isLight
          ? const Color(0xFF7A6A4A)
          : const Color(0xFF4A3E28);
    } else if (isLaser && isVisible) {
      backgroundColor = isLight
          ? const Color(0xFF5C2A2A)
          : const Color(0xFF3A1515);
    } else if (isSilent && isVisible) {
      backgroundColor = isLight
          ? const Color(0xFF2B3E57)
          : const Color(0xFF172638);
    } else if (game.isAuctionSquare && game.auctionSquare == square && isVisible) {
      backgroundColor = isLight
          ? const Color(0xFF5A4614)
          : const Color(0xFF2E2308);
    } else if (isLava && isVisible) {
      backgroundColor = isLight
          ? const Color(0xFF8B3A2A)
          : const Color(0xFF5C1F14);
    } else {
      backgroundColor = isLight
          ? BalatroTheme.lightSquare
          : BalatroTheme.darkSquare;
    }

    if (isVisible && territoryOwner != null && !inCheck && !isSelected) {
      // Царь горы: claimed squares become exact light/dark board colors
      // (a2 / a1 shades), not a translucent tint.
      backgroundColor = territoryOwner == PieceColor.white
          ? BalatroTheme.lightSquare
          : BalatroTheme.darkSquare;
    }

    final last = game.lastMove;
    if (last != null &&
        isVisible &&
        !inCheck &&
        !isSelected &&
        (square == last.from || square == last.to)) {
      backgroundColor = Color.alphaBlend(
        const Color(0x99CDD26A),
        backgroundColor,
      );
    }

    if (isVisible &&
        game.scorchingSunActive &&
        game.sunSquares.contains(square) &&
        !inCheck &&
        !isSelected) {
      backgroundColor = Color.alphaBlend(
        const Color(0x55F59E0B),
        backgroundColor,
      );
    }
    if (isVisible &&
        game.quicksandRevealed.contains(square) &&
        !inCheck &&
        !isSelected) {
      backgroundColor = Color.alphaBlend(
        const Color(0x664A3728),
        backgroundColor,
      );
    }
    if (isVisible && isCustoms && !inCheck && !isSelected) {
      backgroundColor = Color.alphaBlend(
        const Color(0x332F6FED),
        backgroundColor,
      );
    }
    if (isVisible && isSecretRoute && !inCheck && !isSelected) {
      backgroundColor = Color.alphaBlend(
        const Color(0x334ADE80),
        backgroundColor,
      );
    }

    final coordStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: math.max(9.0, cellSize * 0.16),
      fontWeight: FontWeight.w700,
      height: 1,
      color: isLight
          ? BalatroTheme.darkSquare.withValues(alpha: 0.75)
          : BalatroTheme.lightSquare.withValues(alpha: 0.85),
    );

    return GestureDetector(
      onTap: () => onSquareTap(square),
      child: Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: isSelected
              ? Border.all(color: BalatroTheme.gold, width: 2)
              : isAbilityTarget
              ? Border.all(
                  color: const Color(0xFF38BDF8),
                  width: 2.5,
                )
              : isGuard
              ? Border.all(
                  color: const Color(0xFFA78BFA),
                  width: 2,
                )
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (fileCoord != null)
              Positioned(
                left: cellSize * 0.06,
                bottom: cellSize * 0.04,
                child: Text(fileCoord, style: coordStyle),
              ),
            if (rankCoord != null)
              Positioned(
                right: cellSize * 0.06,
                top: cellSize * 0.04,
                child: Text(rankCoord, style: coordStyle),
              ),
            if (isVisible && isGuard)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x33A78BFA),
                  ),
                ),
              ),
            if (isVisible && isAbilityTarget)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x2238BDF8),
                  ),
                ),
              ),
            if (isVisible && isLava)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFFFF6B00).withValues(alpha: 0.55),
                        const Color(0xFFFFD000).withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            if (isVisible && isWormhole)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7B2FF7).withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.blur_on,
                    size: cellSize * 0.4,
                    color: BalatroTheme.cream.withValues(alpha: 0.5),
                  ),
                ),
              ),
            if (isVisible && isTeleport)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF2EC4B6).withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.swap_horiz,
                    size: cellSize * 0.32,
                    color: BalatroTheme.cream.withValues(alpha: 0.55),
                  ),
                ),
              ),
            if (isVisible && isGhost)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    Icons.blur_on,
                    size: cellSize * 0.3,
                    color: BalatroTheme.cream.withValues(alpha: 0.4),
                  ),
                ),
              ),
            if (isVisible && isQuarantine)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  child: Center(
                    child: Text(
                      '${game.quarantineMovesLeft}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: cellSize * 0.42,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: BalatroTheme.cream.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ),
            if (!isVisible)
              Positioned.fill(
                child: CustomPaint(
                  painter: _FogOfWarPainter(
                    seed: square.file * 37 + square.rank * 17,
                  ),
                ),
              ),
            if (isVisible && isMoveTarget && !isCapture)
              Container(
                width: cellSize * 0.26,
                height: cellSize * 0.26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BalatroTheme.moveHint,
                  border: Border.all(
                    color: BalatroTheme.gold.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
              ),
            if (isVisible && isMoveTarget && isCapture)
              Container(
                width: cellSize * 0.88,
                height: cellSize * 0.88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: BalatroTheme.accent.withValues(alpha: 0.9),
                    width: cellSize * 0.1,
                  ),
                ),
              ),
            if (showPieces && visiblePieces.length == 1)
              _pieceVisual(
                piece: visiblePieces.first,
                size: cellSize * 0.88,
                sanctuaryProtected: sanctuaryProtected,
                curfewIds: curfewIds,
                siegeByTarget: siegeByTarget,
                visibleEnemyTurncoatId:
                    game.visibleEnemyTurncoatId(viewerColor),
              ),
            if (showPieces && visiblePieces.length > 1) ...[
              Positioned(
                left: cellSize * 0.05,
                top: cellSize * 0.08,
                child: _pieceVisual(
                  piece: visiblePieces[0],
                  size: cellSize * 0.58,
                  sanctuaryProtected: sanctuaryProtected,
                  curfewIds: curfewIds,
                  siegeByTarget: siegeByTarget,
                  visibleEnemyTurncoatId:
                      game.visibleEnemyTurncoatId(viewerColor),
                ),
              ),
              Positioned(
                right: cellSize * 0.05,
                bottom: cellSize * 0.08,
                child: _pieceVisual(
                  piece: visiblePieces[1],
                  size: cellSize * 0.58,
                  sanctuaryProtected: sanctuaryProtected,
                  curfewIds: curfewIds,
                  siegeByTarget: siegeByTarget,
                  visibleEnemyTurncoatId:
                      game.visibleEnemyTurncoatId(viewerColor),
                ),
              ),
            ],
            if (showLavaDeath)
              Transform.rotate(
                angle: rotatePieces ? math.pi : 0,
                child: LavaDeathOverlay(
                  piece: lavaDeath.piece,
                  size: cellSize * 0.88,
                  onFinished: onLavaDeathFinished,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rankCount = game.rankCount;
    final fileCount = game.fileCount;
    final extraFile = game.extraFilePlacement;
    final visible = game.fogOfWarActive
        ? game.visibleSquaresFor(viewerColor)
        : null;

    final abilityTargets = game.isAwaitingAbilityTarget
        ? game.legalAbilityTargetSquares.toSet()
        : const <Square>{};
    final guardSquares = {
      for (final guard in game.knightGuards) guard.square,
    };
    final secretRoute = game.secretRouteFor(viewerColor);
    final secretRouteSquares =
        secretRoute == null ? const <Square>{} : secretRoute.toSet();
    final customsSquares = <Square>{};
    for (final state in game.customs) {
      if (state.axis == AbilityAxis.file) {
        for (var rank = 0; rank < rankCount; rank++) {
          customsSquares.add(Square(state.line, rank));
        }
      } else {
        for (var file = 0; file < fileCount; file++) {
          customsSquares.add(Square(file, state.line));
        }
      }
    }
    final sanctuaryProtected = <String>{};
    final curfewIds = {for (final c in game.rookCurfews) c.pieceId};
    final siegeByTarget = {
      for (final s in game.rookSieges) s.targetPieceId: s.counter,
    };
    for (var rank = 0; rank < rankCount; rank++) {
      for (var file = 0; file < fileCount; file++) {
        for (final piece in game.piecesAt(Square(file, rank))) {
          final ward = game.sanctuaryTargetOf(piece.pieceId);
          if (ward != null) sanctuaryProtected.add(ward);
        }
      }
    }

    // По возможности на всю ширину экрана; если не влезает по высоте — уменьшаем.
    var cellSize = maxWidth / fileCount;
    if (cellSize * rankCount > maxHeight) {
      cellSize = maxHeight / rankCount;
    }
    final boardWidth = cellSize * fileCount;
    final boardHeight = cellSize * rankCount;
    final bottomRank = flipBoard ? rankCount - 1 : 0;
    final rightFile = flipBoard ? 0 : fileCount - 1;

    return SizedBox(
      width: boardWidth,
      height: boardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: List.generate(rankCount, (displayRow) {
              final rank = flipBoard ? displayRow : rankCount - 1 - displayRow;
              return Row(
                children: List.generate(fileCount, (displayCol) {
                  final file =
                      flipBoard ? fileCount - 1 - displayCol : displayCol;
                  final square = Square(file, rank);
                  return _buildCell(
                    cellSize: cellSize,
                    square: square,
                    isLight: game.isSquareLight(square),
                    isVisible: visible == null || visible.contains(square),
                    abilityTargets: abilityTargets,
                    guardSquares: guardSquares,
                    secretRouteSquares: secretRouteSquares,
                    customsSquares: customsSquares,
                    sanctuaryProtected: sanctuaryProtected,
                    curfewIds: curfewIds,
                    siegeByTarget: siegeByTarget,
                    fileCoord: rank == bottomRank
                        ? fileLabel(
                            file,
                            fileCount: fileCount,
                            extraFile: extraFile,
                          )
                        : null,
                    rankCoord: file == rightFile
                        ? chessRankLabel(rank).toString()
                        : null,
                  );
                }),
              );
            }),
          ),
          if (pieceFlight != null)
            _FlyingPiece(
              key: ValueKey(
                '${pieceFlight!.from.file},${pieceFlight!.from.rank}->'
                '${pieceFlight!.to.file},${pieceFlight!.to.rank}',
              ),
              flight: pieceFlight!,
              cellSize: cellSize,
              rankCount: rankCount,
              fileCount: fileCount,
              flipBoard: flipBoard,
              rotatePiece: rotatePieces,
              onFinished: onPieceFlightFinished ?? () {},
            ),
        ],
      ),
    );
  }
}

class _FlyingPiece extends StatefulWidget {
  const _FlyingPiece({
    super.key,
    required this.flight,
    required this.cellSize,
    required this.rankCount,
    required this.onFinished,
    this.fileCount = 8,
    this.flipBoard = false,
    this.rotatePiece = false,
  });

  final _PieceFlight flight;
  final double cellSize;
  final int rankCount;
  final int fileCount;
  final bool flipBoard;
  final VoidCallback onFinished;
  final bool rotatePiece;

  @override
  State<_FlyingPiece> createState() => _FlyingPieceState();
}

class _FlyingPieceState extends State<_FlyingPiece>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _position;

  Offset _offsetFor(Square square) {
    final displayFile =
        widget.flipBoard ? widget.fileCount - 1 - square.file : square.file;
    final displayRank =
        widget.flipBoard ? square.rank : widget.rankCount - 1 - square.rank;
    return Offset(displayFile * widget.cellSize, displayRank * widget.cellSize);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.flight.duration,
    );
    _position = Tween<Offset>(
      begin: _offsetFor(widget.flight.from),
      end: _offsetFor(widget.flight.to),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        // Softer ease reads better on web where frame pacing is uneven.
        curve: kIsWeb ? Curves.easeInOutCubicEmphasized : Curves.easeInOutCubic,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
      }
    });
    // Wait one frame so the piece is painted at the origin before moving
    // (otherwise the first web frames often skip and the move looks like a snap).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.cellSize * 0.88;
    final pad = (widget.cellSize - size) / 2;

    // Transform.translate composites without relayout — critical on Flutter web,
    // where animating Positioned left/top every frame drops frames and looks abrupt.
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _position,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _position.value.dx + pad,
                _position.value.dy + pad,
              ),
              child: child,
            );
          },
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              child: Transform.rotate(
                angle: widget.rotatePiece ? math.pi : 0,
                child: ChessPieceWidget(
                  piece: widget.flight.piece,
                  size: size,
                  displayAs: widget.flight.displayAs,
                  isZebra: widget.flight.isZebra,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AbilitySectionHeader extends StatelessWidget {
  const _AbilitySectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: BalatroTheme.statusStyle.copyWith(
          fontSize: 12,
          color: BalatroTheme.gold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _AbilityEmptyHint extends StatelessWidget {
  const _AbilityEmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: BalatroTheme.statusStyle.copyWith(
          fontSize: 12,
          color: BalatroTheme.cream.withValues(alpha: 0.45),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AbilityInfoTile extends StatelessWidget {
  const _AbilityInfoTile({required this.info});

  final ChosenAbilityInfo info;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            info.title,
            style: BalatroTheme.statusStyle.copyWith(
              fontSize: 13,
              color: BalatroTheme.cream,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            info.description,
            style: BalatroTheme.statusStyle.copyWith(
              fontSize: 11,
              color: BalatroTheme.cream.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
              height: 1.35,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _AbilityStartCard extends StatelessWidget {
  const _AbilityStartCard({required this.sideLabel, required this.info});

  final String sideLabel;
  final ChosenAbilityInfo? info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BalatroTheme.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BalatroTheme.cream.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sideLabel,
            style: BalatroTheme.statusStyle.copyWith(
              fontSize: 10,
              color: BalatroTheme.gold.withValues(alpha: 0.8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          if (info == null)
            Text(
              '—',
              style: BalatroTheme.statusStyle.copyWith(
                fontSize: 12,
                color: BalatroTheme.cream.withValues(alpha: 0.4),
              ),
            )
          else ...[
            Text(
              info!.title,
              style: BalatroTheme.statusStyle.copyWith(
                fontSize: 13,
                color: BalatroTheme.cream,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info!.description,
              style: BalatroTheme.statusStyle.copyWith(
                fontSize: 11,
                color: BalatroTheme.cream.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
                height: 1.3,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Мягкий «туман» поверх клетки, без сплошной тёмной заливки.
class _FogOfWarPainter extends CustomPainter {
  const _FogOfWarPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFC5D0DC).withValues(alpha: 0.42),
    );

    for (var i = 0; i < 5; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final radius = size.shortestSide * (0.32 + rng.nextDouble() * 0.55);
      final center = Offset(cx, cy);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.62),
            const Color(0xFFAEBCC8).withValues(alpha: 0.38),
            const Color(0xFF8A9AAA).withValues(alpha: 0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF6B7C8C).withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _FogOfWarPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
