import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/lab_record.dart';
import '../providers/lab_records_provider.dart';
import '../providers/nav_provider.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';
import 'result_screen.dart';

/// Check your results (after a scan) or type values in by hand.
/// OCR suggests, the user always confirms before anything is saved.
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

  late GlucoseUnit _glucoseUnit;
  late InsulinUnit _insulinUnit;
  DateTime _date = DateTime.now();
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
    _glucoseUnit = widget.initialGlucoseUnit ?? GlucoseUnit.gl;
    _insulinUnit = widget.initialInsulinUnit ?? InsulinUnit.uiuml;
  }

  @override
  void dispose() {
    _glucoseCtrl.dispose();
    _insulinCtrl.dispose();
    _hba1cCtrl.dispose();
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

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _confirm() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final glucoseRaw = _parse(_glucoseCtrl);
    final insulinRaw = _parse(_insulinCtrl);
    final hba1cRaw = _parse(_hba1cCtrl);

    if (glucoseRaw == null && insulinRaw == null && hba1cRaw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one value to continue.')),
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
      updatedAt: DateTime.now(),
    );

    final navigator = Navigator.of(context);

    // With both glucose and insulin there is a HOMA-IR to show: the result
    // screen saves it when the person chooses. Otherwise save straight away.
    if (record.homaIr != null) {
      navigator.push(
        MaterialPageRoute(builder: (_) => ResultScreen(record: record)),
      );
      return;
    }

    final labs = context.read<LabRecordsProvider>();
    final nav = context.read<NavProvider>();
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

  String? _validateOptionalPositive(String? input, String label) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return null;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return 'Enter a positive $label value.';
    }
    return null;
  }

  Widget _tag(bool found) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: found ? DS.green : DS.amber,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        found ? 'From photo' : 'Not found',
        style: DS.text(
          size: 12.5,
          weight: FontWeight.w700,
          color: found ? DS.greenText : DS.amberText,
        ),
      ),
    ],
  );

  Widget _card({
    required String label,
    required Widget child,
    Widget? tag,
    Widget? labelSuffix,
  }) {
    return DsCard(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: label,
                        style: DS.text(size: 15.5, weight: FontWeight.w700),
                      ),
                      if (labelSuffix != null) WidgetSpan(child: labelSuffix),
                    ],
                  ),
                ),
              ),
              ?tag,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _valueRow({
    required TextEditingController controller,
    required String semanticLabel,
    required FormFieldValidator<String> validator,
    required Widget units,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: DS.text(
              size: 26,
              weight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            decoration: dsFieldDecoration(vertical: 15).copyWith(
              hintText: semanticLabel,
              hintStyle: DS.text(
                size: 14,
                weight: FontWeight.w600,
                color: DS.iconMuted,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: units),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scan = widget.fromScan;
    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const DsBackButton(),
                          if (scan)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: DS.skyTint,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Step 2 of 2',
                                style: DS.text(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  color: DS.navy,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      scan
                          ? const DsTitle('Check your', 'results', size: 36)
                          : const DsTitle('Add', 'result', size: 36),
                      const SizedBox(height: 12),
                      Text(
                        scan
                            ? 'Compare with your paper report.'
                            : 'Type the values from your lab report.',
                        style: DS.text(
                          size: 15.5,
                          weight: FontWeight.w500,
                          color: DS.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _card(
                        label: 'Fasting glucose',
                        tag: scan ? _tag(widget.initialGlucose != null) : null,
                        child: _valueRow(
                          controller: _glucoseCtrl,
                          semanticLabel: 'Value',
                          validator: (v) =>
                              _validateOptionalPositive(v, 'glucose'),
                          units: DsSegmented<GlucoseUnit>(
                            options: const {
                              GlucoseUnit.gl: 'g/L',
                              GlucoseUnit.mgdl: 'mg/dL',
                              GlucoseUnit.mmoll: 'mmol/L',
                            },
                            value: _glucoseUnit,
                            height: 50,
                            onChanged: (u) => setState(() => _glucoseUnit = u),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _card(
                        label: 'Fasting insulin',
                        tag: scan ? _tag(widget.initialInsulin != null) : null,
                        child: _valueRow(
                          controller: _insulinCtrl,
                          semanticLabel: 'Value',
                          validator: (v) =>
                              _validateOptionalPositive(v, 'insulin'),
                          units: DsSegmented<InsulinUnit>(
                            options: const {
                              InsulinUnit.uiuml: 'uIU/mL',
                              InsulinUnit.pmoll: 'pmol/L',
                            },
                            value: _insulinUnit,
                            height: 50,
                            onChanged: (u) => setState(() => _insulinUnit = u),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _card(
                        label: 'HbA1c ',
                        labelSuffix: Text(
                          '(optional)',
                          style: DS.text(
                            size: 15.5,
                            weight: FontWeight.w500,
                            color: DS.muted,
                          ),
                        ),
                        tag: scan ? _tag(widget.initialHba1c != null) : null,
                        child: TextFormField(
                          controller: _hba1cCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: DS.text(size: 17, weight: FontWeight.w600),
                          decoration: dsFieldDecoration(
                            hint: 'Add if you have it',
                            vertical: 18,
                            suffix: Padding(
                              padding: const EdgeInsets.only(right: 18),
                              child: Center(
                                widthFactor: 1,
                                child: Text(
                                  '%',
                                  style: DS.text(
                                    size: 17,
                                    weight: FontWeight.w700,
                                    color: DS.muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          validator: (value) {
                            final error = _validateOptionalPositive(
                              value,
                              'HbA1c',
                            );
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
                      ),
                      const SizedBox(height: 14),
                      _card(
                        label: 'Test date',
                        child: Semantics(
                          button: true,
                          label: 'Test date',
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              height: 58,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: DS.field,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 22,
                                    color: DS.navy,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    DateFormat.yMMMd().format(_date),
                                    style: DS.text(
                                      size: 17,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      DsPrimaryButton(
                        label: 'Confirm',
                        loading: _saving,
                        onPressed: _confirm,
                      ),
                      if (scan) ...[
                        const SizedBox(height: 4),
                        DsTextAction(
                          'Retake photo',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ],
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
