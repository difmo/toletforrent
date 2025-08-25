import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/chat_item_widget.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/typing_indicator_widget.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  String? _selectedChatId;
  bool _isSearchVisible = false;
  bool _isTyping = false;
  int _currentBottomIndex = 3; // Messages tab

  // Mock conversations data
  final List<Map<String, dynamic>> _conversations = [
    {
      "id": "1",
      "ownerName": "Rahul Sharma",
      "propertyTitle": "2 BHK in Bandra West",
      "lastMessage": "The property is available for viewing tomorrow",
      "timestamp": "2 min ago",
      "unreadCount": 2,
      "avatar":
          "https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=100",
      "propertyImage":
          "https://images.pexels.com/photos/1396122/pexels-photo-1396122.jpeg?auto=compress&cs=tinysrgb&w=200",
      "isOnline": true,
      "messageType": "text"
    },
    {
      "id": "2",
      "ownerName": "Priya Patel",
      "propertyTitle": "3 BHK Villa in Juhu",
      "lastMessage": "📍 Property location shared",
      "timestamp": "1 hour ago",
      "unreadCount": 0,
      "avatar":
          "https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg?auto=compress&cs=tinysrgb&w=100",
      "propertyImage":
          "https://images.pexels.com/photos/106399/pexels-photo-106399.jpeg?auto=compress&cs=tinysrgb&w=200",
      "isOnline": false,
      "messageType": "location"
    },
    {
      "id": "3",
      "ownerName": "Amit Singh",
      "propertyTitle": "1 BHK Studio in Andheri",
      "lastMessage": "Sure, I'll arrange the virtual tour",
      "timestamp": "3 hours ago",
      "unreadCount": 1,
      "avatar":
          "https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=100",
      "propertyImage":
          "https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg?auto=compress&cs=tinysrgb&w=200",
      "isOnline": true,
      "messageType": "text"
    },
    {
      "id": "4",
      "ownerName": "Neha Gupta",
      "propertyTitle": "2 BHK in Malad West",
      "lastMessage": "📷 Property photos",
      "timestamp": "1 day ago",
      "unreadCount": 0,
      "avatar":
          "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=100",
      "propertyImage":
          "https://images.pexels.com/photos/1571453/pexels-photo-1571453.jpeg?auto=compress&cs=tinysrgb&w=200",
      "isOnline": false,
      "messageType": "image"
    },
    {
      "id": "5",
      "ownerName": "Rajesh Kumar",
      "propertyTitle": "3 BHK Apartment in Powai",
      "lastMessage":
          "Thank you for your interest. When would you like to visit?",
      "timestamp": "2 days ago",
      "unreadCount": 0,
      "avatar":
          "https://images.pexels.com/photos/2379005/pexels-photo-2379005.jpeg?auto=compress&cs=tinysrgb&w=100",
      "propertyImage":
          "https://images.pexels.com/photos/1571468/pexels-photo-1571468.jpeg?auto=compress&cs=tinysrgb&w=200",
      "isOnline": false,
      "messageType": "text"
    }
  ];

  // Mock messages for selected chat
  final Map<String, List<Map<String, dynamic>>> _chatMessages = {
    "1": [
      {
        "id": "msg1",
        "message": "Hi! I'm interested in your 2 BHK property in Bandra West.",
        "isSender": true,
        "timestamp": "10:30 AM",
        "status": "read",
        "type": "text"
      },
      {
        "id": "msg2",
        "message":
            "Hello! Thank you for your interest. The property is available for rent at ₹25,000/month.",
        "isSender": false,
        "timestamp": "10:35 AM",
        "status": "delivered",
        "type": "text"
      },
      {
        "id": "msg3",
        "message": "Could you please share more details about the amenities?",
        "isSender": true,
        "timestamp": "10:37 AM",
        "status": "read",
        "type": "text"
      },
      {
        "id": "msg4",
        "message":
            "The property has gym, swimming pool, parking, and 24/7 security. Would you like to schedule a viewing?",
        "isSender": false,
        "timestamp": "10:40 AM",
        "status": "delivered",
        "type": "text"
      },
      {
        "id": "msg5",
        "message": "Yes, please. When would be convenient for you?",
        "isSender": true,
        "timestamp": "10:42 AM",
        "status": "sent",
        "type": "text"
      },
      {
        "id": "msg6",
        "message":
            "The property is available for viewing tomorrow between 2-5 PM. Would that work for you?",
        "isSender": false,
        "timestamp": "10:45 AM",
        "status": "delivered",
        "type": "text"
      }
    ]
  };

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
      }
    });
  }

  void _onConversationTap(Map<String, dynamic> conversation) {
    setState(() {
      _selectedChatId = conversation['id'];
      // Mark messages as read
      conversation['unreadCount'] = 0;
    });

    // Auto-scroll to bottom when opening chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onBackPressed() {
    setState(() {
      _selectedChatId = null;
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Add message to chat (mock)
    final newMessage = {
      "id": "msg_${DateTime.now().millisecondsSinceEpoch}",
      "message": messageText,
      "isSender": true,
      "timestamp": _formatCurrentTime(),
      "status": "sent",
      "type": "text"
    };

    setState(() {
      _chatMessages[_selectedChatId!] ??= [];
      _chatMessages[_selectedChatId!]!.add(newMessage);
      _isTyping = true;
    });

    // Auto-scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulate owner reply
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          final replyMessage = {
            "id": "msg_${DateTime.now().millisecondsSinceEpoch}",
            "message":
                "Thank you for your message. I'll get back to you shortly.",
            "isSender": false,
            "timestamp": _formatCurrentTime(),
            "status": "delivered",
            "type": "text"
          };
          _chatMessages[_selectedChatId]?.add(replyMessage);
        });
      }
    });
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${now.minute.toString().padLeft(2, '0')} $period';
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomIndex = index;
    });

    // Navigate to appropriate screens
    final routes = [
      '/home-screen',
      '/property-search-screen',
      '/favorites-screen',
      '/messages-screen',
      '/profile-screen',
    ];

    if (index != 3 && index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  List<Map<String, dynamic>> _getFilteredConversations() {
    if (_searchController.text.isEmpty) return _conversations;

    return _conversations.where((conv) {
      final query = _searchController.text.toLowerCase();
      return conv['ownerName'].toLowerCase().contains(query) ||
          conv['propertyTitle'].toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedChatId != null) {
      return _buildChatInterface();
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: CustomIconWidget(
              iconName: _isSearchVisible ? 'close' : 'search',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          if (_isSearchVisible)
            Container(
              margin: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.dividerColor,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: CustomIconWidget(
                    iconName: 'search',
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 2.h,
                  ),
                ),
              ),
            ),

          // Conversations List
          Expanded(
            child: _getFilteredConversations().isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    itemCount: _getFilteredConversations().length,
                    separatorBuilder: (context, index) => Divider(
                      height: 0.1.h,
                      color: AppTheme.lightTheme.dividerColor
                          .withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) {
                      final conversation = _getFilteredConversations()[index];
                      return ChatItemWidget(
                        conversation: conversation,
                        onTap: () => _onConversationTap(conversation),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomNavTap,
        variant: BottomBarVariant.standard,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'chat_bubble_outline',
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.3),
              size: 80,
            ),
            SizedBox(height: 3.h),
            Text(
              'No Messages Yet',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Contact property owners to start conversations and get answers to your questions about rentals.',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home-screen');
              },
              icon: CustomIconWidget(
                iconName: 'home',
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                size: 18,
              ),
              label: const Text('Browse Properties'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    final conversation = _conversations.firstWhere(
      (conv) => conv['id'] == _selectedChatId,
    );
    final messages = _chatMessages[_selectedChatId] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _onBackPressed,
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(conversation['avatar']),
                ),
                if (conversation['isOnline'])
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation['ownerName'],
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    conversation['propertyTitle'],
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Show property details
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Property details coming soon')),
              );
            },
            icon: CustomIconWidget(
              iconName: 'info_outline',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: Column(
        children: [
          // Property Preview Card
          Container(
            margin: EdgeInsets.all(4.w),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.dividerColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImageWidget(
                    imageUrl: conversation['propertyImage'],
                    width: 15.w,
                    height: 15.w,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation['propertyTitle'],
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Owner: ${conversation['ownerName']}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && _isTyping) {
                  return const TypingIndicatorWidget();
                }

                final message = messages[index];
                return MessageBubbleWidget(message: message);
              },
            ),
          ),

          // Input Area
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color:
                      AppTheme.lightTheme.dividerColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // Handle camera/attachment
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Camera coming soon')),
                      );
                    },
                    icon: CustomIconWidget(
                      iconName: 'camera_alt',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.lightTheme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.5.h,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Handle location sharing
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Location sharing coming soon')),
                      );
                    },
                    icon: CustomIconWidget(
                      iconName: 'location_on',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: 'send',
                        color: AppTheme.lightTheme.colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}