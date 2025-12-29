import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fade1;
  late Animation<double> _fade2;
  late Animation<Offset> _slide1;
  late Animation<Offset> _slide2;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fade1 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _fade2 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _slide1 = Tween(
      begin: const Offset(0, 0.8), // MUCH MORE VISIBLE
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slide2 = Tween(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/sign-up-page.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),

                    // Username animation
                    FadeTransition(
                      opacity: _fade1,
                      child: SlideTransition(
                        position: _slide1,
                        child: buildTextField("Username"),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password animation
                    FadeTransition(
                      opacity: _fade2,
                      child: SlideTransition(
                        position: _slide2,
                        child: buildTextField(
                          "Password",
                          isPassword: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.white)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "OR",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        socialButton(Icons.g_mobiledata),
                        socialButton(Icons.apple),
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

  static Widget buildTextField(String hint, {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.orange,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static Widget socialButton(IconData icon) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white,
      child: Icon(icon, size: 32, color: Colors.black),
    );
  }
}
