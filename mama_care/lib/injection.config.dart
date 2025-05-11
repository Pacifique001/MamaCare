// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:dio/dio.dart' as _i361;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_messaging/firebase_messaging.dart' as _i892;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:logger/logger.dart' as _i974;
import 'package:uuid/uuid.dart' as _i706;

import 'data/local/database_helper.dart' as _i441;
import 'data/repositories/admin_repository.dart' as _i1040;
import 'data/repositories/appointment_repository.dart' as _i639;
import 'data/repositories/article_repository.dart' as _i11;
import 'data/repositories/calendar_repository.dart' as _i879;
import 'data/repositories/dashboard_repository.dart' as _i1059;
import 'data/repositories/doctor_repository.dart' as _i595;
import 'data/repositories/food_repository.dart' as _i865;
import 'data/repositories/hospital_repository.dart' as _i343;
import 'data/repositories/login_repository.dart' as _i48;
import 'data/repositories/notification_repository.dart' as _i718;
import 'data/repositories/nurse_assignment_repository.dart' as _i505;
import 'data/repositories/nurse_repository.dart' as _i413;
import 'data/repositories/pregnancy_detail_repository.dart' as _i993;
import 'data/repositories/profile_repository.dart' as _i1011;
import 'data/repositories/risk_detector_repository.dart' as _i844;
import 'data/repositories/signup_repository.dart' as _i771;
import 'data/repositories/timeline_repository.dart' as _i625;
import 'data/repositories/user_repository.dart' as _i443;
import 'data/repositories/video_repository.dart' as _i1010;
import 'domain/entities/admin_repository_impl.dart' as _i979;
import 'domain/repositories/appointment_repository_impl.dart' as _i1052;
import 'domain/repositories/article_repository_impl.dart' as _i1026;
import 'domain/repositories/calendar_repository_impl.dart' as _i350;
import 'domain/repositories/dashboard_repository_impl.dart' as _i909;
import 'domain/repositories/doctor_repository_impl.dart' as _i988;
import 'domain/repositories/firebase_auth_repository.dart' as _i964;
import 'domain/repositories/food_repository_impl.dart' as _i531;
import 'domain/repositories/hospital_repository_impl.dart' as _i49;
import 'domain/repositories/login_repository_impl.dart' as _i389;
import 'domain/repositories/notification_repository_impl.dart' as _i792;
import 'domain/repositories/nurse_assignment_repository_impl.dart' as _i809;
import 'domain/repositories/nurse_repository_impl.dart' as _i1056;
import 'domain/repositories/pregnancy_detail_repository_impl.dart' as _i947;
import 'domain/repositories/profile_repository_impl.dart' as _i125;
import 'domain/repositories/risk_detector_repository_impl.dart' as _i224;
import 'domain/repositories/timeline_repository_impl.dart' as _i878;
import 'domain/repositories/user_repository_impl.dart' as _i800;
import 'domain/repositories/video_repository_impl.dart' as _i1041;
import 'domain/usecases/admin_usecase.dart' as _i528;
import 'domain/usecases/appointment_usecase.dart' as _i234;
import 'domain/usecases/article_usecase.dart' as _i160;
import 'domain/usecases/assign_nurse_usecase.dart' as _i1068;
import 'domain/usecases/calendar_use_case.dart' as _i65;
import 'domain/usecases/dashboard_use_case.dart' as _i736;
import 'domain/usecases/doctor_usecase.dart' as _i144;
import 'domain/usecases/food_usecase.dart' as _i59;
import 'domain/usecases/hospital_use_case.dart' as _i157;
import 'domain/usecases/login_use_case.dart' as _i1005;
import 'domain/usecases/notification_use_case.dart' as _i356;
import 'domain/usecases/nurse_assignment_management_usecase.dart' as _i56;
import 'domain/usecases/nurse_assignment_usecase.dart' as _i429;
import 'domain/usecases/nurse_dashboard_usecase.dart' as _i59;
import 'domain/usecases/nurse_detail_usecase.dart' as _i666;
import 'domain/usecases/pregnancy_detail_use_case.dart' as _i870;
import 'domain/usecases/profile_use_case.dart' as _i808;
import 'domain/usecases/risk_detector_use_case.dart' as _i850;
import 'domain/usecases/signup_use_case.dart' as _i829;
import 'domain/usecases/timeline_use_case.dart' as _i1011;
import 'domain/usecases/video_usecase.dart' as _i155;
import 'injection.dart' as _i464;
import 'presentation/viewmodel/add_appointment_viewmodel.dart' as _i587;
import 'presentation/viewmodel/admin_dashboard_viewmodel.dart' as _i113;
import 'presentation/viewmodel/appointment_detail_viewmodel.dart' as _i8;
import 'presentation/viewmodel/article_list_viewmodel.dart' as _i149;
import 'presentation/viewmodel/article_viewmodel.dart' as _i894;
import 'presentation/viewmodel/assign_nurse_viewmodel.dart' as _i428;
import 'presentation/viewmodel/auth_viewmodel.dart' as _i785;
import 'presentation/viewmodel/dashboard_viewmodel.dart' as _i906;
import 'presentation/viewmodel/doctor_appointments_viewmodel.dart' as _i986;
import 'presentation/viewmodel/doctor_dashboard_viewmodel.dart' as _i437;
import 'presentation/viewmodel/food_detail_viewmodel.dart' as _i447;
import 'presentation/viewmodel/hospital_viewmodel.dart' as _i180;
import 'presentation/viewmodel/nurse_assignment_management_viewmodel.dart'
    as _i974;
