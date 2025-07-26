import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:trottstr/providers/auth_providers.dart';
import 'package:trottstr/screens/tabs/dashboard_tab.dart';
import 'package:trottstr/screens/tabs/tracking_tab.dart';
import 'package:trottstr/screens/tabs/stats_tab.dart';
import 'package:trottstr/screens/tabs/settings_tab.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);
    final profile = ref.watch(userProfileProvider);
    ref.watch(Signer.activePubkeyProvider);

    final pages = const [
      DashboardTab(),
      TrackingTab(),
      StatsTab(),
      SettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trottstr'),
        actions: [
          // Profile avatar in top right
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: profile?.pictureUrl != null
                    ? CachedNetworkImageProvider(profile!.pictureUrl!)
                    : null,
                child: profile?.pictureUrl == null
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: currentIndex.value, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex.value,
        onTap: (index) => currentIndex.value = index,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
