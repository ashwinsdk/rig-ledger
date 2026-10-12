import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../../core/theme/app_colors.dart';

/// Address / city field with suggestions from addresses used on earlier bills
/// (this rig). Used by the main bore and side bore forms.
///
/// The form owns [controller]; this widget never replaces its text, so the
/// cursor does not jump and no listeners leak across rebuilds.
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    this.hintText = 'Enter city/address',
    this.icon = Icons.location_on_outlined,
  });

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focus,
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<String>.empty();
        return DatabaseService.getUniqueAddresses()
            .where((a) => a.toLowerCase().contains(q) && a.toLowerCase() != q);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(widget.icon),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Address is required'
              : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 520),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final option = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined,
                        size: 20, color: AppColors.textSecondary),
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
