import 'package:flutter/material.dart';

class RadiusSliderWidget extends StatelessWidget {
  final double selectedRadius;
  final ValueChanged<double> onChanged;

  const RadiusSliderWidget({
    Key? key,
    required this.selectedRadius,
    required this.onChanged,
  }) : super(key: key);

  static const List<double> presetRadii = [20.0, 50.0, 100.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF213042)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.radar_rounded, color: Color(0xFF00E6FF), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Geofence Radius',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E6FF), Color(0xFF00E6FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${selectedRadius.toInt()} Meters',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF00E6FF),
              inactiveTrackColor: const Color(0xFF213042),
              thumbColor: const Color(0xFF00E6FF),
              overlayColor: const Color(0xFF00E6FF).withOpacity(0.2),
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: selectedRadius,
              min: 20.0,
              max: 100.0,
              divisions: 16,
              label: '${selectedRadius.toInt()}m',
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: presetRadii.map((r) {
              final isSelected = (selectedRadius - r).abs() < 0.5;
              return GestureDetector(
                onTap: () => onChanged(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00E6FF) : const Color(0xFF070B12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00E6FF) : const Color(0xFF213042),
                    ),
                  ),
                  child: Text(
                    '${r.toInt()}m',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
