# ADR-015 — Idioma Português / Inglês

Estado: aceite (Fase 9, Lote K)

## Contexto
O perfil passa a ter "Idioma" (Português / English). Todos os textos estavam
escritos à mão nos widgets, em português.

## Decisão
- **Localização escrita à mão**, sem gerador: `lib/l10n/app_localizations.dart`
  (classe abstrata, uma função/getter por texto) com `AppLocalizationsPt` e
  `AppLocalizationsEn`. É o mecanismo "mínimo" documentado pelo Flutter
  (`LocalizationsDelegate`). Motivo: não depende de `flutter gen-l10n`, de
  `l10n.yaml` nem de ficheiros gerados fora do Git (o projeto não versiona
  código gerado), e o compilador verifica que os dois idiomas têm todos os
  textos (se faltar um, não compila).
- `flutter_localizations` fornece os textos do Material/Cupertino
  (seletor de horas, etc.). `intl` não foi adicionado: não é preciso para dois
  idiomas e evita conflito de versões com o SDK.
- Os widgets usam `context.l10n`. Sem `Localizations` instalado (um teste de
  widget com `MaterialApp` simples) cai para Português — por isso os testes
  antigos continuam a passar sem alteração.
- A escolha vive em `Settings.languageCode` (`pt`/`en`, valor desconhecido =
  `pt`), coluna `language_code`, base de dados v8. `languageProvider` →
  `MaterialApp.locale`. A mudança é imediata.
- Datas: `AppLocalizations.longDate/weekdayName/weekdayShort/monthName`
  (PT: "Sexta-feira, 14 de agosto"; EN: "Friday, August 14").
  `PtDateLabels` continua para os ecrãs ainda não migrados.
- Os nomes dos idiomas aparecem sempre na própria língua.

## Âmbito do Lote K
Migrado: Perfil (todos os ecrãs e folhas), barra de navegação, Calendário
(Dia/Mês/Ano, detalhe da tarefa), saudação do Início.
**Ainda em português** (próximo lote, mesmo mecanismo): Tarefas e formulário,
ecrã do alarme, Progresso, Insights, onboarding, mensagens do Início, TTS e
texto das notificações.

## Consequências
- Adicionar um texto = uma entrada na classe abstrata + PT + EN.
- Adicionar um idioma = nova subclasse + entrada em `AppLanguage`.
