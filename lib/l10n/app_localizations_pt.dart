// Hand-written localisations (no code generation): see ADR-015.
import 'dart:ui';

import 'app_localizations.dart';

class AppLocalizationsPt extends AppLocalizations {
  const AppLocalizationsPt() : super(const Locale('pt'));

  static const List<String> _weekdays = <String>[
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  static const List<String> _weekdaysShort = <String>[
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];

  static const List<String> _months = <String>[
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  String weekdayName(int weekday) => _weekdays[weekday - 1];

  @override
  String weekdayShort(int weekday) => _weekdaysShort[weekday - 1];

  @override
  String monthName(int month) => _months[month - 1];

  @override
  String longDate(DateTime date) =>
      '${weekdayName(date.weekday)}, ${date.day} de '
      '${monthName(date.month).toLowerCase()}';

  @override
  String get navHome => 'Início';

  @override
  String get navTasks => 'Tarefas';

  @override
  String get navCalendar => 'Calendário';

  @override
  String get navProgress => 'Progresso';

  @override
  String get navProfile => 'Perfil';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSaveFailed => 'Não foi possível guardar.';

  @override
  String minutes(int n) => '$n min';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileInsightsTitle => 'Insights';

  @override
  String get profileInsightsSubtitle =>
      'O teu melhor horário e as tarefas que mais concluis.';

  @override
  String get profileLoadError => 'Não foi possível carregar o perfil.';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileNoName => 'Sem nome';

  @override
  String get profileNoObjective => 'Sem objetivo definido';

  @override
  String get fieldName => 'Nome';

  @override
  String get fieldObjective => 'Objetivo principal';

  @override
  String get nameRequired => 'Escreve o teu nome.';

  @override
  String get sectionNotifications => 'NOTIFICAÇÕES';

  @override
  String get sectionAppearance => 'APARÊNCIA';

  @override
  String get sectionLanguage => 'IDIOMA';

  @override
  String get sectionOther => 'OUTRAS CONFIGURAÇÕES';

  @override
  String get rowNotifications => 'Notificações';

  @override
  String get stateEnabled => 'Ativadas';

  @override
  String get stateDisabled => 'Desativadas';

  @override
  String get rowSound => 'Som da notificação';

  @override
  String get rowVibration => 'Vibração';

  @override
  String get vibrationOn => 'Ligada';

  @override
  String get vibrationOff => 'Desligada';

  @override
  String get rowSnooze => 'Snooze padrão';

  @override
  String get rowTolerance => 'Tolerância padrão';

  @override
  String get rowTheme => 'Tema';

  @override
  String get rowLanguage => 'Idioma';

  @override
  String get rowTts => 'Voz (TTS)';

  @override
  String get ttsOn => 'Ativada';

  @override
  String get ttsOff => 'Desativada';

  @override
  String get rowDayStart => 'Início do dia';

  @override
  String get rowDayEnd => 'Fim do dia';

  @override
  String get dayEndBeforeStart => 'O fim do dia tem de ser depois do início.';

  @override
  String get soundSoft => 'GuiaGo — Suave';

  @override
  String get soundAlert => 'GuiaGo — Alerta';

  @override
  String get soundWake => 'GuiaGo — Despertar';

  @override
  String get soundSystem => 'Som do sistema';

  @override
  String get soundNone => 'Sem som';

  @override
  String soundPreview(String name) => 'Ouvir $name';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get calendarTitle => 'Calendário';

  @override
  String get viewDay => 'Dia';

  @override
  String get viewMonth => 'Mês';

  @override
  String get viewYear => 'Ano';

  @override
  String get previousDay => 'Dia anterior';

  @override
  String get nextDay => 'Dia seguinte';

  @override
  String get previousMonth => 'Mês anterior';

  @override
  String get nextMonth => 'Mês seguinte';

  @override
  String get previousYear => 'Ano anterior';

  @override
  String get nextYear => 'Ano seguinte';

  @override
  String yourDay(String window) => 'O teu dia: $window';

  @override
  String get outsideYourDay => 'fora do teu dia';

  @override
  String get newTask => 'Nova tarefa';

  @override
  String dayTasks(int n) => 'Tarefas do dia ($n)';

  @override
  String get noTasksTitle => 'Sem tarefas neste dia';

  @override
  String get noTasksMessage =>
      'As tarefas agendadas para este dia aparecem aqui.';

  @override
  String get calendarLoadError => 'Não foi possível carregar o calendário.';

  @override
  String get yearHint => 'Escolhe um mês para ver os dias e planear tarefas.';

  @override
  String get selectedLabel => 'seleccionado';

  @override
  String dayNumber(int day) => 'Dia $day';

  @override
  String taskCount(int n) => n == 1 ? '1 tarefa' : '$n tarefas';

  @override
  String get statusScheduled => 'Agendada';

  @override
  String get statusTriggered => 'Em curso';

  @override
  String get statusSnoozed => 'Adiada';

  @override
  String get statusCompleted => 'Concluída';

  @override
  String get statusDeclined => 'Recusada';

  @override
  String get statusMissed => 'Perdida';

  @override
  String get statusCancelled => 'Cancelada';

  @override
  String get priorityLow => 'Baixa';

  @override
  String get priorityMedium => 'Média';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get recurrenceNone => 'Nenhuma';

  @override
  String get recurrenceDaily => 'Diária';

  @override
  String get recurrenceWeekly => 'Semanal';

  @override
  String get recurrenceCustom => 'Dias específicos';

  @override
  String get detailWhen => 'Quando';

  @override
  String get detailStatus => 'Estado';

  @override
  String get detailPriority => 'Prioridade';

  @override
  String get detailRepeat => 'Repetição';

  @override
  String get detailTolerance => 'Tolerância';

  @override
  String get detailSnoozes => 'Adiamentos';

  @override
  String get detailEditHint => 'Para editar ou apagar, usa a aba Tarefas.';

  @override
  String get detailLoadError => 'Não foi possível carregar a tarefa.';

  @override
  String get photoTitle => 'Foto de perfil';

  @override
  String get photoCamera => 'Tirar foto';

  @override
  String get photoGallery => 'Escolher da galeria';

  @override
  String get photoRemove => 'Remover foto';

  @override
  String get photoChange => 'Alterar foto';

  @override
  String get photoFailed => 'Não foi possível usar essa foto.';

  @override
  String get greetingMorning => 'Bom dia';

  @override
  String get greetingAfternoon => 'Boa tarde';

  @override
  String get greetingEvening => 'Boa noite';
}
