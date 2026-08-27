import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ZoomableAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final String heroTag;
  final double radius;
  final Color backgroundColor;
  final Color textColor;

  const ZoomableAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.heroTag,
    this.radius = 60.0,
    this.backgroundColor = Colors.purple,
    this.textColor = Colors.white,
  });

  bool get _hasValidImage {
    return imageUrl != null &&
        (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAvatarZoom(context),
      child: Hero(
        tag: heroTag,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          backgroundImage: _hasValidImage
              ? CachedNetworkImageProvider(
                  imageUrl!,
                  cacheKey: imageUrl!.split('?').first,
                )
              : null,
          onBackgroundImageError: _hasValidImage ? (_, __) {} : null,
          child: _hasValidImage ? null : _buildFallbackContent(radius * 0.5),
        ),
      ),
    );
  }

  Widget _buildFallbackContent(double fontSize) {
    return Text(
      name != null && name!.isNotEmpty ? name![0].toUpperCase() : '?',
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _showAvatarZoom(BuildContext context) {
    final TransformationController transformationController =
        TransformationController();
    TapDownDetails? doubleTapDetails;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onDoubleTapDown: (details) => doubleTapDetails = details,
              onDoubleTap: () {
                if (transformationController.value != Matrix4.identity()) {
                  transformationController.value = Matrix4.identity();
                } else {
                  final position = doubleTapDetails!.localPosition;
                  transformationController.value = Matrix4.identity()
                    ..translate(-position.dx * 2, -position.dy * 2)
                    ..scale(3.0);
                }
              },
              child: InteractiveViewer(
                transformationController: transformationController,
                panEnabled: true,
                minScale: 1.0,
                maxScale: 5.0,
                child: Hero(
                  tag: heroTag,
                  child: _hasValidImage
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          cacheKey: imageUrl!.split('?').first,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (_, __, ___) => _buildZoomedFallback(),
                        )
                      : _buildZoomedFallback(),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomedFallback() {
    return CircleAvatar(
      radius: 100,
      backgroundColor: backgroundColor,
      child: _buildFallbackContent(80),
    );
  }
}
