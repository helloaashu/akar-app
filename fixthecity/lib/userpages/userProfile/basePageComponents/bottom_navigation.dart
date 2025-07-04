import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int pageIndex;
  final Function(int) onPageChanged;

  const CustomBottomNavigation({
    Key? key,
    required this.pageIndex,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      buttonBackgroundColor: Colors.deepPurple,
      color: Colors.deepPurple,
      height: 67,
      animationDuration: const Duration(milliseconds: 49),
      items: const [
        Icon(Icons.home, color: Colors.white),
        Icon(Icons.add, color: Colors.white),
        Icon(Icons.feed_outlined, color: Colors.white),
        Icon(Icons.person, color: Colors.white),
      ],
      onTap: (index) {
        onPageChanged(index);
      },
      index: pageIndex,
    );
  }
}