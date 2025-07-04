import 'package:flutter/material.dart';


class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
      ),
      body: PrivacyPolicyContent(),
    );
  }
}

class PrivacyPolicyContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text(
          'App Privacy Policy',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        CustomExpandableTile(
          title: 'Information Collection',
          content: InformationCollectionContent(),
        ),
        CustomExpandableTile(
          title: 'Use of Information',
          content: UseOfInformationContent(),
        ),
        CustomExpandableTile(
          title: 'Data Storage and Security',
          content: DataStorageContent(),
        ),
         CustomExpandableTile(
         title: 'Data Sharing',
         content: DataSharingContent(),
        ),
        CustomExpandableTile(
          title: 'User Rights',
          content: UserRightsContent(),
        ),
        // CustomExpandableTile(
        //   title: 'Updates to Privacy Policy',
        //   content: UpdatesContent(),
        // ),
        CustomExpandableTile(
          title: 'Contact Information',
          content: ContactInformationContent(),
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
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));
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
          title: Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
class InformationCollectionContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('We collect the following information for user verification:', style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 8),
        Text('Profile Details:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        BulletList([
          'State/Province',
          'Zip Code',
          'Home Number',
          'Contact Number',
          'Job Position',
          'Gender',
        ]),
        SizedBox(height: 8),
        Text('ID Details:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        BulletList([
          'For Adults: Citizenship ID',
          'For Minors: School ID',
        ]),
        SizedBox(height: 16),
        Text('Complaint Details:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        BulletList([
          'Problem Category',
          'Issue Type',
          'Nature of the Problem',
          'Location Details (via OSM Map)',
          'Photos of Affected Areas',
        ]),
        SizedBox(height: 8),
        Text('All data is collected through user input.', style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class UseOfInformationContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('We use the collected information for:', style: Theme.of(context).textTheme.bodyLarge),
        BulletList([
          'User verification to prevent fake complaints',
          'Improving app functionality',
          'Solving the respective road issues based on the complaint details provided',
        ]),
        SizedBox(height: 8),
        Text('We are committed to using your information responsibly and ensuring your privacy is protected.', style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class DataStorageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data Storage:', style: Theme.of(context).textTheme.bodyLarge),
        BulletList([
          'All data is stored securely in Firebase',
          'We implement industry-standard security measures to protect your data',
        ]),
      ],
    );
  }
}

class DataSharingContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('We may share your data with third parties under the following circumstances:', style: Theme.of(context).textTheme.bodyLarge),
        BulletList([
          'Local authorities to address and resolve the road issues reported',
          'Service providers who assist us in improving our app functionality',
          'Compliance with legal obligations, such as court orders or government regulations',
        ]),
        SizedBox(height: 8),
        Text('We ensure that any third parties we share your data with adhere to strict data protection standards to safeguard your privacy.', style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
class UserRightsContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Users have the following rights regarding their data:', style: Theme.of(context).textTheme.bodyLarge),
        BulletList([
          'Access: Users can request access to the data we have collected about them.',
          'Modification: Users can request corrections or updates to their data.',
          'Deletion: Users can request the deletion of their data from our records.',
        ]),
        SizedBox(height: 8),
        Text('To exercise any of these rights, please contact us through the provided contact information in this policy.', style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
class ContactInformationContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('If you have any privacy-related questions or concerns, you can contact us through the following methods:', style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 8),
        BulletList([
          'Email: support@roadissuesapp.com',
          'Phone: +1 (555) 123-4567',
          'Mail: 123 Road Issues St, City, Country, ZIP',
        ]),
        SizedBox(height: 8),
        Text('We are committed to addressing your concerns and ensuring the protection of your privacy.', style: Theme.of(context).textTheme.bodyLarge),
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
