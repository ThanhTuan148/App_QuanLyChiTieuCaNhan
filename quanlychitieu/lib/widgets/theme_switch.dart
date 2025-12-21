/// Widget toggle dark mode với animation mặt trời/mặt trăng
/// Dựa trên design từ Uiverse.io by Galahhad
import 'package:flutter/material.dart';

class ThemeSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ThemeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<ThemeSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ThemeSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const containerWidth = 90.0;
    const containerHeight = 40.0;
    const circleDiameter = 54.0;
    const sunMoonDiameter = 34.0;
    const offset = (circleDiameter - containerHeight) / 2;

    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final isDark = widget.value;
          final slideValue = _slideAnimation.value;
          
          // Calculate circle position
          final circleLeft = (containerWidth - circleDiameter) * slideValue - offset;
          
          // Animated background color
          final bgColor = Color.lerp(
            const Color(0xFF3D7EAE), // Light mode - blue sky
            const Color(0xFF1D1F2C), // Dark mode - dark night
            slideValue,
          )!;

          return Container(
            width: containerWidth,
            height: containerHeight,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Clouds (only in light mode) - positioned at bottom center
                if (!isDark)
                  Positioned(
                    left: (containerWidth - 55) / 2,
                    bottom: -5,
                    child: _buildClouds(),
                  ),
                
                // Stars (only in dark mode) - positioned on the left
                if (isDark)
                  Positioned(
                    left: 10,
                    top: containerHeight / 2 - 8.5,
                    child: _buildStars(),
                  ),
                
                // Circle container with sun/moon
                Positioned(
                  left: circleLeft,
                  top: -offset,
                  child: Container(
                    width: circleDiameter,
                    height: circleDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          spreadRadius: 8,
                          blurRadius: 12,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          spreadRadius: 4,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: sunMoonDiameter,
                        height: sunMoonDiameter,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFFC4C9D1)
                              : const Color(0xFFECCA2F),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark
                                      ? const Color(0xFFC4C9D1)
                                      : const Color(0xFFECCA2F))
                                  .withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.6),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                              spreadRadius: -1,
                            ),
                            BoxShadow(
                              color: (isDark
                                      ? const Color(0xFF969696)
                                      : const Color(0xFFA1872A))
                                  .withOpacity(0.8),
                              offset: const Offset(0, -1),
                              blurRadius: 2,
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                        child: isDark
                            ? Stack(
                                children: _buildMoonSpots(),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildMoonSpots() {
    return [
      Positioned(
        top: 12,
        left: 5,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF959DB1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        top: 16,
        left: 20,
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF959DB1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        top: 6,
        left: 13,
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFF959DB1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildClouds() {
    return SizedBox(
      width: 55,
      height: 25,
      child: CustomPaint(
        painter: CloudsPainter(),
      ),
    );
  }

  Widget _buildStars() {
    return SizedBox(
      width: 44,
      height: 17,
      child: CustomPaint(
        painter: StarsPainter(),
      ),
    );
  }
}

class CloudsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cloudColor = const Color(0xFFF3FDFF);
    final backCloudColor = const Color(0xFFAACADF);
    final paint = Paint()..style = PaintingStyle.fill;

    // Cloud group - bottom right
    // Main cloud circles
    paint.color = cloudColor;
    canvas.drawCircle(const Offset(8, 18), 7, paint);
    canvas.drawCircle(const Offset(20, 18), 7, paint);
    canvas.drawCircle(const Offset(32, 18), 7, paint);
    canvas.drawCircle(const Offset(44, 18), 7, paint);
    
    // Back layer clouds for depth
    paint.color = backCloudColor;
    canvas.drawCircle(const Offset(14, 14), 6, paint);
    canvas.drawCircle(const Offset(26, 14), 6, paint);
    canvas.drawCircle(const Offset(38, 14), 6, paint);
    
    // Top highlights
    paint.color = cloudColor;
    canvas.drawCircle(const Offset(14, 12), 5, paint);
    canvas.drawCircle(const Offset(26, 12), 5, paint);
    canvas.drawCircle(const Offset(38, 12), 5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw stars with different sizes
    final starPositions = [
      {'pos': const Offset(5, 3), 'size': 1.5},
      {'pos': const Offset(12, 8), 'size': 1.0},
      {'pos': const Offset(20, 2), 'size': 1.5},
      {'pos': const Offset(28, 7), 'size': 1.0},
      {'pos': const Offset(35, 4), 'size': 1.5},
      {'pos': const Offset(42, 9), 'size': 1.0},
    ];

    for (final star in starPositions) {
      final position = star['pos'] as Offset;
      final starSize = star['size'] as double;
      
      // Glow effect
      paint.color = Colors.white.withOpacity(0.3);
      canvas.drawCircle(position, starSize + 1, paint);
      // Star core
      paint.color = Colors.white;
      canvas.drawCircle(position, starSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
