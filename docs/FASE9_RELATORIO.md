# Fase 9 — Relatório de fecho

## 1. O que já existia
Fases 0–8: tarefas e recorrência, alarmes locais, recuperação após reinício,
Calendário (Dia), Progresso, Perfil básico, permissões (Lote F da Fase 8).

## 2. O que foi alterado
- Calendário: seletor Dia | Mês | Ano; Dia com a janela do dia.
- Perfil: reorganizado em NOTIFICAÇÕES, APARÊNCIA, IDIOMA e OUTRAS.
- `AppColors` deixou de ser `const` (paleta ativa); ver ADR-014.
- Textos do Perfil, Calendário, navegação e saudação passaram para `context.l10n`.
- Notificações: um canal Android por combinação som + vibração.

## 3. O que foi adicionado
- Lote E: editar nome/objetivo, snooze/tolerância padrão, interruptores.
- Lote F: pedido de permissões depois da primeira tarefa; TTS respeita a opção.
- Lote G: vistas Mês melhorada e Ano (12 meses, navegação), criar tarefa
  para o dia escolhido (até 5 anos).
- Lote H: sons GuiaGo (3 tons gerados), som do sistema, sem som, pré-escuta,
  vibração; mudar re-arma os alarmes.
- Lote I: Início/Fim do dia ligados (aviso no formulário, marca no Calendário).
- Lote J: tema Claro/Escuro/Sistema, aplicado na hora.
- Lote K: Português/Inglês (ADR-015).
- Lote P: foto de perfil (câmara/galeria/remover).

## 4. Ficheiros
Cerca de 90 novos e 130 alterados em oito lotes (zips `guiago_lote_*`).
Principais pastas: `lib/l10n`, `lib/app/theme`, `lib/features/profile`,
`lib/features/calendar`, `lib/features/scheduler`, `docs/adr`.

## 5. Testes
`flutter analyze` sem problemas e `flutter test` totalmente verde no último
lote entregue (cerca de 420 testes). Novos: calendário Dia/Mês/Ano, janela do
dia, sons e canais, migrações v5→v9, tema, idioma, foto, permissões.

## 6. Problemas encontrados
- Código gerado desatualizado depois de mudar `Settings`/Drift: obriga a
  `dart run build_runner build -d`.
- `google_fonts` e delegates de localização exigem cuidado nos testes.
- Um ficheiro de localização antigo voltou a ser enviado num zip e reintroduziu
  o carregamento assíncrono (corrigido com `SynchronousFuture`).
- Limitação: Idioma ainda parcial (Tarefas, alarme, Progresso, Insights,
  onboarding, notificações, TTS).
- Limitação: os 3 sons são tons simples, a trocar pelos preferidos.

## 7. O que precisa de telemóvel físico
Tudo o que está em `docs/QA_FASE8_CHECKLIST.md` §7, §8, §10 e §11: alarme com
a app fechada e com o ecrã bloqueado, reinício, sons reais, vibração, snooze,
Não incomodar, poupança de bateria, câmara e galeria, e aspeto do tema claro
em todos os ecrãs. Os testes automáticos não cobrem estes pontos.
