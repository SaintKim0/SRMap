import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/user_profile_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nicknameController;
  late TextEditingController _statusController;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileProvider>().userProfile;
    _nicknameController = TextEditingController(text: profile.nickname);
    _statusController = TextEditingController(text: profile.statusMessage);
    _selectedImagePath = profile.profileImage;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('카메라로 촬영'),
                onTap: () async {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('갤러리에서 선택'),
                onTap: () async {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지를 불러오는데 실패했습니다.')),
      );
    }
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    final status = _statusController.text.trim();

    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }

    final success = await context.read<UserProfileProvider>().updateProfile(
      nickname: nickname,
      statusMessage: status,
      profileImage: _selectedImagePath,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        actions: [
          TextButton(
            onPressed: context.watch<UserProfileProvider>().isLoading 
                ? null 
                : _saveProfile,
            child: const Text('완료'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 프로필 이미지
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                   CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    backgroundImage: _selectedImagePath != null
                        ? FileImage(File(_selectedImagePath!)) as ImageProvider
                        : const AssetImage('assets/images/user_placeholder.png'),
                    child: _selectedImagePath == null 
                        ? const Icon(Icons.person, size: 50, color: Colors.white) 
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE62117),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 닉네임 입력
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
                hintText: '닉네임을 입력하세요',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              maxLength: 12,
            ),
            const SizedBox(height: 24),

            // 상태 메시지 입력
            TextField(
              controller: _statusController,
              decoration: const InputDecoration(
                labelText: '상태 메시지',
                hintText: '나를 표현하는 한마디',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat_bubble_outline),
              ),
              maxLength: 30,
            ),
          ],
        ),
      ),
    );
  }
}
