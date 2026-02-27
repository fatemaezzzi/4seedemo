import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'student_profile_page.dart';

class SignupPageStudent extends StatelessWidget {
  const SignupPageStudent({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors from your design
    final Color tealColor = const Color(0xFF8ACDB8); // The Green/Teal
    final Color pinkColor = const Color(0xFFF5C3DE); // The Pink for the "4"

    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/signup_background.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. THE CONTENT (Centered & Fixed Width)
          Center(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 350, // <--- FIXED WIDTH prevents stretching on Web
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO: "4see"
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                        children: [
                          TextSpan(text: '4', style: TextStyle(color: pinkColor)),
                          const TextSpan(text: 'see', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    // INPUT FIELDS (Fixed Height 55)
                    _buildTextField("Username", tealColor),
                    const SizedBox(height: 15),
                    _buildTextField("Email ID", tealColor),
                    const SizedBox(height: 15),
                    _buildTextField("Password", tealColor, isPassword: true),
                    const SizedBox(height: 15),
                    _buildTextField("Confirm Password", tealColor, isPassword: true),
                    const SizedBox(height: 15),

                    // CONTINUE BUTTON
                    SizedBox(
                      width: double.infinity, // Fills the 350px width constraint
                      height: 55,             // Fixed height matches inputs
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to Role Selection Page
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StudentProfilePage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tealColor,
                          foregroundColor: Colors.black,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Continue",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // "OR" DIVIDER
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white30, thickness: 1)),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: tealColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "OR",
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: Colors.white30, thickness: 1)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // SOCIAL ICONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton('assets/google_icon.png'),
                        const SizedBox(width: 20),
                        _buildSocialButton('assets/apple_icon.png'),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Buttons/Fields
  Widget _buildTextField(String hint, Color fillColor, {bool isPassword = false}) {
    return Container(
      height: 55, // Fixed Height
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Center(
        child: TextField(
          obscureText: isPassword,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.black,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String assetPath) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Image.asset(assetPath, errorBuilder: (c,o,s) => const Icon(Icons.error)),
      ),
    );
  }
}