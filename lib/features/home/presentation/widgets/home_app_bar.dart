import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function()? onMenuTap;

  const HomeAppBar({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000), // Very subtle shadow
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 2,
        left: 8,
        right: 8,
        bottom: 0,
      ),
      child: Row(
        children: [
          // Modern menu button with container
          GestureDetector(
            onTap: onMenuTap,
            child: Image.asset(
              "assets/icons/app_logo.png",
              height: 60,
              fit: BoxFit.contain,
            ),
          ),

          const Spacer(),

          const Spacer(),

          // Profile/notification button
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF1E293B),
              size: 22,
            ),
            onPressed: () {
              // Handle notifications
            },
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(76);
}
