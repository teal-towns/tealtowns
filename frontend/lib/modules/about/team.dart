import 'package:flutter/material.dart'; //need on every page

import '../../app_scaffold.dart';

class Team extends StatefulWidget {
  @override
  _TeamState createState() => _TeamState();
}

class _TeamState extends State<Team> {
  
  // List of headshots, names, and roles
  final List<ImageData> imagesData = [
    ImageData(
      imagePath: 'assets/images/luke-madera-headshot.jpg',
      name: 'Luke Madera',
      role: 'Product Engineer',
    ), 
    ImageData(
      imagePath: 'assets/images/layla-tadjpour-headshot.jpg',
      name: 'Layla Tadjpour',
      role: 'Product Engineer',
    ),
    ImageData(
      imagePath: 'assets/images/claire-adair-headshot.jpg',
      name: 'Claire Adair',
      role: 'Customer Acquisition',
    ),
    ImageData(
      imagePath: 'assets/images/jacob-russo-headshot.jpg',
      name: 'Jacob Russo',
      role: 'Web Developer',
    ),
  ];

  @override
  void initState() {
    super.initState();
  } 

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      
      body: Column(
        children: [

          // Title widget
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              'Team',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // ListView 
          Expanded(
            child: Center( // Align center
              child: ListView(
                children: [
                  // For each pair of images a Row is created with 2 Columns of images
                  for (int i = 0; i < imagesData.length; i += 2)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildImageColumn(imagesData[i]),
                        SizedBox(width: 20),
                        // Prevent "index out of bounds" error when number of images is not even
                        if (i + 1 < imagesData.length)
                          buildImageColumn(imagesData[i + 1]),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to dynamically create columns with images and text
  Widget buildImageColumn(ImageData imageData) {
    return Column(
      children: [
        
        // Headshots
        Image.asset(
          imageData.imagePath, 
          width: 150, 
          height: 150, 
          fit: BoxFit.cover, 
        ),

        SizedBox(height: 5), // Space

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

        SizedBox(height: 20),

      ],
    );
  }
}

// Represent data
class ImageData {
  final String imagePath;
  final String name;
  final String role;

  ImageData({required this.imagePath, required this.name, required this.role});
}
