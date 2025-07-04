import 'package:flutter/material.dart';

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    Key? key,
    required this.text,
    required this.icon,
    this.press,
  }) : super(key: key);

  final String text;
  final Icon icon;
  final VoidCallback? press;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = screenWidth * 0.04; // 4% of screen width
    double iconTextSpacing = screenWidth * 0.05; // 5% of screen width

    return GestureDetector(
      onTap: press,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalPadding), // Responsive margin
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F9),
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  icon,
                  SizedBox(width: iconTextSpacing), // Responsive spacing
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: screenWidth * 0.5),
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
