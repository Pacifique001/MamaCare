import 'package:injectable/injectable.dart';
import 'package:mama_care/injection.config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
//import 'package:mama_care/navigation/navigation_service.dart';

import 'package:uuid/uuid.dart';

// Mock classes for Linux platform
class MockFirebaseAuth implements FirebaseAuth {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return null or mock implementations as needed
    return null;
  }
}

class MockFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return null or mock implementations as needed
    return null;
  }
}

class MockFirebaseMessaging implements FirebaseMessaging {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return null or mock implementations as needed
    return null;
  }
}

class MockGoogleSignIn implements GoogleSignIn {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return null or mock implementations as needed
    return null;
  }
}

final locator = GetIt.instance;
final _logger = Logger();

@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
Future<void> configureDependencies() async {
  // Call the generated dependency initializer
  await $initGetIt(locator);
}

// External dependencies need to be registered
@module
abstract class RegisterModule {
  @singleton
  FirebaseAuth get firebaseAuth {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      _logger.i('Using mock FirebaseAuth for Linux platform');
      return MockFirebaseAuth();
    }
    return FirebaseAuth.instance;
  }

  @singleton
  FirebaseFirestore get firebaseFirestore {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      _logger.i('Using mock FirebaseFirestore for Linux platform');
      return MockFirebaseFirestore();
    }
    return FirebaseFirestore.instance;
  }

  @singleton
  FirebaseMessaging get firebaseMessaging {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      _logger.i('Using mock FirebaseMessaging for Linux platform');
      return MockFirebaseMessaging();
    }
    return FirebaseMessaging.instance;
  }

  @singleton
  GoogleSignIn get googleSignIn {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      _logger.i('Using mock GoogleSignIn for Linux platform');
      return MockGoogleSignIn();
    }
    return GoogleSignIn();
  }

  @singleton
  Dio get dio => Dio();

  @singleton
  DatabaseHelper get databaseHelper => DatabaseHelper();

  @singleton // Register Uuid
  Uuid get uuid => const Uuid();

  @singleton
  Logger get logger => Logger();
}