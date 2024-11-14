// Add this to lib/models/message_reply.dart


import 'package:celebrease_manager/modules/sample.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';


class MessageReply {
  final String id;
  final String messageId;
  final String content;
  final String senderId;
  final DateTime timestamp;
  final String status;

  MessageReply({
    required this.id,
    required this.messageId,
    required this.content,
    required this.senderId,
    required this.timestamp,
    required this.status,
  });

  factory MessageReply.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageReply(
      id: doc.id,
      messageId: data['messageId'] ?? '',
      content: data['content'] ?? '',
      senderId: data['senderId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'sent',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'messageId': messageId,
      'content': content,
      'senderId': senderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }
}



class VendorCommunicationCenter extends StatefulWidget {
  const VendorCommunicationCenter({super.key});

  @override
  State<VendorCommunicationCenter> createState() => _VendorCommunicationCenterState();
}

class _VendorCommunicationCenterState extends State<VendorCommunicationCenter> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _vendorId = FirebaseAuth.instance.currentUser!.uid;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    final messages = await _firestore
        .collection('messages')
        .where('recipients', arrayContains: _vendorId)
        .where('status', whereIn: ['sent', 'delivered'])
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'status': 'read'});
    }
    await batch.commit();
  }

  Stream<List<Message>> _getMessages(String type) {
    return _firestore
        .collection('messages')
        .where('recipients', arrayContains: _vendorId)
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
        title: const Text('Messages'),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('message_replies')
                  .where('messageId', isEqualTo: message.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final replies = snapshot.data!.docs.length;
                if (replies == 0) return const SizedBox();
                return Text(
                  '$replies ${replies == 1 ? 'reply' : 'replies'}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ],
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
            builder: (context) => VendorMessageDetailScreen(message: message),
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
}

// Add this to lib/pages/vendor/vendor_message_detail.dart
class VendorMessageDetailScreen extends StatefulWidget {
  final Message message;

  const VendorMessageDetailScreen({super.key, required this.message});

  @override
  State<VendorMessageDetailScreen> createState() => _VendorMessageDetailScreenState();
}

class _VendorMessageDetailScreenState extends State<VendorMessageDetailScreen> {
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
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageHeader(),
                  const Divider(height: 32),
                  _buildMessageContent(),
                  if (widget.message.metadata != null) ...[
                    const Divider(height: 32),
                    _buildMetadata(),
                  ],
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

  Widget _buildMessageHeader() {
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

  Widget _buildMessageContent() {
    return Text(
      widget.message.content,
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
      ),
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
                    child: Text(entry.value.toString()),
                  ),
                ],
              ),
            )),
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
          return const SizedBox();
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
                        // Continuing from where paste.txt left off in the VendorMessageDetailScreen class...

                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(reply.senderId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Text('Loading...',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey));
                                }
                                final userData =
                                    snapshot.data!.data() as Map<String, dynamic>?;
                                return Text(
                                  userData?['name'] ?? 'Unknown User',
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

