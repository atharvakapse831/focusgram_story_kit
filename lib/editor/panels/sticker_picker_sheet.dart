import 'package:flutter/material.dart';
import '../../assets/asset_provider.dart';
import '../../models/element_payloads.dart';
import '../../models/story_element.dart';
import '../../models/story_transform.dart';
import '../editor_controller.dart';

/// Modal bottom sheet for browsing and selecting categorized stickers and emojis.
class StickerPickerSheet extends StatefulWidget {
  const StickerPickerSheet({
    super.key,
    required this.controller,
    required this.assetProvider,
  });

  final EditorController controller;
  final StoryAssetProvider assetProvider;

  @override
  State<StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<StickerPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<StoryAssetCategory> _categories = [];
  List<StoryStickerItem> _stickers = [];
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cats = await widget.assetProvider.getCategories();
    _categories = cats;
    _selectedCategory = cats.isNotEmpty ? cats.first.id : null;
    final items = await widget.assetProvider.getStickers(
      categoryId: _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _stickers = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCategory(String catId) async {
    setState(() {
      _selectedCategory = catId;
      _isLoading = true;
    });
    final items = await widget.assetProvider.getStickers(categoryId: catId);
    if (mounted) {
      setState(() {
        _stickers = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    final results = await widget.assetProvider.searchStickers(query);
    if (mounted) {
      setState(() {
        _stickers = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF222222),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header & Search
          Row(
            children: [
              const Text(
                'Stickers & Emojis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: _search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search stickers...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: Colors.white12,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Categories horizontal bar
          if (_categories.isNotEmpty)
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat.id == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${cat.iconEmoji ?? ''} ${cat.name}'.trim()),
                      selected: isSelected,
                      onSelected: (_) => _selectCategory(cat.id),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          // Stickers Grid
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : _stickers.isEmpty
                    ? const Center(
                      child: Text(
                        'No stickers found',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                    : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemCount: _stickers.length,
                      itemBuilder: (context, index) {
                        final item = _stickers[index];
                        return InkWell(
                          onTap: () => _handleSelectSticker(item),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                item.isEmoji
                                    ? Text(
                                      item.emojiText!,
                                      style: const TextStyle(fontSize: 32),
                                    )
                                    : const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 32,
                                    ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  void _handleSelectSticker(StoryStickerItem item) {
    final element = StoryElement(
      id: 'stk_${DateTime.now().millisecondsSinceEpoch}',
      type: StoryElementType.sticker,
      transform: const StoryTransform(
        x: 0.5,
        y: 0.5,
        width: 0.25,
        height: 0.15,
      ),
      payload: StickerElementPayload(
        stickerId: item.id,
        assetUri: item.assetUri,
        label: item.isEmoji ? item.emojiText : item.name,
      ),
    );

    widget.controller.addElement(element);
    Navigator.of(context).pop();
  }
}
