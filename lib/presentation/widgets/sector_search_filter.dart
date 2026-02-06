import 'package:flutter/material.dart';

class SectorSearchFilter extends StatelessWidget {
  final List<Map<String, dynamic>> selectedFilters; // List of {'type': ..., 'value': ...}
  final Function(List<Map<String, dynamic>>) onFiltersChanged;

  const SectorSearchFilter({
    super.key,
    required this.selectedFilters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              _buildBtn('흑백요리사\n시즌1', 'bw', 'season1'),
              const SizedBox(width: 6),
              _buildBtn('흑백요리사\n시즌2', 'bw', 'season2'),
              const SizedBox(width: 6),
              _buildBtn('예능출연\n맛집', 'show', 'all'),
              const SizedBox(width: 6),
              _buildBtn('미슐랭\nRegistered', 'michelin', 'michelin'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildBtn('미슐랭\n1스타', 'michelin', '1star'),
              const SizedBox(width: 6),
              _buildBtn('미슐랭\n2스타', 'michelin', '2star'),
              const SizedBox(width: 6),
              _buildBtn('미슐랭\n3스타', 'michelin', '3star'),
              const SizedBox(width: 6),
              _buildBtn('미슐랭\n빕구르망', 'michelin', 'bib'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBtn(String label, String type, String value) {
    final isSelected = selectedFilters.any((f) => f['type'] == type && f['value'] == value);
    
    return Expanded(
      child: InkWell(
        onTap: () {
          final newFilters = List<Map<String, dynamic>>.from(selectedFilters);
          if (isSelected) {
            newFilters.removeWhere((f) => f['type'] == type && f['value'] == value);
          } else {
            newFilters.add({'type': type, 'value': value});
          }
          onFiltersChanged(newFilters);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white30,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF1E1E1E) : Colors.white, // Inverted for Dark AppBar
            ),
          ),
        ),
      ),
    );
  }
}
