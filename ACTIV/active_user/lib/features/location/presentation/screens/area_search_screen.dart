import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_header.dart';
import 'package:activ_user_app/core/widgets/fields/app_search_bar.dart';
import '../widgets/location_list_item.dart';

class AreaSearchScreen extends StatefulWidget {
  final String city;
  final List<String> areas;

  const AreaSearchScreen({
    super.key,
    required this.city,
    required this.areas,
  });

  @override
  State<AreaSearchScreen> createState() => _AreaSearchScreenState();
}

class _AreaSearchScreenState extends State<AreaSearchScreen> {
  String _searchQuery = '';
  
  List<String> get _filteredAreas {
    if (_searchQuery.isEmpty) return widget.areas;
    final query = _searchQuery.toLowerCase();
    return widget.areas
        .where((area) => area.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAreas;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(title: 'Pick an area in ${widget.city}'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AppSearchBar(
              hintText: 'Search area...',
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              }),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final area = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: LocationListItem(
                      title: area,
                      onTap: () {
                        Navigator.pop(context, area);
                      }));
                })),
          ])));
  }
}
