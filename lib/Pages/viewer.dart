import 'package:celebrease_manager/modules/3dotMenu.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluentui_icons/fluentui_icons.dart';

class DetailScreen extends StatefulWidget {
  final String collectionName;
  final String document;

  const DetailScreen({
    super.key,
    required this.collectionName,
    required this.document,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  late Map<String, dynamic> data = {};
  void getData() async {
    DocumentSnapshot<Map<String, dynamic>> data1 = await _fireStore
        .collection(widget.collectionName)
        .doc(widget.document)
        .get();

    setState(() {
      data = data1.data()!;
    });
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            actions: [
              ThreeDotMenu(
                  items: ['Hide This', 'Delete This'],
                  type: widget.collectionName,
                  id: widget.document)
            ],
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                data.isNotEmpty
                    ? (data['business name'] ??
                        data['packageName'] ??
                        data['title'] ??
                        data['serviceName'] ??
                        data['bannerName'] ??
                        data['name'] ??
                        (widget.document != '' && widget.document.length < 20
                            ? widget.document
                            : 'No Name')) // Provide a default value if all are null
                    : 'Loading...', // Fallback text while data is being loaded
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image with gradient overlay
                  Hero(
                    tag: 'item_${widget.document}',
                    child: (data['profilePic'] ??
                                data['packagePic'] ??
                                data['adPic'] ??
                                data['servicePic'] ??
                                data['bannerPic'] ??
                                data['imagePath']) !=
                            null
                        ? Image.network(
                            data['profilePic'] ??
                                data['packagePic'] ??
                                data['adPic'] ??
                                data['bannerPic'] ??
                                data['servicePic'] ??
                                data['imagePath']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(context),
                          )
                        : _buildPlaceholder(context),
                  ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entries = data.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key));

                  if (index >= entries.length) return null;

                  final entry = entries[index];
                  // Skip imageUrl as it's shown in the app bar
                  if (entry.key == 'profilePic') return null;

                  return _buildFieldCard(context, entry.key, entry.value);
                },
                childCount: data.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.2),
      child: const Icon(
        FluentSystemIcons.ic_fluent_image_regular,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildFieldCard(BuildContext context, String key, dynamic value) {
    // Format the key for display
    final displayKey = key
        .split('_') // Split by underscore
        .map((word) => word.capitalize()) // Capitalize each word
        .join(' '); // Join with spaces

    // Format the value based on its type
    Widget valueWidget;

    if (value == null) {
      valueWidget = const Text('Not specified');
    } else if (value is Timestamp) {
      valueWidget = Text(value.toDate().toString());
    } else if (value is List) {
      valueWidget = Wrap(
        spacing: 8,
        runSpacing: 8,
        children: value
            .map((item) => Chip(
                  label: Text(item.toString()),
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                ))
            .toList(),
      );
    } else if (value is bool) {
      valueWidget = Row(
        children: [
          Icon(
            value
                ? FluentSystemIcons.ic_fluent_checkmark_circle_regular
                : FluentSystemIcons.ic_fluent_dismiss_circle_regular,
            color: value ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(value ? 'Yes' : 'No'),
        ],
      );
    } else {
      valueWidget = Text(
        value.toString(),
        style: const TextStyle(fontSize: 16),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayKey,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            valueWidget,
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize first letter of string
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
