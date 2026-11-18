import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HealthXLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double fontSize;

  const HealthXLogo({
    Key? key,
    this.size = 36,
    this.showText = true,
    this.fontSize = 22,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Premium HX Overlapping Monogram Icon Box
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: size * 0.3,
                offset: Offset(0, size * 0.08),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.05),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFDAA520).withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The 'H' Background Letter
              Positioned(
                left: size * 0.15,
                top: size * 0.1,
                child: Text(
                  'H',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: size * 0.65,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              // The 'X' Foreground Letter Overlapping
              Positioned(
                right: size * 0.1,
                bottom: size * 0.08,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'X',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.75,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      height: 1,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.3),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFE0E0E0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              'HEALTH',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                fontFamily: 'Montserrat', 
              ),
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'X',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize * 1.15,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                fontFamily: 'Montserrat',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

