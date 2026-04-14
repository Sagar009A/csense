/// AI Chat Screen
/// Follow-up conversation with Gemini about a chart analysis
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import 'chat_controller.dart';

class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.textPrimaryLight),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_rounded, color: Colors.white, size: 20.w),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask AI',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  'Powered by Gemini',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      body: Column(
        children: [
          // Credit cost note
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            color: isDark ? AppColors.surfaceDark : const Color(0xFFF8F5FF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.toll_rounded, size: 14.w, color: const Color(0xFF8B5CF6)),
                SizedBox(width: 4.w),
                Text(
                  'Each message costs 1 credit',
                  style: TextStyle(fontSize: 12.sp, color: const Color(0xFF8B5CF6)),
                ),
              ],
            ),
          ),
          // Messages list
          Expanded(
            child: Obx(() => ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              itemCount: controller.messages.length,
              reverse: false,
              itemBuilder: (_, index) {
                final msg = controller.messages[index];
                return _ChatBubble(message: msg, isDark: isDark);
              },
            )),
          ),
          // Typing indicator
          Obx(() => controller.isLoading.value
              ? _buildTypingIndicator(isDark)
              : const SizedBox.shrink()),
          // Input bar
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology_rounded, color: Colors.white, size: 16.w),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                _Dot(delay: 0),
                SizedBox(width: 4.w),
                _Dot(delay: 150),
                SizedBox(width: 4.w),
                _Dot(delay: 300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: TextField(
                controller: controller.inputController,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask about this analysis...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 14.sp,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  border: InputBorder.none,
                ),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => controller.sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Obx(() => GestureDetector(
            onTap: controller.isLoading.value ? null : controller.sendMessage,
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                gradient: controller.isLoading.value
                    ? const LinearGradient(colors: [Color(0xFFCCCCCC), Color(0xFFAAAAAA)])
                    : const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20.w),
            ),
          )),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const _ChatBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32.w,
              height: 32.w,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_rounded, color: Colors.white, size: 16.w),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF8B5CF6)
                    : (isDark ? AppColors.cardDark : AppColors.cardLight),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(isUser ? 16.r : 4.r),
                  bottomRight: Radius.circular(isUser ? 4.r : 16.r),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : AppColors.textPrimaryLight),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) SizedBox(width: 8.w),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 6.w,
        height: 6.w + (_anim.value * 4.w),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6),
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }
}
