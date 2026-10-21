import 'package:flutter/material.dart';
import 'package:activ_user_app/shared/widgets/navigation/custom_bottom_nav_bar.dart';
import 'package:activ_user_app/features/my_bookings/presentation/screens/bookings_screen.dart';
import 'package:activ_user_app/features/calendar/presentation/screens/activ_calendar_screen.dart';
import 'package:activ_user_app/features/home/presentation/screens/home_screen.dart';
import 'package:activ_user_app/features/saved_venues/presentation/screens/saved_venues_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex;
    }
  }

  final List<Widget> _pages = const [
    HomeScreen(),
    BookingsScreen(),
    ActivCalendarScreen(),
    SavedVenuesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        }));
  }
}
