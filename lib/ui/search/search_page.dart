import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cariindong_app/providers/app_state.dart';
import 'package:cariindong_app/models/item_model.dart';
import 'package:cariindong_app/ui/widgets/item_card.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final categories = [
      'Semua',
      'Elektronik',
      'Dompet',
      'Dokumen',
      'Kunci',
      'Lainnya',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Barang'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => appState.setSearchQuery(value),
              decoration: InputDecoration(
                hintText: 'Cari nama atau keterangan...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = appState.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat, style: const TextStyle(fontSize: 12)),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    selected: isSelected,
                    onSelected: (selected) {
                      appState.setFilter(cat, appState.selectedStatus);
                    },
                  ),
                );
              },
            ),
          ),
          // Filter Status (Hilang/Ditemukan)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<ItemStatus?>(
                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -2,
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: null,
                        label: Text('Semua', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: ItemStatus.lost,
                        label: Text('Hilang', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: ItemStatus.found,
                        label: Text('Temukan', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: ItemStatus.claimed,
                        label: Text('Diklaim', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: {appState.selectedStatus},
                    onSelectionChanged: (Set<ItemStatus?> newSelection) {
                      appState.setFilter(
                        appState.selectedCategory,
                        newSelection.first,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: appState.filteredItems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Barang tidak ditemukan',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: appState.filteredItems.length,
                    itemBuilder: (context, index) {
                      return ItemCard(item: appState.filteredItems[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
