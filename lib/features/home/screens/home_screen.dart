import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../matches/providers/match_provider.dart';
import '../../coupons/providers/coupon_provider.dart';
import 'views/dashboard_view.dart';
import 'views/predictions_view.dart';
import 'views/stats_view.dart';
import 'views/profile_view.dart';
import '../../coupons/screens/coupon_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    DashboardView(),
    PredictionsView(),
    CouponScreen(),
    StatsView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MatchProvider>(context, listen: false).fetchMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161829),
          border: Border(
            top: BorderSide(color: Color(0xFF2A2D4A), width: 1),
          ),
        ),
        child: Consumer<CouponProvider>(
          builder: (context, couponProvider, _) {
            final int couponCount = couponProvider.activeCoupon?.selections.length ?? 0;
            
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textMuted,
              selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Accueil',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.auto_awesome_outlined),
                  activeIcon: Icon(Icons.auto_awesome),
                  label: 'Pronos',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: couponCount > 0,
                    label: Text(couponCount.toString()),
                    backgroundColor: AppColors.success,
                    child: const Icon(Icons.receipt_long_outlined),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: couponCount > 0,
                    label: Text(couponCount.toString()),
                    backgroundColor: AppColors.success,
                    child: const Icon(Icons.receipt_long),
                  ),
                  label: 'Coupon',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined),
                  activeIcon: Icon(Icons.analytics),
                  label: 'Stats',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
