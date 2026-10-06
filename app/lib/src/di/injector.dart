import 'package:driver_shifts/src/core/config/env.dart';
import 'package:driver_shifts/src/di/injector.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  throwOnMissingDependencies: true,
  ignoreUnregisteredTypes: [Env],
)
void configureDependencies(Env env) {
  getIt
    ..registerSingleton<Env>(env)
    ..init();
}
