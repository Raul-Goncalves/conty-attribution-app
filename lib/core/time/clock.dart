abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

class FixedClock implements Clock {
  final DateTime instant;

  FixedClock(this.instant);

  @override
  DateTime now() => instant;
}