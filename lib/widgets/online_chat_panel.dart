import 'package:flutter/material.dart';

import '../theme/balatro_theme.dart';

class ChatLine {
  const ChatLine({required this.text, required this.mine});

  final String text;
  final bool mine;
}

class OnlineChatPanel extends StatefulWidget {
  const OnlineChatPanel({
    super.key,
    required this.messages,
    required this.onSend,
    this.embedded = true,
  });

  final List<ChatLine> messages;
  final ValueChanged<String> onSend;
  final bool embedded;

  static Future<void> showSheet({
    required BuildContext context,
    required List<ChatLine> messages,
    required ValueChanged<String> onSend,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BalatroTheme.felt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: OnlineChatPanel(
              messages: messages,
              onSend: onSend,
              embedded: false,
            ),
          ),
        );
      },
    );
  }

  @override
  State<OnlineChatPanel> createState() => _OnlineChatPanelState();
}

class _OnlineChatPanelState extends State<OnlineChatPanel> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OnlineChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BalatroTheme.felt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              'Чат',
              style: BalatroTheme.titleStyle.copyWith(fontSize: 14),
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: widget.messages.isEmpty
                ? Center(
                    child: Text(
                      'Пока тихо',
                      style: BalatroTheme.statusStyle.copyWith(
                        fontSize: 12,
                        color: BalatroTheme.cream.withValues(alpha: 0.45),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(10),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final line = widget.messages[index];
                      return Align(
                        alignment: line.mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: line.mine
                                ? BalatroTheme.appBar
                                : BalatroTheme.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            line.text,
                            style: BalatroTheme.statusStyle.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Сообщение…',
                      hintStyle: BalatroTheme.statusStyle.copyWith(
                        fontSize: 13,
                        color: BalatroTheme.cream.withValues(alpha: 0.35),
                      ),
                      filled: true,
                      fillColor: BalatroTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                IconButton(
                  onPressed: _submit,
                  icon: const Icon(Icons.send_rounded, color: BalatroTheme.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
