import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, 0, Icons.home_outlined, Icons.home),
          _buildNavItem(context, 1, Icons.search_outlined, Icons.search),
          _buildAddButton(context, 2),
          _buildNavItem(context, 3, Icons.chat_bubble_outline, Icons.chat_bubble),
          _buildNavItem(context, 4, Icons.person_outline, Icons.person),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData outlineIcon, IconData filledIcon) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected 
                  ? Theme.of(context).colorScheme.onSurface 
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, int index) {
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
        ),
      ),
    );
  }
}
