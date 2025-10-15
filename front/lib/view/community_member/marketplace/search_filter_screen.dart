import 'package:flutter/material.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedCondition = 'All';
  String _selectedSortBy = 'newest';
  double _minPrice = 0;
  double _maxPrice = 10000000;
  String _selectedLocation = 'All';

  final List<String> _categories = ['All', 'Vehicles', 'Parts', 'Accessories'];
  final List<String> _conditions = ['All', 'Excellent', 'Good', 'Fair', 'Poor'];
  final List<String> _sortOptions = ['newest', 'oldest', 'price_low', 'price_high', 'most_viewed'];
  final List<String> _locations = ['All', 'Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'Faisalabad'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Search & Filter',
          style: TextStyle(
            color: Color(0xFFFF6B35),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              'Clear',
              style: TextStyle(color: Color(0xFFFF6B35)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search vehicles, parts...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF6B35)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Category Filter
            _buildSectionTitle('Category'),
            const SizedBox(height: 12),
            _buildChipFilter(_categories, _selectedCategory, (value) {
              setState(() {
                _selectedCategory = value;
              });
            }),

            const SizedBox(height: 24),

            // Condition Filter
            _buildSectionTitle('Condition'),
            const SizedBox(height: 12),
            _buildChipFilter(_conditions, _selectedCondition, (value) {
              setState(() {
                _selectedCondition = value;
              });
            }),

            const SizedBox(height: 24),

            // Price Range
            _buildSectionTitle('Price Range'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PKR ${_minPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'PKR ${_maxPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RangeSlider(
                    values: RangeValues(_minPrice, _maxPrice),
                    min: 0,
                    max: 10000000,
                    divisions: 100,
                    activeColor: const Color(0xFFFF6B35),
                    inactiveColor: Colors.grey[600],
                    onChanged: (values) {
                      setState(() {
                        _minPrice = values.start;
                        _maxPrice = values.end;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Location Filter
            _buildSectionTitle('Location'),
            const SizedBox(height: 12),
            _buildChipFilter(_locations, _selectedLocation, (value) {
              setState(() {
                _selectedLocation = value;
              });
            }),

            const SizedBox(height: 24),

            // Sort By
            _buildSectionTitle('Sort By'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _sortOptions.map((option) {
                  return RadioListTile<String>(
                    title: Text(
                      _getSortDisplayName(option),
                      style: const TextStyle(color: Colors.white),
                    ),
                    value: option,
                    groupValue: _selectedSortBy,
                    onChanged: (value) {
                      setState(() {
                        _selectedSortBy = value!;
                      });
                    },
                    activeColor: const Color(0xFFFF6B35),
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Additional Filters
            _buildSectionTitle('Additional Filters'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Auction Only',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Show only auction listings',
                      style: TextStyle(color: Colors.grey),
                    ),
                    value: false,
                    onChanged: (value) {
                      // TODO: Implement auction filter
                    },
                    activeColor: const Color(0xFFFF6B35),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text(
                      'Negotiable Only',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Show only negotiable listings',
                      style: TextStyle(color: Colors.grey),
                    ),
                    value: false,
                    onChanged: (value) {
                      // TODO: Implement negotiable filter
                    },
                    activeColor: const Color(0xFFFF6B35),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Apply Filters Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Reset Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _clearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B35),
                  side: const BorderSide(color: Color(0xFFFF6B35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Reset Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildChipFilter(List<String> options, String selected, Function(String) onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onChanged(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF6B35) : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? null : Border.all(color: Colors.grey),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getSortDisplayName(String option) {
    switch (option) {
      case 'newest':
        return 'Newest First';
      case 'oldest':
        return 'Oldest First';
      case 'price_low':
        return 'Price: Low to High';
      case 'price_high':
        return 'Price: High to Low';
      case 'most_viewed':
        return 'Most Viewed';
      default:
        return option;
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'All';
      _selectedCondition = 'All';
      _selectedSortBy = 'newest';
      _minPrice = 0;
      _maxPrice = 10000000;
      _selectedLocation = 'All';
    });
  }

  void _applyFilters() {
    // TODO: Apply filters and navigate back with results
    Navigator.pop(context);
  }
}
