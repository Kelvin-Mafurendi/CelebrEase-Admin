// In database_config.dart
import 'package:celebrease_manager/States/changemanger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class MigrationHistory {
  final String collectionName;
  final String backupCollectionName;
  final DateTime timestamp;
  final int processedDocs;
  final int updatedDocs;

  MigrationHistory({
    required this.collectionName,
    required this.backupCollectionName,
    required this.timestamp,
    required this.processedDocs,
    required this.updatedDocs,
  });

  Map<String, dynamic> toMap() {
    return {
      'collectionName': collectionName,
      'backupCollectionName': backupCollectionName,
      'timestamp': timestamp,
      'processedDocs': processedDocs,
      'updatedDocs': updatedDocs,
    };
  }

  factory MigrationHistory.fromMap(Map<String, dynamic> map) {
    return MigrationHistory(
      collectionName: map['collectionName'],
      backupCollectionName: map['backupCollectionName'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      processedDocs: map['processedDocs'],
      updatedDocs: map['updatedDocs'],
    );
  }
}

class MigrationConfig {
  final String collectionName;
  final Map<String, dynamic> defaultValues;
  final Map<String, String> fieldNameChanges;
  final List<String> requiredFields;
  final Map<String, dynamic> Function(
      Map<String, dynamic>, ChangeManager manager)? dataTransformer;

  MigrationConfig({
    required this.collectionName,
    required this.defaultValues,
    this.fieldNameChanges = const {},
    this.requiredFields = const [],
    this.dataTransformer,
  });
}

class MigrationResult {
  final bool success;
  final String backupCollectionName;
  final int processedDocs;
  final int updatedDocs;
  final String? error;

  MigrationResult({
    required this.success,
    required this.backupCollectionName,
    required this.processedDocs,
    required this.updatedDocs,
    this.error,
  });
}

final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

extension MigrationManager on ChangeManager {
  static final Map<String, MigrationConfig> migrationConfigs = {
    'Services': MigrationConfig(
      collectionName: 'Services',
      defaultValues: {
        'hidden': 'false',
        'status': 'active',
        'featured': false,
        'priority': 0,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'timeStamp': FieldValue.serverTimestamp(),
      },
      fieldNameChanges: {
        'imagePath': 'servicePic',
        'iconPath': 'serviceIcon',
      },
      requiredFields: ['serviceName', 'description'],
      dataTransformer: (data, manager) {
        if (data.containsKey('serviceName')) {
          data['searchServiceName'] =
              manager.generateSearchVariations(data['serviceName']);
        }
        return data;
      },
    ),
    'Packages': MigrationConfig(
      collectionName: 'Packages',
      defaultValues: {
        'hidden': false,
        'status': 'active',
        'featured': false,
        'priority': 0,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'timeStamp': FieldValue.serverTimestamp(),
      },
      fieldNameChanges: {
        'mainImagePath': 'packagePic',
        'videoUrl': 'videoPath',
      },
      requiredFields: ['packageName', 'rate'],
      dataTransformer: (data, manager) {
        if (data.containsKey('packageName')) {
          data['searchPackageName'] =
              manager.generateSearchVariations(data['packageName']);
        }
        return data;
      },
    ),
    'Banners': MigrationConfig(
      collectionName: 'Banners',
      defaultValues: {
        'active': true,
        'priority': 0,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'timeStamp': FieldValue.serverTimestamp(),
      },
      fieldNameChanges: {
        'image': 'bannerImage',
      },
      requiredFields: ['title'],
    ),
  };

