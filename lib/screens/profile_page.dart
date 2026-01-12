import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stress_detection_app/core/stress_data.dart';
import 'package:stress_detection_app/core/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotification = true;

  // Image Picker Logic
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Updates the Singleton -> Auto-updates Home Monitor
      StressData().updateProfileImage(File(pickedFile.path));
    }
  }

  // Name Editing Logic
  Future<void> _showEditNameDialog() async {
    final TextEditingController nameController = TextEditingController(
        text: StressData().userNameNotifier.value
    );

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Name"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Enter your name"),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  StressData().updateUserName(nameController.text.trim());
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Text("Settings", style: AppTheme.titleStyle.copyWith(fontSize: 32)),
              const SizedBox(height: 32),

              // 2. Profile Card (Syncs with Global State)
              ValueListenableBuilder<File?>(
                valueListenable: StressData().profileImageNotifier,
                builder: (context, profileFile, child) {
                  return Row(
                    children: [
                      // Avatar Area
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: profileFile != null ? FileImage(profileFile) : null,
                              child: profileFile == null
                                  ? const Icon(Icons.person, size: 35, color: Colors.grey)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryTeal,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Name Area
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Welcome", style: AppTheme.labelStyle),

                          // LISTENS FOR NAME CHANGES
                          ValueListenableBuilder<String>(
                            valueListenable: StressData().userNameNotifier,
                            builder: (context, userName, _) {
                              return Text(
                                userName,
                                style: AppTheme.headingStyle.copyWith(fontSize: 20),
                              );
                            },
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Edit/Rename Icon (Formerly Logout)
                      GestureDetector(
                        onTap: _showEditNameDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit, color: AppTheme.primaryTeal),
                        ),
                      )
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // 3. Menu Items
              _buildMenuItem(Icons.person_outline, "User Profile"),
              _buildMenuItem(Icons.lock_outline, "Change Password"),
              _buildMenuItem(Icons.help_outline, "FAQs"),

              // 4. Toggle Item
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Text("Push Notification", style: AppTheme.headingStyle.copyWith(fontSize: 16)),
                    const Spacer(),
                    Switch(
                      value: _pushNotification,
                      activeColor: AppTheme.statuscodecalm,
                      onChanged: (val) => setState(() => _pushNotification = val),
                    )
                  ],
                ),
              ),

              // 5. Logout Item
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout, color: Colors.red),
                    ),
                    const SizedBox(width: 16),
                    Text("Logout", style: AppTheme.headingStyle.copyWith(fontSize: 16, color: Colors.red)),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.red),
                  ],
                ),
              ),

              const Divider(height: 32, color: Colors.grey),

              const SizedBox(height: 5),

              // 6. Bottom Call to Action
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      "If you have any other query you\ncan reach out to us.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF2D3436), height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "WhatsApp Us",
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),

              // 7. Extra Bottom Padding
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Text(title, style: AppTheme.headingStyle.copyWith(fontSize: 16)),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}