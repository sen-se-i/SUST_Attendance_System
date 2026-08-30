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
      width: 170,
      height: 170,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double pulseScale = widget.isScanning ? 1.0 + (_controller.value * 0.35) : 1.0;
          double opacity = widget.isScanning ? (1.0 - _controller.value) : 0.4;

          return Stack(
            alignment: Alignment.center,
            children: [

              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: opacity * 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: opacity * 0.7),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  border: Border.all(
                    color: const Color(0xFFFFFFFF),
                    width: 1.5,
                  ),
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.white),
                    ),
                    child: const Text(
                      'GPS',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white),
                    ),
                    child: Text(
                      '${widget.radiusMeters.toInt()}M RAD',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
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
