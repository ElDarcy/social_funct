import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class ReactionButton extends StatefulWidget {
  final PostModel post;
  final Function(String reaction) onReactionSelected;

  const ReactionButton({
    super.key,
    required this.post,
    required this.onReactionSelected,
  });

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> {
  bool _isReacting = false;

  final List<Map<String, dynamic>> _reactions = [
    {'icon': Icons.favorite, 'color': AppColors.likeColor, 'label': 'Like'},
    {'icon': Icons.favorite, 'color': AppColors.heartColor, 'label': 'Love'},
    {'icon': Icons.local_fire_department, 'color': AppColors.fireColor, 'label': 'Fire'},
    {'icon': Icons.emoji_people, 'color': AppColors.clapColor, 'label': 'Clap'},
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLiked = widget.post.isLikedBy(authProvider.currentUser!.id);

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isReacting = true;
        });
      },
      onLongPressEnd: (_) {
        setState(() {
          _isReacting = false;
        });
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Main like button
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_outline,
              color: isLiked ? AppColors.heartColor : null,
            ),
            onPressed: () {
              widget.onReactionSelected('like');
            },
          ),

          // Reaction picker
          if (_isReacting)
            Container(
              margin: const EdgeInsets.only(bottom: 50),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _reactions.map((reaction) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _isReacting = false;
                      });
                      widget.onReactionSelected(reaction['label']);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        reaction['icon'] as IconData,
                        color: reaction['color'] as Color,
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
