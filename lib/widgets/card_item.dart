import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// بطاقة قسم في الصفحة الرئيسية
class CardItem extends StatelessWidget {
  final HomeSection section;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const CardItem(
      {super.key,
      required this.section,
      required this.onTap,
      this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: section.title,
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InkWell(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      section.color.withOpacity(0.92),
                      section.color.withOpacity(0.65),
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
            if (onRemove != null)
              Positioned(
                top: 6,
                left: 6,
                child: Material(
                  color: Colors.black.withOpacity(0.55),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
