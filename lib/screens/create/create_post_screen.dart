import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
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

  // Can store File (mobile) or XFile (web)
  final List<dynamic> _mediaFiles = [];
  final List<String> _mediaUrls = [];

  bool _isUploading = false;
  PostType _postType = PostType.image;
  final ImagePicker _picker = ImagePicker();

  // =================== PICK MEDIA ===================
  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    try {
      if (isVideo) {
        final XFile? video = await _picker.pickVideo(source: source);
        if (video != null) {
          setState(() {
            _mediaFiles.add(kIsWeb ? video : File(video.path));
            _postType = PostType.video;
          });
        }
      } else {
        final List<XFile>? images = await _picker.pickMultiImage();
        if (images != null && images.isNotEmpty) {
          setState(() {
            _mediaFiles.addAll(
                images.map((img) => kIsWeb ? img : File(img.path)));
            _postType =
            _mediaFiles.length > 1 ? PostType.carousel : PostType.image;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: $e')),
      );
    }
  }

  // =================== CREATE POST ===================
  Future<void> _createPost() async {
    if (_mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image or video'),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final postProvider = context.read<PostProvider>();

      _mediaUrls.clear();

      for (var file in _mediaFiles) {
        String url;
        if (_postType == PostType.video) {
          url = await postProvider.uploadVideo(file, authProvider.currentUser!.id);
        } else {
          url = await postProvider.uploadImage(file, authProvider.currentUser!.id);
        }
        _mediaUrls.add(url);
      }

      await postProvider.createPost(
        userId: authProvider.currentUser!.id,
        caption: _captionController.text,
        mediaUrls: _mediaUrls,
        type: _postType,
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // =================== REMOVE MEDIA ===================
  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);

      if (_mediaFiles.length > 1) {
        _postType = PostType.carousel;
      } else if (_mediaFiles.isEmpty) {
        _postType = PostType.image;
      } else if (_mediaFiles.length == 1 && _postType != PostType.video) {
        _postType = PostType.image;
      }
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // =================== BUILD WIDGET ===================
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== USER INFO =====
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
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ===== CAPTION INPUT =====
            TextFormField(
              controller: _captionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write a caption...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ===== MEDIA PREVIEW =====
            if (_mediaFiles.isNotEmpty)
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: _mediaFiles.length,
                  itemBuilder: (context, index) {
                    final file = _mediaFiles[index];
                    final isVideo = _postType == PostType.video;

                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: isVideo
                              ? VideoPlayerWidget(file: file)
                              : kIsWeb
                              ? Image.network(file.path,
                              fit: BoxFit.cover,
                              width: double.infinity)
                              : Image.file(file,
                              fit: BoxFit.cover,
                              width: double.infinity),
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

            const SizedBox(height: 16),

            // ===== ADD MEDIA BUTTONS =====
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () => _pickMedia(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () => _pickMedia(ImageSource.gallery, isVideo: true),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Video'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () => _pickMedia(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take Photo'),
              ),
            ),

            const SizedBox(height: 32),

            // ===== POST BUTTON =====
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                _isUploading || _mediaFiles.isEmpty ? null : _createPost,
                child: _isUploading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text('Share'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================== VIDEO PLAYER WIDGET ===================
class VideoPlayerWidget extends StatefulWidget {
  final dynamic file;
  const VideoPlayerWidget({super.key, required this.file});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = kIsWeb
          ? VideoPlayerController.network(widget.file.path)
          : VideoPlayerController.file(widget.file);

      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.play();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Video initialization error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: GestureDetector(
            onTap: () {
              if (_controller!.value.isPlaying) {
                _controller!.pause();
              } else {
                _controller!.play();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _controller!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}