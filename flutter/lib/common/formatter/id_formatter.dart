import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IDTextEditingController extends TextEditingController {
  IDTextEditingController({String? text, this.usePersianDigits = false})
      : super(text: text);

  final bool usePersianDigits;

  String get id => trimID(value.text);

  set id(String newID) => text = formatID(newID);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final span = super.buildTextSpan(
        context: context, style: style, withComposing: withComposing);
    // Localize only the rendered text; the controller value stays ASCII.
    return usePersianDigits ? _localizeDigitsInSpan(span) : span;
  }
}

TextSpan _localizeDigitsInSpan(TextSpan span) {
  return TextSpan(
    text: _toPersianDigits(span.text ?? ''),
    style: span.style,
    children: span.children?.map((child) {
      return child is TextSpan ? _localizeDigitsInSpan(child) : child;
    }).toList(),
  );
}

class IDTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    } else if (newValue.text.compareTo(oldValue.text) == 0) {
      return newValue;
    } else {
      int selectionIndexFromTheRight =
          newValue.text.length - newValue.selection.extentOffset;
      String newID = formatID(newValue.text);
      return TextEditingValue(
        text: newID,
        selection: TextSelection.collapsed(
          offset: newID.length - selectionIndexFromTheRight,
        ),
        // https://github.com/flutter/flutter/issues/78066#issuecomment-797869906
        composing: newValue.composing,
      );
    }
  }
}

// Pasted IDs can carry a trailing newline or tab (e.g. copied from a
// spreadsheet cell) or non-breaking spaces, so strip all whitespace, not only
// plain spaces.
final _whitespace = RegExp(r'\s');

String formatID(String id) {
  String id2 = _toAsciiDigits(id.replaceAll(_whitespace, ''));
  String suffix = '';
  if (id2.endsWith(r'\r') || id2.endsWith(r'/r')) {
    suffix = id2.substring(id2.length - 2, id2.length);
    id2 = id2.substring(0, id2.length - 2);
  }
  if (int.tryParse(id2) == null) return _toAsciiDigits(id);
  String newID = '';
  if (id2.length <= 3) {
    newID = id2;
  } else {
    var n = id2.length;
    var a = n % 3 != 0 ? n % 3 : 3;
    newID = id2.substring(0, a);
    for (var i = a; i < n; i += 3) {
      newID += " ${id2.substring(i, i + 3)}";
    }
  }
  return newID + suffix;
}

String formatIDForDisplay(String id, {bool usePersianDigits = false}) {
  final formatted = formatID(id);
  return usePersianDigits ? _toPersianDigits(formatted) : formatted;
}

String trimID(String id) {
  return _toAsciiDigits(id.replaceAll(_whitespace, ''));
}

String _toAsciiDigits(String value) => value.replaceAllMapped(
      RegExp(r'[\u0660-\u0669\u06F0-\u06F9]'),
      (match) {
        final code = match[0]!.codeUnitAt(0);
        final zero = code >= 0x06F0 ? 0x06F0 : 0x0660;
        return String.fromCharCode(0x30 + code - zero);
      },
    );

String _toPersianDigits(String value) => value.replaceAllMapped(
      RegExp(r'[0-9]'),
      (match) => String.fromCharCode(match[0]!.codeUnitAt(0) + 0x06F0 - 0x30),
    );
