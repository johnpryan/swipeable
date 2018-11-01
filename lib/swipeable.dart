library swipeable;
import 'dart:math' as math;

import 'package:flutter/material.dart';

class Swipeable extends StatefulWidget {
  final Widget child;
  final Widget background;
  final Widget secondaryBackground;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeCancel;
  final VoidCallback onSwipeEnd;
  final double threshold;

  Swipeable({
    this.child,
    this.background,
    this.secondaryBackground,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeCancel,
    this.onSwipeEnd,
    this.threshold = 64.0,
  });

  State<StatefulWidget> createState() {
    return _SwipeableState();
  }
}

class _SwipeableClipper extends CustomClipper<Rect> {
  _SwipeableClipper({@required this.moveAnimation})
      : assert(moveAnimation != null),
        super(reclip: moveAnimation);

  final Animation<Offset> moveAnimation;

  @override
  Rect getClip(Size size) {
    final double offset = moveAnimation.value.dx * size.width;
    if (offset < 0)
      return Rect.fromLTRB(size.width + offset, 0.0, size.width, size.height);
    return Rect.fromLTRB(0.0, 0.0, offset, size.height);
  }

  @override
  Rect getApproximateClipRect(Size size) => getClip(size);

  @override
  bool shouldReclip(_SwipeableClipper oldClipper) {
    return oldClipper.moveAnimation.value != moveAnimation.value;
  }
}

class _SwipeableState extends State<Swipeable> with TickerProviderStateMixin {
  double _dragExtent = 0.0;
  AnimationController _moveController;
  Animation<Offset> _moveAnimation;
  bool _pastLeftThreshold = false;
  bool _pastRightThreshold = false;

  void initState() {
    super.initState();
    _moveController =
        AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    _moveAnimation = Tween<Offset>(begin: Offset.zero, end: Offset(1.0, 0.0))
        .animate(_moveController);

    var controllerValue = 0.0;
    _moveController.animateTo(controllerValue);
  }

  void dispose() {
    super.dispose();
    _moveController.dispose();
  }

  void _handleDragStart(DragStartDetails details) {}

  void _handleDragUpdate(DragUpdateDetails details) {
    var delta = details.primaryDelta;
    var oldDragExtent = _dragExtent;
    _dragExtent += delta;
    if (oldDragExtent.sign != _dragExtent.sign) {
      setState(() {
        _updateMoveAnimation();
      });
    }
    if (!_moveController.isAnimating) {
      var movePastThresholdPixels = widget.threshold;
      var newPos = _dragExtent.abs() / context.size.width;

      if (_dragExtent.abs() > movePastThresholdPixels) {
        // how many "thresholds" past the threshold we are. 1 = the threshold 2
        // = two thresholds.
        var n = _dragExtent.abs() / movePastThresholdPixels;

        // Take the number of thresholds past the threshold, and reduce this
        // number
        var reducedThreshold = math.pow(n, 0.3);

        var adjustedPixelPos = movePastThresholdPixels * reducedThreshold;
        newPos = adjustedPixelPos / context.size.width;

        if (_dragExtent > 0 && !_pastLeftThreshold) {
          _pastLeftThreshold = true;

          if (widget.onSwipeLeft != null) {
            widget.onSwipeLeft();
          }
        }
        if (_dragExtent < 0 && !_pastRightThreshold) {
          _pastRightThreshold = true;

          if (widget.onSwipeRight != null) {
            widget.onSwipeRight();
          }
        }
      } else {
        // Send a cancel event if the user has swiped back underneath the threshold
        if (_pastLeftThreshold || _pastRightThreshold) {
          if (widget.onSwipeCancel != null) {
            widget.onSwipeCancel();
          }
        }
        _pastLeftThreshold = false;
        _pastRightThreshold = false;
      }

      _moveController.animateTo(newPos);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    _moveController.animateTo(0.0, duration: Duration(milliseconds: 200));
    _dragExtent = 0.0;

    if (widget.onSwipeEnd != null) {
      widget.onSwipeEnd();
    }
  }

  void _updateMoveAnimation() {
    var end = _dragExtent.sign;
    _moveAnimation =
        Tween<Offset>(begin: Offset(0.0, 0.0), end: Offset(end, 0.0))
            .animate(_moveController);
  }

  Widget build(BuildContext context) {
    var background = widget.background;
    if (widget.secondaryBackground != null) {
      if (_dragExtent < 0) {
        background = widget.secondaryBackground;
      }
    }

    var children = <Widget>[
      Positioned.fill(
          child: ClipRect(
              clipper: _SwipeableClipper(
                moveAnimation: _moveAnimation,
              ),
              child: background)),
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
