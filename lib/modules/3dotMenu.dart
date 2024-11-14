import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThreeDotMenu extends StatefulWidget {
  final List<String> items;
  final String type;
  final String id;

  const ThreeDotMenu({
    super.key,
    required this.items,
    required this.type,
    required this.id,
  });

  @override
  State<ThreeDotMenu> createState() => _ThreeDotMenuState();
}

class _ThreeDotMenuState extends State<ThreeDotMenu> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isProcessing = false;

  Future<bool> _showDeleteConfirmation(String type) async {
    final String itemType =
        type.substring(0, type.length - 1); // Remove 's' from end
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                'Delete $itemType',
                style: GoogleFonts.lateef(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Are you sure you want to delete this $itemType? This action cannot be undone.',
                style: GoogleFonts.lateef(fontSize: 18),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.lateef(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                ),
                TextButton(
                  child: Text(
                    'Delete',
                    style: GoogleFonts.lateef(
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false; // Return false if dialog is dismissed
  }

  Future<void> _deleteDocument(String collection, String id) async {
    final docRef = _firestore.collection(collection).doc(id);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw Exception('Document not found');
    }

    // If there's an image, delete it first
    final data = docSnapshot.data();
    if (data != null) {
      final imagePath = data['packagePic'] ??
          data['image'] ??
          data['imagePath'] ??
          data['profilePic'] ??
          data['flashPic'];
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(imagePath);
          await ref.delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }
    }

    // Delete the document
    await docRef.delete();
  }

  Future<void> _toggleVisibility(String collection, String id) async {
    final docRef = _firestore.collection(collection).doc(id);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw Exception('Document not found');
    }

    final bool currentHidden = docSnapshot.data()?['hidden'] == 'true';
    await docRef.update({'hidden': (!currentHidden).toString()});
  }

  Future<void> _manageItem(String item, String type) async {
    if (_isProcessing || widget.id.isEmpty) return;

    setState(() => _isProcessing = true);
    String type = widget.type;

    try {
      switch (item) {
        case 'Delete This':
          final shouldDelete = await _showDeleteConfirmation(type);
          if (shouldDelete) {
            await _deleteDocument(widget.type, widget.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.type} deleted successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
          break;

        case 'Hide This':
          await _toggleVisibility(widget.type, widget.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.type} visibility updated'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Operation failed: ${error.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      enabled: !_isProcessing,
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.grey[500]
            : Colors.white70,
      ),
      itemBuilder: (BuildContext context) => widget.items
          .map(
            (item) => PopupMenuItem(
              onTap: () => _manageItem(item, widget.type),
              value: item,
              child: Text(
                item,
                style: GoogleFonts.lateef(
                  fontSize: 15,
                  color: item.startsWith('Delete') ? Colors.red : null,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
