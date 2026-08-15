import 'package:flutter/material.dart';

class LocationRadarWidget extends StatefulWidget {
  final bool isScanning;
  final double radiusMeters;

  const LocationRadarWidget({
    Key? key,
    this.isScanning = true,
    this.radiusMeters = 10.0,
  }) : super(key: key);

  @override
  State<LocationRadarWidget> createState() => _LocationRadarWidgetState();
}

class _LocationRadarWidgetState extends State<LocationRadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double pulseScale = widget.isScanning ? 1.0 + (_controller.value * 0.4) : 1.0;
          double opacity = widget.isScanning ? (1.0 - _controller.value) : 0.4;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer radar ring pulse
              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E6FF).withOpacity(opacity * 0.3),
                    border: Border.all(
                      color: const Color(0xFF00E6FF).withOpacity(opacity),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Inner geofence circle
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00E6FF).withOpacity(0.4),
                      const Color(0xFF00C8E0).withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF00E6FF),
                    width: 2,
                  ),
                ),
              ),
              // Center location pin
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF00E6FF),
                    size: 38,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                    ),
                    child: Text(
                      '${widget.radiusMeters.toInt()}m Radius',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
