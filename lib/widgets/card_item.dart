import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// بطاقة قسم في الصفحة الرئيسية
class CardItem extends StatelessWidget {
  final HomeSection section;
  final VoidCallback onTap;

  const CardItem({super.key, required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: section.title,
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  section.color.withValues(alpha: 0.92),
                  section.color.withValues(alpha: 0.65),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(section.icon, size: 44, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  section.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
