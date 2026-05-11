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

// ✅ Fixed
class CreatePostScreen extends StatefulWidget {
  final VoidCallback? onPostCreated;

  const CreatePostScreen({super.key, this.onPostCreated});  // ✅ optional param

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final List<dynamic> _mediaFiles = [];
  final List<String> _mediaUrls = [];

  bool _isUploading = false;
  int _currentUploadIndex = 0;
  int _totalUploadCount = 0;
  String _uploadStatus = '';
  PostType _postType = PostType.image;
  final ImagePicker _picker = ImagePicker();

  // =================== PICK MEDIA ===================
  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    try {
      if (isVideo) {
        final XFile? video = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 2), // ✅ limit video length
        );
        if (video != null && mounted) {
          setState(() {
            _mediaFiles.add(kIsWeb ? video : File(video.path));
            _postType = PostType.video;
          });
        }
      } else {
        final List<XFile>? images = await _picker.pickMultiImage(
          imageQuality: 75, // ✅ compress before upload
          maxWidth: 1080,
          maxHeight: 1080,
        );
        if (images != null && images.isNotEmpty && mounted) {
          setState(() {
            _mediaFiles.addAll(
                images.map((img) => kIsWeb ? img : File(img.path)));
            _postType =
                _mediaFiles.length > 1 ? PostType.carousel : PostType.image;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking media: $e')),
        );
      }
    }
  }

  // =================== CREATE POST ===================
  Future<void> _createPost() async {
    if (_mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image or video')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isUploading = true;
      _currentUploadIndex = 0;
      _totalUploadCount = _mediaFiles.length;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final postProvider = context.read<PostProvider>();

      _mediaUrls.clear();

      for (int i = 0; i < _mediaFiles.length; i++) {
        if (!mounted) return;
        setState(() {
          _currentUploadIndex = i + 1;
          _uploadStatus =
              'Uploading ${_postType == PostType.video ? 'video' : 'photo'} ${i + 1} of ${_mediaFiles.length}...';
        });

        final file = _mediaFiles[i];
        String url;

        if (_postType == PostType.video) {
          url = await postProvider.uploadVideo(
              file, authProvider.currentUser!.id);
        } else {
          url = await postProvider.uploadImage(
              file, authProvider.currentUser!.id);
        }
        _mediaUrls.add(url);
      }

      if (!mounted) return;
      setState(() => _uploadStatus = 'Saving post...');

      await postProvider.createPost(
        userId: authProvider.currentUser!.id,
        caption: _captionController.text.trim(),
        mediaUrls: _mediaUrls,
        type: _postType,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post shared successfully! ✅'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // ✅ Navigate to home and clear the entire back stack
      widget.onPostCreated?.call(); // tells HomeScreen to switch to Feed tab => false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
    // Note: no finally block that resets _isUploading=false on success
    // because we navigate away — avoids setState on unmounted widget
  }

  // =================== REMOVE MEDIA ===================
  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
      if (_mediaFiles.length > 1) {
        _postType = PostType.carousel;
      } else if (_mediaFiles.isEmpty) {
        _postType = PostType.image;
      } else if (_postType != PostType.video) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Colors.black87,
      ),
      // ✅ Block interaction during upload with a full overlay
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== USER INFO =====
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: authProvider
                                  .currentUser?.profileImageUrl !=
                              null
                          ? NetworkImage(
                              authProvider.currentUser!.profileImageUrl!)
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
                  enabled: !_isUploading,
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
                            if (!_isUploading)
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
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 20),
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
                            : () =>
                                _pickMedia(ImageSource.gallery, isVideo: true),
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
                    onPressed: _isUploading || _mediaFiles.isEmpty
                        ? null
                        : _createPost,
                    child: _isUploading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  '$_uploadStatus ($_currentUploadIndex/$_totalUploadCount)',
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : const Text('Share'),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),

          // ✅ Full-screen upload overlay — prevents white screen / interaction
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _uploadStatus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_currentUploadIndex of $_totalUploadCount',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (kIsWeb) {
        // ✅ Fixed: use networkUrl for web (not deprecated .network())
        _controller = VideoPlayerController.networkUrl(
            Uri.parse(widget.file.path));
      } else {
        _controller = VideoPlayerController.file(widget.file);
      }

      await _controller!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Video preview timed out'),
      );

      if (mounted) {
        _controller!.setLooping(true);
        _controller!.play();
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.videocam_off, size: 40, color: Colors.grey),
        SizedBox(height: 8),
        Text('Preview unavailable', style: TextStyle(color: Colors.grey)),
      ]));
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20)),
              child: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}