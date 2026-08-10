import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chess/game_end_messages.dart';
import '../l10n/app_strings.dart';
import '../theme/balatro_theme.dart';
import 'game_screen.dart';

const tutorialDonePrefsKey = 'tutorial_done';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  var _step = 0;

  List<({String title, String body})> _steps(AppStrings s) {
    final ru = s.isRu;
    return [
      (
        title: ru ? 'SuperChess' : 'SuperChess',
        body: ru
            ? 'Это шахматы, где после стартового выбора и взятий появляются моды — особые правила для фигур, доски и всей партии.'
            : 'This is chess where start picks and captures grant mods — special rules for pieces, the board, and the whole game.',
      ),
      (
        title: ru ? 'Выбор мода' : 'Picking a mod',
        body: ru
            ? 'В начале партии и примерно каждые 3 хода каждой стороны вам предлагают несколько модов. Выберите один — он сразу действует.'
            : 'At the start and about every 3 moves per side you get several mods. Pick one — it applies immediately.',
      ),
      (
        title: ru ? 'Ход и взятие' : 'Moves and captures',
        body: ru
            ? 'Ходите как в обычных шахматах. После взятия фигурой часто открывается выбор мода именно для неё.'
            : 'Move as in normal chess. After a capture you often choose a mod for that piece.',
      ),
      (
        title: ru ? 'Онлайн' : 'Online',
        body: ru
            ? 'В онлайне часы общие, при обрыве связи есть время переподключиться. Можно играть в приватной комнате или смотреть чужую партию.'
            : 'Online clocks stay in sync; after a disconnect you have time to reconnect. You can use private rooms or spectate.',
      ),
      (
        title: ru ? 'Готово' : 'Ready',
        body: ru
            ? 'Откройте браузер модов, чтобы изучить эффекты, или сыграйте учебную партию локально.'
            : 'Browse the mod catalog to learn effects, or play a local practice game.',
      ),
    ];
  }

  Future<void> _markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tutorialDonePrefsKey, true);
  }

  Future<void> _finish({bool practice = false}) async {
    await _markDone();
    if (!mounted) return;
    if (practice) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const GameScreen(
            // Hot-seat local practice
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final steps = _steps(s);
    final step = steps[_step.clamp(0, steps.length - 1)];
    final last = _step >= steps.length - 1;

    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          s.tutorial,
          style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
        actions: [
          TextButton(
            onPressed: () => _finish(),
            child: Text(s.skip, style: BalatroTheme.statusStyle),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_step + 1} / ${steps.length}',
                style: BalatroTheme.statusStyle.copyWith(
                  fontSize: 12,
                  color: BalatroTheme.cream.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                step.title,
                style: BalatroTheme.titleStyle.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 16),
              Text(
                step.body,
                style: BalatroTheme.statusStyle.copyWith(
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              if (last) ...[
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const _EndReasonsHelpPage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BalatroTheme.cream,
                    side: BorderSide(
                      color: BalatroTheme.cream.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    s.endReasonsHelp,
                    style: BalatroTheme.statusStyle,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => _finish(practice: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: BalatroTheme.gold,
                    foregroundColor: BalatroTheme.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    s.startTutorialGame,
                    style: BalatroTheme.statusStyle.copyWith(
                      color: BalatroTheme.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              FilledButton(
                onPressed: () {
                  if (last) {
                    _finish();
                  } else {
                    setState(() => _step++);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: BalatroTheme.accent,
                  foregroundColor: BalatroTheme.cream,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  last ? s.tutorialDone : s.next,
                  style: BalatroTheme.statusStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EndReasonsHelpPage extends StatelessWidget {
  const _EndReasonsHelpPage();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          s.endReasonsHelp,
          style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: GameEndMessages.catalog.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final item = GameEndMessages.catalog[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BalatroTheme.felt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: BalatroTheme.titleStyle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  item.body,
                  style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Optional CTA banner for the home screen.
class TutorialHomeCta extends StatefulWidget {
  const TutorialHomeCta({super.key});

  @override
  State<TutorialHomeCta> createState() => _TutorialHomeCtaState();
}

class _TutorialHomeCtaState extends State<TutorialHomeCta> {
  bool? _show;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _show = !(prefs.getBool(tutorialDonePrefsKey) ?? false));
  }

  @override
  Widget build(BuildContext context) {
    if (_show != true) return const SizedBox.shrink();
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: BalatroTheme.felt,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TutorialScreen()),
            );
            await _load();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: BalatroTheme.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.tryTutorialCta,
                    style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
                  ),
                ),
                const Icon(Icons.chevron_right, color: BalatroTheme.cream),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
