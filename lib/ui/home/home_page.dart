import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cariindong_app/providers/app_state.dart';
import 'package:cariindong_app/models/user_model.dart';
import 'package:cariindong_app/ui/widgets/item_card.dart';
import 'package:cariindong_app/ui/form/lost_item_form_page.dart';
import 'package:cariindong_app/models/item_model.dart';
import 'package:cariindong_app/ui/inbox/inbox_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final isSuperAdmin = user.role == UserRole.superAdmin;
    final hasPendingClaims = appState.items.any((item) =>
        item.reporterUid == user.uid &&
        item.pendingClaims.isNotEmpty &&
        (item.status == ItemStatus.lost || item.status == ItemStatus.found));

    return Scaffold(
      appBar: AppBar(
        title: const Text('CariinDong'),
        actions: [
          if (isSuperAdmin)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 16,
                    color: Colors.red.shade800,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InboxPage(),
                    ),
                  );
                },
              ),
              if (hasPendingClaims)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${user.name} 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatisticsCard(context, appState),
                  const SizedBox(height: 24),
                  const Text(
                    'Laporan Terbaru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = appState.items[index];
              return ItemCard(item: item);
            }, childCount: appState.items.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: !isSuperAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LostItemFormPage(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildStatisticsCard(BuildContext context, AppState state) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Hilang', state.totalLost.toString(), Colors.red),
            _buildStatItem(
              'Ditemukan',
              state.totalFound.toString(),
              Colors.green,
            ),
            _buildStatItem(
              'Diklaim',
              state.totalClaimed.toString(),
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
