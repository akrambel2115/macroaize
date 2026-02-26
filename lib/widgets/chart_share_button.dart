import 'package:flutter/material.dart';
import 'package:macroaize/shared/services/chart_share_service.dart';

class ChartShareButton extends StatelessWidget {
  final GlobalKey boundaryKey;
  final String? shareText;

  const ChartShareButton({
    super.key,
    required this.boundaryKey,
    this.shareText,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        return Semantics(
          button: true,
          label: 'Share chart',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              final box = ctx.findRenderObject() as RenderBox?;
              final rect =
                  box != null
                      ? box.localToGlobal(Offset.zero) & box.size
                      : null;
              ChartShareService.shareChartBoundary(
                boundaryKey: boundaryKey,
                sharePositionOrigin: rect,
                text: shareText,
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.share_outlined),
            ),
          ),
        );
      },
    );
  }
}
