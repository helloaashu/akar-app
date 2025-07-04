import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms of Service'),
      ),
      body: TermsOfServiceContent(),
    );
  }
}

class TermsOfServiceContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text(
          'Terms of Service',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        CustomExpandableTile(
          title: 'Introduction',
          content: IntroductionContent(),
        ),
        CustomExpandableTile(
          title: 'User Responsibilities',
          content: UserResponsibilitiesContent(),
        ),
        CustomExpandableTile(
          title: 'Prohibited Activities',
          content: ProhibitedActivitiesContent(),
        ),
        CustomExpandableTile(
          title: 'Limitation of Liability',
          content: LimitationOfLiabilityContent(),
        ),
        CustomExpandableTile(
          title: 'Governing Law',
          content: GoverningLawContent(),
        ),
        CustomExpandableTile(
          title: 'Contact Information',
          content: TermsContactInformationContent(),
        ),
      ],
    );
  }
}

class CustomExpandableTile extends StatefulWidget {
  final String title;
  final Widget content;

  CustomExpandableTile({required this.title, required this.content});

  @override
  _CustomExpandableTileState createState() => _CustomExpandableTileState();
}

class _CustomExpandableTileState extends State<CustomExpandableTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          trailing: RotationTransition(
            turns: Tween(begin: 0.0, end: 0.5).animate(_controller),
            child: Icon(Icons.expand_more),
          ),
          onTap: _handleTap,
        ),
        SizeTransition(
          axisAlignment: 1.0,
          sizeFactor: _heightFactor,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: widget.content,
          ),
        ),
      ],
    );
  }
}

class IntroductionContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Welcome to the AKAR App. By using our app, you agree to comply with and be bound by the following terms and conditions. Please review these terms carefully.',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class UserResponsibilitiesContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BulletList([
      'Provide accurate and complete information.',
      'Respect the rights and privacy of other users.',
      'Comply with all applicable laws and regulations.',
    ]);
  }
}

class ProhibitedActivitiesContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BulletList([
      'Submitting false or misleading information.',
      'Engaging in any unlawful activities.',
      'Harassing, abusing, or harming other users.',
      'Attempting to hack or disrupt the app’s functionality.',
    ]);
  }
}

class LimitationOfLiabilityContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'We are not liable for any damages or losses resulting from your use of our app. Use the app at your own risk.',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class GoverningLawContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'These terms are governed by and construed in accordance with the laws of our country. Any disputes arising from these terms will be resolved in the courts of our country.',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class TermsContactInformationContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('If you have any questions about these Terms of Service, please contact us:', style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 8),
        BulletList([
          'Email: support@roadissuesapp.com',
          'Phone: +1 (555) 123-4567',
          'Mail: 123 Road Issues St, City, Country, ZIP',
        ]),
      ],
    );
  }
}

class BulletList extends StatelessWidget {
  final List<String> items;

  BulletList(this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: TextStyle(fontSize: 18, height: 1.5)),
            Expanded(child: Text(item, style: Theme.of(context).textTheme.bodyLarge)),
          ],
        ),
      )).toList(),
    );
  }
}
