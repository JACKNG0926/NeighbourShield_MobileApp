import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A country with its dial code and the allowed length of the NATIONAL number
/// (digits after the country code, without the leading trunk "0").
class PhoneCountry {
  const PhoneCountry(this.flag, this.name, this.dialCode, this.minDigits, this.maxDigits);
  final String flag;
  final String name;
  final String dialCode; // e.g. '+60'
  final int minDigits;
  final int maxDigits;

  String get label => '$flag $dialCode';
  String get lengthHint =>
      minDigits == maxDigits ? '$minDigits digits' : '$minDigits-$maxDigits digits';
}

const List<PhoneCountry> kPhoneCountries = [
  PhoneCountry('🇲🇾', 'Malaysia', '+60', 9, 10),
  PhoneCountry('🇸🇬', 'Singapore', '+65', 8, 8),
  PhoneCountry('🇮🇩', 'Indonesia', '+62', 9, 12),
  PhoneCountry('🇹🇭', 'Thailand', '+66', 9, 9),
  PhoneCountry('🇧🇳', 'Brunei', '+673', 7, 7),
  PhoneCountry('🇵🇭', 'Philippines', '+63', 10, 10),
  PhoneCountry('🇻🇳', 'Vietnam', '+84', 9, 10),
  PhoneCountry('🇨🇳', 'China', '+86', 11, 11),
  PhoneCountry('🇮🇳', 'India', '+91', 10, 10),
  PhoneCountry('🇧🇩', 'Bangladesh', '+880', 10, 10),
  PhoneCountry('🇵🇰', 'Pakistan', '+92', 10, 10),
  PhoneCountry('🇯🇵', 'Japan', '+81', 10, 10),
  PhoneCountry('🇰🇷', 'South Korea', '+82', 9, 10),
  PhoneCountry('🇦🇺', 'Australia', '+61', 9, 9),
  PhoneCountry('🇬🇧', 'United Kingdom', '+44', 10, 10),
  PhoneCountry('🇺🇸', 'USA / Canada', '+1', 10, 10),
  PhoneCountry('🌐', 'Other', '+', 6, 12),
];

/// Country-code dropdown + number box.
///
/// [controller] always holds the FULL international number (e.g. +60123456789),
/// so existing code that reads `controller.text` keeps working. Numbers saved
/// earlier in local format ("0123456789") are read as Malaysian.
class PhoneInputField extends StatefulWidget {
  const PhoneInputField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late PhoneCountry _country;
  final _national = TextEditingController();

  @override
  void initState() {
    super.initState();
    _country = kPhoneCountries.first;
    _parseExisting(widget.controller.text.trim());
  }

  void _parseExisting(String raw) {
    if (raw.isEmpty) return;
    if (raw.startsWith('+')) {
      final sorted = [...kPhoneCountries]
        ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
      for (final c in sorted) {
        if (c.dialCode != '+' && raw.startsWith(c.dialCode)) {
          _country = c;
          _national.text = raw.substring(c.dialCode.length);
          return;
        }
      }
      _country = kPhoneCountries.last;
      _national.text = raw.substring(1);
      return;
    }
    // Legacy local format, assume Malaysia.
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('60')) digits = digits.substring(2);
    _national.text = digits.replaceFirst(RegExp(r'^0+'), '');
  }

  void _sync() {
    var digits = _national.text.replaceAll(RegExp(r'\D'), '');
    digits = digits.replaceFirst(RegExp(r'^0+'), ''); // drop trunk zero
    widget.controller.text =
        digits.isEmpty ? '' : '${_country.dialCode == '+' ? '+' : _country.dialCode}$digits';
  }

  String? _validate(String? _) {
    final digits = _national.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) return 'Phone number is required';
    if (digits.length < _country.minDigits || digits.length > _country.maxDigits) {
      return '${_country.name} numbers have ${_country.lengthHint} (without the leading 0)';
    }
    return null;
  }

  @override
  void dispose() {
    _national.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: DropdownButtonFormField<PhoneCountry>(
            value: _country,
            isExpanded: true,
            decoration: const InputDecoration(),
            selectedItemBuilder: (_) =>
                kPhoneCountries.map((c) => Text(c.label, overflow: TextOverflow.ellipsis)).toList(),
            items: kPhoneCountries
                .map((c) => DropdownMenuItem(value: c, child: Text('${c.flag} ${c.name} ${c.dialCode}')))
                .toList(),
            onChanged: (c) {
              if (c == null) return;
              setState(() => _country = c);
              _sync();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _national,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 \-]')),
              LengthLimitingTextInputFormatter(16),
            ],
            decoration: InputDecoration(
              hintText: _country.name == 'Malaysia' ? 'e.g. 123456789' : _country.lengthHint,
              helperText: '${_country.lengthHint}, no leading 0',
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            onChanged: (_) => _sync(),
            validator: _validate,
          ),
        ),
      ],
    );
  }
}
