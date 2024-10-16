import 'package:flutter/material.dart'; //need on every page

import '../../app_scaffold.dart';

class Team extends StatefulWidget {
  @override
  _TeamState createState() => _TeamState();
}

// Represent image data
class ImageData {
  final String imagePath;
  final String name;
  final String role;

  ImageData({required this.imagePath, required this.name, required this.role});
}

class _TeamState extends State<Team> {
  
  // List of headshots, names, and roles
  final List<ImageData> imagesData = [
    // ImageData(imagePath: 'assets/images/team/claire-adair.jpeg', name: 'Claire Adair', role: '',),
    ImageData(imagePath: 'assets/images/team/euny-park.jpeg', name: 'Euny Park', role: '',),
    ImageData(imagePath: 'assets/images/team/joni-chan.jpeg', name: 'Joni Chan', role: '',),
    ImageData(imagePath: 'assets/images/team/luke-madera.jpg', name: 'Luke Madera', role: '',),
    ImageData(imagePath: 'assets/images/team/morgan-long.jpeg', name: 'Morgan Long', role: '',),
    ImageData(imagePath: 'assets/images/team/rebecca-odim.jpg', name: 'Rebecca Odim', role: '',),
  ];
  double _imageSize = 200.0;

  // Function to dynamically create columns with images and text
  Widget buildImageColumn(ImageData imageData) {
    return Column(
      children: [
        // Headshots
        Image.asset(
          imageData.imagePath, 
          width: _imageSize, 
          height: _imageSize, 
          fit: BoxFit.cover, 
        ),
        SizedBox(height: 5),
        // Text
        FittedBox(
          fit: BoxFit.fitWidth,
          child: Column(
            children: [
              Text(
                imageData.name,
                style: TextStyle(fontSize: 14),
              ), 
              Text(
                imageData.role,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
  } 

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      listWrapper: true,
      width: 750,
      body: Column(
        children: [
          SizedBox(height: 20),
          // Wrap widget deals with varying number of images on different screen sizes
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: <Widget> [
              ...imagesData.map((imageData) => buildImageColumn(imageData) ).toList(),
            ]
          ),
        ],
      ),
    );
  }
}
