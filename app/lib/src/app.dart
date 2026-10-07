import 'package:driver_shifts/src/core/theme/app_theme.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/di/injector.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/repositories/trips_repository.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/day_bloc.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/screens/shift_diary_screen.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class DriverShiftsApp extends StatelessWidget {
  const DriverShiftsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: getIt<DriverClock>()),
        RepositoryProvider.value(value: getIt<TripsRepository>()),
      ],
      child: MaterialApp(
        title: ShiftDiaryStrings.title,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('ru')],
        debugShowCheckedModeBanner: false,
        home: BlocProvider(
          create: (_) => getIt<DayBloc>()..add(const DayStarted()),
          child: const ShiftDiaryScreen(),
        ),
      ),
    );
  }
}
