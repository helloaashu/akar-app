import 'package:flutter/material.dart';

class MyBox extends StatelessWidget {
  final String SectionName;
  final String text;
  final void Function()? onPressed;
  const MyBox({super.key,required this.text, required this.SectionName,required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.only(left: 14,bottom: 14,),
      margin: EdgeInsets.only(left: 20,right: 20,top: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(SectionName,
               style: TextStyle(color: Colors.grey[700]),),

               IconButton(onPressed: onPressed, icon:Icon(Icons.settings),
               color: Colors.grey[700]),
             ],

           ),

           Text(text),
         ],
      ),
    );
  }
}
