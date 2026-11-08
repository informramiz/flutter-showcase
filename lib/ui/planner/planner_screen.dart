import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_showcase/router.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';
import 'package:flutter_showcase/ui/core/plan_labels.dart';
import 'package:flutter_showcase/ui/core/widgets/meal_thumbnail.dart';
import 'package:flutter_showcase/ui/core/widgets/state_views.dart';
import 'package:flutter_showcase/ui/planner/plan_slot_sheet.dart';
import 'package:flutter_showcase/ui/planner/planner_view_model.dart';
import 'package:go_router/go_router.dart';

/// The weekly plan, grouped by day, with the shopping list one tap away.
class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(plannerViewModelProvider).plan;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.plannerTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.shoppingList,
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.go(Routes.shopping),
          ),
        ],
      ),
      body: plan.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (entries) => entries.isEmpty
            ? EmptyView(
                icon: Icons.calendar_month,
                title: context.l10n.emptyPlan,
                hint: context.l10n.emptyPlanHint,
              )
            : _PlanList(entries: entries),
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({required this.entries});

  final List<PlannedMeal> entries;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final day in PlanDay.values)
          if (entries.where((e) => e.day == day).toList() case final inDay
              when inDay.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(context.l10n.dayName(day), style: text.titleMedium),
            ),
            for (final entry in inDay) _EntryTile(entry: entry),
          ],
      ],
    );
  }
}

enum _EntryAction { moveUp, moveDown, moveTo, reminder, remove }

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry});

  final PlannedMeal entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final viewModel = ref.read(plannerViewModelProvider.notifier);
    return ListTile(
      key: ValueKey('plan-entry-${entry.entryId}'),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: MealThumbnail(url: entry.meal.thumbnailUrl, size: 48),
      ),
      title: Text(entry.meal.name),
      subtitle: Row(
        children: [
          Text(l10n.slotName(entry.slot)),
          if (entry.reminderEnabled) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.notifications_active_outlined,
              key: ValueKey('reminder-on-${entry.entryId}'),
              size: 16,
            ),
          ],
        ],
      ),
      onTap: () => context.push(Routes.meal(entry.meal.id)),
      trailing: PopupMenuButton<_EntryAction>(
        onSelected: (action) => unawaited(
          switch (action) {
            _EntryAction.moveUp => viewModel.moveUp(entry),
            _EntryAction.moveDown => viewModel.moveDown(entry),
            _EntryAction.moveTo => _moveTo(context, viewModel),
            _EntryAction.reminder => _toggleReminder(context, viewModel),
            _EntryAction.remove => viewModel.remove(entry),
          },
        ),
        itemBuilder: (_) => [
          if (entry.position > 0)
            PopupMenuItem(value: _EntryAction.moveUp, child: Text(l10n.moveUp)),
          if (!viewModel.isLastInSlot(entry))
            PopupMenuItem(
              value: _EntryAction.moveDown,
              child: Text(l10n.moveDown),
            ),
          PopupMenuItem(value: _EntryAction.moveTo, child: Text(l10n.moveTo)),
          if (viewModel.remindersSupported)
            CheckedPopupMenuItem(
              value: _EntryAction.reminder,
              checked: entry.reminderEnabled,
              child: Text(l10n.cookReminder),
            ),
          PopupMenuItem(value: _EntryAction.remove, child: Text(l10n.remove)),
        ],
      ),
    );
  }

  Future<void> _moveTo(BuildContext context, PlannerViewModel viewModel) async {
    final target = await showPlanSlotSheet(
      context,
      title: context.l10n.moveTo,
      initial: (day: entry.day, slot: entry.slot),
    );
    if (target == null || !context.mounted) return;
    await viewModel.moveTo(
      entry,
      target.day,
      target.slot,
      reminder: _reminderText(context),
    );
  }

  Future<void> _toggleReminder(
    BuildContext context,
    PlannerViewModel viewModel,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final deniedMessage = context.l10n.reminderDenied;
    final changed = await viewModel.setReminder(
      entry,
      enabled: !entry.reminderEnabled,
      text: _reminderText(context),
    );
    if (!changed) {
      messenger.showSnackBar(SnackBar(content: Text(deniedMessage)));
    }
  }

  ReminderText _reminderText(BuildContext context) => (
    title: context.l10n.reminderTitle,
    body: context.l10n.reminderBody(entry.meal.name),
  );
}
