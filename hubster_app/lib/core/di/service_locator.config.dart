// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../services/auth_service.dart' as _i610;
import '../../services/upload_service.dart' as _i105;
import '../api/api_client.dart' as _i277;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  gh.lazySingleton<_i277.ApiClient>(() => _i277.ApiClient());
  gh.lazySingleton<_i610.AuthService>(
    () => _i610.AuthService(gh<_i277.ApiClient>()),
  );
  gh.lazySingleton<_i105.UploadService>(
    () => _i105.UploadService(gh<_i277.ApiClient>()),
  );
  return getIt;
}
