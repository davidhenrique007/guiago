# ADR-013 — Editar/apagar tarefas com alarmes e pedido de permissões (Fase 8)

## Contexto
A Fase 8 passa a permitir editar e apagar tarefas pela UI. Cada tarefa tem
ocorrências, alarmes agendados no sistema, eventos, registos de alarme e
pontuação que referenciam essas ocorrências. As chaves estrangeiras do Drift
não são impostas (sem `PRAGMA foreign_keys`), por isso apagar linhas deixaria
histórico órfão. Além disso nunca se pedia nenhuma permissão ao utilizador.

## Decisão
1. **Apagar = arquivar.** `TaskEngine.removeTask` arquiva a tarefa, cancela as
   ocorrências ainda vivas (`scheduled`/`snoozed`, respeitando a máquina de
   estados do ADR-005) e cancela os alarmes. O histórico (Progresso, eventos,
   pontuação) mantém-se. `deleteTask` físico fica sem uso na UI.
2. **Editar** (`TaskEngine.editTask`) atualiza a tarefa e, se a hora mudou,
   reagenda a ocorrência pendente e o alarme. Só se pode mudar a hora enquanto
   a ocorrência está `scheduled`.
3. **Início só lê e age**: Concluir/Adiar passam por `triggerOccurrence` antes
   (a máquina não permite `scheduled → completed`). Adiar só aparece quando a
   tarefa já é devida.
4. **Settings**: `SettingsController.saveChange` grava primeiro e só publica o
   estado se a gravação teve sucesso. (Não se chama `update`: colide com
   `AsyncNotifier.update` do Riverpod.)
5. **Permissões** pedidas ao criar a **primeira tarefa** (momento em que
   interessam), por `AlarmPermissionPrompter`: uma vez por execução da app,
   só se faltar algo e só se as notificações estiverem ativas em Perfil. Uma
   recusa nunca bloqueia a criação; o aviso do Início continua a explicar e a
   levar às definições. Interface própria (`AlarmPermissionRequester`), como o
   `AlarmPermissionChecker`, para não mexer em `AlarmNotifier` e nos fakes.
6. **TTS**: o `AlarmRingController` só fala se `ttsEnabled` estiver ligado
   (se as definições não puderem ser lidas, fala).

## Consequências
- Tarefas apagadas deixam de aparecer nas listas mas contam no histórico.
- `notificationsEnabled` e a janela do dia continuam a ser só preferências
  guardadas: ainda não alteram o agendador (pós-MVP).
- O teste de reinício/alarme em telemóvel real é manual: ver
  `docs/QA_FASE8_CHECKLIST.md`.
