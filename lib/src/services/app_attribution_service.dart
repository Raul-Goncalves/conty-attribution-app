import '../../core/time/clock.dart';
import '../domain/entities/attribution_result.dart';
import '../domain/entities/attribution_touch.dart';
import '../domain/services/attribution_engine.dart';

class AppAttributionService {
  final AttributionEngine engine;
  final Clock clock;

  DateTime? _firstOpenAt;
  final List<AttributionTouch> _recordedTouches = [];

  AppAttributionService({
    required this.engine,
    required this.clock,
  });

  /// Data e hora da primeira abertura da aplicação.
  DateTime? get firstOpenAt => _firstOpenAt;

  /// Lista de toques armazenados em memória.
  List<AttributionTouch> get recordedTouches =>
      List.unmodifiable(_recordedTouches);

  /// Chamado na inicialização da aplicação: grava a primeira abertura se ainda não existir.
  void recordAppOpen() {
    _firstOpenAt ??= clock.now();
  }

  /// Regista um toque a partir da URI/link acedido (webview ou deep link externo).
  void recordLinkClick(Uri linkUri) {
    recordAppOpen(); // Garante o registo de abertura caso o link abra o app diretamente

    final touch = AttributionTouch.fromUri(
      linkUri,
      clickedAt: clock.now(),
    );

    // Evita duplicar cliques com o mesmo identificador na recolha bruta
    final alreadyExists = _recordedTouches.any((t) => t.clickId == touch.clickId);
    if (!alreadyExists) {
      _recordedTouches.add(touch);
    }
  }

  /// Processa e consome a atribuição no instante em que o utilizador conclui o cadastro.
  AttributionResult attributeRegistration({DateTime? registeredAt}) {
    recordAppOpen();

    final registrationInstant = registeredAt ?? clock.now();

    return engine.evaluate(
      firstOpenAt: _firstOpenAt!,
      registeredAt: registrationInstant,
      rawTouches: _recordedTouches,
    );
  }
}