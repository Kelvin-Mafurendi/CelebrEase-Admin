import 'package:cached_network_image/cached_network_image.dart';
import 'package:celebrease_manager/Pages/uploat_post.dart';
import 'package:celebrease_manager/Pages/viewer.dart';
import 'package:celebrease_manager/modules/sample.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Data model for generic item
class ItemModel {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final String image;

  ItemModel({
    required this.image,
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc, String collection) {
    final data = doc.data() as Map<String, dynamic>;
    switch (collection) {
      case 'Packages':
        {
          return ItemModel(
              id: doc.id,
              name: data['packageName'] ?? '',
              description: data['description'] ?? '',
              createdAt: (data['timeStamp'] as Timestamp).toDate(),
              image: data['packagePic']);
        }
      case 'banners':
        {
          return ItemModel(
              id: doc.id,
              name: data['bannerName'],
              description: '',
              createdAt: DateTime.now(),
              image: data['bannerPic']);
        }
      case 'Vendors':
        {
          return ItemModel(
              id: doc.id,
              name: data['business name'] ?? '',
              description: data['business description'] ?? '',
              createdAt: (data['timeStamp'] as Timestamp).toDate(),
              image: data['profilePic']);
        }
      case 'FlashAds':
        {
          return ItemModel(
              id: doc.id,
              name: data['title'] ?? '',
              description: data['description'] ?? '',
              createdAt: (data['timeStamp'] as Timestamp).toDate(),
              image: data['adPic']);
        }
      case 'Customers':
        {
          return ItemModel(
              id: doc.id,
              name: data['name'] ?? '',
              description: data['location'] ?? '',
              createdAt: (data['timeStamp'] as Timestamp).toDate(),
              image: data['profilePic']);
        }
      case 'Services':
        {
          return ItemModel(
              id: doc.id,
              name: doc.id,
              description: 'Service',
              createdAt: DateTime.now(),
              image: data['servicePic']);
        }

      default:
        {
          return ItemModel(
              id: doc.id,
              name: data['packageName'] ?? '',
              description: data['description'] ?? '',
              createdAt: (data['timeStamp'] as Timestamp).toDate(),
              image: data['packagePic']);
        }
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabsController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<({IconData icon, String label, String collection})> tabData = [
    (
      icon: CupertinoIcons.photo_on_rectangle,
      label: 'Banners',
      collection: 'banners'
    ),
    (
      icon: FluentSystemIcons.ic_fluent_settings_regular,
      label: 'Services',
      collection: 'Services'
    ),
    (
      icon: FluentSystemIcons.ic_fluent_people_team_regular,
      label: 'Vendors',
      collection: 'Vendors'
    ),
    (
      icon: FluentSystemIcons.ic_fluent_person_regular,
      label: 'Customers',
      collection: 'Customers'
    ),
    (
      icon: FluentSystemIcons.ic_fluent_gift_regular,
      label: 'Packages',
      collection: 'Packages'
    ),
    (
      icon: FluentSystemIcons.ic_fluent_flash_on_regular,
      label: 'FlashAds',
      collection: 'FlashAds'
    ),
  ];

  void _manageTabs(int index) {
    // Additional tab management logic can be added here
  }

  @override
  void initState() {
    super.initState();
    _tabsController = TabController(
      length: tabData.length,
      vsync: this,
    );

    _tabsController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabsController.dispose();
    super.dispose();
  }

  Stream<List<ItemModel>> _getCollectionStream(String collection) {
    return _firestore
        .collection(collection)
        .orderBy('timeStamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ItemModel.fromFirestore(doc, collection))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabsController,
            onTap: _manageTabs,
            isScrollable: true,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tabs: tabData.map((tab) => _buildTab(tab.icon, tab.label)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabsController,
            children: tabData
                .map((tab) => _buildTabContent(tab.collection, tab.label))
                .toList(),
          ),
        ),
        
      ],
    );
  }

  Widget _buildTab(IconData icon, String label) {
    final isSelected = tabData.indexWhere((tab) => tab.label == label) ==
        _tabsController.index;

    return Tab(
      height: 40,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 20 : 18,
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String collection, String label) {
    return Stack(children: [
      StreamBuilder<List<ItemModel>>(
        stream: _getCollectionStream(collection),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final List items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FluentSystemIcons.ic_fluent_storage_regular,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${label.toLowerCase()} found',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 40),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                    child: item.image != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: item.image,
                              fit: BoxFit
                                  .cover, // Adjust the image to cover the circle without distortion
                              width: double
                                  .infinity, // Ensures the image fills the CircleAvatar width
                              height: double
                                  .infinity, // Ensures the image fills the CircleAvatar height
                            ),
                          )
                        : Icon(
                            FluentSystemIcons.ic_fluent_storage_regular,
                            color: Colors.grey.withOpacity(0.9),
                          ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.fade,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(
                      FluentSystemIcons.ic_fluent_chevron_right_regular),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          collectionName: collection,
                          document: item.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      if (collection != 'Vendors' && collection != 'Customers')
        Positioned(
          bottom: 50,
          right: 10,
          child: FloatingActionButton(
              backgroundColor: Colors.red.withOpacity(0),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DynamicForm(
                      formType: collection == 'FlashAds'
                          ? FormType.flashAd
                          : collection == 'banners'
                              ? FormType.banner
                              : collection == 'Services'
                                  ? FormType.service
                                  : FormType.package,
                    ),
                  ),
                );
              },
              child: Icon(FluentSystemIcons.ic_fluent_add_regular)),
        )
    ]);
  }
}
