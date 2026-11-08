import 'package:flutter/material.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';
import 'package:flutter_showcase/ui/core/plan_labels.dart';

/// A day and slot the user picked.
typedef PlanSlot = ({PlanDay day, MealSlot slot});

/// Asks for a day and slot. Completes with `null` if dismissed.
Future<PlanSlot?> showPlanSlotSheet(
  BuildContext context, {
  required String title,
  PlanSlot initial = (day: PlanDay.monday, slot: MealSlot.dinner),
}) => showModalBottomSheet<PlanSlot>(
  context: context,
  isScrollControlled: true,
  builder: (_) => PlanSlotSheet(title: title, initial: initial),
);

class PlanSlotSheet extends StatefulWidget {
  const PlanSlotSheet({required this.title, required this.initial, super.key});

  final String title;
  final PlanSlot initial;

  @override
  State<PlanSlotSheet> createState() => _PlanSlotSheetState();
}

class _PlanSlotSheetState extends State<PlanSlotSheet> {
  late PlanDay _day = widget.initial.day;
  late MealSlot _slot = widget.initial.slot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: text.titleLarge),
            const SizedBox(height: 16),
            Text(l10n.chooseDay, style: text.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final day in PlanDay.values)
                  ChoiceChip(
                    label: Text(l10n.dayName(day)),
                    selected: day == _day,
                    onSelected: (_) => setState(() => _day = day),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.chooseSlot, style: text.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<MealSlot>(
              segments: [
                for (final slot in MealSlot.values)
                  ButtonSegment(value: slot, label: Text(l10n.slotName(slot))),
              ],
              selected: {_slot},
              onSelectionChanged: (s) => setState(() => _slot = s.single),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop((day: _day, slot: _slot)),
                child: Text(l10n.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
