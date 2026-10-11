# Origem do Cadastro no App - Motor de Atribuição e Auditoria

Biblioteca desenvolvida em Dart para identificação, deduplicação e auditoria da origem de cadastros de criadores no aplicativo, cobrindo cenários com deep links, webviews que perdem referer, janelas de validade temporal e resolução determinística de empates.

---

## 🎯 O que olhar primeiro

1. **Motor de Atribuição e Auditoria (`lib/src/domain/services/attribution_engine.dart`):**
   * Avalia todos os toques registrados e devolve o histórico completo com a justificativa de vitória ou desqualificação de cada toque.
   * Cadastros sem toques válidos não geram dados ausentes ou nulos: são explicitamente registrados como `organic` com motivo gravado (`ORGANIC_NO_CLICKS` ou `ORGANIC_ALL_EXPIRED`).
2. **Orquestração da Aplicação (`lib/src/services/app_attribution_service.dart`):**
   * Grava a data/hora da primeira abertura do app (`firstOpenAt`) para delimitar a janela de conversão.
   * Recebe e converte links (deep links / webviews) evitando repetição do mesmo `click_id`.
   * Resolve a atribuição no momento exato em que o cadastro é concluído.
3. **Suíte de Testes Unitários (`test/attribution_test.dart`):**
   * Cobertura de cenários de Last-Touch, desempate com horário idêntico, cliques repetidos, toques após o cadastro e toques fora da janela de expiração.

---

## 🔗 Formatos de Links Suportados

### 1. Link de Campanha (Parâmetros UTM)
```text
https://conty.app/join?utm_source=instagram&utm_campaign=creator_summit&click_id=c_camp_101
```
* **Tipo:** `campaign`
* **Identificador da origem:** `creator_summit`

### 2. Link de Indicação (Convite / Referral)
```text
https://conty.app/join?ref=criador_pedro&channel=whatsapp&click_id=c_ref_202
```
* **Tipo:** `referral`
* **Identificador da origem:** `criador_pedro`

---

## ⚖️ Critérios de Decisão e Desempate

* **Janela de Validade da Origem:** 7 dias a contar do instante da primeira abertura do app (`firstOpenAt`). Cliques anteriores à janela ou após o seu vencimento expiram (`EXPIRED_WINDOW`).
* **Cliques Posteriores ao Cadastro:** Toques ocorridos após o horário do cadastro (`registeredAt`) são desqualificados (`AFTER_REGISTRATION`).
* **Deduplicação de Cliques:** Múltiplos eventos com o mesmo `click_id` não geram origens repetidas.
* **Modelo Vencedor (Mais de um toque):** Modelo de *Último Toque (Last-Touch)* — o clique qualificado mais recente vence (`WON_LAST_TOUCH`).
* **Empate Exato de Horário:**
  * Se dois links possuírem o mesmo timestamp, o link de **indicação direta (`referral`) tem precedência sobre campanha de marketing**, pois reflete um convite de criador.
  * Em caso de empate entre links do mesmo tipo no mesmo instante, o critério de desempate é determinístico por ordem alfabética do `click_id`.

---

## 📡 Exemplo de Saída da Avaliação (Auditoria Completa)

Ao concluir o cadastro, a resposta documenta o veredito final e o motivo de cada toque considerado:

```json
{
  "origin": "criador_pedro",
  "originType": "referral",
  "explanation": "Atribuição atribuída a criador_pedro com base em último toque.",
  "evaluatedTouches": [
    {
      "clickId": "c_ref_202",
      "source": "whatsapp",
      "type": "referral",
      "clickedAt": "2026-10-02T16:00:00.000Z",
      "won": true,
      "reason": "WON_LAST_TOUCH: Venceu pelo modelo de último toque qualificado."
    },
    {
      "clickId": "c_camp_101",
      "source": "instagram",
      "type": "campaign",
      "clickedAt": "2026-10-01T14:00:00.000Z",
      "won": false,
      "reason": "SUPERSEDED_BY_LAST_TOUCH: Substituído por um toque mais recente."
    },
    {
      "clickId": "c_late_999",
      "source": "tiktok",
      "type": "campaign",
      "clickedAt": "2026-10-04T10:00:00.000Z",
      "won": false,
      "reason": "AFTER_REGISTRATION: Clique efetuado após a criação da conta."
    }
  ]
}
```

---

## 🚀 Como Executar

### Pré-requisitos
* Dart SDK `^3.0.0` (ou Flutter SDK instalado).

### Instalação de dependências
```bash
dart pub get
```

### Execução dos testes
```bash
dart test
```

---

## 🧭 O que ficou de fora e Decisões que tomaria diferente com mais tempo

* **Persistência Segura do Dispositivo:** Para fins de demonstração da biblioteca, os toques e o primeiro acesso são mantidos em memória. Em ambiente produtivo, seriam gravados via `flutter_secure_storage` ou `shared_preferences` para sobreviver a reinicializações do app antes do cadastro.
* **Fingerprinting Heurístico:** Webviews sem envio de referer se beneficiariam de heurísticas temporais baseadas em IP e User-Agent caso o `click_id` não estivesse presente na URL.
* **Envio para Backend:** Implementaria uma camada de rede para despachar o payload de auditoria para a API da Conty assim que o cadastro fosse concluído com sucesso.

---

## 🤖 Declaração sobre Uso de IA

* **Uso de IA:** A Inteligência Artificial foi utilizada exclusivamente para auxílio no levantamento e estruturação dos requisitos do problema (definição dos cenários de borda para deep links e empates de horário).
