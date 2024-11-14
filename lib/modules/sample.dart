// Add this to lib/models/message.dart
import 'package:celebrease_manager/modules/comms_smaple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Message {
  final String id;
  final String title;
  final String content;
  final String type; // 'broadcast', 'direct', 'notification'
  final String status; // 'sent', 'delivered', 'read'
  final List<String> recipients;
  final DateTime timestamp;
  final String senderId;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.status,
    required this.recipients,
    required this.timestamp,
    required this.senderId,
    this.metadata,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'direct',
      status: data['status'] ?? 'sent',
      recipients: List<String>.from(data['recipients'] ?? []),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      senderId: data['senderId'] ?? '',
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'type': type,
      'status': status,
      'recipients': recipients,
      'timestamp': Timestamp.fromDate(timestamp),
      'senderId': senderId,
      'metadata': metadata,
    };
  }
}

// Add this to lib/pages/communication/communication_center.dart

class CommunicationCenter extends StatefulWidget {
  const CommunicationCenter({super.key});

  @override
  State<CommunicationCenter> createState() => _CommunicationCenterState();
}

class _CommunicationCenterState extends State<CommunicationCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Message>> _getMessages(String type) {
    return _firestore
        .collection('messages')
        .where('type', isEqualTo: type)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication Center'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.broadcast_on_home_outlined),
              text: 'Broadcasts',
            ),
            Tab(
              icon: Icon(FluentSystemIcons.ic_fluent_mail_regular),
              text: 'Direct',
            ),
            Tab(
              icon: Icon(FluentSystemIcons.ic_fluent_alert_regular),
              text: 'Notifications',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessageList('broadcast'),
          _buildMessageList('direct'),
          _buildMessageList('notification'),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: FloatingActionButton(
          onPressed: () => _showComposeDialog(context),
          child: const Icon(FluentSystemIcons.ic_fluent_compose_regular),
        ),
      ),
    );
  }

  Widget _buildMessageList(String type) {
    return StreamBuilder<List<Message>>(
      stream: _getMessages(type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FluentSystemIcons.ic_fluent_mail_regular,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${type.capitalize()} Messages',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: messages.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageCard(message);
          },
        );
      },
    );
  }

  Widget _buildMessageCard(Message message) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            _getMessageIcon(message.type),
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          message.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          message.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDate(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            _buildStatusIndicator(message.status),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageDetailScreen(message: message),
          ),
        ),
      ),
    );
  }

  IconData _getMessageIcon(String type) {
    switch (type) {
      case 'broadcast':
        return Icons.broadcast_on_home_outlined;
      case 'direct':
        return FluentSystemIcons.ic_fluent_mail_regular;
      case 'notification':
        return FluentSystemIcons.ic_fluent_alert_regular;
      default:
        return FluentSystemIcons.ic_fluent_mail_regular;
    }
  }

  Widget _buildStatusIndicator(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'sent':
        color = Colors.blue;
        icon = FluentSystemIcons.ic_fluent_checkmark_regular;
        break;
      case 'delivered':
        color = Colors.green;
        icon = FluentSystemIcons.ic_fluent_checkmark_circle_regular;
        break;
      case 'read':
        color = Colors.purple;
        icon = FluentSystemIcons.ic_fluent_eye_show_regular;
        break;
      default:
        color = Colors.grey;
        icon = FluentSystemIcons.ic_fluent_clock_regular;
    }

    return Icon(icon, size: 16, color: color);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showComposeDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ComposeMessageScreen(),
      ),
    );
  }
}

class ComposeMessageScreen extends StatefulWidget {
  const ComposeMessageScreen({super.key});

  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'direct';
  final List<String> _selectedRecipients = [];
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final message = {
        'title': _titleController.text,
        'content': _contentController.text,
        'type': _selectedType,
        'status': 'sent',
        'recipients': _selectedRecipients,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': FirebaseAuth.instance.currentUser?.uid,
      };

