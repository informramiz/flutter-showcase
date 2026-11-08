import 'package:flutter/material.dart';
import 'package:flutter_showcase/domain/services/collection_name.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';

/// Asks for a collection name. [validate] runs on submit; the dialog stays
/// open and shows the reason while it returns an error. Resolves to the
/// trimmed name, or `null` when cancelled.
Future<String?> showCollectionNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required CollectionNameError? Function(String name) validate,
  String initial = '',
}) => showDialog<String>(
  context: context,
  builder: (_) => _CollectionNameDialog(
    title: title,
    confirmLabel: confirmLabel,
    validate: validate,
    initial: initial,
  ),
);

extension CollectionNameErrorText on AppLocalizations {
  String collectionNameError(CollectionNameError error) => switch (error) {
    CollectionNameError.empty => nameEmpty,
    CollectionNameError.tooLong => nameTooLong(maxCollectionNameLength),
    CollectionNameError.duplicate => nameDuplicate,
  };
}

class _CollectionNameDialog extends StatefulWidget {
  const _CollectionNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.validate,
    required this.initial,
  });

  final String title;
  final String confirmLabel;
  final CollectionNameError? Function(String name) validate;
  final String initial;

  @override
  State<_CollectionNameDialog> createState() => _CollectionNameDialogState();
}

class _CollectionNameDialogState extends State<_CollectionNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  CollectionNameError? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final error = widget.validate(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const ValueKey('collection-name-field'),
        controller: _controller,
        autofocus: true,
        maxLength: maxCollectionNameLength,
        decoration: InputDecoration(
          labelText: l10n.collectionName,
          errorText: switch (_error) {
            final error? => l10n.collectionNameError(error),
            null => null,
          },
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
