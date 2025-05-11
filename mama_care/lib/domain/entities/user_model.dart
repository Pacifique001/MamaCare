// lib/domain/entities/user_model.dart

import 'dart:convert'; // For jsonEncode/Decode
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' show User; // For fromFirebaseAuth factory
import 'package:flutter/foundation.dart'; // For @immutable
import 'package:mama_care/domain/entities/user_role.dart'; // Import UserRole enum and helpers

// Assuming helper functions exist (or define them below)
// UserRole userRoleFromString(String? roleString) { ... }
// String userRoleToString(UserRole role) { ... }

@immutable // Mark class as immutable
class UserModel extends Equatable {
  // --- Core Identifiers ---
  final String id; // Primary ID (can be local UUID or Firebase UID)
  final String? firebaseId; // Firebase Auth UID (nullable initially)

  // --- Profile Info ---
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final bool verified; // Email verification status
  final bool isActive;
  // --- Authentication/Metadata ---
  final String? password; // Hashed password (ONLY for local auth)
  final int createdAt; // Timestamp ms (non-nullable)
  final int? lastLogin; // Timestamp ms (nullable)
  final String? specialty;
  // --- App-Specific ---
  final UserRole role;
  final List<String> permissions;

  // --- Sync Status (If using local DB sync) ---
  final int syncStatus; // 0=Synced, 1=NeedsPush, 2=NeedsPull, 3=Error
  final int? lastSynced; // Timestamp ms

  // --- Constructor ---
  const UserModel({
    required this.id,
    this.firebaseId, // Nullable
    required this.name,
    required this.email,
    this.phoneNumber,
    this.password,
    this.profileImageUrl,
    required this.verified,
    required this.createdAt,
    this.specialty,
    this.isActive = true,
    this.lastLogin,
    required this.role,
    this.permissions = const [], // Default to empty list
    this.syncStatus = 0,
    this.lastSynced,
  });

  // --- Factory Constructors ---

  /// Creates a UserModel from a Firebase Auth User object upon successful authentication.
  /// **Note:** Role and Permissions will be default and need fetching from Firestore/backend.
  factory UserModel.fromFirebaseAuth(User firebaseUser, DocumentSnapshot doc,{UserRole defaultRole = UserRole.patient}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final data = doc.data() as Map<String, dynamic>;
    // Assign default permissions based on the default role
    final defaultPermissions = _getDefaultPermissionsForRoleStatic(defaultRole);
    return UserModel(
      id: firebaseUser.uid, // Use Firebase UID as primary ID
      firebaseId: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? 'New User',
      phoneNumber: firebaseUser.phoneNumber,
      profileImageUrl: firebaseUser.photoURL,
      verified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime?.millisecondsSinceEpoch ?? now,
      lastLogin: firebaseUser.metadata.lastSignInTime?.millisecondsSinceEpoch ?? now,
      isActive: data['isActive'] as bool? ?? true,
      role: defaultRole, // Assign default role initially
      permissions: defaultPermissions, // Assign default permissions initially
      password: null,
      syncStatus: 0,
      lastSynced: now,
    );
  }

