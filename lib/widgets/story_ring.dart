import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class StoryRing extends StatelessWidget {
  final bool isAddStory;
  final String? imageUrl;
  final String username;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap; // ✅ right-click on web

  const StoryRing({
    super.key,
    this.isAddStory = false,
    this.imageUrl,
    required this.username,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,                         // ✅ left click / tap
        onLongPress: onLongPress,             // ✅ long press (mobile)
        onSecondaryTap: onSecondaryTap,       // ✅ right click (web)
        borderRadius: BorderRadius.circular(50),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: isAddStory
                    ? null
                    : const LinearGradient(
                        colors: AppColors.storyGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: !isAddStory && imageUrl != null
                      ? NetworkImage(imageUrl!)
                      : null,
                  child: isAddStory
                      ? Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              size: 28, color: AppColors.primary),
                        )
                      : imageUrl == null
                          ? const Icon(Icons.person, size: 28)
                          : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                isAddStory ? 'Add Story' : username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}