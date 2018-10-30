library swipeable;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class Swipeable extends StatefulWidget {
  final Widget child;
  final Widget background;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final double threshold;

  Swipeable({
    this.child,
    this.background,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.threshold,
  });

  State<StatefulWidget> createState() {
    return new _SwipeableState();
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
    _moveController = new AnimationController(
        duration: Duration(milliseconds: 200), vsync: this);
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
          widget.onSwipeLeft();
        }
        if (_dragExtent < 0 && !_pastRightThreshold) {
          _pastRightThreshold = true;
          widget.onSwipeRight();
        }
      } else {
        _pastLeftThreshold = false;
        _pastRightThreshold = false;
      }


      _moveController.animateTo(newPos);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    _moveController.animateTo(0.0, duration: Duration(milliseconds: 200));
    _dragExtent = 0.0;
  }

  void _updateMoveAnimation() {
    var end = _dragExtent.sign;
    _moveAnimation = new Tween<Offset>(
        begin: new Offset(0.0, 0.0), end: new Offset(end, 0.0))
        .animate(_moveController);
  }

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
      child: new Stack(
        children: children,
      ),
    );
  }
}
