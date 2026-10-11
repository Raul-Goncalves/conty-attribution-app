enum TouchType { referral, campaign }

class AttributionTouch {
  final String clickId;
  final TouchType type;
  final String source;
  final String? campaign;
  final String? referrerId;
  final DateTime clickedAt;

  const AttributionTouch({
    required this.clickId,
    required this.type,
    required this.source,
    this.campaign,
    this.referrerId,
    required this.clickedAt,
  });

  /// Reconhece os parâmetros do deep link / query string
  factory AttributionTouch.fromUri(Uri uri, {required DateTime clickedAt}) {
    final clickId = uri.queryParameters['click_id'] ?? uri.queryParameters['id'] ?? 'c_${clickedAt.millisecondsSinceEpoch}';
    final ref = uri.queryParameters['ref'];

    if (ref != null && ref.isNotEmpty) {
      return AttributionTouch(
        clickId: clickId,
        type: TouchType.referral,
        source: uri.queryParameters['channel'] ?? 'referral',
        referrerId: ref,
        clickedAt: clickedAt,
      );
    }

    return AttributionTouch(
      clickId: clickId,
      type: TouchType.campaign,
      source: uri.queryParameters['utm_source'] ?? 'direct',
      campaign: uri.queryParameters['utm_campaign'],
      clickedAt: clickedAt,
    );
  }
}