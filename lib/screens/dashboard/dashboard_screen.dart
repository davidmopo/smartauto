import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../widgets/dashboard/quick_actions_widget.dart';
import '../../widgets/dashboard/recent_campaigns_widget.dart';
import '../../widgets/dashboard/activity_feed_widget.dart';
import '../../widgets/dashboard/analytics_chart.dart';
import '../auth/profile_screen.dart';
import '../contacts/contacts_screen.dart';
import '../templates/templates_screen.dart';
import '../campaigns/campaigns_screen.dart';
import '../analytics/analytics_screen.dart';
import '../automation/automations_screen.dart';

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    NavigationItem(icon: Icons.contacts, label: 'Contacts', route: '/contacts'),
    NavigationItem(
      icon: Icons.campaign,
      label: 'Campaigns',
      route: '/campaigns',
    ),
    NavigationItem(icon: Icons.email, label: 'Templates', route: '/templates'),
    NavigationItem(
      icon: Icons.analytics,
      label: 'Analytics',
      route: '/analytics',
    ),
    NavigationItem(
      icon: Icons.auto_awesome,
      label: 'Automations',
      route: '/automations',
    ),
    NavigationItem(icon: Icons.settings, label: 'Settings', route: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('SmartAutoMailer'),
        leading: isWideScreen
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications - Coming soon!')),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildUserMenu(isWideScreen),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isWideScreen ? null : _buildDrawer(),
      body: Row(
        children: [
          if (isWideScreen) _buildSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildUserMenu(bool isWideScreen) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (user?.displayName?.isNotEmpty == true
                        ? user!.displayName![0].toUpperCase()
                        : user?.email[0].toUpperCase() ?? 'U'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                if (isWideScreen) ...[
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.displayName ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          itemBuilder: (context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'profile',
              child: const ListTile(
                leading: Icon(Icons.person),
                title: Text('Profile'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                });
              },
            ),
            PopupMenuItem<String>(
              value: 'settings',
              child: const ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings - Coming soon!')),
                );
              },
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'signout',
              child: const ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Sign Out', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () async {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: List.generate(_navigationItems.length, (index) {
          final item = _navigationItems[index];
          final isSelected = _selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: Icon(
                item.icon,
                color: isSelected ? Colors.blue : Colors.grey.shade700,
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey.shade700,
                ),
              ),
              selected: isSelected,
              selectedTileColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () {
                setState(() => _selectedIndex = index);
                if (index == 1) {
                  // Navigate to Contacts screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactsScreen(),
                    ),
                  );
                } else if (index == 2) {
                  // Navigate to Campaigns screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CampaignsScreen(),
                    ),
                  );
                } else if (index == 3) {
                  // Navigate to Templates screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TemplatesScreen(),
                    ),
                  );
                } else if (index == 4) {
                  // Navigate to Analytics screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
                    ),
                  );
                } else if (index == 5) {
                  // Navigate to Automations screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AutomationsScreen(),
                    ),
                  );
                } else if (index != 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.label} - Coming soon!')),
                  );
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.email, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'SmartAutoMailer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_navigationItems.length, (index) {
            final item = _navigationItems[index];
            final isSelected = _selectedIndex == index;
            return ListTile(
              leading: Icon(item.icon, color: isSelected ? Colors.blue : null),
              title: Text(
                item.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : null,
                ),
              ),
              selected: isSelected,
              onTap: () {
                setState(() => _selectedIndex = index);
                Navigator.pop(context);
                if (index == 1) {
                  // Navigate to Contacts screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactsScreen(),
                    ),
                  );
                } else if (index == 2) {
                  // Navigate to Campaigns screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CampaignsScreen(),
                    ),
                  );
                } else if (index == 3) {
                  // Navigate to Templates screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TemplatesScreen(),
                    ),
                  );
                } else if (index == 4) {
                  // Navigate to Analytics screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
                    ),
                  );
                } else if (index == 5) {
                  // Navigate to Automations screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AutomationsScreen(),
                    ),
                  );
                } else if (index != 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.label} - Coming soon!')),
                  );
                }
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(user),
              const SizedBox(height: 24),
              if (user != null && !user.emailVerified)
                _buildEmailVerificationBanner(authProvider),
              _buildStatsSection(),
              const SizedBox(height: 24),
              _buildChartsAndActions(),
              const SizedBox(height: 24),
              _buildCampaignsAndActivity(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${user?.displayName ?? user?.email ?? 'User'}!',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Here\'s what\'s happening with your email campaigns today.',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildEmailVerificationBanner(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email Not Verified',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please verify your email to access all features.',
                  style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.sendEmailVerification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification email sent!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final isWideScreen = MediaQuery.of(context).size.width >= 1024;
    return GridView.count(
      crossAxisCount: isWideScreen ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isWideScreen ? 1.3 : 1.5,
      children: [
        StatCard(
          title: 'Total Contacts',
          value: '1,234',
          icon: Icons.contacts,
          color: Colors.blue,
          trend: '+12%',
          isPositiveTrend: true,
          subtitle: 'vs last month',
        ),
        StatCard(
          title: 'Active Campaigns',
          value: '8',
          icon: Icons.campaign,
          color: Colors.green,
          trend: '+2',
          isPositiveTrend: true,
          subtitle: '3 completed',
        ),
        StatCard(
          title: 'Emails Sent',
          value: '45.2K',
          icon: Icons.send,
          color: Colors.orange,
          trend: '+18%',
          isPositiveTrend: true,
          subtitle: 'this month',
        ),
        StatCard(
          title: 'Avg Open Rate',
          value: '42.5%',
          icon: Icons.mark_email_read,
          color: Colors.purple,
          trend: '-2.3%',
          isPositiveTrend: false,
          subtitle: 'vs last month',
        ),
      ],
    );
  }

  Widget _buildChartsAndActions() {
    final isWideScreen = MediaQuery.of(context).size.width >= 1024;
    if (isWideScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(flex: 2, child: AnalyticsChart()),
          const SizedBox(width: 24),
          Expanded(flex: 1, child: QuickActionsWidget()),
        ],
      );
    } else {
      return Column(
        children: [
          const AnalyticsChart(),
          const SizedBox(height: 24),
          QuickActionsWidget(),
        ],
      );
    }
  }

  Widget _buildCampaignsAndActivity() {
    final isWideScreen = MediaQuery.of(context).size.width >= 1024;
    if (isWideScreen) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: RecentCampaignsWidget()),
          SizedBox(width: 24),
          Expanded(flex: 1, child: ActivityFeedWidget()),
        ],
      );
    } else {
      return const Column(
        children: [
          RecentCampaignsWidget(),
          SizedBox(height: 24),
          ActivityFeedWidget(),
        ],
      );
    }
  }
}
