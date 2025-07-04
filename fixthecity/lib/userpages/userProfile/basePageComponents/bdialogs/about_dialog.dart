import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomAboutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildContentBox(context),
    );
  }

  Widget _buildContentBox(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 20, top: 65, right: 20, bottom: 20),
          margin: EdgeInsets.only(top: 45),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildTitle(),
              SizedBox(height: 15),
              _buildDescription(),
              SizedBox(height: 22),
              _buildAppName(),
              SizedBox(height: 10),
              _buildSocialMediaIcons(),
              SizedBox(height: 10),
              _buildWebsite(),
              SizedBox(height: 10),
              _buildCopyright(),
              SizedBox(height: 22),
              _buildCloseButton(context),
            ],
          ),
        ),
        _buildLogo(),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      "About Sajha Samadhan",
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDescription() {
    return Text(
      "Sajha Samadhan is developed by a group of college students as a Hackathon Project. Sajha Samadhan, as part of their project to empower citizens to report Community Based issues directly through the app, fostering community involvement.",
      style: TextStyle(fontSize: 14),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAppName() {
    return Text(
      "Sajha Samadhan App",
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildSocialMediaIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIcon(FontAwesomeIcons.linkedin, () {
          // Add LinkedIn URL action
        }),
        _buildSocialIcon(FontAwesomeIcons.twitter, () {
          // Add Twitter URL action
        }),
        _buildSocialIcon(FontAwesomeIcons.facebook, () {
          // Add Facebook URL action
        }),
        _buildSocialIcon(FontAwesomeIcons.instagram, () {
          // Add Instagram URL action
        }),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: FaIcon(icon),
      onPressed: onPressed,
    );
  }

  Widget _buildWebsite() {
    return Text(
      "www.FixMyRoads.com.np",
      style: TextStyle(fontSize: 16, color: Colors.blue),
    );
  }

  Widget _buildCopyright() {
    return Text(
      "© Copyright 2025 All Rights Reserved.",
      style: TextStyle(fontSize: 12, color: Colors.grey),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text("Close", style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildLogo() {
    return Positioned(
      left: 20,
      right: 20,
      child: CircleAvatar(
        backgroundColor: Colors.yellow,
        radius: 45,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(45)),
          child: Image.asset("assets/Akar_logo.png"),
        ),
      ),
    );
  }
}