// Hand-written localisations (no code generation): see ADR-015.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

/// Every user-visible text that has been moved out of the widgets.
/// Portuguese is the reference language; English mirrors it. Screens
/// get it with `context.l10n`, which falls back to Portuguese when no
/// localisation is installed (e.g. a widget test with a bare
/// `MaterialApp`).
abstract class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt'),
    Locale('en'),
  ];

  /// The localisation for [locale]; anything but English is Portuguese.
  static AppLocalizations forLocale(Locale locale) =>
      locale.languageCode == 'en'
          ? const AppLocalizationsEn()
          : const AppLocalizationsPt();

  static AppLocalizations? maybeOf(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  /// Capitalised full weekday name; [weekday] is `DateTime.weekday`
  /// (1 = Monday).
  String weekdayName(int weekday);

  /// Short weekday name; [weekday] is `DateTime.weekday`.
  String weekdayShort(int weekday);

  /// Capitalised month name; [month] is 1..12.
  String monthName(int month);

  /// "Quinta-feira, 14 de agosto" / "Thursday, August 14".
  String longDate(DateTime date);

  String get navHome;

  String get navTasks;

  String get navCalendar;

  String get navProgress;

  String get navProfile;

  String get commonSave;

  String get commonSaveFailed;

  String minutes(int n);

  String get profileTitle;

  String get profileInsightsTitle;

  String get profileInsightsSubtitle;

  String get profileLoadError;

  String get profileEditTitle;

  String get profileNoName;

  String get profileNoObjective;

  String get fieldName;

  String get fieldObjective;

  String get nameRequired;

  String get sectionNotifications;

  String get sectionAppearance;

  String get sectionLanguage;

  String get sectionOther;

  String get rowNotifications;

  String get stateEnabled;

  String get stateDisabled;

  String get rowSound;

  String get rowVibration;

  String get vibrationOn;

  String get vibrationOff;

  String get rowSnooze;

  String get rowTolerance;

  String get rowTheme;

  String get rowLanguage;

  String get rowTts;

  String get ttsOn;

  String get ttsOff;

  String get rowDayStart;

  String get rowDayEnd;

  String get dayEndBeforeStart;

  String get soundSoft;

  String get soundAlert;

  String get soundWake;

  String get soundSystem;

  String get soundNone;

  String soundPreview(String name);

  String get themeSystem;

  String get themeLight;

  String get themeDark;

  String get calendarTitle;

  String get viewDay;

  String get viewMonth;

  String get viewYear;

  String get previousDay;

  String get nextDay;

  String get previousMonth;

  String get nextMonth;

  String get previousYear;

  String get nextYear;

  String yourDay(String window);

  String get outsideYourDay;

  String get newTask;

  String dayTasks(int n);

  String get noTasksTitle;

  String get noTasksMessage;

  String get calendarLoadError;

  String get yearHint;

  String get selectedLabel;

  String dayNumber(int day);

  String taskCount(int n);

  String get statusScheduled;

  String get statusTriggered;

  String get statusSnoozed;

  String get statusCompleted;

  String get statusDeclined;

  String get statusMissed;

  String get statusCancelled;

  String get priorityLow;

  String get priorityMedium;

  String get priorityHigh;

  String get recurrenceNone;

  String get recurrenceDaily;

  String get recurrenceWeekly;

  String get recurrenceCustom;

  String get detailWhen;

  String get detailStatus;

  String get detailPriority;

  String get detailRepeat;

  String get detailTolerance;

  String get detailSnoozes;

  String get detailEditHint;

  String get detailLoadError;

  String get photoTitle;

  String get photoCamera;

  String get photoGallery;

  String get photoRemove;

  String get photoChange;

  String get photoFailed;

  String get greetingMorning;

  String get greetingAfternoon;

  String get greetingEvening;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'pt' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations.forLocale(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// `context.l10n`: the installed localisation, or Portuguese when there
/// is none.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.maybeOf(this) ?? const AppLocalizationsPt();
}