import 'presentation/viewmodel/nurse_dashboard_viewmodel.dart' as _i332;
import 'presentation/viewmodel/nurse_detail_viewmodel.dart' as _i418;
import 'presentation/viewmodel/patient_appointments_viewmodel.dart' as _i517;
import 'presentation/viewmodel/pregnancy_detail_viewmodel.dart' as _i68;
import 'presentation/viewmodel/profile_viewmodel.dart' as _i181;
import 'presentation/viewmodel/reschedule_viewmodel.dart' as _i417;
import 'presentation/viewmodel/signup_viewmodel.dart' as _i681;
import 'presentation/viewmodel/suggested_food_viewmodel.dart' as _i290;
import 'utils/theme_controller.dart' as _i453;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  final registerModule = _$RegisterModule();
  gh.factory<_i964.FirebaseAuthRepository>(
    () => _i964.FirebaseAuthRepository(),
  );
  gh.singleton<_i59.FirebaseAuth>(() => registerModule.firebaseAuth);
  gh.singleton<_i974.FirebaseFirestore>(() => registerModule.firebaseFirestore);
  gh.singleton<_i892.FirebaseMessaging>(() => registerModule.firebaseMessaging);
  gh.singleton<_i116.GoogleSignIn>(() => registerModule.googleSignIn);
  gh.singleton<_i361.Dio>(() => registerModule.dio);
  gh.singleton<_i441.DatabaseHelper>(() => registerModule.databaseHelper);
  gh.singleton<_i706.Uuid>(() => registerModule.uuid);
  gh.singleton<_i974.Logger>(() => registerModule.logger);
  gh.factory<_i505.NurseAssignmentRepository>(
    () => _i809.NurseAssignmentRepositoryImpl(
      gh<_i974.FirebaseFirestore>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i595.DoctorRepository>(
    () => _i988.DoctorRepositoryImpl(
      gh<_i974.FirebaseFirestore>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i1040.AdminRepository>(
    () => _i979.AdminRepositoryImpl(
      gh<_i974.FirebaseFirestore>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i785.AuthViewModel>(
    () => _i785.AuthViewModel(
      gh<_i441.DatabaseHelper>(),
      gh<_i892.FirebaseMessaging>(),
      gh<_i59.FirebaseAuth>(),
      gh<_i116.GoogleSignIn>(),
      gh<_i974.Logger>(),
      gh<_i974.FirebaseFirestore>(),
      gh<_i706.Uuid>(),
    ),
  );
  gh.factory<_i681.SignupViewModel>(
    () => _i681.SignupViewModel(gh<_i785.AuthViewModel>(), gh<_i974.Logger>()),
  );
  gh.factory<_i718.NotificationRepository>(
    () => _i792.NotificationRepositoryImpl(
      gh<_i892.FirebaseMessaging>(),
      gh<_i441.DatabaseHelper>(),
      gh<_i974.Logger>(),
      gh<_i59.FirebaseAuth>(),
    ),
  );
  gh.factory<_i639.AppointmentRepository>(
    () => _i1052.AppointmentRepositoryImpl(
      gh<_i974.FirebaseFirestore>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i1059.DashboardRepository>(
    () => _i909.DashboardRepositoryImpl(
      gh<_i441.DatabaseHelper>(),
      gh<_i892.FirebaseMessaging>(),
      gh<_i974.FirebaseFirestore>(),
    ),
  );
  gh.factory<_i413.NurseRepository>(
    () => _i1056.NurseRepositoryImpl(
      gh<_i974.FirebaseFirestore>(),
      gh<_i59.FirebaseAuth>(),
      gh<_i974.Logger>(),
      gh<_i706.Uuid>(),
    ),
  );
  gh.factory<_i447.FoodDetailViewModel>(
    () => _i447.FoodDetailViewModel(gh<_i974.Logger>()),
  );
  gh.factory<_i144.DoctorUseCase>(
    () => _i144.DoctorUseCase(gh<_i595.DoctorRepository>(), gh<_i974.Logger>()),
  );
  gh.factory<_i56.NurseAssignmentManagementUseCase>(
    () => _i56.NurseAssignmentManagementUseCase(
      gh<_i413.NurseRepository>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i865.FoodRepository>(
    () => _i531.FoodRepositoryImpl(
      gh<_i441.DatabaseHelper>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i443.UserRepository>(
    () => _i800.UserRepositoryImpl(gh<_i974.FirebaseFirestore>()),
  );
  gh.factory<_i528.AdminUseCase>(
    () => _i528.AdminUseCase(
      gh<_i1040.AdminRepository>(),
      gh<_i59.FirebaseAuth>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i59.FoodUseCase>(
    () => _i59.FoodUseCase(gh<_i865.FoodRepository>()),
  );
  gh.factory<_i625.TimelineRepository>(
    () => _i878.TimelineRepositoryImpl(
      gh<_i59.FirebaseAuth>(),
      gh<_i974.FirebaseFirestore>(),
      gh<_i441.DatabaseHelper>(),
      gh<_i892.FirebaseMessaging>(),
    ),
  );
  gh.factory<_i993.PregnancyDetailRepository>(
    () => _i947.PregnancyDetailRepositoryImpl(
      gh<_i59.FirebaseAuth>(),
      gh<_i974.FirebaseFirestore>(),
      gh<_i441.DatabaseHelper>(),
      gh<_i892.FirebaseMessaging>(),
    ),
  );
  gh.factory<_i48.LoginRepository>(
    () => _i389.LoginRepositoryImpl(
      gh<_i441.DatabaseHelper>(),
      gh<_i892.FirebaseMessaging>(),
      gh<_i59.FirebaseAuth>(),
      gh<_i116.GoogleSignIn>(),
      gh<_i974.FirebaseFirestore>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i11.ArticleRepository>(
    () => _i1026.ArticleRepositoryImpl(
      gh<_i441.DatabaseHelper>(),
      gh<_i892.FirebaseMessaging>(),
    ),
  );
  gh.factory<_i453.ThemeController>(
    () => _i453.ThemeController(gh<_i441.DatabaseHelper>()),
  );
  gh.factory<_i771.SignupRepository>(
    () => _i771.SignupRepository(gh<_i441.DatabaseHelper>()),
  );
  gh.factory<_i666.NurseDetailUseCase>(
    () => _i666.NurseDetailUseCase(
      gh<_i413.NurseRepository>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i1010.VideoRepository>(
    () => _i1041.VideoRepositoryImpl(
      gh<_i361.Dio>(),
      gh<_i441.DatabaseHelper>(),
      gh<_i974.Logger>(),
      gh<_i59.FirebaseAuth>(),
    ),
  );
  gh.factory<_i343.HospitalRepository>(
    () => _i49.HospitalRepositoryImpl(
      gh<_i361.Dio>(),
      gh<_i441.DatabaseHelper>(),
      gh<_i974.Logger>(),
      gh<_i785.AuthViewModel>(),
    ),
  );
  gh.factory<_i1068.AssignNurseUseCase>(
    () => _i1068.AssignNurseUseCase(
      gh<_i413.NurseRepository>(),
      gh<_i59.FirebaseAuth>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i332.NurseDashboardViewModel>(
    () => _i332.NurseDashboardViewModel(
      gh<_i413.NurseRepository>(),
      gh<_i59.FirebaseAuth>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i1011.ProfileRepository>(
    () => _i125.ProfileRepositoryImpl(
      gh<_i441.DatabaseHelper>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i879.CalendarRepository>(
    () => _i350.CalendarRepositoryImpl(
      gh<_i974.FirebaseFirestore>(),
      gh<_i441.DatabaseHelper>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i844.RiskDetectorRepository>(
    () => _i224.RiskDetectorRepositoryImpl(
      gh<_i361.Dio>(),
      gh<_i441.DatabaseHelper>(),
      gh<_i892.FirebaseMessaging>(),
    ),
  );
  gh.factory<_i1011.TimelineUseCase>(
    () => _i1011.TimelineUseCase(gh<_i625.TimelineRepository>()),
  );
  gh.factoryParam<_i974.NurseAssignmentManagementViewModel, String, dynamic>(
    (nurseId, _) => _i974.NurseAssignmentManagementViewModel(
      gh<_i56.NurseAssignmentManagementUseCase>(),
      gh<_i974.Logger>(),
      nurseId,
    ),
  );
  gh.factory<_i829.SignupUseCase>(
    () => _i829.SignupUseCase(gh<_i771.SignupRepository>()),
  );
  gh.factory<_i113.AdminDashboardViewModel>(
    () => _i113.AdminDashboardViewModel(
      gh<_i528.AdminUseCase>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i65.CalendarUseCase>(
    () => _i65.CalendarUseCase(
      gh<_i879.CalendarRepository>(),
      gh<_i785.AuthViewModel>(),
    ),
  );
  gh.factory<_i160.ArticleUseCase>(
    () => _i160.ArticleUseCase(gh<_i11.ArticleRepository>()),
  );
  gh.factory<_i870.PregnancyDetailUseCase>(
    () => _i870.PregnancyDetailUseCase(gh<_i993.PregnancyDetailRepository>()),
  );
  gh.factory<_i356.NotificationUseCase>(
    () => _i356.NotificationUseCase(gh<_i718.NotificationRepository>()),
  );
  gh.factory<_i234.AppointmentUseCase>(
    () => _i234.AppointmentUseCase(
      gh<_i639.AppointmentRepository>(),
      gh<_i443.UserRepository>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factoryParam<_i418.NurseDetailViewModel, String, dynamic>(
    (nurseId, _) => _i418.NurseDetailViewModel(
      gh<_i666.NurseDetailUseCase>(),
      gh<_i974.Logger>(),
      nurseId,
    ),
  );
  gh.factory<_i587.AddAppointmentViewModel>(
    () => _i587.AddAppointmentViewModel(
      gh<_i234.AppointmentUseCase>(),
      gh<_i144.DoctorUseCase>(),
      gh<_i785.AuthViewModel>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i157.HospitalUseCase>(
    () => _i157.HospitalUseCase(gh<_i343.HospitalRepository>()),
  );
  gh.factory<_i429.NurseAssignmentUseCase>(
    () => _i429.NurseAssignmentUseCase(
      gh<_i505.NurseAssignmentRepository>(),
      gh<_i974.Logger>(),
      gh<_i443.UserRepository>(),
    ),
  );
  gh.factoryParam<_i894.ArticleViewModel, String, dynamic>(
    (articleId, _) => _i894.ArticleViewModel(
      gh<_i160.ArticleUseCase>(),
      gh<_i974.Logger>(),
      articleId,
    ),
  );
  gh.factory<_i290.SuggestedFoodViewModel>(
    () => _i290.SuggestedFoodViewModel(
      gh<_i59.FoodUseCase>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i1005.LoginUseCase>(
    () => _i1005.LoginUseCase(gh<_i48.LoginRepository>()),
  );
  gh.factory<_i59.NurseDashboardUseCase>(
    () => _i59.NurseDashboardUseCase(
      gh<_i413.NurseRepository>(),
      gh<_i639.AppointmentRepository>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i736.DashboardUseCase>(
    () => _i736.DashboardUseCase(
      gh<_i1059.DashboardRepository>(),
      gh<_i639.AppointmentRepository>(),
    ),
  );
  gh.factory<_i437.DoctorDashboardViewModel>(
    () => _i437.DoctorDashboardViewModel(
      gh<_i234.AppointmentUseCase>(),
      gh<_i785.AuthViewModel>(),
      gh<_i505.NurseAssignmentRepository>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i155.VideoUseCase>(
    () => _i155.VideoUseCase(gh<_i1010.VideoRepository>()),
  );
  gh.factory<_i180.HospitalViewModel>(
    () => _i180.HospitalViewModel(
      gh<_i157.HospitalUseCase>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i428.AssignNurseViewModel>(
    () => _i428.AssignNurseViewModel(
      gh<_i1068.AssignNurseUseCase>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i808.ProfileUseCase>(
    () => _i808.ProfileUseCase(gh<_i1011.ProfileRepository>()),
  );
  gh.factory<_i8.AppointmentDetailViewModel>(
    () => _i8.AppointmentDetailViewModel(
      gh<_i234.AppointmentUseCase>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i417.RescheduleViewModel>(
    () => _i417.RescheduleViewModel(
      gh<_i234.AppointmentUseCase>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i68.PregnancyDetailViewModel>(
    () => _i68.PregnancyDetailViewModel(
      gh<_i870.PregnancyDetailUseCase>(),
      gh<_i785.AuthViewModel>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i149.ArticleListViewModel>(
    () => _i149.ArticleListViewModel(
      gh<_i160.ArticleUseCase>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i906.DashboardViewModel>(
    () => _i906.DashboardViewModel(
      gh<_i736.DashboardUseCase>(),
      gh<_i441.DatabaseHelper>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i850.RiskDetectorUseCase>(
    () => _i850.RiskDetectorUseCase(gh<_i844.RiskDetectorRepository>()),
  );
  gh.factory<_i181.ProfileViewModel>(
    () => _i181.ProfileViewModel(
      gh<_i808.ProfileUseCase>(),
      gh<_i785.AuthViewModel>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i517.PatientAppointmentsViewModel>(
    () => _i517.PatientAppointmentsViewModel(
      gh<_i234.AppointmentUseCase>(),
      gh<_i785.AuthViewModel>(),
      gh<_i974.Logger>(),
    ),
  );
  gh.factory<_i986.DoctorAppointmentsViewModel>(
    () => _i986.DoctorAppointmentsViewModel(
      gh<_i234.AppointmentUseCase>(),
      gh<_i785.AuthViewModel>(),
      gh<_i974.Logger>(),
    ),
  );
  return getIt;
}

class _$RegisterModule extends _i464.RegisterModule {}
