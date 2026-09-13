/// Why the user declined an alarm occurrence (master spec §24: "NÃO
/// VOU" pode solicitar motivo — Sem tempo, Não disponível, Não é
/// mais necessário, Esqueci, Outro).
enum DeclineReason { noTime, notAvailable, noLongerNeeded, forgot, other }

extension DeclineReasonLabel on DeclineReason {
  /// User-facing Portuguese label, exactly as listed in the spec.
  String get label => switch (this) {
        DeclineReason.noTime => 'Sem tempo',
        DeclineReason.notAvailable => 'Não disponível',
        DeclineReason.noLongerNeeded => 'Não é mais necessário',
        DeclineReason.forgot => 'Esqueci',
        DeclineReason.other => 'Outro',
      };
}