   /// Creates a UserModel from a Map (e.g., from Firestore or local DB).
   /// Handles Timestamp conversion and parses role/permissions.
   factory UserModel.fromMap(Map<String, dynamic> map) {
     final now = DateTime.now().millisecondsSinceEpoch; // Fallback timestamp

     // Helper function to safely convert Timestamp or int to int (millis)
     int? timestampToIntMillis(dynamic value) {
       if (value == null) return null;
       if (value is Timestamp) return value.millisecondsSinceEpoch;
       if (value is int) return value;
       // Try parsing if it's a String representation of int
       if (value is String) return int.tryParse(value);
       print("Warning: Unexpected timestamp type: ${value.runtimeType}");
       return null;
     }

     return UserModel(
       // Prioritize 'id' from map, fallback needed if structure varies
       id: map['id'] as String? ?? map['firebaseId'] as String? ?? '',
       firebaseId: map['firebaseId'] as String? ?? map['id'] as String? ?? '', // Handle potential missing firebaseId
       email: map['email'] as String? ?? '',
       name: map['name'] as String? ?? 'Unnamed User',
       password: map['password'] as String?, // Load hashed password if exists
       phoneNumber: map['phoneNumber'] as String?,
       profileImageUrl: map['profileImageUrl'] as String?,
       verified: (map['verified'] == 1 || map['verified'] == true), // Handle int/bool
       createdAt: timestampToIntMillis(map['createdAt']) ?? now, // Use helper, default to now
       lastLogin: timestampToIntMillis(map['lastLogin']),      // Use helper
       syncStatus: map['syncStatus'] as int? ?? 0,
       lastSynced: timestampToIntMillis(map['lastSynced']),    // Use helper
       role: userRoleFromString(map['role'] as String?),     // Parse role from String
       permissions: _parsePermissions(map['permissions']),    // Parse permissions
     );
   }

   /// Provides an empty UserModel, useful for initial states or placeholders.
   factory UserModel.empty() {
     final now = DateTime.now().millisecondsSinceEpoch;
     return UserModel(
       id: '',
       firebaseId: null, // No Firebase ID for empty user
       name: '',
       email: '',
       verified: false,
       createdAt: now,
       role: UserRole.unknown,
       permissions: [],
       syncStatus: 0,
     );
   }


  // --- Serialization ---

  /// Converts instance to a map suitable for Firestore storage.
  /// Uses Timestamps for dates, stores permissions list directly.
  Map<String, dynamic> toFirestoreMap() {
    return {
      // Usually doc ID is 'id' or 'firebaseId', so don't store in map data itself
      'email': email.toLowerCase(), // Store consistent case
      'name': name,
      'phoneNumber': phoneNumber, // Keep null if null
      'profileImageUrl': profileImageUrl, // Keep null if null
      'verified': verified, // Store bool
      // Convert int (millis) back to Firestore Timestamp
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(createdAt),
      'lastLogin': lastLogin == null ? null : Timestamp.fromMillisecondsSinceEpoch(lastLogin!),
      'role': userRoleToString(role), // Enum to String
      'permissions': permissions, // Store List<String> directly
      // Add sync/update timestamps managed by Firestore
      // 'fcmTokens' & 'fcmTokenLastUpdated' might be managed separately or here
      'lastUpdated': FieldValue.serverTimestamp(), // General update timestamp
    };
  }

   /// Converts to a map suitable for SQLite storage (bools as ints, lists as JSON).
   Map<String, dynamic> toSqliteMap() {
     return {
       'id': id, // Crucial for SQLite PK
       'firebaseId': firebaseId, // Store link to Firebase Auth
       'email': email.toLowerCase(),
       'name': name,
       'password': password, // Include password hash if using local auth
       'phoneNumber': phoneNumber,
       'profileImageUrl': profileImageUrl,
       'verified': verified ? 1 : 0, // Convert bool to int
       'createdAt': createdAt, // Store millis int
       'lastLogin': lastLogin, // Store millis int
       'syncStatus': syncStatus, // Store int status
       'lastSynced': lastSynced, // Store millis int
       'role': userRoleToString(role), // Store enum as string
       'permissions': jsonEncode(permissions), // Encode list to JSON string
     };
   }

