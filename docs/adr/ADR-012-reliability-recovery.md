# ADR-012 — Reliability + Offline Recovery (Fase 7)

## Contexto
Um alarme pode perder-se sem que a app saiba: o telemóvel foi reiniciado,
a app foi forçada a parar, uma permissão foi revogada, ou uma chamada de
agendamento falhou (o `TaskEngine` ignora essa falha de propósito, ADR-006).
O `_missTimer` do `AlarmRingController` só existe enquanto o ecrã do alarme
está aberto, por isso uma ocorrência que ninguém abriu ficava `scheduled`
para sempre.

## Decisão
1. **`RecoveryService`** (`features/recovery`) corre quando a app arranca e
   sempre que volta ao primeiro plano.
   - Fase 1 (catch-up): ocorrências com a tolerância já fechada passam a
     `missed`, sempre pelo `TaskEngine`. A máquina de estados (§11) não
     permite `scheduled → missed`, por isso faz-se `triggerOccurrence` e
     depois `markMissed`. Cada ocorrência recorrente resolvida gera a
     seguinte, que pode também estar atrasada: repete-se até estabilizar,
     com limite `RecoveryPolicy.maxCatchUpPasses`.
   - Fase 2 (re-armar): ocorrências futuras voltam a ser agendadas; as
     atrasadas ainda dentro da tolerância recebem uma notificação imediata
     (`RecoveryPolicy.surfaceDelay`), sem alterar o `scheduledAt` guardado.
2. A classificação é uma função pura (`OverdueClassifier`). Numa ocorrência
   `scheduled` a tolerância conta desde `scheduledAt` e **não** desde o
   `triggeredAt` antigo, que sobra de um snooze.
3. Se a app foi aberta ao tocar numa notificação, essa ocorrência fica fora
   da recuperação (`excludeOccurrenceId`), para não competir com o ecrã do
   alarme.
4. Falhas por ocorrência vão para o `RecoveryReport` e nunca abortam a
   corrida; a seguinte tenta de novo. Isto cobre a falha silenciosa do
   agendamento.
5. **Permissões**: `AlarmPermissionChecker` é uma interface própria, para não
   obrigar a alterar `AlarmNotifier` e os seus fakes. A Home mostra um aviso
   quando faltam notificações ou alarmes exactos, com atalho para as
   definições, e volta a verificar quando a app regressa ao primeiro plano.
6. **Android**: `RECEIVE_BOOT_COMPLETED` e os receptores
   `ScheduledNotificationReceiver` e `ScheduledNotificationBootReceiver` do
   `flutter_local_notifications` ficam declarados no manifest, para o sistema
   repor os alarmes depois de um reinício.
7. Quando a recuperação marca ocorrências como perdidas, o `app.dart` invalida
   Home, Dashboard, Calendário e Insights.

## Consequências
- Ocorrências perdidas contam como perdidas (pontuação e streak), mesmo que o
  telemóvel tenha estado desligado. É a regra já existente, não uma nova.
- Fora de âmbito: restrições de bateria específicas de cada fabricante.
