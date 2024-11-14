import 'package:celebrease_manager/States/changemanger.dart';
import 'package:celebrease_manager/States/database_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CollectionMigrationDialog extends StatefulWidget {
  const CollectionMigrationDialog({super.key});

  @override
  State<CollectionMigrationDialog> createState() => _CollectionMigrationDialogState();
}

class _CollectionMigrationDialogState extends State<CollectionMigrationDialog> {
  String? lastMigratedCollection;
  String? lastBackupCollection;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: CollectionMigrationContent(
        onMigrationComplete: (collection, backup) {
          setState(() {
            lastMigratedCollection = collection;
            lastBackupCollection = backup;
          });
        },
        lastMigratedCollection: lastMigratedCollection,
        lastBackupCollection: lastBackupCollection,
      ),
    );
  }
}

class CollectionMigrationContent extends StatelessWidget {
  final Function(String, String)? onMigrationComplete;
  final String? lastMigratedCollection;
  final String? lastBackupCollection;

  const CollectionMigrationContent({
    super.key,
    this.onMigrationComplete,
    this.lastMigratedCollection,
    this.lastBackupCollection,
  });

  @override
  Widget build(BuildContext context) {
    final collections = MigrationManager.migrationConfigs;

    return Container(
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Database Migration Tool',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (lastMigratedCollection != null && lastBackupCollection != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Migration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Collection: $lastMigratedCollection'),
                      Text('Backup: $lastBackupCollection'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Rollback'),
                              content: Text(
                                'This will restore $lastMigratedCollection to its previous state. '
                                'Are you sure you want to continue?'
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Proceed'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final changeManager = Provider.of<ChangeManager>(
                              context,
                              listen: false,
                            );
                            await changeManager.rollbackMigration(
                              lastMigratedCollection!,
                              lastBackupCollection!,
                            );
                          }
                        },
                        icon: const Icon(Icons.restore),
                        label: const Text('Rollback Migration'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: collections.length,
              itemBuilder: (context, index) {
                final name = collections.keys.elementAt(index);
                final config = collections[name]!;
                
                return CollectionCard(
                  name: name,
                  config: config,
                  onTap: () async {
                    bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Migration'),
                        content: Text(
                          'This will update all existing documents in the "$name" collection. '
                          'A backup will be created before proceeding. Continue?'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Proceed'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final changeManager = Provider.of<ChangeManager>(
                        context,
                        listen: false,
                      );
                      final result = await changeManager.migrateCollection(name);
                      if (result.success) {
                        onMigrationComplete?.call(name, result.backupCollectionName);
                      }
                    }
                  },
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CollectionCard extends StatelessWidget {
  final String name;
  final MigrationConfig config;
  final VoidCallback onTap;

  const CollectionCard({
    super.key,
    required this.name,
    required this.config,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storage, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Fields: ${config.requiredFields.join(", ")}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (config.fieldNameChanges.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Field Changes:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: config.fieldNameChanges.entries.map((entry) => Chip(
                    label: Text(
                      '${entry.key} → ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )).toList(),
                ),
              ],
              if (config.defaultValues.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Default Values:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: config.defaultValues.entries
                      .where((e) => e.value is! FieldValue)
                      .map((entry) => Chip(
                    label: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}