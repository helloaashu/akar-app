import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ImageCarousel extends StatefulWidget {
  final String complaintId;

  ImageCarousel({required this.complaintId});

  @override
  _ImageCarouselState createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  List<String> imageUrls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  void fetchImages() async {
    try {
      print("Fetching document for complaint ID: ${widget.complaintId}");
      var documentSnapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.complaintId)
          .get();

      if (documentSnapshot.exists) {
        print("Document exists");
        setState(() {
          imageUrls = List<String>.from(documentSnapshot['images']);
          print("Fetched images: $imageUrls");

          // Ensure only up to 3 images are displayed
          if (imageUrls.length > 3) {
            imageUrls = imageUrls.sublist(0, 3);
          }
          isLoading = false;
        });
      } else {
        print("Document does not exist");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching images: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Carousel', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white), // This will make the back button white
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : imageUrls.isEmpty
          ? Center(child: Text("No images available"))
          : Center(
        child: CarouselSlider(
          options: CarouselOptions(
            height: 400.0,
            enlargeCenterPage: true,
            autoPlay: true,
            aspectRatio: 16 / 9,
            autoPlayInterval: Duration(seconds: 3),
            autoPlayAnimationDuration: Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enableInfiniteScroll: false,
            viewportFraction: 0.8,
          ),
          items: imageUrls.map((imageUrl) {
            print("Displaying image: $imageUrl"); // Debug print
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print("Error loading image: $imageUrl"); // Debug print
                        return Container(
                          color: Colors.grey,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
