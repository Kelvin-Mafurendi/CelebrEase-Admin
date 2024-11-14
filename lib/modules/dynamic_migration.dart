import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:celebrease_manager/States/changemanger.dart';
import 'package:celebrease_manager/States/database_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a dynamic migration configuration.
class DynamicMigrationConfig {
  String collectionName;
  Map<String, String> fieldNameChanges;
  Map<String, dynamic> defaultValues;
  List<String> requiredFields;

  DynamicMigrationConfig({
    required this.collectionName,
    this.fieldNameChanges = const {},
    this.defaultValues = const {},
    this.requiredFields = const [],
  });

  // Converts the dynamic configuration into the static MigrationConfig.
  MigrationConfig toMigrationConfig() {
    return MigrationConfig(
      collectionName: collectionName,
      fieldNameChanges: fieldNameChanges,
      defaultValues: defaultValues,
      requiredFields: requiredFields,
    );
  }
}

// Implements the dialog for dynamic migration configuration.
class DynamicMigrationDialog extends StatefulWidget {
  const DynamicMigrationDialog({super.key});

  @override
  State<DynamicMigrationDialog> createState() => _DynamicMigrationDialogState();
}

class _DynamicMigrationDialogState extends State<DynamicMigrationDialog> {
  final _formKey = GlobalKey<FormState>();
  late DynamicMigrationConfig _config;
  String? _selectedCollection;
  List<String> _collections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _config = DynamicMigrationConfig(collectionName: '');
    _loadCollections();
  }

  // First, create a metadata collection with your collections list
  Future<void> updateCollectionsMetadata() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    print('Function ON');
    final meta =
        await firestore.collection('metadata').doc('collections').get();
    print('Looking for metadata collection');

    if (meta.exists && meta.data() != null && meta.data()!.isNotEmpty) {
      print('Found it...updating now...');
      await firestore.collection('metadata').doc('collections').set({
        'collections': [
          'Vendors',
          'Customers',
          'chats',
          'Packages',
          'Highlights',
          'FlashAds',
          'banners',
          'Services',
          'Pending',
          'Cart',
          'Shared Cart',
          'proposals',
          'notifications',
          'calls',
          'vendor_availability',
          'user_tokens',
        ], // Your collections
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('Done Updating...');
    } else {
      print('Not available...attempting to create...');
      await initializeMetadata();
      // updateCollectionsMetadata();
    }
  }

  Future<void> initializeMetadata() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    print('Creating metadata collection');
    await firestore.collection('metadata').doc('collections').set({
      'collections': [
        'Vendors',
        'Customers',
        'chats',
        'Packages',
        'Highlights',
        'FlashAds',
        'banners',
        'Services',
        'Pending',
        'Cart',
        'Shared Cart',
        'proposals',
        'notifications',
        'calls',
        'vendor_availability',
        'user_tokens',
      ],
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    print('Done, creating!');
  }

// Then use this method to load collections
  Future<void> _loadCollections() async {
    setState(() => _isLoading = true);
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final metadataDoc =
          await firestore.collection('metadata').doc('collections').get();

      if (!metadataDoc.exists) {
        throw Exception('Collections metadata not found');
      }

      final collections =
          List<String>.from(metadataDoc.data()?['collections'] ?? []);

      // Verify collections still exist and have data
      final verifiedCollections = <String>[];
      for (final collection in collections) {
        final query = await firestore.collection(collection).limit(1).get();
        if (query.docs.isNotEmpty) {
          verifiedCollections.add(collection);
        }
      }

      if (mounted) {
        setState(() {
          _collections = verifiedCollections;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading collections: $e')),
        );
        updateCollectionsMetadata();
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCollectionSelector(),
                      if (_selectedCollection != null) ...[
                        const SizedBox(height: 24),
                        _buildFieldChangesSection(),
                        const SizedBox(height: 24),
                        _buildDefaultValuesSection(),
                        const SizedBox(height: 24),
                        _buildRequiredFieldsSection(),
                      ],
                    ],
                  ),
                ),
              ),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the header section of the dialog.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings_applications, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Custom Collection Migration',
            textScaler: const TextScaler.linear(0.6),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          IconButton(
              onPressed: () async {
                try {
                  EasyLoading.show(status: 'Updating collections metadata');
                  await updateCollectionsMetadata();
                } catch (e) {
                  print('Error updating metadata: $e');
                } finally {
                  EasyLoading.dismiss();
                }
              },
              icon: Icon(FluentSystemIcons.ic_fluent_duo_update_regular))
        ],
      ),
    );
  }

  // Builds the collection selector dropdown.
  Widget _buildCollectionSelector() {
    // Debug print to check values
    print('Collections: $_collections');
    print('Selected Collection: $_selectedCollection');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Collection',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const CircularProgressIndicator()
        else if (_collections.isEmpty) // Add check for empty collections
          const Text('No collections available')
        else
          DropdownButtonFormField<String>(
            value: _selectedCollection, // Make sure this is null initially
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select a collection to migrate',
            ),
            items: _collections.map((String collection) {
              return DropdownMenuItem(
                value: collection,
                child: Text(collection),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() => _selectedCollection = value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a collection';
              }
              return null;
            },
          ),
      ],
    );
  }

  // Builds the field changes section with dynamic input fields.
  Widget _buildFieldChangesSection() {
    return _buildDynamicSection(
      title: 'Field Name Changes',
      subtitle: 'Specify old field names and their new names',
      itemBuilder: (remove) => _FieldNameChangeInput(
        onChanged: (oldName, newName) {
          setState(() {
            _config.fieldNameChanges[oldName] = newName;
          });
        },
        onRemoved: remove,
      ),
    );
  }

  // Builds the default values section with dynamic input fields.
  Widget _buildDefaultValuesSection() {
    return _buildDynamicSection(
      title: 'Default Values',
      subtitle: 'Add default values for new or existing fields',
      itemBuilder: (remove) => _DefaultValueInput(
        onChanged: (field, value) {
          setState(() {
            _config.defaultValues[field] = value;
          });
        },
        onRemoved: remove,
      ),
    );
  }

  // Builds the required fields section with dynamic input fields.
  Widget _buildRequiredFieldsSection() {
    return _buildDynamicSection(
      title: 'Required Fields',
      subtitle: 'Specify fields that must exist in the collection',
      itemBuilder: (remove) => _RequiredFieldInput(
        onChanged: (field) {
          setState(() {
            if (!_config.requiredFields.contains(field)) {
              _config.requiredFields.add(field);
            }
          });
        },
        onRemoved: remove,
      ),
    );
  }

  // A helper function to build dynamic sections with varying input types.
  Widget _buildDynamicSection({
    required String title,
    required String subtitle,
    required Widget Function(VoidCallback) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        _DynamicList(itemBuilder: itemBuilder),
      ],
    );
  }

  // Builds the actions section with buttons for cancellation and migration execution.
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _executeMigration,
            child: const Text('Start Migration'),
          ),
        ],
      ),
    );
  }

  // Executes the migration process after validation and confirmation.
  Future<void> _executeMigration() async {
    if (!_formKey.currentState!.validate()) return;
    final changeManager = Provider.of<ChangeManager>(context, listen: false);
    _config.collectionName = _selectedCollection!;

    // Confirmation dialog before proceeding with the migration.
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Migration'),
        content: Text(
            'This will update all documents in the "${_config.collectionName}" collection. '
            'A backup will be created before proceeding. Continue?'),
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
      // Add the dynamic config to the migration configs
      MigrationManager.migrationConfigs[_config.collectionName] =
          _config.toMigrationConfig();
      final result =
          await changeManager.migrateCollection(_config.collectionName);
      if (result.success) {
        Navigator.pop(context, result);
      }
    }
  }
}

