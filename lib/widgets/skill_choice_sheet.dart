import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/models/ability_group.dart';
import '../l10n/models/game_ability.dart';
import '../theme/balatro_theme.dart';

class SkillChoiceSheet extends StatelessWidget {
  const SkillChoiceSheet({
    super.key,
    required this.offers,
    required this.onSelected,
    required this.title,
    required this.subtitle,
    this.secondsLeft,
    this.onReroll,
    this.canReroll = false,
    this.permanentReroll = false,
    this.onPreviewOffer,
    this.previewing = false,
  });

  final List<AbilityOffer> offers;
  final ValueChanged<GameAbility> onSelected;
  final String title;
  final String subtitle;
  final int? secondsLeft;
  final VoidCallback? onReroll;
  final bool canReroll;
  final bool permanentReroll;
  /// Hold-to-preview: non-null while a finger is held on a card.
  final ValueChanged<AbilityOffer?>? onPreviewOffer;
  final bool previewing;

  static Future<GameAbility?> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<AbilityOffer> offers,
    int? seconds,
    bool rotate180 = false,
    VoidCallback? onReroll,
    bool canReroll = false,
    bool permanentReroll = false,
    ValueChanged<AbilityOffer?>? onPreviewOffer,
  }) {
    return showDialog<GameAbility>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x99000000),
      builder: (dialogContext) {
        return _PreviewAwareDialog(
          rotate180: rotate180,
          onPreviewOffer: onPreviewOffer,
          childBuilder: (previewing, setPreview) {
            Widget sheet = seconds == null
                ? SkillChoiceSheet(
                    title: title,
                    subtitle: subtitle,
                    offers: offers,
                    onSelected: (ability) =>
                        Navigator.pop(dialogContext, ability),
                    onReroll: onReroll,
                    canReroll: canReroll,
                    permanentReroll: permanentReroll,
                    previewing: previewing,
                    onPreviewOffer: (offer) {
                      setPreview(offer != null);
                      onPreviewOffer?.call(offer);
                    },
                  )
                : _TimedSkillChoiceSheet(
                    title: title,
                    subtitle: subtitle,
                    offers: offers,
                    seconds: seconds,
                    onReroll: onReroll,
                    canReroll: canReroll,
                    permanentReroll: permanentReroll,
                    previewing: previewing,
                    onPreviewOffer: (offer) {
                      setPreview(offer != null);
                      onPreviewOffer?.call(offer);
                    },
                  );
            return sheet;
          },
        );
      },
    ).whenComplete(() => onPreviewOffer?.call(null));
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return AnimatedOpacity(
      opacity: previewing ? 0.18 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: BalatroTheme.felt.withValues(alpha: previewing ? 0.55 : 1),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 440, maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: BalatroTheme.titleStyle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: BalatroTheme.statusStyle.copyWith(
                    fontSize: 13,
                    color: BalatroTheme.cream.withValues(alpha: 0.75),
                  ),
                ),
                if (secondsLeft != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Осталось: $secondsLeft с',
                    textAlign: TextAlign.center,
                    style: BalatroTheme.statusStyle.copyWith(
                      fontSize: 13,
                      color: secondsLeft! <= 10
                          ? BalatroTheme.accent
                          : BalatroTheme.gold.withValues(alpha: 0.85),
                    ),
                  ),
                ],
                if (canReroll && onReroll != null) ...[
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: onReroll,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BalatroTheme.gold,
                      side: BorderSide(
                        color: BalatroTheme.gold.withValues(alpha: 0.7),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      permanentReroll ? 'ОБНОВИТЬ ∞' : 'ОБНОВИТЬ',
                      style: BalatroTheme.statusStyle.copyWith(fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                for (var i = 0; i < offers.length; i++)
                  Padding(
                    padding:
                        EdgeInsets.only(bottom: i < offers.length - 1 ? 10 : 0),
                    child: _SkillCard(
                      offer: offers[i],
                      onTap: () => onSelected(offers[i].ability),
                      onPreviewOffer: onPreviewOffer,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewAwareDialog extends StatefulWidget {
  const _PreviewAwareDialog({
    required this.childBuilder,
    required this.rotate180,
    this.onPreviewOffer,
  });

  final Widget Function(bool previewing, void Function(bool) setPreview)
      childBuilder;
  final bool rotate180;
  final ValueChanged<AbilityOffer?>? onPreviewOffer;

  @override
  State<_PreviewAwareDialog> createState() => _PreviewAwareDialogState();
}

class _PreviewAwareDialogState extends State<_PreviewAwareDialog> {
  bool _previewing = false;

  @override
  Widget build(BuildContext context) {
    Widget dialog = Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: widget.childBuilder(_previewing, (v) {
        if (_previewing == v) return;
        setState(() => _previewing = v);
      }),
    );
    if (widget.rotate180) {
      dialog = Transform.rotate(angle: math.pi, child: dialog);
    }
    return dialog;
  }
}

class _TimedSkillChoiceSheet extends StatefulWidget {
  const _TimedSkillChoiceSheet({
    required this.title,
    required this.subtitle,
    required this.offers,
    required this.seconds,
    this.onReroll,
    this.canReroll = false,
    this.permanentReroll = false,
    this.onPreviewOffer,
    this.previewing = false,
  });

  final String title;
  final String subtitle;
  final List<AbilityOffer> offers;
  final int seconds;
  final VoidCallback? onReroll;
  final bool canReroll;
  final bool permanentReroll;
  final ValueChanged<AbilityOffer?>? onPreviewOffer;
  final bool previewing;

  @override
  State<_TimedSkillChoiceSheet> createState() => _TimedSkillChoiceSheetState();
}

class _TimedSkillChoiceSheetState extends State<_TimedSkillChoiceSheet> {
  late int _secondsLeft;
  Timer? _timer;
  bool _closed = false;
  late List<AbilityOffer> _offers;
  late bool _canReroll;
  late bool _permanentReroll;

  @override
  void initState() {
    super.initState();
    _offers = widget.offers;
    _canReroll = widget.canReroll;
    _permanentReroll = widget.permanentReroll;
    _secondsLeft = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          timer.cancel();
          _autoPick();
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant _TimedSkillChoiceSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offers != widget.offers) {
      _offers = widget.offers;
    }
    _canReroll = widget.canReroll;
    _permanentReroll = widget.permanentReroll;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pick(GameAbility ability) {
    if (_closed || !mounted) return;
    _closed = true;
    _timer?.cancel();
    widget.onPreviewOffer?.call(null);
    Navigator.pop(context, ability);
  }

  void _autoPick() {
    if (_offers.isEmpty) {
      _pick(GameAbility.randomCalm);
      return;
    }
    final pick = _offers[math.Random().nextInt(_offers.length)];
    _pick(pick.ability);
  }

  void _handleReroll() {
    widget.onReroll?.call();
    if (!mounted) return;
    setState(() {
      _offers = widget.offers;
      _canReroll = widget.canReroll;
      _permanentReroll = widget.permanentReroll;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SkillChoiceSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      offers: _offers,
      secondsLeft: _secondsLeft,
      onSelected: _pick,
      onReroll: widget.onReroll == null ? null : _handleReroll,
      canReroll: _canReroll,
      permanentReroll: _permanentReroll,
      onPreviewOffer: widget.onPreviewOffer,
      previewing: widget.previewing,
    );
  }
}

class _SkillCard extends StatefulWidget {
  const _SkillCard({
    required this.offer,
    required this.onTap,
    this.onPreviewOffer,
  });

  final AbilityOffer offer;
  final VoidCallback onTap;
  final ValueChanged<AbilityOffer?>? onPreviewOffer;

  @override
  State<_SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<_SkillCard> {
  bool _holding = false;

  void _clearPreview() {
    if (!_holding) return;
    _holding = false;
    widget.onPreviewOffer?.call(null);
  }

  @override
  void dispose() {
    if (_holding) widget.onPreviewOffer?.call(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ability = widget.offer.ability;
    final groupLabel = ability.group.title;

    return Material(
      color: BalatroTheme.background.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(10),
      child: GestureDetector(
        // Tap selects; long-press only previews (does not select).
        onTap: () {
          _clearPreview();
          widget.onTap();
        },
        onLongPressStart: widget.onPreviewOffer == null
            ? null
            : (_) {
                _holding = true;
                HapticFeedback.selectionClick();
                widget.onPreviewOffer!(widget.offer);
              },
        onLongPressEnd: widget.onPreviewOffer == null
            ? null
            : (_) => _clearPreview(),
        onLongPressCancel: widget.onPreviewOffer == null
            ? null
            : _clearPreview,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.offer.isWildcard
                  ? BalatroTheme.accent.withValues(alpha: 0.85)
                  : BalatroTheme.gold.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      groupLabel.toUpperCase(),
                      style: BalatroTheme.statusStyle.copyWith(
                        fontSize: 11,
                        color: BalatroTheme.accentSoft,
                      ),
                    ),
                    if (widget.offer.isWildcard) ...[
                      const SizedBox(width: 8),
                      Text(
                        '· СЛУЧАЙНАЯ',
                        style: BalatroTheme.statusStyle.copyWith(
                          fontSize: 11,
                          color: BalatroTheme.gold.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ability.title.toUpperCase(),
                  style: BalatroTheme.statusStyle.copyWith(
                    color: BalatroTheme.gold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.offer.displayDescription,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.35,
                    color: BalatroTheme.cream.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
