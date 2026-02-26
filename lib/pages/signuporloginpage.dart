import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7F68FF),
      body: Stack(
    children: [
        Positioned(
        top: 80,
        left: 0,
        right: 0,
      child:  Center(
        child: RichText(
          text: TextSpan(
            style: TextStyle(fontFamily: 'Pridi'), // Base style
            children: [
              TextSpan(
                text: '4',
                style: TextStyle(
                  fontSize: 130,
                  color: Color(0xFFFF4500), // Your orange hex
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'see',
                style: TextStyle(
                  fontSize: 60,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
        ),
      Positioned(
        top: 280,
        left: 0,
        child: Image.asset(
          'assets/imagesfor4see/vectororangeleft.png',
        ),
      ),
      Positioned(
        top: 280, // Adjust this so they sit nicely on the orange area
        bottom: 20,
        left: 20,   // Adds space from the left edge
        right: 20,  // Adds space from the right edge
        child: Column(
          children: [
            // BUTTON 1: Already have an account?
            SizedBox(
              width: 300, // Makes the button full width
              height: 45,            // Set a consistent height
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),

                ),
                child: Text(
                  'Already have an account?',
                  style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                ),
              ),
            ),

            const SizedBox(height: 15), // Space between the two buttons

            // BUTTON 2: Create an account
            SizedBox(
              width: 300,
              height: 45,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                    'Create an account',
                     style: TextStyle(
                       fontSize: 16,
                       fontWeight: FontWeight.w600,
                       color: Colors.black,
                     ),
                ),
              ),
            ),
          ],
        ),
      ),
      Positioned(
          bottom: 0,
          left: 0,
          right: 0,
        child: Image.asset(
          'assets/imagesfor4see/Rectangle 14.png',
        ),
         ),
      Positioned(
        bottom: 20,
        left: 0,
        right: 0,
        child: Image.asset(
          'assets/imagesfor4see/Woman with tablet learning online.png',
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Image.asset(
          'assets/imagesfor4see/Vector.png',
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        width: 200,
        child: Image.asset(
          'assets/imagesfor4see/Vector (1).png',
          fit: BoxFit.contain,
        ),
      ),
      Positioned(
       top: 0,
        right: 0,
        child: Image.asset(
          'assets/imagesfor4see/Vectororangeright.png',
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Image.asset(
          'assets/imagesfor4see/vectorpurpleright.png',
        ),
      ),
    ],
      ),
    );
  }
}
