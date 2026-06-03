import 'package:flutter/material.dart';

class BounchingDialog extends StatefulWidget {
  final Widget child;
  final double? height;
  final double? width;
  final double padding;
  const BounchingDialog(
      {super.key, required this.child, this.height, this.width, this.padding=10});

  @override
  State<BounchingDialog> createState() => _BounchingDialogState();
}

class _BounchingDialogState extends State<BounchingDialog>
    with SingleTickerProviderStateMixin {
  AnimationController? controller;
  Animation<double>? scaleAnimation;
  @override
  void initState() {
    super.initState();

    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    scaleAnimation =
        CurvedAnimation(parent: controller!, curve: Curves.elasticInOut);

    controller!.addListener(() {
      setState(() {});
    });

    controller!.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.padding != 0 ? widget.padding :60.0),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: ScaleTransition(
            scale: scaleAnimation!,
            child: SizedBox(
              height: widget.height,
              child: Card(
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
