import 'package:flutter/material.dart';

import 'translator.dart';

/// A `Text` that shows the French or Arabic version of its English text.
/// Same options as `Text`, so it can replace it anywhere.
class Tx extends StatelessWidget {
  const Tx(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final code = LangScope.of(context);
    return Text(
      L10n.tr(data, code),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel == null
          ? null
          : L10n.tr(semanticsLabel!, code),
    );
  }
}
