import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final int particleCount = 8;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = [];
    _animations = [];

    for (int i = 0; i < particleCount; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 3000 + (i * 500)),
        vsync: this,
      );

      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      ));

      _controllers.add(controller);
      _animations.add(animation);

      controller.repeat();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: List.generate(particleCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              final progress = _animations[index].value;
              final size = MediaQuery.of(context).size;
              
              // Calculate particle position
              final x = (size.width * 0.1) + 
                       (size.width * 0.8 * math.sin(progress * 2 * math.pi + index));
              final y = size.height * progress;
              
              return Positioned(
                left: x,
                top: y - 50, // Start above screen
                child: _buildParticle(index),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildParticle(int index) {
    final colors = [
      Colors.orange.withOpacity(0.1),
      Colors.green.withOpacity(0.1),
      Colors.blue.withOpacity(0.1),
      Colors.purple.withOpacity(0.1),
    ];
    
    final shapes = [
      Icons.circle,
      Icons.star,
      Icons.favorite,
      Icons.hexagon,
    ];
    
    return Container(
      width: 20 + (index % 3) * 10,
      height: 20 + (index % 3) * 10,
      decoration: BoxDecoration(
        color: colors[index % colors.length],
        shape: BoxShape.circle,
      ),
      child: Icon(
        shapes[index % shapes.length],
        color: colors[index % colors.length].withOpacity(0.3),
        size: 15 + (index % 2) * 5,
      ),
    );
  }
}
