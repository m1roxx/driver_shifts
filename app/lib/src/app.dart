import 'package:driver_shifts/src/core/theme/app_theme.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:flutter/material.dart';

class DriverShiftsApp extends StatelessWidget {
  const DriverShiftsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Дневник смен',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const _HomePlaceholder(),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Дневник смен')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_taxi_outlined,
                size: theme.textTheme.displayMedium?.fontSize,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Смены и поездки',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Здесь появятся сводка за день и список поездок.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
