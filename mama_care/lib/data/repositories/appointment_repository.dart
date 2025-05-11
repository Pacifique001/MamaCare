// lib/data/repositories/appointment_repository.dart

import 'package:cloud_firestore_platform_interface/src/timestamp.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/appointment_status.dart'; // Import enum

abstract class AppointmentRepository {
  Future<String> createAppointment(Appointment appointment);

  // Accept enum for status filtering
  Future<List<Appointment>> getPatientAppointments(
    String patientId, {
    AppointmentStatus? status,
  });
  Future<List<Appointment>> getDoctorAppointments(
    String doctorId, {
    AppointmentStatus? status,
  }); // Change Future<List> to Stream if needed
  // Stream<List<Appointment>> getDoctorAppointmentsStream(String doctorId, {AppointmentStatus? status}); // Example stream version

  Future<Appointment?> getAppointmentById(String appointmentId);

  // Method specific to updating status - accepts enum
  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  );

  // Generic update (less common if specific updates exist)
  Future<void> updateAppointment(Appointment appointment);

  Future<void> deleteAppointment(String appointmentId);

  // Combined fetch
  Future<List<Appointment>> getUserAppointments(String userId);

  Future<void> updateAppointmentDateTime(String appointmentId, Timestamp newTimestamp);
}
