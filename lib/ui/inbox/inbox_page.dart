import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cariindong_app/providers/app_state.dart';
import 'package:cariindong_app/models/item_model.dart';
import 'package:cariindong_app/ui/detail/item_detail_page.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentUser = appState.currentUser;

    final inboxItems = appState.items.where((item) {
      return item.reporterUid == currentUser.uid &&
          item.pendingClaims.isNotEmpty &&
          (item.status == ItemStatus.lost || item.status == ItemStatus.found);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kotak Masuk'),
      ),
      body: inboxItems.isEmpty
          ? const Center(
              child: Text(
                'Belum ada klaim baru untuk laporan Anda.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: inboxItems.length,
              itemBuilder: (context, index) {
                final item = inboxItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.notifications_active, color: Colors.blue),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Ada ${item.pendingClaims.length} pengklaim baru yang menunggu konfirmasi Anda.',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailPage(item: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
