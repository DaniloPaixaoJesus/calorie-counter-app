import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('en', 'US'),
    Locale('pt', 'BR'),
    Locale('es'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en', 'US'));
  }

  static String localeNameOf(BuildContext context) {
    final locale = of(context).locale;
    if (locale.languageCode == 'pt') return 'pt_BR';
    if (locale.languageCode == 'es') return 'es';
    return 'en_US';
  }

  static Locale resolve(Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null) return const Locale('en', 'US');
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode &&
          (supported.countryCode == null ||
              supported.countryCode == locale.countryCode)) {
        return supported;
      }
    }
    return const Locale('en', 'US');
  }

  bool get _pt => locale.languageCode == 'pt';
  bool get _es => locale.languageCode == 'es';

  String pick({required String en, required String pt, required String es}) {
    if (_pt) return pt;
    if (_es) return es;
    return en;
  }

  String get appTitle => 'Nutrity';
  String get mockAiBadge => pick(en: 'MOCK AI', pt: 'IA MOCK', es: 'IA MOCK');
  String get back => pick(en: 'Back', pt: 'Voltar', es: 'Volver');
  String get cancel => pick(en: 'Cancel', pt: 'Cancelar', es: 'Cancelar');
  String get save => pick(en: 'Save', pt: 'Salvar', es: 'Guardar');
  String get edit => pick(en: 'Edit', pt: 'Editar', es: 'Editar');
  String get remove => pick(en: 'Remove', pt: 'Remover', es: 'Eliminar');
  String get continueLabel =>
      pick(en: 'Continue', pt: 'Continuar', es: 'Continuar');
  String get home => pick(en: 'Home', pt: 'Home', es: 'Inicio');
  String get add => pick(en: 'Add', pt: 'Adicionar', es: 'Agregar');
  String get today => pick(en: 'Today', pt: 'Hoje', es: 'Hoy');
  String get previous => pick(en: 'Previous', pt: 'Anterior', es: 'Anterior');
  String get next => pick(en: 'Next', pt: 'Próximo', es: 'Siguiente');
  String get kcal => 'kcal';
  String get gramsShort => 'g';

  String get loading =>
      pick(en: 'Loading...', pt: 'Carregando...', es: 'Cargando...');
  String get splashTagline => pick(
        en: 'Intelligence for\nyour daily choices',
        pt: 'Inteligência para\nsuas escolhas diárias',
        es: 'Inteligencia para\ntus elecciones diarias',
      );

  String get chooseYourPlan => pick(
        en: 'Choose your plan',
        pt: 'Escolha seu plano',
        es: 'Elige tu plan',
      );
  String get startForFree => pick(
        en: 'Start for free',
        pt: 'Comece de forma gratuita',
        es: 'Empieza gratis',
      );
  String get notNow => pick(en: 'Not now', pt: 'Agora nao', es: 'Ahora no');
  String get free => 'Free';
  String get premium => 'Premium';
  String get freeBadge => pick(en: 'Free', pt: 'Gratuito', es: 'Gratis');
  String get mostRecommended => pick(
        en: 'Most recommended',
        pt: 'Mais recomendado',
        es: 'Más recomendado',
      );
  String get continueWithFree => pick(
        en: 'Continue with Free',
        pt: 'Continuar com Free',
        es: 'Continuar con Free',
      );
  List<String> get freePlanBullets => [
        pick(
          en: '3 AI estimates per day',
          pt: '3 estimativas com IA por dia',
          es: '3 estimaciones con IA por día',
        ),
        pick(en: 'No login', pt: 'Sem login', es: 'Sin inicio de sesión'),
        pick(
          en: 'Data saved only on this device',
          pt: 'Dados salvos apenas no dispositivo',
          es: 'Datos guardados solo en este dispositivo',
        ),
        pick(en: 'Contains ads', pt: 'Com anúncios', es: 'Con anuncios'),
      ];
  List<String> get premiumPlanBullets => [
        pick(
          en: 'Unlimited AI estimates',
          pt: 'Estimativas ilimitadas com IA',
          es: 'Estimaciones ilimitadas con IA',
        ),
        pick(
          en: 'Macros (protein, carbs and fat)',
          pt: 'Macros (proteínas, carboidratos e gorduras)',
          es: 'Macros (proteínas, carbohidratos y grasas)',
        ),
        pick(
          en: 'Cloud history',
          pt: 'Histórico na nuvem',
          es: 'Historial en la nube',
        ),
        pick(en: 'No ads', pt: 'Sem anúncios', es: 'Sin anuncios'),
        pick(
          en: 'Priority support',
          pt: 'Suporte prioritário',
          es: 'Soporte prioritario',
        ),
      ];

  String get premiumPlans => pick(
        en: 'Premium Plans',
        pt: 'Planos Premium',
        es: 'Planes Premium',
      );
  String get chooseIdealPlan => pick(
        en: 'Choose the ideal plan for you',
        pt: 'Escolha o plano ideal para você',
        es: 'Elige el plan ideal para ti',
      );
  String get monthly => pick(en: 'Monthly', pt: 'Mensal', es: 'Mensual');
  String get yearly => pick(en: 'Yearly', pt: 'Anual', es: 'Anual');
  String get perMonth => pick(en: '/month', pt: '/mês', es: '/mes');
  String get perYear => pick(en: '/year', pt: '/ano', es: '/año');
  String get mostChosen => pick(
        en: 'Most chosen',
        pt: 'Mais escolhido',
        es: 'Más elegido',
      );
  String get save33 =>
      pick(en: 'Save 33%', pt: 'Economize 33%', es: 'Ahorra 33%');
  String get accessYourAccount => pick(
        en: 'Access your account',
        pt: 'Acesse sua conta',
        es: 'Accede a tu cuenta',
      );
  String get premiumLoginSubtitle => pick(
        en: 'Continue to enjoy\nall Premium benefits',
        pt: 'Para continuar e aproveitar\ntodos os benefícios do Premium',
        es: 'Continúa para disfrutar\ntodos los beneficios Premium',
      );
  String get continueWithGoogle => pick(
        en: 'Continue with Google',
        pt: 'Continuar com Google',
        es: 'Continuar con Google',
      );
  String get connectingGoogle => pick(
        en: 'Connecting to Google...',
        pt: 'Conectando ao Google...',
        es: 'Conectando con Google...',
      );
  String get googleLoginCancelled => pick(
        en: 'Google login cancelled.',
        pt: 'Login Google cancelado.',
        es: 'Inicio con Google cancelado.',
      );
  String get secureCloudData => pick(
        en: 'Your data will be secure\nand synced in the cloud.',
        pt: 'Seus dados estarão seguros\ne sincronizados na nuvem.',
        es: 'Tus datos estarán seguros\ny sincronizados en la nube.',
      );

  String get profileAndGoals => pick(
        en: 'Profile and goals',
        pt: 'Perfil e metas',
        es: 'Perfil y metas',
      );
  String get becomePremium => pick(
        en: 'Become Premium!',
        pt: 'Seja Premium!',
        es: 'Hazte Premium!',
      );
  String get macrosToday => pick(
        en: 'Today\'s macros',
        pt: 'Macros de hoje',
        es: 'Macros de hoy',
      );
  String macrosOn(String date) => pick(
        en: 'Macros on $date',
        pt: 'Macros de $date',
        es: 'Macros de $date',
      );
  String get totalCalories => pick(
        en: 'Total calories',
        pt: 'Total de calorias',
        es: 'Calorías totales',
      );
  String totalCaloriesSemantic(int calories) => pick(
        en: 'Total calories: $calories kilocalories',
        pt: 'Total de calorias: $calories quilocalorias',
        es: 'Calorías totales: $calories kilocalorías',
      );
  String get consumedToday => pick(
        en: 'Consumed today',
        pt: 'Consumidas hoje',
        es: 'Consumidas hoy',
      );
  String dailyGoalCalories(int goal) => pick(
        en: 'Daily goal: $goal kcal',
        pt: 'Meta diaria: $goal kcal',
        es: 'Meta diaria: $goal kcal',
      );
  String get noMealsRegistered => pick(
        en: 'No meals registered',
        pt: 'Nenhuma refeicao registrada',
        es: 'No hay comidas registradas',
      );
  String get emptyMealsHint => pick(
        en: 'Tap Add to register your first meal of the day.',
        pt: 'Toque em Adicionar para registrar sua primeira refeicao do dia.',
        es: 'Toca Agregar para registrar tu primera comida del día.',
      );
  String get sponsored =>
      pick(en: 'Sponsored', pt: 'Patrocinado', es: 'Patrocinado');
  String get adSpace => pick(
        en: 'Advertising space',
        pt: 'Espaço de publicidade',
        es: 'Espacio publicitario',
      );
  String get adReservedGoogle => pick(
        en: 'Reserved for future Google AdMob integration.',
        pt: 'Reservado para integração futura com Google AdMob.',
        es: 'Reservado para futura integración con Google AdMob.',
      );
  String get adSemantics => pick(
        en: 'Reserved advertising space',
        pt: 'Espaco reservado para publicidade',
        es: 'Espacio reservado para publicidad',
      );

  String get addMeal => pick(
        en: 'Add Meal',
        pt: 'Adicionar Refeicao',
        es: 'Agregar comida',
      );
  String get tellWhatYouAte => pick(
        en: 'Tell what you ate',
        pt: 'Fale o que voce comeu',
        es: 'Di qué comiste',
      );
  String get describeMealDetails => pick(
        en: 'Describe your meal in detail',
        pt: 'Descreva sua refeicao com detalhes',
        es: 'Describe tu comida con detalles',
      );
  String get stop => pick(en: 'Stop', pt: 'Parar', es: 'Detener');
  String get recordAudio => pick(
        en: 'Record audio',
        pt: 'Gravar audio',
        es: 'Grabar audio',
      );
  String get audioInput => pick(
        en: 'Audio input:',
        pt: 'Entrada por audio:',
        es: 'Entrada por audio:',
      );
  String recordingSeconds(int seconds) => pick(
        en: 'Recording... ${seconds}s',
        pt: 'Gravando... ${seconds}s',
        es: 'Grabando... ${seconds}s',
      );
  String recordingAudioSemantic(int seconds) => pick(
        en: 'Recording audio. $seconds seconds remaining.',
        pt: 'Gravando audio. $seconds segundos restantes.',
        es: 'Grabando audio. Quedan $seconds segundos.',
      );
  String get recording =>
      pick(en: 'Recording...', pt: 'Gravando...', es: 'Grabando...');
  String get estimateWithAi => pick(
        en: 'Estimate with AI',
        pt: 'Estimar com IA',
        es: 'Estimar con IA',
      );
  String get reviewAndConfirm => pick(
        en: 'Review and confirm',
        pt: 'Revisar e confirmar',
        es: 'Revisar y confirmar',
      );
  String get unlimitedEstimates => pick(
        en: 'Unlimited estimates',
        pt: 'Estimativas ilimitadas',
        es: 'Estimaciones ilimitadas',
      );
  String get dailyEstimateLimitReached => pick(
        en: 'Daily estimate limit reached.',
        pt: 'Limite diário de estimativas atingido.',
        es: 'Límite diario de estimaciones alcanzado.',
      );
  String remainingEstimatesToday(int count) => pick(
        en: '$count estimates remaining today',
        pt: '$count estimativas restantes hoje',
        es: '$count estimaciones restantes hoy',
      );
  String voiceRecognitionError(String error) => pick(
        en: 'Voice recognition error: $error',
        pt: 'Erro no reconhecimento de voz: $error',
        es: 'Error de reconocimiento de voz: $error',
      );
  String get typeAtLeast2Chars => pick(
        en: 'Type at least 2 characters.',
        pt: 'Digite pelo menos 2 caracteres.',
        es: 'Escribe al menos 2 caracteres.',
      );
  String get enterCaloriesBeforeSave => pick(
        en: 'Enter calories before saving.',
        pt: 'Informe as calorias antes de salvar.',
        es: 'Informa las calorías antes de guardar.',
      );
  String get estimateBeforeConfirm => pick(
        en: 'Estimate calories before confirming.',
        pt: 'Estime as calorias antes de confirmar.',
        es: 'Estima las calorías antes de confirmar.',
      );
  String get noDescription => pick(
        en: 'No description',
        pt: 'Sem descrição',
        es: 'Sin descripción',
      );
  String get closeNotice => pick(
        en: 'Close notice',
        pt: 'Fechar aviso',
        es: 'Cerrar aviso',
      );
  String get estimateErrorNotice => pick(
        en: 'Estimate error notice',
        pt: 'Aviso de erro da estimativa',
        es: 'Aviso de error de estimación',
      );
  String get mealDescriptionLabel => pick(
        en: 'Meal description',
        pt: 'Descricao da refeicao',
        es: 'Descripción de la comida',
      );
  String get mealDescriptionHint => pick(
        en: 'Ex: rice, beans, grilled chicken and salad',
        pt: 'Ex: arroz, feijao, frango grelhado e salada',
        es: 'Ej: arroz, frijoles, pollo a la plancha y ensalada',
      );
  String get caloriesLabel => pick(
        en: 'Calories (kcal)',
        pt: 'Calorias (kcal)',
        es: 'Calorías (kcal)',
      );
  String get editIfNeeded => pick(
        en: 'Edit if needed',
        pt: 'Edite se necessario',
        es: 'Edita si es necesario',
      );

  String get reviewEstimateTitle => pick(
        en: 'Review and confirm',
        pt: 'Revisar e confirmar',
        es: 'Revisar y confirmar',
      );
  String get reviewMealDetails => pick(
        en: 'Check your meal details',
        pt: 'Confira os detalhes da sua refeição',
        es: 'Revisa los detalles de tu comida',
      );
  String get estimatedMacros => pick(
        en: 'Estimated macros',
        pt: 'Macros estimados',
        es: 'Macros estimados',
      );
  String get aiObservation => pick(
        en: 'AI observation',
        pt: 'Observacao da IA',
        es: 'Observación de IA',
      );
  String get aiConfidence => pick(
        en: 'AI confidence',
        pt: 'Confianca da IA',
        es: 'Confianza de IA',
      );
  String get confirm => pick(en: 'Confirm', pt: 'Confirmar', es: 'Confirmar');

  String get removeMealQuestion => pick(
        en: 'Remove meal?',
        pt: 'Remover refeicao?',
        es: '¿Eliminar comida?',
      );
  String get cannotBeUndone => pick(
        en: 'This action cannot be undone.',
        pt: 'Esta acao nao pode ser desfeita.',
        es: 'Esta acción no se puede deshacer.',
      );
  String get removeMealTooltip => pick(
        en: 'Remove meal',
        pt: 'Remover refeicao',
        es: 'Eliminar comida',
      );

  String get dailyLimitTitle => pick(
        en: 'Daily limit reached',
        pt: 'Limite diário atingido',
        es: 'Límite diario alcanzado',
      );
  String get dailyLimitUsed => pick(
        en: 'You have already used your 3 AI\nestimates today.',
        pt: 'Você já utilizou suas 3 estimativas\ncom IA hoje.',
        es: 'Ya usaste tus 3 estimaciones\ncon IA hoy.',
      );
  String get dailyLimitUpgrade => pick(
        en: 'Come back tomorrow for new\nestimates or upgrade to Premium\nfor unlimited estimates!',
        pt: 'Volte amanhã para novas\nestimativas ou faça upgrade\npara Premium e tenha\nestimativas ilimitadas!',
        es: 'Vuelve mañana para nuevas\nestimaciones o mejora a Premium\ny obtén estimaciones ilimitadas!',
      );
  String get viewPlans => pick(
        en: 'View plans',
        pt: 'Ver planos',
        es: 'Ver planes',
      );
  String get gotIt => pick(en: 'Got it', pt: 'Entendi', es: 'Entendido');

  String get estimatedMacronutrients => pick(
        en: 'Estimated macronutrients',
        pt: 'Macronutrientes estimados',
        es: 'Macronutrientes estimados',
      );
  String get proteins => pick(en: 'Protein', pt: 'Proteínas', es: 'Proteínas');
  String get carbs =>
      pick(en: 'Carbs', pt: 'Carboidratos', es: 'Carbohidratos');
  String get fats => pick(en: 'Fat', pt: 'Gorduras', es: 'Grasas');

  String get editMeal => pick(
        en: 'Edit meal',
        pt: 'Editar refeicao',
        es: 'Editar comida',
      );
  String get mealDetails => pick(
        en: 'Meal details',
        pt: 'Detalhes da refeicao',
        es: 'Detalles de la comida',
      );
  String get changeBeforeSaving => pick(
        en: 'Change description and calories before saving',
        pt: 'Altere descricao e calorias antes de salvar',
        es: 'Cambia la descripción y calorías antes de guardar',
      );
  String get reviewSavedInfo => pick(
        en: 'Review the registered information',
        pt: 'Revise as informacoes registradas',
        es: 'Revisa la información registrada',
      );
  String get description =>
      pick(en: 'Description', pt: 'Descricao', es: 'Descripción');
  String get calories => pick(en: 'Calories', pt: 'Calorias', es: 'Calorías');
  String get source => pick(en: 'Source', pt: 'Origem', es: 'Origen');
  String get audio => pick(en: 'Audio', pt: 'Audio', es: 'Audio');
  String get text => pick(en: 'Text', pt: 'Texto', es: 'Texto');
  String get dateAndTime => pick(
        en: 'Date and time',
        pt: 'Data e hora',
        es: 'Fecha y hora',
      );
  String get notInformed => pick(
        en: 'Not informed',
        pt: 'Nao informada',
        es: 'No informada',
      );
  String get observation => pick(
        en: 'Observation',
        pt: 'Observacao',
        es: 'Observación',
      );
  String get noObservation => pick(
        en: 'No observation',
        pt: 'Sem observacao',
        es: 'Sin observación',
      );
  String userFacingMessage(String message) {
    switch (message) {
      case 'Limite diário de estimativas atingido. Tente novamente amanhã.':
        return pick(
          en: 'Daily estimate limit reached. Try again tomorrow.',
          pt: 'Limite diário de estimativas atingido. Tente novamente amanhã.',
          es: 'Límite diario de estimaciones alcanzado. Inténtalo mañana.',
        );
      case 'Erro inesperado ao estimar calorias.':
        return pick(
          en: 'Unexpected error while estimating calories.',
          pt: 'Erro inesperado ao estimar calorias.',
          es: 'Error inesperado al estimar calorías.',
        );
      case 'Refeição não encontrada':
        return pick(
          en: 'Meal not found',
          pt: 'Refeição não encontrada',
          es: 'Comida no encontrada',
        );
      case 'Refeição não pertence à data selecionada':
        return pick(
          en: 'Meal does not belong to the selected date',
          pt: 'Refeição não pertence à data selecionada',
          es: 'La comida no pertenece a la fecha seleccionada',
        );
    }
    return message;
  }

  String get saveChanges => pick(
        en: 'Save changes',
        pt: 'Salvar alteracoes',
        es: 'Guardar cambios',
      );
  String get backToDetails => pick(
        en: 'Back to details',
        pt: 'Voltar aos detalhes',
        es: 'Volver a detalles',
      );

  String get premiumProfile => pick(
        en: 'Premium Profile',
        pt: 'Perfil Premium',
        es: 'Perfil Premium',
      );
  String get goalUpdated => pick(
        en: 'Daily goal updated.',
        pt: 'Meta diaria atualizada.',
        es: 'Meta diaria actualizada.',
      );
  String get logout => pick(
        en: 'Sign out',
        pt: 'Sair da conta',
        es: 'Cerrar sesión',
      );
  String get premiumUser => pick(
        en: 'Premium User',
        pt: 'Usuario Premium',
        es: 'Usuario Premium',
      );
  String get emailNotInformed => pick(
        en: 'E-mail not informed',
        pt: 'E-mail nao informado',
        es: 'E-mail no informado',
      );
  String get managePlanSoon => pick(
        en: 'Plan management coming soon.',
        pt: 'Gerenciamento de plano em breve.',
        es: 'Gestión del plan próximamente.',
      );
  String get managePlan => pick(
        en: 'Manage plan',
        pt: 'Gerenciar plano',
        es: 'Gestionar plan',
      );
  String get premiumPlan => pick(
        en: 'Premium Plan',
        pt: 'Plano Premium',
        es: 'Plan Premium',
      );
  String get activeSubscription => pick(
        en: 'Active subscription',
        pt: 'Assinatura ativa',
        es: 'Suscripción activa',
      );
  String get memberSince => pick(
        en: 'Member since',
        pt: 'Membro desde',
        es: 'Miembro desde',
      );
  String get currentStreak => pick(
        en: 'Current streak',
        pt: 'Sequencia atual',
        es: 'Racha actual',
      );
  String get bestStreak => pick(
        en: 'Best streak',
        pt: 'Melhor sequencia',
        es: 'Mejor racha',
      );
  String daysCount(int days) => pick(
        en: '$days days',
        pt: '$days dias',
        es: '$days días',
      );
  String get dailyGoal => pick(
        en: 'Daily goal',
        pt: 'Meta diaria',
        es: 'Meta diaria',
      );
  String get dailyCalorieGoal => pick(
        en: 'Daily calorie goal',
        pt: 'Meta de calorias diaria',
        es: 'Meta diaria de calorías',
      );
  String get goalInKcal => pick(
        en: 'Goal in kcal',
        pt: 'Meta em kcal',
        es: 'Meta en kcal',
      );
  String get caloriesLast7Days => pick(
        en: 'Calories in the last 7 days',
        pt: 'Calorias dos ultimos 7 dias',
        es: 'Calorías de los últimos 7 días',
      );
  String get dailyConsumption => pick(
        en: 'Daily consumption',
        pt: 'Consumo diario',
        es: 'Consumo diario',
      );
  String get macrosLast7Days => pick(
        en: 'Macros in the last 7 days',
        pt: 'Macros dos ultimos 7 dias',
        es: 'Macros de los últimos 7 días',
      );
  String get gramsPerDay => pick(
        en: 'Grams per day',
        pt: 'Gramas por dia',
        es: 'Gramos por día',
      );
  String averageLabel(int average, String suffix) => pick(
        en: 'average $average $suffix',
        pt: 'media $average $suffix',
        es: 'media $average $suffix',
      );
  String get noDataInPeriod => pick(
        en: 'No data in this period',
        pt: 'Sem dados no período',
        es: 'Sin datos en el período',
      );
  String get totalInWeek => pick(
        en: 'Week total',
        pt: 'Total na semana',
        es: 'Total semanal',
      );
  String get highestConsumption => pick(
        en: 'Highest consumption',
        pt: 'Maior consumo',
        es: 'Mayor consumo',
      );
  String get lowestConsumption => pick(
        en: 'Lowest consumption',
        pt: 'Menor consumo',
        es: 'Menor consumo',
      );
  String get averageGoalPercent => pick(
        en: '% of goal (avg)',
        pt: '% da meta (media)',
        es: '% de meta (media)',
      );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'en' ||
        locale.languageCode == 'pt' ||
        locale.languageCode == 'es';
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(AppLocalizations.resolve(
      locale,
      AppLocalizations.supportedLocales,
    )));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
