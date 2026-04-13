import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  bool get isArabic => locale.languageCode == 'ar';

  String get _lang => locale.languageCode;

  String _t(String ar, String en) => _lang == 'ar' ? ar : en;

  // ── Navigation ──
  String get habits => _t('العادات', 'Habits');
  String get fitness => _t('اللياقة', 'Fitness');
  String get water => _t('الماء', 'Water');
  String get tools => _t('الأدوات', 'Tools');

  // ── Habit Tracker ──
  String get habitTracking => _t('تتبع العادات', 'Habit Tracking');
  String get today => _t('اليوم', 'Today');
  String get completed => _t('مكتمل', 'Completed');
  String get noHabits => _t('لا توجد عادات', 'No habits');
  String get noHabitsHint => _t('لا توجد عادات\nاضغط + لإضافة عادة جديدة', 'No habits\nTap + to add a new habit');
  String get addNewHabit => _t('إضافة عادة جديدة', 'Add New Habit');
  String get habitName => _t('اسم العادة', 'Habit name');
  String get cancel => _t('إلغاء', 'Cancel');
  String get add => _t('إضافة', 'Add');
  String get deleteHabit => _t('حذف العادة', 'Delete Habit');
  String confirmDeleteHabit(String name) => _t('هل أنت متأكد من حذف "$name"؟', 'Are you sure you want to delete "$name"?');
  String get delete => _t('حذف', 'Delete');

  // ── Weekday names ──
  List<String> get weekdays => _t(
    'الأحد,الاثنين,الثلاثاء,الأربعاء,الخميس,الجمعة,السبت',
    'Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday',
  ).split(',');

  List<String> get weekdaysShort => _t(
    'أحد,اثنين,ثلاثاء,أربعاء,خميس,جمعة,سبت',
    'Sun,Mon,Tue,Wed,Thu,Fri,Sat',
  ).split(',');

  // ── Month names ──
  List<String> get months => _t(
    'يناير,فبراير,مارس,أبريل,مايو,يونيو,يوليو,أغسطس,سبتمبر,أكتوبر,نوفمبر,ديسمبر',
    'January,February,March,April,May,June,July,August,September,October,November,December',
  ).split(',');

  // ── Calendar ──
  String get monthlyCalendar => _t('التقويم الشهري', 'Monthly Calendar');
  String get completionRate => _t('نسبة الإنجاز', 'Completion Rate');

  // ── Statistics ──
  String get statistics => _t('الإحصائيات', 'Statistics');
  String get monthlyCompletionRate => _t('نسبة الإنجاز الشهرية', 'Monthly Completion Rate');
  String get dailyCompletion => _t('الإنجاز اليومي', 'Daily Completion');
  String get completedLabel => _t('مكتمل', 'Completed');
  String get remaining => _t('متبقي', 'Remaining');
  String get habitRanking => _t('ترتيب العادات', 'Habit Ranking');

  // ── Mood & Sleep ──
  String get moodAndSleep => _t('المزاج والنوم', 'Mood & Sleep');
  String get howAreYouToday => _t('كيف حالك اليوم؟', 'How are you today?');
  List<String> get moodLabels => _t(
    ',سيء جداً,سيء,عادي,جيد,ممتاز',
    ',Very Bad,Bad,Okay,Good,Excellent',
  ).split(',');
  String get sleepHours => _t('ساعات النوم', 'Sleep Hours');
  String get hour => _t('ساعة', 'hour');
  String get goalTarget8 => _t('الهدف: 8', 'Goal: 8');
  String get average => _t('المعدل', 'Average');
  String get sleep => _t('النوم', 'Sleep');
  String get bestMood => _t('أفضل مزاج', 'Best Mood');
  String get days => _t('أيام', 'Days');
  String get noMoodData => _t('لا توجد بيانات مزاج', 'No mood data');
  String get logMoodDaily => _t('سجّل مزاجك يومياً لرؤية الرسم البياني', 'Log your mood daily to see the chart');
  String get moodChange => _t('تغير المزاج', 'Mood Changes');
  String get noSleepData => _t('لا توجد بيانات نوم', 'No sleep data');
  String get logSleepDaily => _t('سجّل ساعات نومك يومياً لرؤية الرسم البياني', 'Log your sleep daily to see the chart');
  String get sleepHoursChart => _t('ساعات النوم', 'Sleep Hours');
  String averageSleep(String value) => _t('المعدل: $value ساعة', 'Average: ${value}h');
  String get goalTarget8Arabic => _t('الهدف: ٨', 'Goal: 8');

  // ── Fitness Tracker ──
  String get fitnessTracking => _t('تتبع اللياقة', 'Fitness Tracking');
  String get noWeeks => _t('لا توجد أسابيع\nاضغط + لإضافة أسبوع جديد', 'No weeks\nTap + to add a new week');
  String get currentWeek => _t('الأسبوع الحالي', 'Current Week');
  String get nextWeek => _t('الأسبوع القادم', 'Next Week');
  String get pickDate => _t('اختيار تاريخ', 'Pick Date');
  String get pickDayHint => _t('اختر أي يوم في الأسبوع المطلوب', 'Pick any day in the desired week');
  String get deleteWeek => _t('حذف الأسبوع', 'Delete Week');
  String get deleteWeekConfirm => _t('هل أنت متأكد؟ سيتم حذف جميع بيانات هذا الأسبوع.', 'Are you sure? All data for this week will be deleted.');
  String weekLabel(String start, String end) => _t('الأسبوع: $start - $end', 'Week: $start - $end');
  String currentWeekYear(int year) => _t('الأسبوع الحالي - $year', 'Current Week - $year');

  // ── Week Detail Tabs ──
  String get nutrition => _t('التغذية', 'Nutrition');
  String get weight => _t('الوزن', 'Weight');
  String get steps => _t('الخطوات', 'Steps');
  String get assessment => _t('التقييم', 'Assessment');
  String get measurements => _t('القياسات', 'Measurements');

  // ── Nutrition Tab ──
  String get dailyTargets => _t('الأهداف اليومية', 'Daily Targets');
  String get noTargetsSet => _t('لم يتم تحديد الأهداف', 'No targets set');
  String get tapToSetMacroTargets => _t('اضغط لتحديد أهداف الماكرو', 'Tap to set macro targets');
  String get actualVsGoal => _t('الفعلي vs الهدف', 'Actual vs Goal');
  String get weeklyAverage => _t('متوسط الأسبوع', 'Weekly Average');
  String get calories => _t('السعرات', 'Calories');
  String get protein => _t('بروتين', 'Protein');
  String get carbs => _t('كارب', 'Carbs');
  String get fats => _t('دهون', 'Fats');
  String get dailyMacroTargets => _t('أهداف الماكرو اليومية', 'Daily Macro Targets');
  String get macroTargetsNote => _t('هذه الأهداف ثابتة وتنطبق على كل أسبوع', 'These targets apply to every week');
  String get caloriesField => _t('السعرات الحرارية', 'Calories');
  String get proteinGrams => _t('البروتين (جرام)', 'Protein (g)');
  String get carbsGrams => _t('الكربوهيدرات (جرام)', 'Carbs (g)');
  String get fatsGrams => _t('الدهون (جرام)', 'Fats (g)');
  String get notLogged => _t('لم يتم التسجيل', 'Not logged');
  String get save => _t('حفظ', 'Save');
  String nutritionDate(String date) => _t('تغذية $date', 'Nutrition $date');
  String get calorieSuffix => _t('سعرة', 'cal');

  // ── Weight Tab ──
  String get weeklyAverageWeight => _t('معدل الأسبوع', 'Weekly Average');
  String get kg => _t('كجم', 'kg');
  String weightDate(String date) => _t('الوزن - $date', 'Weight - $date');
  String get weightHint => _t('الوزن (كجم)', 'Weight (kg)');

  // ── Steps Tab ──
  String get stepsSummary => _t('ملخص الخطوات', 'Steps Summary');
  String get dailyAverage => _t('المتوسط اليومي', 'Daily Average');
  String get weeklyTotal => _t('إجمالي الأسبوع', 'Weekly Total');
  String get step => _t('خطوة', 'step');
  String get noData => _t('لا توجد بيانات', 'No data');
  String get stepDailyGoal => _t('الهدف اليومي', 'Daily Goal');
  String get setStepGoal => _t('تحديد هدف الخطوات', 'Set Step Goal');
  String get stepGoalHint => _t('عدد الخطوات', 'Number of steps');

  // ── Assessment Tab ──
  String get weekEndAssessment => _t('تقييم نهاية الأسبوع', 'Week-End Assessment');
  String get sleepCommitment => _t('التزامك بالنوم', 'Sleep Commitment');
  String get calorieNeeds => _t('الاحتياج من السعرات', 'Calorie Needs');
  String get fluids => _t('السوائل', 'Fluids');
  String get stepsLabel => _t('الخطوات', 'Steps');
  String get committed => _t('ملتزم', 'Committed');
  String get notCommitted => _t('غير ملتزم', 'Not Committed');
  String get progress => _t('التطور', 'Progress');
  String get noProgress => _t('لا تطور', 'No Progress');
  String get slightProgress => _t('تطور طفيف', 'Slight Progress');
  String get normalProgress => _t('تطور عادي', 'Normal Progress');
  String get historicProgress => _t('تطور تاريخي', 'Historic Progress');
  String get fatigue => _t('الإجهاد', 'Fatigue');
  String get low => _t('منخفض', 'Low');
  String get medium => _t('متوسط', 'Medium');
  String get high => _t('عالي', 'High');
  String get saveAssessment => _t('حفظ التقييم', 'Save Assessment');
  String get assessmentSaved => _t('تم حفظ التقييم', 'Assessment saved');

  // ── Measurements Tab ──
  String get bodyMeasurements => _t('القياسات الجسدية', 'Body Measurements');
  String get chestCm => _t('الصدر (سم)', 'Chest (cm)');
  String get calvesCm => _t('البطات (سم)', 'Calves (cm)');
  String get waistCm => _t('الخصر (سم)', 'Waist (cm)');
  String get glutesCm => _t('القلوتس (سم)', 'Glutes (cm)');
  String get armCm => _t('الذراع (سم)', 'Arm (cm)');
  String get thighCm => _t('الفخذ (سم)', 'Thigh (cm)');
  String get photos => _t('الصور', 'Photos');
  String get front => _t('أمامية', 'Front');
  String get back => _t('خلفية', 'Back');
  String get saveMeasurements => _t('حفظ القياسات', 'Save Measurements');
  String get measurementsSaved => _t('تم حفظ القياسات', 'Measurements saved');

  // ── Water Tracker ──
  String get waterTracking => _t('تتبع الماء', 'Water Tracking');
  String ofGoalMl(int goal) => _t('من $goal مل', 'of $goal ml');
  String get goalReached => _t('تم تحقيق الهدف!', 'Goal reached!');
  String get customAmount => _t('كمية مخصصة', 'Custom Amount');
  String get noWaterYet => _t('لم تشرب شيئاً بعد', "You haven't drunk anything yet");
  String get tapToLog => _t('اضغط على أحد الأزرار لتسجيل شربك', 'Tap a button to log your intake');
  String get todayLog => _t('سجل اليوم', "Today's Log");
  String get dailyGoal => _t('هدف الشرب اليومي', 'Daily Water Goal');
  String get exampleGoal => _t('مثال: 2500', 'e.g. 2500');
  String get ml => _t('مل', 'ml');
  String get exampleAmount => _t('مثال: 250', 'e.g. 250');
  String mlAmount(int amount) => _t('$amount مل', '$amount ml');

  // ── Bottle presets ──
  String get bottle200 => _t('200 مل', '200 ml');
  String get bottle330 => _t('330 مل', '330 ml');
  String get bottle600 => _t('600 مل', '600 ml');
  String get bottle1500 => _t('1.5 لتر', '1.5 L');

  // ── Settings / Calculators ──
  String get calculators => _t('الحاسبات', 'Calculators');
  String get waterIntakeCalc => _t('حاسبة شرب الماء', 'Water Intake Calculator');
  String get waterIntakeDesc => _t('احسب احتياجك اليومي حسب وزنك', 'Calculate your daily needs based on weight');
  String get macroCalc => _t('حاسبة السعرات والماكروز', 'Calorie & Macro Calculator');
  String get macroCalcDesc => _t('احسب سعراتك وتوزيع الماكروز', 'Calculate your calories and macros');
  String get bmiCalc => _t('حاسبة كتلة الجسم BMI', 'BMI Calculator');
  String get bmiCalcDesc => _t('اعرف تصنيف وزنك حسب طولك', 'Check your weight classification');
  String get oneRmCalc => _t('حاسبة أقصى رفعة 1RM', '1RM Calculator');
  String get oneRmCalcDesc => _t('احسب أقصى وزن تقدر ترفعه', 'Estimate your max lift');
  String get bodyFatCalc => _t('حاسبة نسبة الدهون', 'Body Fat Calculator');
  String get bodyFatCalcDesc => _t('طريقة البحرية الأمريكية', 'US Navy Method');
  String get idealWeightCalc => _t('حاسبة الوزن المثالي', 'Ideal Weight Calculator');
  String get idealWeightCalcDesc => _t('اعرف وزنك المثالي حسب طولك', 'Find your ideal weight by height');

  // ── Apple Health ──
  String get appleHealth => _t('صحة Apple', 'Apple Health');
  String get syncAppleHealth => _t('مزامنة صحة Apple', 'Sync Apple Health');
  String get syncing => _t('جاري المزامنة...', 'Syncing...');
  String get healthSyncData => _t('التغذية، الوزن، النوم، الخطوات', 'Nutrition, weight, sleep, steps');
  String get healthPermissionDenied => _t('لم يتم منح صلاحيات صحة Apple', 'Apple Health permissions denied');

  // ── Backup ──
  String get backup => _t('النسخ الاحتياطي', 'Backup');
  String get exportBackup => _t('تصدير النسخة الاحتياطية', 'Export Backup');
  String get exportBackupDesc => _t('حفظ جميع البيانات كملف JSON', 'Save all data as JSON file');
  String get importBackup => _t('استيراد نسخة احتياطية', 'Import Backup');
  String get importBackupDesc => _t('استعادة البيانات من ملف JSON', 'Restore data from JSON file');
  String get backupNote => _t(
    'احفظ النسخة الاحتياطية في مكان آمن (iCloud, Google Drive) حتى تقدر تسترجع بياناتك لو حذفت التطبيق.',
    'Save your backup in a safe place (iCloud, Google Drive) so you can restore your data if you delete the app.',
  );
  String get exporting => _t('جاري التصدير...', 'Exporting...');
  String exportFailed(String error) => _t('فشل التصدير: $error', 'Export failed: $error');
  String get importConfirmTitle => _t('استيراد نسخة احتياطية', 'Import Backup');
  String get importConfirmBody => _t(
    'سيتم استبدال جميع البيانات الحالية بالبيانات من الملف المختار.\n\nهل أنت متأكد؟',
    'All current data will be replaced with data from the selected file.\n\nAre you sure?',
  );
  String get confirmImport => _t('متأكد، استيراد', 'Yes, Import');
  String get importing => _t('جاري الاستيراد...', 'Importing...');
  String get importSuccess => _t('تم استيراد النسخة الاحتياطية بنجاح', 'Backup imported successfully');
  String importFailed(String error) => _t('فشل الاستيراد: $error', 'Import failed: $error');

  // ── Water Intake Calculator ──
  String get enterWeightForWater => _t('أدخل وزنك لحساب كمية الماء المناسبة يومياً', 'Enter your weight to calculate daily water needs');
  String get enterWeight => _t('أدخل وزنك', 'Enter weight');
  String get consumptionRate => _t('معدل الاستهلاك', 'Consumption Rate');
  String get lowRate => _t('منخفض', 'Low');
  String get mediumRate => _t('متوسط', 'Medium');
  String get highRate => _t('مرتفع', 'High');
  String get highRateNote => _t('المعدل المرتفع للنشاط البدني العالي أو الطقس الحار', 'Higher rate for intense physical activity or hot weather');
  String get dailyNeeds => _t('احتياجك اليومي', 'Your Daily Needs');
  String get setAsDailyGoal => _t('تعيين كهدف يومي', 'Set as Daily Goal');
  String get waterGoalUpdated => _t('تم تحديث هدف شرب الماء', 'Water goal updated');
  String get waterFormula => _t('المعادلة: الوزن (كجم) × المعدل (مل/كجم) = الاحتياج اليومي', 'Formula: Weight (kg) x Rate (ml/kg) = Daily Needs');
  String mlPerKg(int value) => _t('$value مل/كجم', '$value ml/kg');
  String get liter => _t('لتر', 'L');

  // ── Macro Calculator ──
  String get basicData => _t('البيانات الأساسية', 'Basic Data');
  String get male => _t('ذكر', 'Male');
  String get female => _t('أنثى', 'Female');
  String get weightField => _t('الوزن', 'Weight');
  String get heightField => _t('الطول', 'Height');
  String get ageField => _t('العمر', 'Age');
  String get leanBodyMass => _t('الكتلة العضلية الصافية', 'Lean Body Mass');
  String get bmrFormula => _t('معادلة BMR', 'BMR Formula');
  String get mifflinAccuracy => _t('الأدق لعامة الناس', 'Most accurate for general population');
  String get katchAccuracy => _t('الأدق للرياضيين (تحتاج نسبة الدهون)', 'Most accurate for athletes (needs body fat %)');
  String get activityLevel => _t('مستوى النشاط', 'Activity Level');
  List<String> get activityLabels => _t(
    'خامل (مكتبي),نشاط خفيف (١-٣ أيام),نشاط متوسط (٣-٥ أيام),نشاط عالي (٦-٧ أيام),نشاط مكثف (تمرين + عمل بدني)',
    'Sedentary (desk job),Light Activity (1-3 days),Moderate Activity (3-5 days),High Activity (6-7 days),Intense Activity (training + physical work)',
  ).split(',');
  String get goal => _t('الهدف', 'Goal');
  Map<String, String> get goalLabels => {
    'aggressive': _t('تنشيف قوي', 'Aggressive Cut'),
    'cut': _t('خسارة دهون', 'Fat Loss'),
    'maintain': _t('ثبات', 'Maintain'),
    'lean': _t('بناء عضل', 'Lean Bulk'),
  };
  String get macroDistribution => _t('توزيع الماكروز', 'Macro Distribution');
  String get proteinPerKg => _t('البروتين (جم/كجم)', 'Protein (g/kg)');
  List<String> get proteinLabels => _t(
    'خامل (0.8-1.0),نشط (1.4-1.8),بناء عضل (1.6-2.2),تنشيف (2.0-2.4)',
    'Sedentary (0.8-1.0),Active (1.4-1.8),Muscle Building (1.6-2.2),Cutting (2.0-2.4)',
  ).split(',');
  String get fatPerKg => _t('الدهون (جم/كجم)', 'Fats (g/kg)');
  List<String> get fatLabels => _t(
    'تنشيف (0.7),خسارة دهون (0.85),متوازن (1.0),بناء عضل (1.2)',
    'Cutting (0.7),Fat Loss (0.85),Balanced (1.0),Muscle Building (1.2)',
  ).split(',');
  String get carbsNote => _t('الكاربوهيدرات = باقي السعرات بعد البروتين والدهون', 'Carbs = remaining calories after protein and fats');
  String get calculate => _t('احسب', 'Calculate');
  String get targetCalories => _t('السعرات المستهدفة', 'Target Calories');
  String get caloriesPerDay => _t('سعرة / يوم', 'cal / day');
  String get setAsDailyTargets => _t('تعيين كأهداف يومية', 'Set as Daily Targets');
  String get macroTargetsUpdated => _t('تم تحديث أهداف الماكروز', 'Macro targets updated');
  String get grams => _t('جم', 'g');

  // ── BMI Calculator ──
  String get bmiTitle => _t('حاسبة كتلة الجسم BMI', 'BMI Calculator');
  String get bodyMassIndex => _t('مؤشر كتلة الجسم', 'Body Mass Index');
  String get categories => _t('التصنيفات', 'Categories');
  String get underweight => _t('نقص في الوزن', 'Underweight');
  String get normalWeight => _t('وزن طبيعي', 'Normal Weight');
  String get overweight => _t('وزن زائد', 'Overweight');
  String get obese => _t('سمنة', 'Obese');
  String get bmiDisclaimer => _t(
    'مؤشر كتلة الجسم لا يأخذ بعين الاعتبار الكتلة العضلية أو توزيع الدهون. يُنصح باستشارة طبيب مختص قبل اتخاذ أي قرارات صحية.',
    'BMI does not account for muscle mass or fat distribution. Consult a healthcare professional before making health decisions.',
  );
  String get bmiSource => _t(
    'المصدر: منظمة الصحة العالمية (WHO) — تصنيف مؤشر كتلة الجسم',
    'Source: World Health Organization (WHO) — BMI Classification',
  );
  String get sources => _t('المصادر العلمية', 'Scientific Sources');
  String get medicalDisclaimer => _t(
    'هذه الأداة للأغراض التعليمية فقط وليست بديلاً عن الاستشارة الطبية. يُنصح بمراجعة طبيب مختص قبل اتخاذ أي قرارات صحية بناءً على هذه النتائج.',
    'This tool is for educational purposes only and is not a substitute for medical advice. Consult a healthcare professional before making health decisions based on these results.',
  );
  String get dataSection => _t('البيانات', 'Data');
  String get cm => _t('سم', 'cm');
  String get yearUnit => _t('سنة', 'year');

  // ── 1RM Calculator ──
  String get oneRmTitle => _t('حاسبة أقصى رفعة 1RM', '1RM Calculator');
  String get liftedWeight => _t('الوزن المرفوع', 'Lifted Weight');
  String get repsCount => _t('عدد التكرارات (1-12)', 'Reps (1-12)');
  String get estimatedMax => _t('أقصى رفعة مقدّرة', 'Estimated 1RM');
  String get formulaBreakdown => _t('تفصيل المعادلات', 'Formula Breakdown');
  String get percentageTable => _t('جدول الأوزان حسب النسبة', 'Percentage Weight Table');
  String get rep => _t('تكرار', 'rep');
  String get oneRmDisclaimer => _t(
    'هذا تقدير فقط. لا تحاول رفع الوزن الأقصى بدون إحماء كافي ومساعد. الدقة تقل عند أكثر من 10 تكرارات.',
    'This is an estimate only. Do not attempt max lifts without proper warm-up and a spotter. Accuracy decreases above 10 reps.',
  );

  // ── Ideal Weight Calculator ──
  String get idealWeightTitle => _t('حاسبة الوزن المثالي', 'Ideal Weight Calculator');
  String get estimatedIdealWeight => _t('الوزن المثالي المقدّر', 'Estimated Ideal Weight');
  String get healthyRange => _t('النطاق الصحي (BMI 18.5-24.9)', 'Healthy Range (BMI 18.5-24.9)');
  String get wristCircumference => _t('محيط المعصم (اختياري)', 'Wrist Circumference (optional)');
  String get wristHint => _t('محيط المعصم لتحديد حجم الهيكل العظمي وتعديل النتيجة', 'Wrist circumference to determine frame size and adjust results');
  String frameAdjusted(String size) => _t('معدّل لهيكل $size', 'Adjusted for $size frame');
  String get boneFrameSize => _t('حجم الهيكل العظمي', 'Bone Frame Size');
  Map<String, String> get frameSizeLabels => {
    'small': _t('صغير', 'Small'),
    'medium': _t('متوسط', 'Medium'),
    'large': _t('كبير', 'Large'),
  };
  String get idealWeightDisclaimer => _t(
    'الوزن المثالي يختلف حسب الكتلة العضلية وتركيب الجسم والجينات. هذه المعادلات مرجع عام وليست هدف ثابت. يُنصح باستشارة طبيب مختص قبل اتخاذ أي قرارات صحية.',
    'Ideal weight varies by muscle mass, body composition, and genetics. These formulas are general references, not fixed targets. Consult a healthcare professional before making health decisions.',
  );
  String get idealWeightSources => _t(
    '• Devine BJ (1974) — معادلة Devine للوزن المثالي\n• Robinson JD et al. (1983) — معادلة Robinson\n• Miller DR et al. (1983) — معادلة Miller\n• Hamwi GJ (1964) — معادلة Hamwi\n• منظمة الصحة العالمية (WHO) — نطاق BMI الصحي 18.5-24.9',
    '• Devine BJ (1974) — Devine ideal body weight formula\n• Robinson JD et al. (1983) — Robinson formula\n• Miller DR et al. (1983) — Miller formula\n• Hamwi GJ (1964) — Hamwi formula\n• World Health Organization (WHO) — Healthy BMI range 18.5-24.9',
  );

  // ── Body Fat Calculator ──
  String get bodyFatTitle => _t('حاسبة نسبة الدهون', 'Body Fat Calculator');
  String get estimatedBodyFat => _t('نسبة الدهون المقدّرة', 'Estimated Body Fat');
  String get neckCircumference => _t('محيط الرقبة', 'Neck Circumference');
  String get waistCircumference => _t('محيط الخصر', 'Waist Circumference');
  String get hipCircumference => _t('محيط الأرداف', 'Hip Circumference');
  String get essentialFat => _t('دهون أساسية', 'Essential Fat');
  String get athlete => _t('رياضي', 'Athlete');
  String get athleteFemale => _t('رياضية', 'Athlete');
  String get fitnessCategory => _t('لياقة', 'Fitness');
  String get averageCategory => _t('متوسط', 'Average');
  String get obeseCategory => _t('سمنة', 'Obese');
  String get measurementGuide => _t('طريقة القياس الصحيحة', 'Correct Measurement Method');
  String get neckMeasure => _t('قس تحت تفاحة آدم مباشرة', 'Measure just below the Adam\'s apple');
  String get waistMeasureMale => _t('قس عند مستوى السرة', 'Measure at navel level');
  String get waistMeasureFemale => _t('قس عند أضيق نقطة', 'Measure at the narrowest point');
  String get hipMeasure => _t('قس عند أعرض نقطة', 'Measure at the widest point');
  String get measurementTip => _t(
    'شد الشريط بشكل مستوي بدون ضغط على الجلد. قس في الصباح قبل الأكل للحصول على أدق نتيجة.',
    'Keep the tape level without pressing into skin. Measure in the morning before eating for best accuracy.',
  );
  String get bodyFatDisclaimer => _t(
    'هذا تقدير بهامش خطأ ±3-4%. للدقة العالية، يُنصح بعمل فحص DEXA. يُنصح باستشارة طبيب مختص قبل اتخاذ أي قرارات صحية.',
    'This is an estimate with ±3-4% error margin. For high accuracy, a DEXA scan is recommended. Consult a healthcare professional before making health decisions.',
  );
  String get bodyFatSources => _t(
    '• Hodgdon JA, Beckett MB (1984) — معادلة البحرية الأمريكية لنسبة الدهون\n• Naval Health Research Center, San Diego\n• American Council on Exercise (ACE) — تصنيفات نسبة الدهون',
    '• Hodgdon JA, Beckett MB (1984) — U.S. Navy body fat formula\n• Naval Health Research Center, San Diego\n• American Council on Exercise (ACE) — Body fat categories',
  );

  // ── Language ──
  String get language => _t('اللغة', 'Language');
  String get arabic => _t('العربية', 'Arabic');
  String get english => _t('English', 'English');

  // ── Nutrition abbreviations ──
  String get proteinShort => _t('ب', 'P');
  String get carbsShort => _t('ك', 'C');
  String get fatsShort => _t('د', 'F');

  // ── Measurement body parts for guide ──
  String get neck => _t('الرقبة', 'Neck');
  String get waist => _t('الخصر', 'Waist');
  String get hips => _t('الأرداف', 'Hips');

  // ── Tutorial ──
  String get tutorialSkip => _t('تخطّي', 'Skip');
  String get tutorialNext => _t('التالي', 'Next');
  String get tutorialDone => _t('تمام', 'Got it');
  String get tutorialReplayTitle => _t('إعادة عرض الشرح', 'Replay tutorial');
  String get tutorialReplaySubtitle =>
      _t('شاهد جولة المميزات من جديد', 'See the feature tour again');
  String get tutorialReplayConfirmSnack => _t(
        'سيتم عرض الشرح عند زيارة كل قسم',
        'Tutorial will show when you visit each tab',
      );

  // Habits tab
  String get tutorialHabitsAddTitle => _t('أضف أول عادة', 'Add your first habit');
  String get tutorialHabitsAddBody => _t(
        'اضغط هنا لإنشاء عادة يومية تريد متابعتها',
        'Tap here to create a daily habit you want to track',
      );
  String get tutorialHabitsTrackTitle =>
      _t('تتبّع تقدّمك', 'Track your progress');
  String get tutorialHabitsTrackBody => _t(
        'اضغط على العادة لتعليمها كمُنجَزة، واسحبها لليسار لحذفها',
        'Tap a habit to mark it done, swipe left to delete',
      );
  String get tutorialHabitsHistoryTitle => _t('شوف سجلّك', 'See your history');
  String get tutorialHabitsHistoryBody => _t(
        'التقويم والإحصائيات توضّح لك تقدّمك عبر الوقت',
        'Calendar and stats show your progress over time',
      );

  // Fitness tab
  String get tutorialFitnessWeekTitle => _t('ابدأ أسبوعك', 'Start your week');
  String get tutorialFitnessWeekBody => _t(
        'أنشئ أسبوع تدريب لتسجيل تغذيتك ووزنك وقياساتك',
        'Create a training week to log nutrition, weight, and measurements',
      );
  String get tutorialFitnessOpenTitle =>
      _t('كل شيء في مكانه', 'Everything in one place');
  String get tutorialFitnessOpenBody => _t(
        'افتح الأسبوع لتسجّل التغذية، الوزن، الخطوات، التقييم، والقياسات',
        'Open a week to log nutrition, weight, steps, assessment, and measurements',
      );

  // Water tab
  String get tutorialWaterLogTitle => _t('سجّل الماء بسرعة', 'Log water fast');
  String get tutorialWaterLogBody => _t(
        'اضغط على زجاجة لإضافة كمية الماء فوراً',
        'Tap a bottle to instantly add water',
      );
  String get tutorialWaterGoalTitle =>
      _t('حدّد هدفك اليومي', 'Set your daily goal');
  String get tutorialWaterGoalBody => _t(
        'اضبط كمية الماء المطلوبة كل يوم من هنا',
        'Adjust your daily water target here',
      );

  // Tools tab
  String get tutorialToolsCalculatorsTitle =>
      _t('حاسبات جاهزة', 'Built-in calculators');
  String get tutorialToolsCalculatorsBody => _t(
        '6 حاسبات تساعدك: الماء، الماكروز، BMI، 1RM، نسبة الدهون، والوزن المثالي',
        '6 calculators to help you: water, macros, BMI, 1RM, body fat, and ideal weight',
      );
  String get tutorialToolsHealthTitle =>
      _t('مزامنة Apple Health', 'Apple Health sync');
  String get tutorialToolsHealthBody => _t(
        'فعّل المزامنة لاستيراد وزنك وخطواتك تلقائياً',
        'Enable to auto-import your weight and steps',
      );
  String get tutorialToolsBackupTitle =>
      _t('احفظ بياناتك', 'Back up your data');
  String get tutorialToolsBackupBody => _t(
        'صدّر نسخة احتياطية حتى لا تفقد تقدّمك أبداً',
        'Export a backup so you never lose your progress',
      );

  // ── Profile ──
  String get profileTitle => _t('الملف الشخصي', 'Profile');
  String get setupProfile => _t('إعداد الملف الشخصي', 'Set Up Your Profile');
  String get welcomeTitle => _t('مرحبًا بك!', 'Welcome!');
  String get welcomeSubtitle => _t('أدخل بياناتك لتجربة أفضل', 'Enter your info for a better experience');
  String get profileName => _t('الاسم', 'Name');
  String get profileAge => _t('العمر', 'Age');
  String get profileHeight => _t('الطول (سم)', 'Height (cm)');
  String get profileWeight => _t('الوزن (كجم)', 'Weight (kg)');
  String get start => _t('ابدأ', 'Start');
  String get skip => _t('تخطي', 'Skip');
  String get profileSaved => _t('تم حفظ الملف الشخصي', 'Profile saved');
  String get profileYears => _t('سنة', 'years');
  String get profileCm => _t('سم', 'cm');
  String get profileKg => _t('كجم', 'kg');
  String get gender => _t('الجنس', 'Gender');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
