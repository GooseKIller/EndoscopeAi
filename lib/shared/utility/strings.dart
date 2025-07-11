// ====================================================
//  Файл содержит фунции для работы со строками
// ====================================================

// Форматировние времени в виде mm:ss или hh:mm:ss
String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));

  return duration.inHours > 0
      ? '$hours:$minutes:$seconds'
      : '$minutes:$seconds';
}

// Форматировние даты в виде yyyy-mm-dd-hh-mm
String formatDateTillMinDash(DateTime date) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String fourDigits(int n) => n.toString().padLeft(4, '0');

  String y = fourDigits(date.year);
  String m = twoDigits(date.month);
  String d = twoDigits(date.day);
  String h = twoDigits(date.hour);
  String min = twoDigits(date.minute);

  return "$y-$m-$d-$h-$min";
}
