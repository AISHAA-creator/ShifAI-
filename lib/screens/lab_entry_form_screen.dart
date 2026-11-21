import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/lab_record.dart';
import '../providers/lab_records_provider.dart';
import '../providers/nav_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/step_header.dart';

/// Manual entry / confirmation form for a lab record.
/// Used both for typing values in directly and for reviewing OCR-extracted
/// values before they're saved (OCR suggests, the user always confirms).
class LabEntryFormScreen extends StatefulWidget {
  final double? initialGlucose;
  final GlucoseUnit? initialGlucoseUnit;
  final double? initialInsulin;
  final InsulinUnit? initialInsulinUnit;
  final double? initialHba1c;
  final bool fromScan;

  const LabEntryFormScreen({
    super.key,
    this.initialGlucose,
    this.initialGlucoseUnit,
    this.initialInsulin,
    this.initialInsulinUnit,
    this.initialHba1c,
    this.fromScan = false,
  });

  @override
  State<LabEntryFormScreen> createState() => _LabEntryFormScreenState();
}

class _LabEntryFormScreenState extends State<LabEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _glucoseCtrl;
  late final TextEditingController _insulinCtrl;
  late final TextEditingController _hba1cCtrl;
  late final TextEditingController _notesCtrl;

  late GlucoseUnit _glucoseUnit;
  late InsulinUnit _insulinUnit;
  DateTime _date = DateTime.now();
  final List<LabMarker> _otherMarkers = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _glucoseCtrl = TextEditingController(
      text: widget.initialGlucose?.toString() ?? '',
    );
    _insulinCtrl = TextEditingController(
      text: widget.initialInsulin?.toString() ?? '',
    );
    _hba1cCtrl = TextEditingController(
      text: widget.initialHba1c?.toString() ?? '',
    );
    _notesCtrl = TextEditingController();
    _glucoseUnit = widget.initialGlucoseUnit ?? GlucoseUnit.gl;
    _insulinUnit = widget.initialInsulinUnit ?? InsulinUnit.uiuml;
  }

  @override
  void dispose() {
    _glucoseCtrl.dispose();
    _insulinCtrl.dispose();
    _hba1cCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final glucoseRaw = double.tryParse(_glucoseCtrl.text.replaceAll(',', '.'));
    final insulinRaw = double.tryParse(_insulinCtrl.text.replaceAll(',', '.'));
    final hba1cRaw = double.tryParse(_hba1cCtrl.text.replaceAll(',', '.'));

    if (glucoseRaw == null && insulinRaw == null && hba1cRaw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one value to save.')),
      );
      return;
    }

    final record = LabRecord(
      id: const Uuid().v4(),
      date: _date,
      fastingGlucoseMgdl: glucoseRaw == null
          ? null
          : UnitConverter.glucoseToMgdl(glucoseRaw, _glucoseUnit),
      fastingInsulinUiuml: insulinRaw == null
          ? null
          : UnitConverter.insulinToUiuml(insulinRaw, _insulinUnit),
      hba1cPercent: hba1cRaw,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      otherMarkers: List.unmodifiable(_otherMarkers),
      updatedAt: DateTime.now(),
    );

    final labs = context.read<LabRecordsProvider>();
    final nav = context.read<NavProvider>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await labs.addRecord(record);
      if (!mounted) return;
      navigator.popUntil((route) => route.isFirst);
      nav.setTab(1);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double? get _homaPreview {
    final glucose = double.tryParse(_glucoseCtrl.text.replaceAll(',', '.'));
    final insulin = double.tryParse(_insulinCtrl.text.replaceAll(',', '.'));
    if (glucose == null || insulin == null || glucose <= 0 || insulin <= 0) {
      return null;
    }
    return UnitConverter.glucoseToMgdl(glucose, _glucoseUnit) *
        UnitConverter.insulinToUiuml(insulin, _insulinUnit) /
        405;
  }

  String? _validateOptionalPositive(String? input, String label) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return null;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return 'Enter a positive $label value.';
    }
    return null;
  }

  Future<void> _addMarker() async {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    final unitController = TextEditingController();
    final markerKey = GlobalKey<FormState>();

    final marker = await showDialog<LabMarker>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add lab marker'),
        content: Form(
          key: markerKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Marker name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: valueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Value'),
                validator: (value) =>
                    _validateOptionalPositive(value, 'numeric') ??
                    ((double.tryParse((value ?? '').replaceAll(',', '.')) ==
                            null)
                        ? 'Enter a valid value.'
                        : null),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a unit.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!markerKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                LabMarker(
                  name: nameController.text.trim(),
                  value: double.parse(
                    valueController.text.trim().replaceAll(',', '.'),
                  ),
                  unit: unitController.text.trim(),
                ),
              );
            },
            child: const Text('Add marker'),
          ),
        ],
      ),
    );
    nameController.dispose();
    valueController.dispose();
    unitController.dispose();
    if (marker != null && mounted) {
      setState(() => _otherMarkers.add(marker));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fromScan ? 'Scan Lab Results' : 'Add lab result'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.fromScan) ...[
              const StepHeader(current: 1),
              const SizedBox(height: 16),
            ],
            if (widget.fromScan)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.pastel,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.navy, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Values were read from your photo. Please check them against the printed report before saving.',
                        style: TextStyle(color: AppColors.navy, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_date)),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),

            _valueWithUnitRow(
              label: 'Fasting glucose',
              controller: _glucoseCtrl,
              validator: (value) => _validateOptionalPositive(value, 'glucose'),
              onChanged: (_) => setState(() {}),
              unitWidget: DropdownButton<GlucoseUnit>(
                value: _glucoseUnit,
                items: const [
                  DropdownMenuItem(value: GlucoseUnit.gl, child: Text('g/L')),
                  DropdownMenuItem(
                    value: GlucoseUnit.mgdl,
                    child: Text('mg/dL'),
                  ),
                  DropdownMenuItem(
                    value: GlucoseUnit.mmoll,
                    child: Text('mmol/L'),
                  ),
                ],
                onChanged: (u) => setState(() => _glucoseUnit = u!),
              ),
            ),
            const SizedBox(height: 16),

            _valueWithUnitRow(
              label: 'Fasting insulin',
              controller: _insulinCtrl,
              validator: (value) => _validateOptionalPositive(value, 'insulin'),
              onChanged: (_) => setState(() {}),
              unitWidget: DropdownButton<InsulinUnit>(
                value: _insulinUnit,
                items: const [
                  DropdownMenuItem(
                    value: InsulinUnit.uiuml,
                    child: Text('µIU/mL'),
                  ),
                  DropdownMenuItem(
                    value: InsulinUnit.pmoll,
                    child: Text('pmol/L'),
                  ),
                ],
                onChanged: (u) => setState(() => _insulinUnit = u!),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Both glucose and insulin are needed to calculate HOMA-IR.',
              style: TextStyle(color: AppColors.gray, fontSize: 12),
            ),
            const SizedBox(height: 16),

            _LiveHomaCard(value: _homaPreview),
            const SizedBox(height: 16),

            TextFormField(
              controller: _hba1cCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'HbA1c (%) — optional',
              ),
              validator: (value) {
                final error = _validateOptionalPositive(value, 'HbA1c');
                if (error != null) return error;
                final parsed = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                if (parsed != null && parsed > 100) {
                  return 'Enter HbA1c as a percentage.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            for (var index = 0; index < _otherMarkers.length; index++)
              Card(
                child: ListTile(
                  title: Text(_otherMarkers[index].name),
                  subtitle: Text(
                    '${_otherMarkers[index].value} ${_otherMarkers[index].unit}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove marker',
                    onPressed: () =>
                        setState(() => _otherMarkers.removeAt(index)),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _addMarker,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Missing Lab Marker'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes — optional'),
              maxLines: 2,
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.fromScan
                          ? 'Confirm & calculate'
                          : 'Save & calculate',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valueWithUnitRow({
    required String label,
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
    required ValueChanged<String> onChanged,
    required Widget unitWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: label),
            validator: validator,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        Padding(padding: const EdgeInsets.only(top: 8), child: unitWidget),
      ],
    );
  }
}

class _LiveHomaCard extends StatelessWidget {
  const _LiveHomaCard({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(AppRadii.bigCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live HOMA-IR',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppColors.secondaryFixed),
                ),
                const SizedBox(height: 4),
                Text(
                  value?.toStringAsFixed(2) ?? 'Enter both fasting values',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: AppColors.onPrimary),
                ),
              ],
            ),
          ),
          const Icon(Icons.calculate_outlined, color: AppColors.onPrimary),
        ],
      ),
    );
  }
}
