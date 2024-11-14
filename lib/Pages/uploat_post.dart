import 'package:celebrease_manager/Pages/package_form.dart';
import 'package:celebrease_manager/States/changemanger.dart';
import 'package:celebrease_manager/modules/add_image.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum FormType { flashAd, highlight, package, service, banner }

class DynamicForm extends StatefulWidget {
  final FormType formType;
  final Map<String, dynamic> initialData;

  const DynamicForm({
    super.key,
    required this.formType,
    this.initialData = const {},
  });

  @override
  State<DynamicForm> createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm> {
  late Map<String, TextEditingController> controllers;
  bool isLoading = false;
  String? serviceType;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.formType == FormType.package) {
      _loadServiceType();
    }
  }

  void _initializeControllers() {
    controllers = {};

    // Only initialize controllers for non-package forms
    if (widget.formType != FormType.package) {
      final fields = _getFieldsForFormType();
      for (var field in fields) {
        controllers[field] = TextEditingController(
          text: widget.initialData[field] ?? '',
        );
      }
    }
  }

  List<String> _getFieldsForFormType() {
    switch (widget.formType) {
      case FormType.flashAd:
        return ['title', 'description'];
      case FormType.highlight:
        return ['packageName', 'rate', 'description'];
      case FormType.package:
        return [];
      case FormType.service:
        return ['serviceName', 'description'];
      case FormType.banner:
        return ['bannerName'];
    }
  }

  Future<void> _loadServiceType() async {
    setState(() => isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('Vendors')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        setState(() {
          serviceType = doc.docs.first['category'] as String?;
        });
      }
    } catch (e) {
      print('Error loading service type: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildFormContent() {
    if (widget.formType == FormType.package) {
      return DynamicPackageForm(initialData: widget.initialData);
    }

    return ListView(
      shrinkWrap: true,
      children: [
        _buildImageUploadSection(),
        ..._buildFormFields(),
        const SizedBox(height: 20),
        Consumer<ChangeManager>(
          builder: (context, changeManager, child) {
            return ElevatedButton.icon(
              onPressed: () => _handleSubmit(changeManager),
              label: Text(
                _getSubmitButtonText(),
              ),
              icon: Icon(
                FluentSystemIcons.ic_fluent_upload_regular,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    String uploadText;
    Widget uploadWidget;

    switch (widget.formType) {
      case FormType.flashAd:
        uploadText = 'Upload Flash Image';
        uploadWidget = AddImage(dataType: 'flashAd', fieldName: 'adPic');
        break;
      case FormType.highlight:
        uploadText = 'Upload Main Highlight Image';
        uploadWidget = Column(
          children: [
            AddImage(dataType: 'highlight', fieldName: 'highlightPic'),
            const SizedBox(height: 20),
          ],
        );
        break;
      case FormType.package:
        uploadText = 'Upload Package Image';
        uploadWidget = AddImage(dataType: 'package', fieldName: 'packagePic');
        break;
      case FormType.service:
        uploadText = 'Upload Serivce Image';
        uploadWidget = AddImage(dataType: 'service', fieldName: 'servicePic');
        break;
      case FormType.banner:
        uploadText = 'Upload Package Image';
        uploadWidget = AddImage(dataType: 'banner', fieldName: 'bannerPic');
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 15),
      child: Column(
        children: [
          uploadWidget,
          const SizedBox(height: 10),
          Text(uploadText),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String fieldName,
    String label,
    String hintText, {
    int maxLines = 1,
    int? maxLength,
    MaxLengthEnforcement? maxLengthEnforcement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: TextField(
        controller: controllers[fieldName]!,
        maxLines: maxLines,
        maxLength: maxLength,
        maxLengthEnforcement: maxLengthEnforcement ?? MaxLengthEnforcement.none,
        decoration: InputDecoration(
          hintText: hintText,
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        style: GoogleFonts.lateef(
          fontSize: 22,
        ),
      ),
    );
  }

  void _handleSubmit(ChangeManager changeManager) async {
    if (widget.formType == FormType.package) {
      return;
    }

    Map<String, dynamic> updatedData = {};

    controllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        updatedData[key] = controller.text;
      }
    });

    try {
      switch (widget.formType) {
        case FormType.flashAd:
          final adImage = changeManager.getImage('flashAd', 'adPic');
          if (adImage != null && adImage.path.isNotEmpty) {
            updatedData['adPic'] = adImage.path;
          } else {
            throw Exception('Please select an image for the flash ad');
          }
          await changeManager.handleData(
            dataType: 'flashAd',
            newData: updatedData,
            collection: 'FlashAds',
            operation: OperationType.create,
            fileFields: {
              'adPic':
                  'FlashAds', // This will now properly upload to this path in Firebase Storage
            },
          );
          break;
        case FormType.highlight:
          final highlightImage =
              changeManager.getImage('highlight', 'highlightPic');
          if (highlightImage != null && highlightImage.path.isNotEmpty) {
            updatedData['highlightPic'] = highlightImage.path;
          } else {
            throw Exception('Please select an image for the highlight');
          }
          await changeManager.handleData(
            dataType: 'highlight',
            newData: updatedData,
            collection: 'Highlights',
            operation: OperationType.create,
            fileFields: {
              'highlightPic':
                  'Highlights', // This will now properly upload to this path in Firebase Storage
            },
          );
          break;
        case FormType.service:
          final serviceImage = changeManager.getImage('service', 'servicePic');
          if (serviceImage != null && serviceImage.path.isNotEmpty) {
            updatedData['servicePic'] = serviceImage.path;
          } else {
            throw Exception('Please select an image for the service');
          }
          await changeManager.handleData(
            dataType: 'service',
            newData: updatedData,
            collection: 'Services',
            operation: OperationType.create,
            fileFields: {
              'servicePic':
                  'Services', // This will now properly upload to this path in Firebase Storage
            },
          );
          break;
        case FormType.banner:
          final bannerImage = changeManager.getImage('banner', 'bannerPic');
          if (bannerImage != null && bannerImage.path.isNotEmpty) {
            updatedData['bannerPic'] = bannerImage.path;
          } else {
            throw Exception('Please select an image for the banner');
          }
          await changeManager.handleData(
            dataType: 'banner',
            newData: updatedData,
            collection: 'banners',
            operation: OperationType.create,
            fileFields: {
              'bannerPic':
                  'banners', // This will now properly upload to this path in Firebase Storage
            },
          );
          break;
        case FormType.package:
          break;
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.formType == FormType.package && serviceType == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child:
              Text('Please set your service category in your profile first.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getFormTitle()),
        elevation: 0,
      ),
      body: _buildFormContent(),
    );
  }

  String _getFormTitle() {
    switch (widget.formType) {
      case FormType.flashAd:
        return 'Add Flash Ad';
      case FormType.highlight:
        return 'Add Highlight';
      case FormType.package:
        return 'Add Package';
      case FormType.service:
        return 'Add Service';
      case FormType.banner:
        return 'Add Banner';
    }
  }

  String _getSubmitButtonText() {
    switch (widget.formType) {
      case FormType.flashAd:
        return 'Post';
      case FormType.highlight:
        return 'Save Changes';
      case FormType.package:
        return 'Save Package';
      case FormType.service:
        return 'Save Service';
      case FormType.banner:
        return 'Save Banner';
    }
  }

  List<Widget> _buildFormFields() {
    switch (widget.formType) {
      case FormType.flashAd:
        return [
          _buildTextField('title', 'Title', 'Ad title..'),
          _buildTextField(
            'description',
            'Advert',
            'Type your Ad Here...\nNote that FlashAds a CelebrEase exclusive advertisements which last for 24 hours on CelebrEase.',
            maxLines: 10,
            maxLength: 500,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
          ),
        ];
      case FormType.highlight:
        return [
          _buildTextField('packageName', 'Package Name',
              'Enter package name for this highlight'),
          _buildTextField(
              'rate', 'Rate', 'How much was this package e.g per hour'),
          _buildTextField(
            'description',
            'Description',
            'What do you want your audience to know about this highlight?',
            maxLines: 10,
            maxLength: 100,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
          ),
        ];
      case FormType.service:
        return [
          _buildTextField('serviceName', 'Service Name',
              'Enter package name for this service'),
          _buildTextField(
            'description',
            'Description',
            'Describe the Service',
            maxLines: 10,
            maxLength: 100,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
          ),
        ];
      case FormType.banner:
        return [
          _buildTextField('bannerName', 'Banner Name',
              'Enter package name for this banner'),
        ];
      case FormType.package:
        return []; // Empty since package uses DynamicPackageForm
    }
  }

  @override
  void dispose() {
    controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}
