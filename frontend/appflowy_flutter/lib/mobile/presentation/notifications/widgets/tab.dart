import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/notification_item.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationTab extends StatefulWidget {
  const NotificationTab({
    super.key,
    required this.tabType,
  });

  final MobileNotificationTabType tabType;

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        final reminders = _filterReminders(state.reminders);

        if (reminders.isEmpty) {
          return EmptyNotification(
            type: widget.tabType,
          );
        }

        return RefreshIndicator.adaptive(
          onRefresh: () async => _onRefresh(context),
          child: ListView.separated(
            itemCount: reminders.length,
            separatorBuilder: (context, index) => const VSpace(8.0),
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return NotificationItem(
                key: ValueKey('${widget.tabType}_${reminder.id}'),
                tabType: widget.tabType,
                reminder: reminder,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _onRefresh(BuildContext context) async {
    context.read<ReminderBloc>().add(const ReminderEvent.refresh());

    // at least 0.5 seconds to dismiss the refresh indicator.
    // otherwise, it will be dismissed immediately.
    await context.read<ReminderBloc>().stream.firstOrNull;
    await Future.delayed(const Duration(milliseconds: 500));

    if (context.mounted) {
      showToastNotification(
        context,
        message: LocaleKeys.settings_notifications_refreshSuccess.tr(),
      );
    }
  }

  List<ReminderPB> _filterReminders(List<ReminderPB> reminders) {
    switch (widget.tabType) {
      case MobileNotificationTabType.inbox:
        return reminders.reversed
            .where((reminder) => !reminder.isArchived)
            .toList();
      case MobileNotificationTabType.archive:
        return reminders.reversed
            .where((reminder) => reminder.isArchived)
            .toList();
      case MobileNotificationTabType.unread:
        return reminders.reversed
            .where((reminder) => !reminder.isRead)
            .toList();
    }
  }
}
