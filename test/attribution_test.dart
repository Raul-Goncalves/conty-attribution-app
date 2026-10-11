import 'package:test/test.dart';
import '../lib/src/domain/entities/attribution_touch.dart';
import '../lib/src/domain/services/attribution_engine.dart';

void main() {
  group('Atribuição de Origem do Cadastro no App', () {
    late AttributionEngine engine;
    final firstOpen = DateTime.utc(2026, 10, 1, 10, 0, 0);
    final registration = DateTime.utc(2026, 10, 3, 15, 0, 0);

    setUp(() {
      engine = AttributionEngine(windowDuration: const Duration(days: 7));
    });

    test('Cadastro sem cliques é marcado explicitamente como orgânico', () {
      final result = engine.evaluate(
        firstOpenAt: firstOpen,
        registeredAt: registration,
        rawTouches: [],
      );

      expect(result.origin, equals('organic'));
      expect(result.originType, equals('organic'));
      expect(result.explanation, contains('ORGANIC_NO_CLICKS'));
      expect(result.touchHistory.isEmpty, isTrue);
    });

    test('O mesmo clique repetido não cria duas origens', () {
      final touch = AttributionTouch(
        clickId: 'click_rep_1',
        type: TouchType.campaign,
        source: 'instagram',
        campaign: 'creator_boost',
        clickedAt: DateTime.utc(2026, 10, 2, 12, 0, 0),
      );

      final result = engine.evaluate(
        firstOpenAt: firstOpen,
        registeredAt: registration,
        rawTouches: [touch, touch], // Clique repetido duplicado
      );

      expect(result.touchHistory.length, equals(1));
      expect(result.origin, equals('creator_boost'));
    });

    test('Dois links diferentes: o mais recente vence (Last-Touch)', () {
      final touch1 = AttributionTouch(
        clickId: 'c1',
        type: TouchType.campaign,
        source: 'youtube',
        campaign: 'video_review',
        clickedAt: DateTime.utc(2026, 10, 1, 14, 0, 0),
      );
      final touch2 = AttributionTouch(
        clickId: 'c2',
        type: TouchType.referral,
        source: 'whatsapp',
        referrerId: 'criador_carlos',
        clickedAt: DateTime.utc(2026, 10, 2, 16, 0, 0),
      );

      final result = engine.evaluate(
        firstOpenAt: firstOpen,
        registeredAt: registration,
        rawTouches: [touch1, touch2],
      );

      expect(result.origin, equals('criador_carlos'));
      final evaluated1 = result.touchHistory.firstWhere((t) => t.touch.clickId == 'c1');
      expect(evaluated1.won, isFalse);
      expect(evaluated1.reason, contains('SUPERSEDED_BY_LAST_TOUCH'));
    });

    test('Empate de horário exato: indicação vence campanha', () {
      final mesmoHorario = DateTime.utc(2026, 10, 2, 12, 0, 0);

      final campaignTouch = AttributionTouch(
        clickId: 'c_camp',
        type: TouchType.campaign,
        source: 'meta_ads',
        campaign: 'campanha_outono',
        clickedAt: mesmoHorario,
      );
      final referralTouch = AttributionTouch(
        clickId: 'c_ref',
        type: TouchType.referral,
        source: 'telegram',
        referrerId: 'amigo_indicador',
        clickedAt: mesmoHorario,
      );

      final result = engine.evaluate(
        firstOpenAt: firstOpen,
        registeredAt: registration,
        rawTouches: [campaignTouch, referralTouch],
      );

      expect(result.origin, equals('amigo_indicador'));
      final campEval = result.touchHistory.firstWhere((t) => t.touch.clickId == 'c_camp');
      expect(campEval.won, isFalse);
      expect(campEval.reason, contains('LOST_TIEBREAKER'));
    });

    test('Toque aberto depois do cadastro é descartado e não vence', () {
      final touchAfter = AttributionTouch(
        clickId: 'c_late',
        type: TouchType.campaign,
        source: 'tiktok',
        campaign: 'viral_post',
        clickedAt: DateTime.utc(2026, 10, 4, 10, 0, 0), // Após registration
      );

      final result = engine.evaluate(
        firstOpenAt: firstOpen,
        registeredAt: registration,
        rawTouches: [touchAfter],
      );

      expect(result.origin, equals('organic'));
      final eval = result.touchHistory.first;
      expect(eval.won, isFalse);
      expect(eval.reason, contains('AFTER_REGISTRATION'));
    });

    test('Toque fora da janela de validade da primeira abertura expira', () {
      final touchExpired = AttributionTouch(
        clickId: 'c_old',
        type: TouchType.campaign,
        source: 'google',
        campaign: 'search_ad',
        clickedAt: DateTime.utc(2026, 10, 10, 11, 0, 0), // Mais de 7 dias após firstOpen
      );

      final result = engine.evaluate(
        firstOpenAt: firstOpen,
        registeredAt: DateTime.utc(2026, 10, 11, 10, 0, 0),
        rawTouches: [touchExpired],
      );

      expect(result.origin, equals('organic'));
      final eval = result.touchHistory.first;
      expect(eval.won, isFalse);
      expect(eval.reason, contains('EXPIRED_WINDOW'));
    });
  });
}