// Manages a dynamic list of input widgets.
class _DynamicList extends StatefulWidget {
  final Widget Function(VoidCallback) itemBuilder;

  const _DynamicList({required this.itemBuilder});

  @override
  State<_DynamicList> createState() => _DynamicListState();
}

class _DynamicListState extends State<_DynamicList> {
  final List<UniqueKey> _items = [];

  void _addItem() {
    setState(() {
      _items.add(UniqueKey());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._items.map((key) {
          return widget.itemBuilder(() {
            setState(() => _items.remove(key));
          });
        }),
        OutlinedButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }
}

// Input widget for specifying field name changes.
class _FieldNameChangeInput extends StatelessWidget {
  final Function(String, String) onChanged;
  final VoidCallback onRemoved;

  const _FieldNameChangeInput({
    required this.onChanged,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return _buildInputRow(
      children: [
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Old Field Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (oldName) => onChanged(oldName, ''),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'New Field Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (newName) => onChanged('', newName),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ),
      ],
    );
  }
}

// Input widget for specifying default values for fields.
class _DefaultValueInput extends StatelessWidget {
  final Function(String, dynamic) onChanged;
  final VoidCallback onRemoved;

  const _DefaultValueInput({
    required this.onChanged,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return _buildInputRow(
      children: [
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Field Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (field) => onChanged(field, null),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Default Value',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => onChanged('', value),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ),
      ],
    );
  }
}

// Input widget for specifying required fields.
class _RequiredFieldInput extends StatelessWidget {
  final Function(String) onChanged;
  final VoidCallback onRemoved;

  const _RequiredFieldInput({
    required this.onChanged,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return _buildInputRow(
      children: [
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Field Name',
              border: OutlineInputBorder(),
            ),
            onChanged: onChanged,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ),
      ],
    );
  }
}

// Helper function to build a row for input widgets.
Widget _buildInputRow({
  required List<Widget> children,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        ...children,
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () {},
          color: Colors.red,
        ),
      ],
    ),
  );
}
