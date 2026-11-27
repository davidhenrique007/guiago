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

## 7. Som, vibração e Notificações (Fase 9, Lote H)
- [ ] Perfil → Som da notificação: tocar no ▶ de cada som **toca** (volume
      das notificações ligado, permissão de notificações dada).
- [ ] Escolher "GuiaGo — Alerta", criar tarefa para daqui a 2 min: toca **esse** som.
- [ ] Repetir com Suave, Despertar, Som do sistema e Sem som (silêncio).
- [ ] Mudar o som com uma tarefa já agendada: ao disparar usa o **novo** som.
- [ ] Vibração desligada: o alarme toca sem vibrar; ligada: vibra.
- [ ] Notificações desligadas: tarefa agendada **não** notifica; ligar de novo
      e criar/aguardar: volta a notificar (as pendentes são rearmadas).
- [ ] Definições do Android → Apps → GuiaGo → Notificações: aparecem canais
      por combinação (ex.: "GuiaGo — GuiaGo — Alerta (com vibração)").
- [ ] Modo "Não incomodar" / volume de notificações a zero: anotar o
      comportamento (é do Android, não da app).

## 8. Tema Claro / Escuro / Sistema (Fase 9, Lote J)
- [ ] Perfil → APARÊNCIA → Tema: Claro, Escuro e Sistema.
- [ ] Claro: a app **inteira** muda na hora (sem reiniciar) e a escolha fica
      depois de fechar e abrir a app.
- [ ] Sistema: mudar o tema do telemóvel (Definições → Ecrã) com a app aberta; a
      app acompanha.
- [ ] Percorrer no tema **Claro**: Início, Tarefas, Calendário (Dia/Mês/Ano),
      Progresso (anel e gráfico), Perfil, formulário de tarefa, folhas
      (editar/apagar/som/tema), ecrã do alarme, onboarding.
      Procurar: texto ilegível, ícone invisível, fundo escuro esquecido.
- [ ] Barra de estado (relógio/bateria) legível nos dois temas.
- [ ] Notificação e som não mudam com o tema.

## 9. Idioma Português / Inglês (Fase 9, Lote K)
- [ ] Perfil → IDIOMA → Idioma: escolher English; Perfil, barra de baixo,
      Calendário (Dia/Mês/Ano, detalhe de uma tarefa) e a saudação do Início
      passam a inglês **na hora**.
- [ ] Fechar e abrir a app: o idioma fica.
- [ ] Voltar a Português: tudo volta.
- [ ] O seletor de horas (Início/Fim do dia) aparece no idioma escolhido.
- [ ] Esperado em português mesmo em English (ainda por migrar): Tarefas e
      formulário, alarme, Progresso, Insights, onboarding, notificações.

## 10. Foto de perfil (Fase 9, Lote P)
- [ ] Perfil → tocar no círculo: Tirar foto / Escolher da galeria.
- [ ] Escolher da galeria: a foto aparece no círculo; fechar e abrir a app e
      continua lá.
- [ ] Tirar foto com a câmara: aparece no círculo.
- [ ] Cancelar o seletor não altera nada.
- [ ] Voltar a tocar: aparece "Remover foto"; remover volta à inicial.
- [ ] Tema claro e escuro: o círculo e a borda ficam bem.

## 11. Android real — fecho da Fase 9 (só num telemóvel físico)
Os testes automáticos não conseguem verificar som, vibração nem o sistema.
Em cada linha, anotar Passou / Falhou / Modelo e versão do Android.
- [ ] **App fechada** (deslizada das recentes): tarefa daqui a 2 min → a
      notificação toca à hora certa, com o som escolhido.
- [ ] **Ecrã bloqueado**: o mesmo; a notificação aparece e toca. (O alarme não
      abre sozinho por cima do ecrã bloqueado: é por desenho, ADR-008.)
- [ ] **Reinício** do telemóvel com uma tarefa futura: depois de reiniciar,
      abrir a app **uma vez** e confirmar que ainda toca à hora.
- [ ] **Som personalizado**: mudar para cada um dos 3 sons GuiaGo, "Som do
      sistema" e "Sem som"; criar tarefa para daqui a 1–2 min e ouvir cada um.
- [ ] **Vibração** desligada: toca sem vibrar. Ligada: vibra.
- [ ] **Snooze**: no alarme tocar "Adiar"; volta a tocar após o tempo escolhido.
- [ ] **Não incomodar / modo silencioso**: anotar o comportamento (é do
      sistema; a app não o contorna).
- [ ] **Poupança de bateria / otimização**: com poupança ativa, o alarme ainda
      toca à hora? Anotar (alguns fabricantes — Xiaomi, Huawei, Tecno,
      Infinix — travam apps em segundo plano; pode ser preciso "Sem
      restrições" nas definições da app).
- [ ] **Permissões**: com "Alarmes e lembretes" desligado nas definições do
      sistema, a app avisa; ligar e voltar → o aviso desaparece.
- [ ] Mudar de idioma e de tema com alarmes agendados: continuam a tocar.

## Limitações conhecidas (MVP)
- A janela do dia (Início/Fim) só orienta: avisa no formulário e marca no Calendário; não altera
  o agendamento nem os alarmes. A Voz (TTS), o som, a vibração e o interruptor de Notificações já são respeitados.
- O som e a vibração pertencem ao *canal* Android e não mudam depois de o canal
  existir: por isso há um canal por combinação. Canais antigos ficam listados
  nas definições do sistema.
- Os 3 sons GuiaGo são tons simples gerados (substituíveis: ver `NotificationSound`).
- O alarme é uma notificação (ADR-008): não abre sozinho sobre o ecrã bloqueado.
- Rotinas ligadas a objetivos ficam pós-MVP.
- Idioma: Tarefas e formulário, alarme, Progresso, Insights, onboarding,
  notificações e voz (TTS) ainda estão só em português.
- A foto de perfil fica só no telemóvel (cópia na pasta da app); não há cópia
  de segurança nem sincronização.
