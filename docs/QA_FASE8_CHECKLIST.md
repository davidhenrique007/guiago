# QA Fase 8 — Checklist de teste no telemóvel (MVP)

Testes que **só se fazem num Android real**. Os testes automáticos
(`flutter test`) não os cobrem. Marca cada linha com ✅ / ❌ e anota o
modelo do telemóvel e a versão do Android.

Telemóvel: ____________  Android: ____  Build: `flutter run --release`

## 0. Instalação limpa
- [ ] Instalar a app num telemóvel/emulador sem dados: abre o onboarding.
- [ ] Depois do onboarding, **Início, Tarefas, Calendário e Progresso estão
      vazios** (sem tarefas de exemplo).
- [ ] Início não tem botão de criar tarefa; só a aba **Tarefas** tem "+ Nova tarefa".

## 1. Permissões
- [ ] Criar a **primeira** tarefa: aparece o pedido de notificações.
- [ ] Aceitar: o aviso "Os alarmes podem não tocar" do Início desaparece.
- [ ] Android 12+: abre a página de "Alarmes e lembretes"; ativar e voltar.
- [ ] Recusar notificações: a tarefa fica criada, a app não bloqueia e o
      Início mostra o aviso com o botão **Abrir definições**.
- [ ] Criar uma segunda tarefa depois de recusar: **não** volta a pedir.
- [ ] Ativar a permissão nas definições do sistema e voltar à app: o aviso
      desaparece sozinho.
- [ ] Perfil → Notificações desligado: criar tarefa **não** pede permissões.

## 2. Alarme a horas
- [ ] Tarefa para daqui a 2 min, app aberta: toca/notifica à hora.
- [ ] Mesma coisa com a **app fechada** (deslizada dos recentes).
- [ ] Com o ecrã bloqueado.
- [ ] Tocar na notificação abre o ecrã do alarme da tarefa certa.
- [ ] Concluir / Adiar / Não vou no ecrã do alarme: o estado aparece certo
      em Início, Tarefas e Calendário.
- [ ] Voz: com **Voz (TTS)** ligada lê o título; desligada em Perfil, fica em silêncio.

## 3. Reinício e sistema
- [ ] Agendar tarefa para daqui a 5 min, **reiniciar o telemóvel**, esperar:
      o alarme dispara (receptores de boot).
- [ ] Poupança de bateria ligada: o alarme ainda dispara (anotar se atrasa).
- [ ] Forçar paragem da app e abrir de novo: tarefas com tolerância passada
      aparecem como perdidas; futuras continuam agendadas.
- [ ] Mudar o fuso horário / a hora do sistema: o alarme continua à hora local certa.
- [ ] Modo avião: tudo funciona (a app é offline).

## 4. Tarefas
- [ ] Criar com recorrência diária: aparece em Hoje e nas Próximas.
- [ ] Editar título e hora: o alarme antigo deixa de tocar, o novo toca.
- [ ] Apagar: sai da lista, o alarme não toca e o histórico mantém-se (Progresso).
- [ ] Início: **Concluir** e **Adiar** funcionam; Adiar só aparece quando a tarefa já é devida.

## 5. Navegação e abas
- [ ] Deslizar de lado troca de aba (e não troca dentro de ecrãs secundários).
- [ ] Calendário: Semana/Mês, escolher um dia, tocar numa tarefa abre o detalhe;
      não se cria tarefa por aqui.
- [ ] Progresso: taxa, sequência, tendência e cartão **OBJETIVO**.

## 6. Perfil
- [ ] Editar nome e objetivo; o Início e o Progresso refletem a mudança.
- [ ] Alterar Snooze e Tolerância: novas tarefas usam os novos valores.
- [ ] Início/Fim do dia: fim anterior ao início é recusado.

## Limitações conhecidas (MVP)
- Notificações (interruptor) e janela do dia ficam guardadas mas **ainda não**
  alteram o agendamento. A Voz (TTS) já é respeitada.
- O alarme é uma notificação (ADR-008): não abre sozinho sobre o ecrã bloqueado.
- Vista de Ano no Calendário e rotinas ligadas a objetivos ficam pós-MVP.