  // Aliases for consistency if using json_serializable or other contexts
  Map<String, dynamic> toJson() => toFirestoreMap(); // Default to Firestore map
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);


  // --- Equatable Overrides ---
  @override
  List<Object?> get props => [
        id, firebaseId, name, email, phoneNumber, profileImageUrl, verified,
        createdAt, lastLogin, syncStatus, lastSynced,
        role, permissions
        // Exclude password from equality checks for security/consistency
      ];

  @override
  bool get stringify => true;

  // --- CopyWith Method ---
  /// Creates a copy of this UserModel, replacing specified fields.
  /// Use `setFieldNameNull: true` to explicitly set nullable fields to null.
  UserModel copyWith({
    String? id,
    String? firebaseId, bool setFirebaseIdNull = false,
    String? name,
    String? email,
    String? phoneNumber, bool setPhoneNumberNull = false,
    String? password, bool setPasswordNull = false,
    String? profileImageUrl, bool setProfileImageUrlNull = false,
    bool? verified,
    int? createdAt,
    int? lastLogin, bool setLastLoginNull = false,
    int? syncStatus,
    int? lastSynced, bool setLastSyncedNull = false,
    UserRole? role,
    List<String>? permissions,
  }) {
    return UserModel(
      id: id ?? this.id,
      firebaseId: setFirebaseIdNull ? null : (firebaseId ?? this.firebaseId),
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: setPhoneNumberNull ? null : (phoneNumber ?? this.phoneNumber),
      password: setPasswordNull ? null : (password ?? this.password),
      profileImageUrl: setProfileImageUrlNull ? null : (profileImageUrl ?? this.profileImageUrl),
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: setLastLoginNull ? null : (lastLogin ?? this.lastLogin),
      syncStatus: syncStatus ?? this.syncStatus,
      lastSynced: setLastSyncedNull ? null : (lastSynced ?? this.lastSynced),
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
    );
  }

  // --- Helper Methods ---

   /// Helper to parse permissions list from DB/Firestore (handles String or List).
   static List<String> _parsePermissions(dynamic dbValue) {
      if (dbValue == null) return [];
      if (dbValue is List) {
         // If it's already a list, ensure elements are strings
         return List<String>.from(dbValue.map((p) => p.toString()));
      }
      if (dbValue is String) { // If it's a JSON string (e.g., from SQLite)
         if (dbValue.isEmpty || dbValue == '[]') return []; // Handle empty string/array
         try {
           final decoded = jsonDecode(dbValue);
           if (decoded is List) {
              return List<String>.from(decoded.map((p) => p.toString()));
           }
         } catch (e) {
            print("Warning: Failed to decode permissions JSON string: $dbValue - Error: $e");
         }
      }
       print("Warning: Unexpected type for permissions data: ${dbValue.runtimeType}");
      return const []; // Default empty list for other types or errors
   }

   /// Static version of default permissions helper for use in factories.
   static List<String> _getDefaultPermissionsForRoleStatic(UserRole role) {
     switch (role) {
       case UserRole.patient: return ['view_profile', 'view_appointments', 'request_appointment', 'view_articles', 'view_videos', 'view_timeline', 'view_calendar'];
       case UserRole.nurse: return ['view_profile', 'view_assigned_patients', 'manage_own_appointments', 'edit_patient_notes', 'view_articles', 'view_videos'];
       case UserRole.doctor: return ['view_profile', 'view_all_patients', 'manage_appointments', 'assign_nurse', 'manage_nurses', 'view_reports', 'edit_articles', 'edit_videos'];
       case UserRole.admin: return ['manage_users', 'manage_roles', 'manage_content', 'view_all_data', 'configure_settings'];
       case UserRole.unknown: default: return [];
     }
   }

   // --- Convenience Getters ---
   bool get isVerified => verified;
   bool get hasPhoneNumber => phoneNumber != null && phoneNumber!.isNotEmpty;
   DateTime? get lastLoginDate => lastLogin != null ? DateTime.fromMillisecondsSinceEpoch(lastLogin!) : null;
   DateTime get creationDate => DateTime.fromMillisecondsSinceEpoch(createdAt);

}

// --- Helper Functions (Define these globally or in a shared utility file) ---

/// Converts a role string (from DB/Firestore) back to UserRole enum.
UserRole userRoleFromString(String? roleString) {
  if (roleString == null) return UserRole.unknown;
  return UserRole.values.firstWhere(
     (e) => e.name.toLowerCase() == roleString.toLowerCase(), // Use .name (Dart 2.15+)
     orElse: () => UserRole.unknown,
  );
}

/// Converts UserRole enum to its string representation for storage.
//String userRoleToString(UserRole role) {
   //return role.name; // Use .name (Dart 2.15+)
//}