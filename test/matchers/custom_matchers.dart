import 'package:matcher/matcher.dart';

/// Matches any Duration
Matcher anyDuration() => isA<Duration>();

/// Matches Duration with specific seconds
Matcher durationWithSeconds(int seconds) => isA<Duration>().having(
      (d) => d.inSeconds,
      'seconds',
      seconds,
    );