      await FirebaseFirestore.instance.collection('messages').add(message);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Message'),
        actions: [
          IconButton(
            icon: const Icon(FluentSystemIcons.ic_fluent_send_regular),
            onPressed: _isSending ? null : _sendMessage,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 16),
            _buildRecipientSelector(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 10,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a message' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'direct',
          icon: Icon(FluentSystemIcons.ic_fluent_mail_regular),
          label: Text('Direct'),
        ),
        ButtonSegment(
          value: 'broadcast',
          icon: Icon(Icons.broadcast_on_home_outlined),
          label: Text('Broadcast'),
        ),
        ButtonSegment(
          value: 'notification',
          icon: Icon(FluentSystemIcons.ic_fluent_alert_regular),
          label: Text('Notification'),
        ),
      ],
      selected: {_selectedType},
      onSelectionChanged: (Set<String> value) {
        setState(() => _selectedType = value.first);
      },
    );
  }

  Widget _buildRecipientSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Vendors').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final vendors = snapshot.data!.docs;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: vendors.map((vendor) {
            final data = vendor.data() as Map<String, dynamic>;
            final vendorId = data['userId'];
            final isSelected = _selectedRecipients.contains(vendorId);

            return FilterChip(
              label: Text(data['business name'] ?? 'Unknown'),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedRecipients.add(vendorId);
                  } else {
                    _selectedRecipients.remove(vendorId);
                  }
                });
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class MessageDetailScreen extends StatefulWidget {
  final Message message;

  const MessageDetailScreen({super.key, required this.message});

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final _replyController = TextEditingController();
  bool _isReplying = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isReplying = true);

    try {
      final reply = {
        'messageId': widget.message.id,
        'content': _replyController.text.trim(),
        'senderId': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
      };

      await FirebaseFirestore.instance.collection('message_replies').add(reply);

      if (mounted) {
        _replyController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending reply: $e')),
        );
      }
    } finally {
      setState(() => _isReplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Details'),
        actions: [
          IconButton(
            icon: const Icon(FluentSystemIcons.ic_fluent_delete_regular),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const Divider(height: 32),
                  _buildContent(),
                  if (widget.message.metadata != null) ...[
                    const Divider(height: 32),
                    _buildMetadata(),
                  ],
                  const Divider(height: 32),
                  _buildRecipients(),
                  const Divider(height: 32),
                  _buildReplies(),
                ],
              ),
            ),
          ),
          if (widget.message.type != 'notification') _buildReplyInput(),
        ],
      ),
    );
  }

  // Continuing from where it left off in message_detail.dart...
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.message.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _getTypeIcon(),
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              widget.message.type.toUpperCase(),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              _getStatusIcon(),
              size: 16,
              color: _getStatusColor(),
            ),
            const SizedBox(width: 8),
            Text(
              widget.message.status.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _formatDateTime(widget.message.timestamp),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Message',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.message.content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadata() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.message.metadata!.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildRecipients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recipients',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.message.recipients
              .map((recipient) => Chip(
                    label: Text(recipient),
                    avatar: const Icon(
                      FluentSystemIcons.ic_fluent_person_regular,
                      size: 16,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildReplies() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('message_replies')
          .where('messageId', isEqualTo: widget.message.id)
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final replies = snapshot.data!.docs
            .map((doc) => MessageReply.fromFirestore(doc))
            .toList();

        if (replies.isEmpty) {
          return const Center(
            child: Text('No replies yet',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Replies',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...replies.map((reply) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reply.content,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('Vendors')
                                  .where('userId',isEqualTo: reply.senderId).limit(1)
                                  .get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Text('Loading...',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey));
                                }
                                final userData =
                                    snapshot.data!.docs.first.data() as Map<String, dynamic>?;
                                return Text(
                                  userData?['business name'] ?? 'Unknown Vendor',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                );
                              },
                            ),
                            Text(
                              _formatDateTime(reply.timestamp),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  // Add this method to build the reply input section
  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: const InputDecoration(
                hintText: 'Type your reply...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isReplying
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(FluentSystemIcons.ic_fluent_send_filled),
            onPressed: _isReplying ? null : _sendReply,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (widget.message.type) {
      case 'broadcast':
        return Icons.broadcast_on_home_outlined;
      case 'direct':
        return FluentSystemIcons.ic_fluent_mail_regular;
      case 'notification':
        return FluentSystemIcons.ic_fluent_alert_regular;
      default:
        return FluentSystemIcons.ic_fluent_mail_regular;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.message.status) {
      case 'sent':
        return FluentSystemIcons.ic_fluent_checkmark_regular;
      case 'delivered':
        return FluentSystemIcons.ic_fluent_checkmark_circle_regular;
      case 'read':
        return FluentSystemIcons.ic_fluent_eye_show_regular;
      default:
        return FluentSystemIcons.ic_fluent_clock_regular;
    }
  }

  Color _getStatusColor() {
    switch (widget.message.status) {
      case 'sent':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'read':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text(
            'Are you sure you want to delete this message? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(widget.message.id)
            .delete();
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting message: $e')),
          );
        }
      }
    }
  }
}

extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