  // Migrate a collection with the given configuration.
  Future<MigrationResult> migrateCollection(String collectionName) async {
    try {
      EasyLoading.show(status: 'Migrating $collectionName...');
      final config = migrationConfigs[collectionName];
      if (config == null) {
        throw Exception('No migration config found for $collectionName');
      }

      // Create backup collection name with timestamp
      final backupCollection =
          '${collectionName}_backup_${DateTime.now().millisecondsSinceEpoch}';
      final snapshot = await _fireStore.collection(collectionName).get();

      // Create backup
      for (var doc in snapshot.docs) {
        await _fireStore
            .collection(backupCollection)
            .doc(doc.id)
            .set(doc.data());
      }

      int totalDocs = snapshot.docs.length;
      int processedDocs = 0;
      int updatedDocs = 0;
      WriteBatch batch = _fireStore.batch();
      int batchCount = 0;

      for (var doc in snapshot.docs) {
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};
        Map<String, dynamic> currentData = Map.from(doc.data());

        // Handle field name changes first
        for (var entry in config.fieldNameChanges.entries) {
          String oldField = entry.key;
          String newField = entry.value;
          if (currentData.containsKey(oldField)) {
            updates[newField] = currentData[oldField];
            // Remove old field
            updates[oldField] = FieldValue.delete();
            needsUpdate = true;
          }
        }

        // Handle default values
        for (var entry in config.defaultValues.entries) {
          if (!currentData.containsKey(entry.key)) {
            updates[entry.key] = entry.value;
            needsUpdate = true;
          }
        }

        // Apply data transformer if provided
        if (config.dataTransformer != null) {
          Map<String, dynamic> transformedData =
              config.dataTransformer!(currentData, this);
          updates.addAll(transformedData);
          needsUpdate = true;
        }

        // Ensure document ID matches collection-specific ID field
        String idFieldName =
            '${collectionName.toLowerCase().substring(0, collectionName.length - 1)}Id';
        if (!currentData.containsKey(idFieldName) ||
            currentData[idFieldName] != doc.id) {
          updates[idFieldName] = doc.id;
          needsUpdate = true;
        }

        // Add timestamp fields
        if (!currentData.containsKey('createdAt')) {
          updates['createdAt'] = FieldValue.serverTimestamp();
          needsUpdate = true;
        }
        updates['updatedAt'] = FieldValue.serverTimestamp();

        // Apply updates if needed
        if (needsUpdate) {
          batch.set(doc.reference, updates, SetOptions(merge: true));
          batchCount++;
          updatedDocs++;
        }

        // Commit batch updates in chunks
        if (batchCount >= 400) {
          await batch.commit();
          batch = _fireStore.batch();
          batchCount = 0;
        }

        processedDocs++;
        EasyLoading.showProgress(processedDocs / totalDocs,
            status: 'Migrating $processedDocs/$totalDocs');
      }

      // Commit any remaining updates
      if (batchCount > 0) {
        await batch.commit();
      }

      EasyLoading.showSuccess(
        'Migration complete\n$updatedDocs documents updated',
        duration: const Duration(seconds: 3),
      );

      return MigrationResult(
        success: true,
        backupCollectionName: backupCollection,
        processedDocs: processedDocs,
        updatedDocs: updatedDocs,
      );
    } catch (e) {
      print('Error during migration: $e');
      EasyLoading.showError('Migration failed: ${e.toString()}');
      return MigrationResult(
        success: false,
        backupCollectionName: '',
        processedDocs: 0,
        updatedDocs: 0,
        error: e.toString(),
      );
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<bool> rollbackMigration(
      String collectionName, String backupCollectionName) async {
    try {
      EasyLoading.show(status: 'Rolling back migration...');

      // Get all documents from backup
      final backupSnapshot =
          await _fireStore.collection(backupCollectionName).get();

      WriteBatch batch = _fireStore.batch();
      int batchCount = 0;

      // Delete current collection documents and restore from backup
      final currentSnapshot = await _fireStore.collection(collectionName).get();

      // Delete current documents
      for (var doc in currentSnapshot.docs) {
        batch.delete(doc.reference);
        batchCount++;

        if (batchCount >= 400) {
          await batch.commit();
          batch = _fireStore.batch();
          batchCount = 0;
        }
      }

      // Restore backup documents
      for (var doc in backupSnapshot.docs) {
        final ref = _fireStore.collection(collectionName).doc(doc.id);
        batch.set(ref, doc.data());
        batchCount++;

        if (batchCount >= 400) {
          await batch.commit();
          batch = _fireStore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      EasyLoading.showSuccess('Rollback completed successfully');
      return true;
    } catch (e) {
      print('Error during rollback: $e');
      EasyLoading.showError('Rollback failed: ${e.toString()}');
      return false;
    } finally {
      EasyLoading.dismiss();
    }
  }
}

extension MigrationHistoryManager on ChangeManager {
  Future<void> saveMigrationHistory(
      MigrationResult result, String collectionName) async {
    if (!result.success) return;

    final history = MigrationHistory(
      collectionName: collectionName,
      backupCollectionName: result.backupCollectionName,
      timestamp: DateTime.now(),
      processedDocs: result.processedDocs,
      updatedDocs: result.updatedDocs,
    );

    await _fireStore
        .collection('migrationHistory')
        .doc(collectionName)
        .set(history.toMap());
  }

  Future<MigrationHistory?> getMigrationHistory(String collectionName) async {
    final doc = await _fireStore
        .collection('migrationHistory')
        .doc(collectionName)
        .get();

    if (!doc.exists) return null;
    return MigrationHistory.fromMap(doc.data()!);
  }

  Future<List<MigrationHistory>> getAllMigrationHistory() async {
    final snapshot = await _fireStore
        .collection('migrationHistory')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MigrationHistory.fromMap(doc.data()))
        .toList();
  }

  Future<void> deleteMigrationHistory(String collectionName) async {
    await _fireStore
        .collection('migrationHistory')
        .doc(collectionName)
        .delete();
  }
}
