library swipeable;

import 'dart:math' as math;

import 'package:flutter/material.dart';

enum SwipeableDirection { LEFT, RIGHT }

class Swipeable extends StatefulWidget {
  final Widget child;
  final Widget background;
  final VoidCallback? onSwipeStart;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeCancel;
  final VoidCallback? onSwipeEnd;
  final double threshold;
  final SwipeableDirection? direction;

  const Swipeable({
    Key? key,
    required this.child,
    required this.background,
    this.onSwipeStart,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeCancel,
    this.onSwipeEnd,
    this.threshold = 64.0,
    this.direction,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SwipeableState();
  }
}

class _SwipeableState extends State<Swipeable> with TickerProviderStateMixin {
  double _dragExtent = 0.0;
  late AnimationController _moveController;
  late Animation<Offset> _moveAnimation;
  bool _pastLeftThreshold = false;
  bool _pastRightThreshold = false;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _moveAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(_moveController);

    var controllerValue = 0.0;
    _moveController.animateTo(controllerValue);
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (widget.onSwipeStart != null) {
      widget.onSwipeStart!();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta;
    final oldDragExtent = _dragExtent;
    _dragExtent += delta!;

    if (oldDragExtent.sign != _dragExtent.sign) {
      setState(() {
        _updateMoveAnimation();
      });
    }

    final movePastThresholdPixels = widget.threshold;
    double newPos = _dragExtent.abs() / context.size!.width;

    SwipeableDirection swipingDirection =
        _dragExtent > 0 ? SwipeableDirection.RIGHT : SwipeableDirection.LEFT;

    if (widget.direction != null && widget.direction != swipingDirection) {
      return;
    }

    if (_dragExtent.abs() > movePastThresholdPixels) {
      // how many "thresholds" past the threshold we are. 1 = the threshold 2
      // = two thresholds.
      final n = _dragExtent.abs() / movePastThresholdPixels;

      // Take the number of thresholds past the threshold, and reduce this
      // number
      final reducedThreshold = math.pow(n, 0.3);

      final adjustedPixelPos = movePastThresholdPixels * reducedThreshold;
      newPos = adjustedPixelPos / context.size!.width;

      if (_dragExtent > 0 && !_pastLeftThreshold) {
        _pastLeftThreshold = true;

        if (widget.onSwipeRight != null) {
          widget.onSwipeRight!();
        }
      }

      if (_dragExtent < 0 && !_pastRightThreshold) {
        _pastRightThreshold = true;

        if (widget.onSwipeLeft != null) {
          widget.onSwipeLeft!();
        }
      }
    } else {
      // Send a cancel event if the user has swiped back underneath the
      // threshold
      if (_pastLeftThreshold || _pastRightThreshold) {
        if (widget.onSwipeCancel != null) {
          widget.onSwipeCancel!();
        }
      }
      _pastLeftThreshold = false;
      _pastRightThreshold = false;
    }

    _moveController.value = newPos;
  }

  void _handleDragEnd(DragEndDetails details) {
    _moveController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 200),
    );
    _dragExtent = 0.0;

    if (widget.onSwipeEnd != null) {
      widget.onSwipeEnd!();
    }
  }

  void _updateMoveAnimation() {
    var end = _dragExtent.sign;
    _moveAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: Offset(end, 0.0),
    ).animate(_moveController);
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[
      widget.background,
      SlideTransition(
        position: _moveAnimation,
        child: widget.child,
      ),
    ];

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: children,
      ),
    );
  }
}
