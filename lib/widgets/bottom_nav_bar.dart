import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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
      height: 80,
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home),
          _buildNavItem(1, Icons.search_outlined, Icons.search),
          const SizedBox(width: 40), // Space for FAB
          _buildNavItem(3, Icons.chat_bubble_outline, Icons.chat_bubble),
          _buildNavItem(4, Icons.person_outline, Icons.person),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Icon(
            isSelected ? filledIcon : outlineIcon,
            color: isSelected ? AppColors.primary : Colors.grey.shade500,
            size: 26,
          ),
        ),
      ),
    );
  }
}