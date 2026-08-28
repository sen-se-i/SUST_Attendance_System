import 'package:flutter/material.dart';

class RadiusSliderWidget extends StatelessWidget {
  final double selectedRadius;
  final ValueChanged<double> onChanged;

  const RadiusSliderWidget({
    Key? key,
    required this.selectedRadius,
    required this.onChanged,
  }) : super(key: key);

  static const List<double> radiusOptions = [
    20.0,
    30.0,
    40.0,
    50.0,
    60.0,
    70.0,
    80.0,
    90.0,
    100.0,
  ];

  @override
  Widget build(BuildContext context) {
    // Ensure selectedRadius matches one of the options
    final currentVal = radiusOptions.contains(selectedRadius)
        ? selectedRadius
        : 30.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GEOFENCE RADIUS',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  border: Border.all(color: Colors.white),
                ),
                child: Text(
                  '${currentVal.toInt()}M ACTIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: currentVal,
                dropdownColor: const Color(0xFF141414),
                isExpanded: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
                items: radiusOptions.map((r) {
                  return DropdownMenuItem<double>(
                    value: r,
                    child: Text('${r.toInt()} METERS (${r.toInt()}M)'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    onChanged(val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
