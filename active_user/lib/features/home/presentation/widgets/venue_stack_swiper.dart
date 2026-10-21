import 'package:flutter/material.dart';
import 'package:activ_user_app/features/home/presentation/widgets/swipe_venue_card.dart';
import 'package:activ_user_app/routes/app_routes.dart';

class VenueStackSwiper extends StatefulWidget {
  final List<Map<String, dynamic>> venues;

  const VenueStackSwiper({super.key, required this.venues});

  @override
  State<VenueStackSwiper> createState() => _VenueStackSwiperState();
}

class _VenueStackSwiperState extends State<VenueStackSwiper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  bool _isSwipingOffScreen = false;
  bool _isSwipingLeft = false;
  Offset _startDragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          setState(() {});
        });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_animationController.isAnimating) return;
    _isSwipingOffScreen = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isSwipingOffScreen) return;

    double deltaDx = details.delta.dx;
    double newDx = _dragOffset.dx + deltaDx;

    // Apply resistance if trying to swipe out of bounds
    if (_currentIndex == 0 && newDx > 0) {
      newDx = _dragOffset.dx + (deltaDx * 0.25);
    } else if (_currentIndex == widget.venues.length - 1 && newDx < 0) {
      newDx = _dragOffset.dx + (deltaDx * 0.25);
    }

    setState(() {
      _dragOffset = Offset(newDx, 0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isSwipingOffScreen) return;

    final velocity = details.velocity.pixelsPerSecond.dx;

    // Prevent right swipe action on the first card
    if (_currentIndex == 0 && (_dragOffset.dx > 0 || velocity > 300)) {
      _resetPosition();
      return;
    }

    // Prevent left swipe action on the last card
    if (_currentIndex == widget.venues.length - 1 &&
        (_dragOffset.dx < 0 || velocity < -300)) {
      _resetPosition();
      return;
    }

    if (_dragOffset.dx.abs() > 100 || velocity.abs() > 300) {
      _isSwipingLeft = _dragOffset.dx < 0 || velocity < -300;
      _animateOffScreen();
    } else {
      _resetPosition();
    }
  }

  void _animateOffScreen() {
    _isSwipingOffScreen = true;
    _startDragOffset = _dragOffset;

    _animationController.forward(from: 0).then((_) {
      setState(() {
        if (_isSwipingLeft) {
          if (_currentIndex < widget.venues.length - 1) {
            _currentIndex++;
          }
        } else {
          if (_currentIndex > 0) {
            _currentIndex--;
          }
        }
        _dragOffset = Offset.zero;
        _isSwipingOffScreen = false;
        _animationController.reset();
      });
    });
  }

  void _resetPosition() {
    _startDragOffset = _dragOffset;
    _animationController.forward(from: 0).then((_) {
      setState(() {
        _dragOffset = Offset.zero;
        _animationController.reset();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.venues.isEmpty) {
      return const Center(
        child: Text(
          'No venues found around you.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final venues = widget.venues;
    final int count = venues.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // To maintain perfect 16px horizontal padding on any device, the total visual width of the stack must exactly equal maxWidth.
        // The topmost card's left edge is at 0.
        // The rearmost card (index 2) is translated 44px right, and scaled down to 0.90.
        // Because scaling happens from the center, the rightmost edge of the rearmost card is mathematically:
        // 44.0 + cardWidth - (cardWidth * 0.05) = 44.0 + (cardWidth * 0.95).
        // Solving for cardWidth to ensure it perfectly hits maxWidth:
        final cardWidth = (constraints.maxWidth - 44.0) / 0.95;

        bool isDraggingRight = false;
        if (_isSwipingOffScreen) {
          isDraggingRight = !_isSwipingLeft;
        } else if (_dragOffset.dx != 0) {
          isDraggingRight = _dragOffset.dx > 0;
        } else if (_startDragOffset.dx != 0 &&
            _animationController.isAnimating) {
          isDraggingRight = _startDragOffset.dx > 0;
        }

        bool isOutOfBoundsDrag =
            (_currentIndex == 0 && isDraggingRight) ||
            (_currentIndex == count - 1 && !isDraggingRight);

        if (_currentIndex == 0 && isDraggingRight) {
          isDraggingRight = false;
        }

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: constraints.maxWidth,
            height: 344,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: List.generate(3, (index) {
                final cardIndex = 2 - index; // 2, 1, 0 (0 is topmost)

                int actualIndex;
                if (!isDraggingRight) {
                  actualIndex = _currentIndex + cardIndex;
                } else {
                  actualIndex = _currentIndex + cardIndex - 1;
                }

                if (actualIndex >= count || actualIndex < 0) {
                  return const SizedBox.shrink();
                }

                final double animValue = Curves.easeOutCubic.transform(
                  _animationController.value,
                );

                // Calculate progress
                double progress = 0.0;
                if (!_isSwipingOffScreen && !_animationController.isAnimating) {
                  progress = (_dragOffset.dx.abs() / constraints.maxWidth)
                      .clamp(0.0, 1.0);
                } else if (_isSwipingOffScreen &&
                    _animationController.isAnimating) {
                  final initialProgress =
                      (_startDragOffset.dx.abs() / constraints.maxWidth).clamp(
                        0.0,
                        1.0,
                      );
                  progress =
                      initialProgress + ((1.0 - initialProgress) * animValue);
                } else if (!_isSwipingOffScreen &&
                    _animationController.isAnimating) {
                  final initialProgress =
                      (_startDragOffset.dx.abs() / constraints.maxWidth).clamp(
                        0.0,
                        1.0,
                      );
                  progress = initialProgress * (1.0 - animValue);
                }

                if (isOutOfBoundsDrag) {
                  progress = 0.0;
                }

                if (cardIndex == 0) {
                  // Topmost card
                  Offset currentOffset = _dragOffset;

                  if (_animationController.isAnimating) {
                    if (_isSwipingOffScreen) {
                      final endOffset = Offset(
                        _isSwipingLeft
                            ? -constraints.maxWidth * 1.5
                            : constraints.maxWidth,
                        _startDragOffset.dy,
                      );
                      currentOffset = Offset.lerp(
                        _startDragOffset,
                        endOffset,
                        animValue,
                      )!;
                    } else {
                      currentOffset = Offset.lerp(
                        _startDragOffset,
                        Offset.zero,
                        animValue,
                      )!;
                    }
                  }

                  if (isDraggingRight) {
                    // If right swipe, the incoming card starts from the left
                    currentOffset = Offset(
                      -constraints.maxWidth + currentOffset.dx,
                      currentOffset.dy,
                    );
                  }

                  return Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Transform.translate(
                      offset: currentOffset,
                      child: SwipeVenueCard(
                        venue: venues[actualIndex],
                        width: cardWidth,
                        onTap: () {
                          if (isDraggingRight) {
                            return; // Prevent tapping incoming card during drag
                          }
                          Navigator.pushNamed(
                            context,
                            AppRoutes.venueDetails,
                            arguments: {'venueId': venues[actualIndex]['id']},
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  // Background cards
                  double baseScale;
                  double nextScale;
                  double baseTranslateX;
                  double nextTranslateX;
                  double baseTranslateY;
                  double nextTranslateY;
                  double baseOpacity;
                  double nextOpacity;

                  if (!isDraggingRight) {
                    // Standard shrink -> grow (Next cards)
                    if (cardIndex == 1) {
                      baseScale = 0.95;
                      nextScale = 1.0;
                      baseTranslateX = 22.0;
                      nextTranslateX = 0.0;
                      baseTranslateY = 0.0;
                      nextTranslateY = 0.0;
                      baseOpacity = 1.0;
                      nextOpacity = 1.0;
                    } else {
                      baseScale = 0.90;
                      nextScale = 0.95;
                      baseTranslateX = 44.0;
                      nextTranslateX = 22.0;
                      baseTranslateY = 0.0;
                      nextTranslateY = 0.0;
                      baseOpacity = 0.8;
                      nextOpacity = 1.0;
                    }
                  } else {
                    // Grow -> shrink (Current cards becoming background)
                    if (cardIndex == 1) {
                      baseScale = 1.0;
                      nextScale = 0.95;
                      baseTranslateX = 0.0;
                      nextTranslateX = 22.0;
                      baseTranslateY = 0.0;
                      nextTranslateY = 0.0;
                      baseOpacity = 1.0;
                      nextOpacity = 1.0;
                    } else {
                      baseScale = 0.95;
                      nextScale = 0.90;
                      baseTranslateX = 22.0;
                      nextTranslateX = 44.0;
                      baseTranslateY = 0.0;
                      nextTranslateY = 0.0;
                      baseOpacity = 1.0;
                      nextOpacity = 0.8;
                    }
                  }

                  final scale =
                      baseScale + ((nextScale - baseScale) * progress);
                  final translateX =
                      baseTranslateX +
                      ((nextTranslateX - baseTranslateX) * progress);
                  final translateY =
                      baseTranslateY +
                      ((nextTranslateY - baseTranslateY) * progress);
                  final opacity =
                      baseOpacity + ((nextOpacity - baseOpacity) * progress);

                  return Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(translateX, translateY),
                        child: Transform.scale(
                          scale: scale,
                          child: SwipeVenueCard(
                            venue: venues[actualIndex],
                            showButton: false,
                            width: cardWidth,
                            onTap: () {
                              if (!isDraggingRight && cardIndex == 1) return;
                              if (isDraggingRight && cardIndex == 1) {
                                // In right swipe, cardIndex 1 is the Current card we're shrinking
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.venueDetails,
                                  arguments: {'venueId': venues[actualIndex]['id']},
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }),
            ),
          ),
        );
      },
    );
  }
}
