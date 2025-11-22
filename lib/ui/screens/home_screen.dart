import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../state/app_state.dart';
import '../../ml/inference_service.dart';
import '../../services/motion_service.dart';
import '../components/glass_card.dart';
import '../components/particle_background.dart';
import '../components/motion_parallax.dart';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              Colors.blue.shade900,
            ],
          ),
        ),
        child: ParticleBackground(
          particleCount: 60,
          particleColor: Colors.white.withValues(alpha: 0.4),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Settings toggle for motion effects
                  Consumer<AppState>(
                    builder: (context, appState, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.motion_photos_on,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Motion',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: appState.motionEffectsEnabled,
                            onChanged: (value) {
                              appState.setMotionEffects(value);
                              if (value) {
                                MotionService().start();
                              } else {
                                MotionService().stop();
                              }
                            },
                            activeTrackColor: Colors.greenAccent.withValues(alpha: 0.5),
                            activeThumbColor: Colors.greenAccent,
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // App Title with glow and parallax
                  MotionParallax(
                    intensity: 0.5,
                    child: const Text(
                      'DermAssist',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: -0.2, end: 0),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  MotionParallax(
                    intensity: 0.3,
                    child: const Text(
                      'AI-Powered Skin Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideX(begin: -0.2, end: 0),
                  ),
                
                  const Spacer(),
                  
                  // Main illustration with 3D effect and parallax
                  MotionParallax(
                    intensity: 1.2,
                    enableBlur: true,
                    maxBlur: 2.0,
                    child: Center(
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.3),
                              Colors.blue.withValues(alpha: 0.2),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.4),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                            BoxShadow(
                              color: Colors.purple.withValues(alpha: 0.3),
                              blurRadius: 80,
                              spreadRadius: 30,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.health_and_safety,
                          size: 120,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            duration: 3000.ms,
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1.05, 1.05),
                            curve: Curves.easeInOut,
                          )
                          .then()
                          .scale(
                            duration: 3000.ms,
                            begin: const Offset(1.05, 1.05),
                            end: const Offset(0.95, 0.95),
                            curve: Curves.easeInOut,
                          ),
                    )
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 400.ms)
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                  ),
                  
                  const Spacer(),
                
                  // Status indicator with glassmorphism and parallax
                  MotionParallax(
                    intensity: 0.7,
                    child: Consumer<AppState>(
                      builder: (context, appState, child) {
                        return GlassCard(
                        blur: 15,
                        opacity: 0.15,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: appState.isModelLoaded
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.orange.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                appState.isModelLoaded
                                    ? Icons.check_circle
                                    : Icons.hourglass_empty,
                                color: appState.isModelLoaded
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appState.isModelLoaded
                                        ? (InferenceService().isMockMode 
                                            ? 'Demo Mode Active' 
                                            : 'AI Model Ready')
                                        : 'Initializing...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    appState.isModelLoaded
                                        ? 'Ready to analyze'
                                        : appState.errorMessage ?? 'Loading model...',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 600.ms)
                          .slideY(begin: 0.2, end: 0);
                      },
                    ),
                  ),
                
                  const SizedBox(height: 24),
                  
                  // Scan button with stunning design and parallax
                  MotionParallax(
                    intensity: 0.8,
                    child: Consumer<AppState>(
                      builder: (context, appState, child) {
                        return Container(
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: appState.isModelLoaded
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.9),
                                    Colors.blue.shade100.withValues(alpha: 0.8),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.withValues(alpha: 0.3),
                                    Colors.grey.withValues(alpha: 0.2),
                                  ],
                                ),
                          boxShadow: appState.isModelLoaded
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: appState.isModelLoaded
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CameraScreen(),
                                      ),
                                    );
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_rounded,
                                    size: 32,
                                    color: appState.isModelLoaded
                                        ? Colors.blue.shade700
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Scan Skin',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: appState.isModelLoaded
                                          ? Colors.blue.shade700
                                          : Colors.grey,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 800.ms)
                          .slideY(begin: 0.3, end: 0)
                          .then(delay: 200.ms)
                          .shimmer(
                            duration: 2000.ms,
                            color: Colors.white.withValues(alpha: 0.3),
                          );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
