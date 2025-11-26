import 'package:flutter/material.dart';
import 'package:stress_detection_app/screens/home_monitor.dart';
import 'package:stress_detection_app/screens/support_chat.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<Widget> _pages = [
    const HomeMonitorScreen(),
    const SupportChatScreen(),
    const Center(child: Text("Profile")),
  ];

  @override
  Widget build(BuildContext context) {
    // 1. DETECT KEYBOARD STATE
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      // Ensure the body extends behind the keyboard if needed
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Layer 1: The Screen Content
          IndexedStack(
            index: _index,
            children: _pages,
          ),

          // Layer 2: The Navigation Bar
          // We only render this layer if the keyboard is CLOSED.
          if (!isKeyboardOpen)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E6E6),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                        icon: Icons.show_chart,
                        label: "Monitor",
                        isActive: _index == 0,
                        onTap: () => setState(() => _index = 0)
                    ),
                    _NavItem(
                        icon: Icons.chat_bubble_outline,
                        label: "Support",
                        isActive: _index == 1,
                        onTap: () => setState(() => _index = 1)
                    ),
                    _NavItem(
                        icon: Icons.person_outline,
                        label: "Profile",
                        isActive: _index == 2,
                        onTap: () => setState(() => _index = 2)
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: isActive
                ? const BoxDecoration(color: Colors.white, shape: BoxShape.circle)
                : null,
            child: Icon(
                icon,
                size: 24,
                color: isActive ? Colors.black87 : Colors.black54
            ),
          ),
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
              ),
            ),
        ],
      ),
    );
  }
}