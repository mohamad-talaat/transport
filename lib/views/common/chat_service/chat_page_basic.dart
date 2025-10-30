import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/user_model.dart' hide UserType;
import 'package:transport_app/services/notification/notification_service.dart';
import 'package:transport_app/views/common/chat_service/communication_service.dart';
import 'package:intl/intl.dart' as intl;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CommunicationService _communicationService =
      Get.find<CommunicationService>();
  final AuthController _authController = Get.find<AuthController>();
  int? _lastMessageCount;

  late String otherUserId;
  late String otherUserName;
  late String tripId;
  late String chatId;
  late UserType currentUserType;

  UserModel? otherUserData;
  bool isLoadingUserData = true;
  bool isTyping = false;

  final List<String> driverQuickMessages = [
    'أنا في الطريق إليك',
    'وصلت إلى الموقع',
    'أين أنت؟',
    'سأتأخر 5 دقائق',
    'أنا أمام المبنى',
    'لم أستطع العثور على المكان',
    'هل يمكنك الخروج؟',
    'شكراً لك',
  ];

  final List<String> riderQuickMessages = [
    'أنا في الانتظار',
    'سأنزل خلال دقيقتين',
    'أين أنت الآن؟',
    'هل يمكنك الانتظار قليلاً؟',
    'أنا أمام الباب',
    'لا أراك، أين موقعك؟',
    'شكراً لك',
    'الرحلة ممتازة',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChatData();

    // ✅ تحديث حالة الشات المفتوح
    _communicationService.currentOpenChatId = chatId;
    NotificationService.to.setOpenChatId(chatId);
    
    _loadOtherUserData();
   
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _communicationService.updateLastSeen(chatId);
    });
  }

  void _initializeChatData() {
    final arguments = Get.arguments as Map<String, dynamic>;
    otherUserId = arguments['otherUserId'];
    otherUserName = arguments['otherUserName'];
    tripId = arguments['tripId'];

    final userTypeString = arguments['currentUserType'] as String? ?? '';
    currentUserType =
        userTypeString == 'driver' ? UserType.driver : UserType.rider;

    final currentUserId = _authController.currentUser.value!.id;
    chatId =
        _communicationService.createChatId(currentUserId, otherUserId, tripId);
  }

  Future<void> _loadOtherUserData() async {
    setState(() => isLoadingUserData = true);

    try {
      final userData =
          await _communicationService.getOtherUserInfo(otherUserId);
      setState(() {
        otherUserData = userData;
        isLoadingUserData = false;
      });
    } catch (e) {
      logger.w('Error loading user data: $e');
      setState(() => isLoadingUserData = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // ✅ مسح حالة الشات المفتوح
    _communicationService.currentOpenChatId = null;
    NotificationService.to.setOpenChatId(null);

    _messageController.dispose();
    _scrollController.dispose();

    _communicationService.updateLastSeen(chatId);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _communicationService.updateLastSeen(chatId);
    }
  }

  List<String> get quickMessages {
    return currentUserType == UserType.driver
        ? driverQuickMessages
        : riderQuickMessages;
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final success = await _communicationService.sendMessage(
      chatId: chatId,
      message: message,
      tripId: tripId,
    );

    if (success) {
      _messageController.clear();

      await _sendNotificationToOtherUser(message);

      _scrollToBottom();

      _communicationService.updateLastSeen(chatId);
    } else {
      Get.snackbar(
        'خطأ',
        'فشل في إرسال الرسالة، يرجى المحاولة مرة أخرى',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _sendNotificationToOtherUser(String message) async {
    try {
      final currentUser = _authController.currentUser.value;
      if (currentUser == null) return;

      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      if (!otherUserDoc.exists) return;

      final otherUserData = otherUserDoc.data();
      if (otherUserData == null) return;

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': otherUserId,
        'title': 'رسالة جديدة من ${currentUser.name}',
        'body':
            message.length > 100 ? '${message.substring(0, 100)}...' : message,
        'type': 'chat',
        'data': {
          'chatId': chatId,
          'tripId': tripId,
          'senderId': currentUser.id,
          'senderName': currentUser.name,
          'senderType':
              currentUser.userType.toString().split('.').last ?? 'unknown',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      logger.w('✅ Notification sent to user $otherUserId');
    } catch (e) {
      logger.w('❌ Error sending notification: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getUserTypeColor() {
    return currentUserType == UserType.driver
        ? Colors.blue.shade700
        : Colors.green.shade700;
  }

  String _getUserTypeTitle() {
    return currentUserType == UserType.driver
        ? 'محادثة مع الراكب'
        : 'محادثة مع السائق';
  }

  void _showUserInfoDialog() {
    if (otherUserData == null) {
      Get.snackbar(
        'تحميل البيانات',
        'جاري تحميل معلومات المستخدم...',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getUserTypeColor(),
                        _getUserTypeColor().withOpacity(0.7)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(5)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: otherUserData?.profileImage != null
                              ? NetworkImage(otherUserData!.profileImage!)
                              : null,
                          backgroundColor: Colors.grey.shade200,
                          child: otherUserData!.profileImage == null
                              ? Icon(
                                  currentUserType == UserType.driver
                                      ? Icons.person
                                      : Icons.local_taxi,
                                  size: 50,
                                  color: _getUserTypeColor(),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        otherUserData!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currentUserType == UserType.driver
                              ? 'الراكب'
                              : 'السائق',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(7),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.phone,
                        label: 'رقم الهاتف',
                        value: otherUserData!.phone ??
                            '',
                        onTap: () {
                          Navigator.pop(context);
                          _communicationService.makePhoneCall(
                            otherUserData!.phone 
                              
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      if (currentUserType == UserType.rider &&
                          otherUserData!.rating != null)
                        _buildInfoRow(
                          icon: Icons.star,
                          label: 'التقييم',
                          value:
                              '${otherUserData!.rating!.toStringAsFixed(1)} ⭐',
                          valueColor: Colors.amber.shade700,
                        ),
                      if (currentUserType == UserType.rider &&
                          otherUserData!.totalTrips != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildInfoRow(
                            icon: Icons.local_taxi,
                            label: 'عدد الرحلات',
                            value: '${otherUserData!.totalTrips} رحلة',
                          ),
                        ),
                      if (currentUserType == UserType.rider) ...[
                        if (otherUserData!.vehicleModel != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildInfoRow(
                              icon: Icons.directions_car,
                              label: 'نوع السيارة',
                              value: otherUserData!.vehicleModel ?? '',
                            ),
                          ),
                        if (otherUserData!.vehicleColor != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildInfoRow(
                              icon: Icons.palette,
                              label: 'لون السيارة',
                              value: otherUserData!.vehicleColor ?? '',
                            ),
                          ),
                        if (otherUserData!.plateNumber != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildInfoRow(
                              icon: Icons.confirmation_number,
                              label: 'رقم اللوحة',
                              value:
                                  "{${otherUserData!.plateNumber} ${otherUserData!.plateNumber} ${otherUserData!.plateNumber} ?? ''}",
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getUserTypeColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إغلاق',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getUserTypeColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _getUserTypeColor(), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ✅ تم حذف هذه الدالة - الآن FCMNotificationService يتولى كل شيء
 

  @override
  Widget build(BuildContext context) {
    final userTypeColor = _getUserTypeColor();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: userTypeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: InkWell(
          onTap: _showUserInfoDialog,
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: otherUserData?.profileImage != null
                        ? NetworkImage(otherUserData!.profileImage!)
                        : null,
                    backgroundColor: Colors.white,
                    child: otherUserData?.profileImage == null
                        ? Icon(
                            currentUserType == UserType.driver
                                ? Icons.person
                                : Icons.local_taxi,
                            color: userTypeColor,
                            size: 22,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUserName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getUserTypeTitle(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              if (otherUserData != null) {
                await _communicationService.makePhoneCall(
                  otherUserData!.phone 
                );
              } else {
                Get.snackbar(
                  'غير متوفر',
                  'معلومات الاتصال غير متوفرة',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
              }
            },
            icon: const Icon(Icons.phone, color: Colors.white),
          ),
          IconButton(
            onPressed: _showUserInfoDialog,
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              userTypeColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('trip_chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: userTypeColor),
                    );
                  }
                  if (!snapshot.hasData) return const SizedBox();

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: userTypeColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: userTypeColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'لا توجد رسائل بعد',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ابدأ المحادثة أو استخدم الرسائل السريعة',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs;
                  _scrollToBottom();

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data = messages[index].data();
                      final isMe = data['senderId'] ==
                          _authController.currentUser.value!.id;
                      final senderType = data['senderType'] as String?;
                      final timestamp = data['timestamp'] as Timestamp?;

                      bool showDateSeparator = false;
                      if (timestamp != null) {
                        if (index == 0) {
                          showDateSeparator = true;
                        } else {
                          final previousTimestamp = messages[index - 1]
                              .data()['timestamp'] as Timestamp?;
                          if (previousTimestamp != null) {
                            final currentDate = timestamp.toDate();
                            final previousDate = previousTimestamp.toDate();
                            showDateSeparator =
                                currentDate.day != previousDate.day ||
                                    currentDate.month != previousDate.month ||
                                    currentDate.year != previousDate.year;
                          }
                        }
                      }

                      return Column(
                        children: [
                          if (showDateSeparator && timestamp != null)
                            _buildDateSeparator(timestamp.toDate()),
                          _buildMessageBubble(
                            message: data['message'],
                            isMe: isMe,
                            senderName: data['senderName'],
                            senderType: senderType,
                            timestamp: timestamp,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            if (quickMessages.isNotEmpty)
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: quickMessages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ActionChip(
                        avatar: Icon(
                          Icons.flash_on,
                          size: 16,
                          color: userTypeColor,
                        ),
                        label: Text(
                          quickMessages[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: userTypeColor,
                          ),
                        ),
                        onPressed: () => _sendMessage(quickMessages[index]),
                        backgroundColor: userTypeColor.withOpacity(0.1),
                        side: BorderSide(color: userTypeColor.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    );
                  },
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'اكتب رسالتك...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.emoji_emotions_outlined,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {},
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: _sendMessage,
                          onChanged: (value) {
                            setState(() => isTyping = value.isNotEmpty);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            userTypeColor,
                            userTypeColor.withOpacity(0.8)
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: userTypeColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _sendMessage(_messageController.text),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'اليوم';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'أمس';
    } else {
      try {
        dateText = intl.DateFormat('d MMMM yyyy', 'ar').format(date);
      } catch (e) {
        dateText = '${date.day}/${date.month}/${date.year}';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dateText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

Widget _buildMessageBubble({
  required String message,
  required bool isMe,
  required String senderName,
  String? senderType,
  Timestamp? timestamp,
}) {
  final userTypeColor = _getUserTypeColor();
  final currentUser = _authController.currentUser.value; // جلب المستخدم الحالي

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      // تحديد المحاذاة بناءً على ما إذا كانت الرسالة مني أم لا
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // إذا لم تكن الرسالة مني، اعرض صورة المستخدم الآخر على اليسار
        if (!isMe) ...[
          CircleAvatar(
            radius: 18,
            backgroundImage: otherUserData?.profileImage != null
                ? NetworkImage(otherUserData!.profileImage!)
                : null,
            backgroundColor: userTypeColor.withOpacity(0.2),
            child: otherUserData?.profileImage == null
                ? Icon(
                    senderType == 'driver' ? Icons.local_taxi : Icons.person,
                    color: userTypeColor,
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(width: 8),
        ],

        // فقاعة الرسالة نفسها
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMe
                  ? LinearGradient(
                      colors: [userTypeColor, userTypeColor.withOpacity(0.8)],
                    )
                  : null,
              color: isMe ? null : Colors.grey.shade100,
              borderRadius: BorderRadius.only(
                // تحديث BorderRadius لجعل الحافة القريبة من الصورة مستديرة أكثر
                topLeft: Radius.circular(isMe ? 18 : 4), // لرسائلي: أعلى اليسار مستديرة، لرسائل الآخر: حادة
                topRight: Radius.circular(isMe ? 4 : 18), // لرسائلي: حادة، لرسائل الآخر: أعلى اليمين مستديرة
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(timestamp.toDate()),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // إذا كانت الرسالة مني، اعرض صورتي على اليمين
        if (isMe) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundImage: currentUser?.profileImage != null
                ? NetworkImage(currentUser!.profileImage!)
                : null,
            backgroundColor: userTypeColor.withOpacity(0.2),
            child: currentUser?.profileImage == null
                ? Icon(
                    currentUserType == UserType.driver ? Icons.person : Icons.local_taxi,
                    color: userTypeColor,
                    size: 18,
                  )
                : null,
          ),
        ],
      ],
    ),
  );
}
  
  String _formatMessageTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();

    final now = DateTime.now();
    final difference = now.difference(localDateTime);

    if (difference.inSeconds < 10) {
      return 'الآن';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds} ث';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} د';
    } else if (difference.inHours < 24) {
      return '${localDateTime.hour}:${localDateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${localDateTime.day}/${localDateTime.month} ${localDateTime.hour}:${localDateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
