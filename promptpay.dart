
const myPromptPayId = '0935453038';

/// QR แบบไม่ระบุยอด (คนสแกนกรอกยอดเอง)
String get myQr => promptPayPayload(myPromptPayId);

/// QR แบบระบุยอด เช่น myQrWithAmount(150) -> แอปธนาคารกรอก 150.00 ให้เอง
String myQrWithAmount(double amount) =>
    promptPayPayload(myPromptPayId, amount: amount);

String promptPayPayload(String id, {double? amount}) {
  final digits = id.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length != 10 && digits.length != 13) {
    throw ArgumentError('ต้องเป็นเบอร์โทร 10 หลัก หรือเลข 13 หลัก');
  }
  final isPhone = digits.length == 10;
  final target = isPhone ? '0066${digits.substring(1)}' : digits;

  final data = _tlv('00', '01') +
      _tlv('01', amount == null ? '11' : '12') +
      _tlv('29', _tlv('00', 'A000000677010111') + _tlv(isPhone ? '01' : '02', target)) +
      _tlv('53', '764') +
      (amount == null ? '' : _tlv('54', amount.toStringAsFixed(2))) +
      _tlv('58', 'TH') +
      '6304';

  return data + _crc16(data).toRadixString(16).toUpperCase().padLeft(4, '0');
}

String _tlv(String tag, String value) =>
    '$tag${value.length.toString().padLeft(2, '0')}$value';

int _crc16(String text) {
  var crc = 0xFFFF;
  for (final byte in text.codeUnits) {
    crc ^= byte << 8;
    for (var i = 0; i < 8; i++) {
      crc = ((crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1) & 0xFFFF;
    }
  }
  return crc;
}