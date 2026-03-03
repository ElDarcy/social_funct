import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../models/post_model.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final List<File> _mediaFiles = [];
  final List<String> _mediaUrls = [];
  bool _isUploading = false;
  PostType _postType = PostType.image;

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    final picker = ImagePicker();

    if (isVideo) {
      final XFile? video = await picker.pickVideo(source: source);
      if (video != null) {
        setState(() {
          _mediaFiles.add(File(video.path));
          _postType = PostType.video;
        });
      }
    } else {
      final List<XFile>? images = await picker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() {
          _mediaFiles.addAll(images.map((img) => File(img.path)));
          _postType = _mediaFiles.length > 1 ? PostType.carousel : PostType.image;
        });
      }
    }
  }

  Future<void> _createPost() async {
    if (_mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image or video')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final postProvider = context.read<PostProvider>();

      // Upload media files
      for (File file in _mediaFiles) {
        String url;
        if (_postType == PostType.video) {
          url = await postProvider.uploadVideo(file, authProvider.currentUser!.id);
        } else {
          url = await postProvider.uploadImage(file, authProvider.currentUser!.id);
        }
        _mediaUrls.add(url);
      }

      // Create post
      await postProvider.createPost(
        userId: authProvider.currentUser!.id,
        caption: _captionController.text,
        mediaUrls: _mediaUrls,
        type: _postType,
      );

      // Clear form and go back
      _captionController.clear();
      _mediaFiles.clear();
      _mediaUrls.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
      if (_mediaFiles.length > 1) {
        _postType = PostType.carousel;
      } else if (_mediaFiles.isEmpty) {
        _postType = PostType.image;
      }
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: authProvider.currentUser?.profileImageUrl != null
                    ? NetworkImage(authProvider.currentUser!.profileImageUrl!)
                    : null,
                child: authProvider.currentUser?.profileImageUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                authProvider.currentUser?.username ?? 'User',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Caption
          TextFormField(
            controller: _captionController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Write a caption...',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 16),

          // Media preview
          if (_mediaFiles.isNotEmpty)
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: _mediaFiles.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _mediaFiles[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeMedia(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // Media count indicator
          if (_mediaFiles.length > 1)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_mediaFiles.length} / ${_mediaFiles.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Add media buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : () => _pickMedia(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : () => _pickMedia(ImageSource.gallery, isVideo: true),
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Video'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Camera button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : () => _pickMedia(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Take Photo'),
            ),
          ),
          const SizedBox(height: 32),

          // Post button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isUploading || _mediaFiles.isEmpty ? null : _createPost,
              child: _isUploading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Share'),
            ),
          ),
        ],
      ),
    );
  }
}