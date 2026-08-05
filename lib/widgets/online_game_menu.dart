import 'package:flutter/material.dart';

import '../theme/balatro_theme.dart';

enum OnlineMenuAction { takeback, draw, resign }

class OnlineGameMenu {
  OnlineGameMenu._();

  static Future<OnlineMenuAction?> showActions(BuildContext context) {
    return showModalBottomSheet<OnlineMenuAction>(
      context: context,
      backgroundColor: BalatroTheme.felt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.u_turn_left_rounded,
                  color: BalatroTheme.cream,
                ),
                title: Text(
                  'Попросить соперника вернуть ход',
                  style: BalatroTheme.statusStyle.copyWith(fontSize: 14),
                ),
                onTap: () =>
                    Navigator.pop(context, OnlineMenuAction.takeback),
              ),
              ListTile(
                leading: Text(
                  '½',
                  style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
                ),
                title: Text(
                  'Предложить ничью',
                  style: BalatroTheme.statusStyle.copyWith(fontSize: 14),
                ),
                onTap: () => Navigator.pop(context, OnlineMenuAction.draw),
              ),
              ListTile(
                leading: const Icon(
                  Icons.flag_rounded,
                  color: BalatroTheme.cream,
                ),
                title: Text(
                  'Сдаться',
                  style: BalatroTheme.statusStyle.copyWith(fontSize: 14),
                ),
                onTap: () => Navigator.pop(context, OnlineMenuAction.resign),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static Future<bool> confirmResign(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: BalatroTheme.felt,
          title: Text(
            'Сдаться?',
            style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_rounded, color: Color(0xFF6BCB77)),
              label: Text(
                'Сдаться',
                style: BalatroTheme.statusStyle.copyWith(fontSize: 14),
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close_rounded, color: Color(0xFFE57373)),
              label: Text(
                'Отменить',
                style: BalatroTheme.statusStyle.copyWith(fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
    return result == true;
  }
}
