import 'package:flutter/material.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B3A3A), // dark maroon background
      body: Center(
        child: Container(
          width: 420, // fixed width for web
          height: 650,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: const Color(0xFF6B3A3A),
          ),
          child: Stack(
            children: [

              /// Green Oval Background
              Positioned(
                top: 0,
                left: -50,
                right: -50,
                child: Container(
                  height: 500,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9EC3B0),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(300),
                      bottomRight: Radius.circular(300),
                    ),
                  ),
                ),
              ),

              /// Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const SizedBox(height: 80),

                    /// Logo Text
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: "4",
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B3A3A),
                            ),
                          ),
                          TextSpan(
                            text: "see",
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    /// Username Field
                    _buildTextField("Username"),

                    const SizedBox(height: 20),

                    /// Password Field
                    _buildTextField("Password", isPassword: true),

                    const SizedBox(height: 20),

                    /// Continue Button
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[200],
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// OR Divider
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.white)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("OR",
                              style: TextStyle(color: Colors.white)),
                        ),
                        Expanded(child: Divider(color: Colors.white)),
                      ],
                    ),

                    const SizedBox(height: 30),

                    /// Social Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialIcon(Icons.g_mobiledata),
                        const SizedBox(width: 30),
                        _socialIcon(Icons.apple),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.pink[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.white,
      child: Icon(icon, size: 35, color: Colors.black),
    );
  }
}