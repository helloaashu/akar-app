import 'package:flutter/material.dart';

class EmergencyContactsDialog extends StatelessWidget {
  final List<Map<String, String>> _emergencyContacts = [
    {"title": "Nepal Police", "number": "100"},
    {"title": "Ambulance Service", "number": "102"},
    {"title": "Fire Brigade", "number": "101"},
    {"title": "Nepal Red Cross Society (Blood Bank)", "number": "977-1-4270650"},
    {"title": "Metropolitan Police Office (Kathmandu Valley)", "number": "100 / 977-1-4411549"},
    {"title": "Bharatpur Metropolitan City Office", "number": "+977-056-511467"},
    {"title": "Nepal Electricity Authority", "number": "1151"},
    {"title": "Department of Roads", "number": "977-1-4216314 / 197"},
    {"title": "National Disaster Management Office", "number": "1155"},
    {"title": "Ministry of Home Affairs", "number": "977-1-4211208"},
  ];

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
              _buildContactsList(),
              SizedBox(height: 22),
              _buildCloseButton(context),
            ],
          ),
        ),
        _buildIcon(),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      "Emergency Contacts",
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildContactsList() {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _emergencyContacts.length,
        itemBuilder: (context, index) {
          final contact = _emergencyContacts[index];
          return _buildContactItem(
            contact['title']!,
            contact['number']!,
          );
        },
      ),
    );
  }

  Widget _buildContactItem(String title, String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(number),
        ],
      ),
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

  Widget _buildIcon() {
    return Positioned(
      left: 20,
      right: 20,
      child: CircleAvatar(
        backgroundColor: Color(0xFF8E354A),
        radius: 45,
        child: Icon(
          Icons.emergency,
          color: Colors.white,
          size: 50,
        ),
      ),
    );
  }
}