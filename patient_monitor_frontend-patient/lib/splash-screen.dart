import 'package:flutter/material.dart';
import 'login_page.dart'; 

class AnimatedSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final int durationSeconds;
  
  const AnimatedSplashScreen({
    Key? key,
    required this.nextScreen,
    this.durationSeconds = 3,
  }) : super(key: key);

  @override
  _AnimatedSplashScreenState createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Create rotation animation (0 to 360 degrees)
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0, // 1.0 represents 360 degrees
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
    
    // Create scale animation (pulse effect)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.5, end: 1.2),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
    
    // Create fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    
    // Start the animation
    _rotationController.forward();
    
    // Navigate to next screen after animation completes + delay
    Future.delayed(Duration(milliseconds: widget.durationSeconds * 1000), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => widget.nextScreen),
      );
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rotating and scaling icon with rounded corners
                Transform.rotate(
                  angle: _rotationAnimation.value * 2 * 3.14159, // Convert to radians
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(75), // Makes it circular (half of width/height)
                        child: Image.asset(
                          'assets/celebral.png',
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover, // Changed from BoxFit.contain to BoxFit.cover
                        ),
                      ),
                    ),
                  ),
                ),
              ],
                   
            );
          },
        ),
      ),
    );
  }
}