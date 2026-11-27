// Hand-written localisations (no code generation): see ADR-015.
import 'dart:ui';

import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  const AppLocalizationsEn() : super(const Locale('en'));

  static const List<String> _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _weekdaysShort = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  String weekdayName(int weekday) => _weekdays[weekday - 1];

  @override
  String weekdayShort(int weekday) => _weekdaysShort[weekday - 1];

  @override
  String monthName(int month) => _months[month - 1];

  @override
  String longDate(DateTime date) =>
      '${weekdayName(date.weekday)}, ${monthName(date.month)} ${date.day}';

  @override
  String get navHome => 'Home';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navProgress => 'Progress';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaveFailed => 'Could not save.';

  @override
  String minutes(int n) => '$n min';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileInsightsTitle => 'Insights';

  @override
  String get profileInsightsSubtitle =>
      'Your best time of day and the tasks you complete most.';

  @override
  String get profileLoadError => 'Could not load your profile.';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileNoName => 'No name';

  @override
  String get profileNoObjective => 'No objective set';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldObjective => 'Main objective';

  @override
  String get nameRequired => 'Enter your name.';

  @override
  String get sectionNotifications => 'NOTIFICATIONS';

  @override
  String get sectionAppearance => 'APPEARANCE';

  @override
  String get sectionLanguage => 'LANGUAGE';

  @override
  String get sectionOther => 'OTHER SETTINGS';

  @override
  String get rowNotifications => 'Notifications';

  @override
  String get stateEnabled => 'On';

  @override
  String get stateDisabled => 'Off';

  @override
  String get rowSound => 'Notification sound';

  @override
  String get rowVibration => 'Vibration';

  @override
  String get vibrationOn => 'On';

  @override
  String get vibrationOff => 'Off';

  @override
  String get rowSnooze => 'Default snooze';

  @override
  String get rowTolerance => 'Default tolerance';

  @override
  String get rowTheme => 'Theme';

  @override
  String get rowLanguage => 'Language';

  @override
  String get rowTts => 'Voice (TTS)';

  @override
  String get ttsOn => 'On';

  @override
  String get ttsOff => 'Off';

  @override
  String get rowDayStart => 'Start of day';

  @override
  String get rowDayEnd => 'End of day';

  @override
  String get dayEndBeforeStart => 'The end of the day must be after the start.';

  @override
  String get soundSoft => 'GuiaGo — Soft';

  @override
  String get soundAlert => 'GuiaGo — Alert';

  @override
  String get soundWake => 'GuiaGo — Wake up';

  @override
  String get soundSystem => 'System sound';

  @override
  String get soundNone => 'No sound';

  @override
  String soundPreview(String name) => 'Listen to $name';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get viewDay => 'Day';

  @override
  String get viewMonth => 'Month';

  @override
  String get viewYear => 'Year';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String yourDay(String window) => 'Your day: $window';

  @override
  String get outsideYourDay => 'outside your day';

  @override
  String get newTask => 'New task';

  @override
  String dayTasks(int n) => 'Tasks for the day ($n)';

  @override
  String get noTasksTitle => 'No tasks on this day';

  @override
  String get noTasksMessage => 'Tasks scheduled for this day appear here.';

  @override
  String get calendarLoadError => 'Could not load the calendar.';

  @override
  String get yearHint => 'Pick a month to see its days and plan tasks.';

  @override
  String get selectedLabel => 'selected';

  @override
  String dayNumber(int day) => 'Day $day';

  @override
  String taskCount(int n) => n == 1 ? '1 task' : '$n tasks';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusTriggered => 'In progress';

  @override
  String get statusSnoozed => 'Snoozed';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusDeclined => 'Declined';

  @override
  String get statusMissed => 'Missed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get recurrenceNone => 'None';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceCustom => 'Specific days';

  @override
  String get detailWhen => 'When';

  @override
  String get detailStatus => 'Status';

  @override
  String get detailPriority => 'Priority';

  @override
  String get detailRepeat => 'Repeats';

  @override
  String get detailTolerance => 'Tolerance';

  @override
  String get detailSnoozes => 'Snoozes';

  @override
  String get detailEditHint => 'To edit or delete, use the Tasks tab.';

  @override
  String get detailLoadError => 'Could not load the task.';

  @override
  String get photoTitle => 'Profile photo';

  @override
  String get photoCamera => 'Take a photo';

  @override
  String get photoGallery => 'Choose from gallery';

  @override
  String get photoRemove => 'Remove photo';

  @override
  String get photoChange => 'Change photo';

  @override
  String get photoFailed => 'Could not use that photo.';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';
}
