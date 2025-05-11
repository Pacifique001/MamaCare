// lib/domain/entities/user_role.dart (New File)

enum UserRole {
  patient,
  nurse,
  doctor,
  admin, // Optional: For administrative users
  unknown // Default or for unassigned roles
}

// Helper function to parse string to enum (case-insensitive)
UserRole userRoleFromString(String? roleString) {
  switch (roleString?.toLowerCase()) {
    case 'patient':
      return UserRole.patient;
    case 'nurse':
      return UserRole.nurse;
    case 'doctor':
      return UserRole.doctor;
    case 'admin':
       return UserRole.admin;
    default:
      return UserRole.unknown;
  }
}

// Helper function to convert enum to string for storage
String userRoleToString(UserRole role) {
  return role.toString().split('.').last;
}