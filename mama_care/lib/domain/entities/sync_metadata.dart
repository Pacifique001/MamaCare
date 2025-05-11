// lib/domain/entities/sync_metadata.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SyncMetadata {
  final String id;
  final DateTime lastSync;
  final String collectionName;
  final int retryCount;
  final String? lastError;

  const SyncMetadata({
    required this.id,
    required this.lastSync,
    required this.collectionName,
    this.retryCount = 0,
    this.lastError,
  });

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      id: json['id'] as String,
      lastSync: DateTime.fromMillisecondsSinceEpoch(json['lastSync'] as int),
      collectionName: json['collectionName'] as String,
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
    );
  }

  factory SyncMetadata.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SyncMetadata(
      id: doc.id,
      lastSync: (data['lastSync'] as Timestamp).toDate(),
      collectionName: data['collectionName'] as String,
      retryCount: data['retryCount'] as int? ?? 0,
      lastError: data['lastError'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lastSync': lastSync.millisecondsSinceEpoch,
      'collectionName': collectionName,
      'retryCount': retryCount,
      'lastError': lastError,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lastSync': Timestamp.fromDate(lastSync),
      'collectionName': collectionName,
      'retryCount': retryCount,
      'lastError': lastError,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  SyncMetadata copyWith({
    String? id,
    DateTime? lastSync,
    String? collectionName,
    int? retryCount,
    String? lastError,
  }) {
    return SyncMetadata(
      id: id ?? this.id,
      lastSync: lastSync ?? this.lastSync,
      collectionName: collectionName ?? this.collectionName,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SyncMetadata &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            lastSync == other.lastSync &&
            collectionName == other.collectionName &&
            retryCount == other.retryCount &&
            lastError == other.lastError);
  }

  @override
  int get hashCode =>
      id.hashCode ^
      lastSync.hashCode ^
      collectionName.hashCode ^
      retryCount.hashCode ^
      lastError.hashCode;

  @override
  String toString() {
    return 'SyncMetadata{'
        'id: $id, '
        'lastSync: $lastSync, '
        'collectionName: $collectionName, '
        'retryCount: $retryCount, '
        'lastError: $lastError}';
  }

  // Validation methods
  bool isValid() => id.isNotEmpty && collectionName.isNotEmpty;

  static SyncMetadata initial(String collectionName) {
    assert(collectionName.isNotEmpty, 'Collection name cannot be empty');
    return SyncMetadata(
      id: 'sync_$collectionName',
      lastSync: DateTime(1970),
      collectionName: collectionName,
    );
  }
}