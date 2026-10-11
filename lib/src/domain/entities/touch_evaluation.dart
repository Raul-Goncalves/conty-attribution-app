import 'attribution_touch.dart';

class TouchEvaluation {
  final AttributionTouch touch;
  final bool won;
  final String reason;

  const TouchEvaluation({
    required this.touch,
    required this.won,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
    'clickId': touch.clickId,
    'source': touch.source,
    'type': touch.type.name,
    'clickedAt': touch.clickedAt.toIso8601String(),
    'won': won,
    'reason': reason,
  };
}