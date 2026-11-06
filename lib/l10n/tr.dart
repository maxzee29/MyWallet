import 'app_language.dart';
import 'en_strings.dart';

part 'tr_templates.dart';

/// Menerjemahkan teks Indonesia ke bahasa aktif.
///
/// Teks aplikasi ditulis dalam bahasa Indonesia. Saat bahasa Inggris dipilih,
/// teks dicari di kamus [kEnglishStrings], lalu di pola teks dinamis
/// ([_templates]), lalu tanggal dan jam diubah formatnya. Teks yang tidak
/// dikenal, misalnya catatan atau nama buatan pengguna, tetap apa adanya.
String tr(String text) {
  if (AppLocale.current == AppLanguage.indonesian) return text;
  return translateToEnglish(text);
}

final Map<String, String> _cache = <String, String>{};

/// Menerjemahkan [text] ke bahasa Inggris tanpa melihat bahasa aktif.
String translateToEnglish(String text) {
  if (text.isEmpty) return text;

  final cached = _cache[text];
  if (cached != null) return cached;

  final result = _translate(text);
  if (_cache.length > 3000) _cache.clear();
  _cache[text] = result;
  return result;
}

class _Template {
  const _Template(this.pattern, this.build);

  final RegExp pattern;
  final String Function(Match match) build;
}

String _translate(String text) {
  final direct = kEnglishStrings[text];
  if (direct != null) return direct;

  for (final template in _templates) {
    final match = template.pattern.firstMatch(text);
    if (match != null) return template.build(match);
  }

  // Gabungan beberapa bagian, misalnya "Makanan • Gopay • 12.02".
  for (final separator in const [' • ', ' · ']) {
    if (text.contains(separator)) {
      return text.split(separator).map(translateToEnglish).join(separator);
    }
  }

  return _dates(text);
}

String _g(Match match, int index) => match.group(index) ?? '';

String _t(Match match, int index) => translateToEnglish(_g(match, index));

/// Daftar nama dipisah koma, misalnya "Makanan, Parkir, dan 2 lainnya".
String _labels(String raw) {
  final more = RegExp(r'^(.*), dan (\d+) lainnya$').firstMatch(raw);
  if (more != null) {
    return '${_joinLabels(more.group(1) ?? '')}, and ${more.group(2)} more';
  }
  return _joinLabels(raw);
}

String _joinLabels(String raw) {
  return raw.split(', ').map(translateToEnglish).join(', ');
}

const Map<String, String> _dayNames = {
  'Senin': 'Monday',
  'Selasa': 'Tuesday',
  'Rabu': 'Wednesday',
  'Kamis': 'Thursday',
  'Jumat': 'Friday',
  'Sabtu': 'Saturday',
  'Minggu': 'Sunday',
};

const Map<String, String> _dayShortNames = {
  'Sen': 'Mon',
  'Sel': 'Tue',
  'Rab': 'Wed',
  'Kam': 'Thu',
  'Jum': 'Fri',
  'Sab': 'Sat',
  'Min': 'Sun',
};

const Map<String, String> _monthNames = {
  'Januari': 'January',
  'Februari': 'February',
  'Maret': 'March',
  'April': 'April',
  'Mei': 'May',
  'Juni': 'June',
  'Juli': 'July',
  'Agustus': 'August',
  'September': 'September',
  'Oktober': 'October',
  'November': 'November',
  'Desember': 'December',
};

const Map<String, String> _monthShortNames = {
  'Jan': 'Jan',
  'Feb': 'Feb',
  'Mar': 'Mar',
  'Apr': 'Apr',
  'Mei': 'May',
  'Jun': 'Jun',
  'Jul': 'Jul',
  'Agu': 'Aug',
  'Sep': 'Sep',
  'Okt': 'Oct',
  'Nov': 'Nov',
  'Des': 'Dec',
};

final RegExp _timePattern = RegExp(r'(^|[,•]\s)(\d{2})\.(\d{2})(?=\s|$)');
final RegExp _dayPattern = RegExp(
  r'\b(Senin|Selasa|Rabu|Kamis|Jumat|Sabtu|Minggu)(?=, )',
);
final RegExp _dayShortPattern = RegExp(
  r'^(Sen|Sel|Rab|Kam|Jum|Sab|Min)(?=, \d)',
);
final RegExp _dayMonthPattern = RegExp(
  r'(\d{1,2} )(Januari|Februari|Maret|April|Mei|Juni|Juli|Agustus|September|Oktober|November|Desember)\b',
);
final RegExp _monthYearPattern = RegExp(
  r'\b(Januari|Februari|Maret|April|Mei|Juni|Juli|Agustus|September|Oktober|November|Desember)( \d{4})\b',
);
final RegExp _dayShortMonthPattern = RegExp(
  r'(\d{1,2} )(Jan|Feb|Mar|Apr|Mei|Jun|Jul|Agu|Sep|Okt|Nov|Des)\b',
);

/// Mengubah nama hari, nama bulan, dan format jam Indonesia ke bahasa Inggris.
String _dates(String text) {
  var result = text;
  result = result.replaceAllMapped(
    _timePattern,
    (m) => '${m[1]}${m[2]}:${m[3]}',
  );
  result = result.replaceAllMapped(
    _dayPattern,
    (m) => _dayNames[m[1]] ?? m[0] ?? '',
  );
  result = result.replaceAllMapped(
    _dayShortPattern,
    (m) => _dayShortNames[m[1]] ?? m[0] ?? '',
  );
  result = result.replaceAllMapped(
    _dayMonthPattern,
    (m) => '${m[1]}${_monthNames[m[2]] ?? m[2]}',
  );
  result = result.replaceAllMapped(
    _monthYearPattern,
    (m) => '${_monthNames[m[1]] ?? m[1]}${m[2]}',
  );
  result = result.replaceAllMapped(
    _dayShortMonthPattern,
    (m) => '${m[1]}${_monthShortNames[m[2]] ?? m[2]}',
  );
  return result;
}
