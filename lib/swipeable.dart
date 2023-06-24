library swipeable;

import 'dart:math' as math;

import 'package:flutter/material.dart';

enum SwipeableDirection { Left, Right }

class Swipeable extends StatefulWidget {
  /// The widget that will be swiped
  final Widget child;

  /// The background that will show behind the [child] when swiping
  final Widget background;

  /// Called when swipe starts
  final VoidCallback? onSwipeStart;

  /// Called when swiped left, see also [onPastThresholdEnd]
  final VoidCallback? onSwipeLeft;

  /// Called when swiped right, see also [onPastThresholdEnd]
  final VoidCallback? onSwipeRight;

  /// Called when swipe is canceled
  final VoidCallback? onSwipeCancel;

  /// Called when swipe ends, regardless of whether or not the threshold was met
  final VoidCallback? onSwipeEnd;

  /// Called when the user has dragged past the threshold, see also [onPastThresholdReleased] and [onPastThresholdEnd]
  final VoidCallback? onPastThresholdStart;

  /// Called when the user has dragged past the threshold and then released, see also [onPastThresholdReleased] and [onPastThresholdEnd]
  final VoidCallback? onPastThresholdReleased;

  /// Called when the user has dragged past the threshold and then animated back, see also [onPastThresholdReleased] and [onPastThresholdStart]
  final VoidCallback? onPastThresholdEnd;

  /// The threshold before the [child] is considered swiped
  final double threshold;

  /// The direction that the widget can be swiped in, leave blank for both
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
    this.onPastThresholdStart,
    this.onPastThresholdEnd,
    this.onPastThresholdReleased,
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
        _dragExtent > 0 ? SwipeableDirection.Right : SwipeableDirection.Left;

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

        widget.onSwipeRight?.call();
        widget.onPastThresholdStart?.call();
      }

      if (_dragExtent < 0 && !_pastRightThreshold) {
        _pastRightThreshold = true;

        widget.onSwipeLeft?.call();
        widget.onPastThresholdStart?.call();
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
    final pastThreshold = _pastLeftThreshold || _pastRightThreshold;

    _moveController
        .animateTo(
      0.0,
      duration: const Duration(milliseconds: 200),
    )
        .then((value) {
      if (pastThreshold) {
        widget.onPastThresholdEnd?.call();
      }
    });
    _dragExtent = 0.0;

    if (widget.onSwipeEnd != null) {
      widget.onSwipeEnd!();
    }

    if (pastThreshold) {
      widget.onPastThresholdReleased?.call();
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
