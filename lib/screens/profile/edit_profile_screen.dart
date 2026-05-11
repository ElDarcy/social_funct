import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  dynamic _imageFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _usernameController.text = authProvider.currentUser?.username ?? '';
    _bioController.text = authProvider.currentUser?.bio ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = kIsWeb ? image : File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final postProvider = context.read<PostProvider>();
      String? imageUrl = authProvider.currentUser?.profileImageUrl;

      if (_imageFile != null) {
        imageUrl = await postProvider.uploadImage(_imageFile, authProvider.currentUser!.id);
      }

      await authProvider.updateProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        profileImageUrl: imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isUploading)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile picture
              Center(
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _imageFile != null
                            ? (kIsWeb ? NetworkImage((_imageFile as XFile).path) : FileImage(_imageFile as File)) as ImageProvider
                            : (user?.profileImageUrl != null ? NetworkImage(user!.profileImageUrl!) : null),
                        child: (_imageFile == null && user?.profileImageUrl == null)
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a username';
                  if (value.length < 3) return 'Username must be at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.info_outline),
                  hintText: 'Tell us about yourself...',
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveProfile,
                  child: _isUploading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
