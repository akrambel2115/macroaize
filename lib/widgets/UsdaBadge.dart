import 'package:flutter/material.dart';

class UsdaBadge extends StatelessWidget {
  final bool verified;
  final bool filled; // New parameter for solid background
  final VoidCallback? onTap;
  const UsdaBadge({super.key, this.verified = false, this.filled = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = verified ? Colors.green : Colors.orange;
    final text = verified ? 'Verified' : 'Not Verified';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: filled 
            ? color.withOpacity(0.9) // Solid background when filled
            : color.withOpacity(0.15), // Translucent background when not filled
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled 
              ? color.withOpacity(0.9) 
              : color.withOpacity(0.4)
          ),
          // Add subtle shadow for better visibility over images when filled
          boxShadow: filled ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              verified ? Icons.verified_rounded : Icons.warning_rounded, 
              size: 14, 
              color: filled ? Colors.white : color
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: filled ? Colors.white : color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
