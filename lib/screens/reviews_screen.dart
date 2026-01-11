import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/reviews_repository.dart';
import '../core/config/app_config.dart';

class ReviewsScreen extends StatefulWidget {
  final String productId;
  const ReviewsScreen({super.key, required this.productId});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ReviewsRepository _repo = ReviewsRepository();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  int _rating = 5;
  bool _posting = false;
  Color _primaryColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _primaryColor = _hexToColor(AppConfig.primaryColorHex);
    _load();
  }

  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.list(widget.productId);
      setState(() => _items = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _posting = true);
    try {
      await _repo.add(widget.productId,
          rating: _rating,
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim());
      _titleCtrl.clear();
      _contentCtrl.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Yorum eklendi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBack(context),
        ),
        title: const Text('Product Reviews'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('Rating: '),
                    DropdownButton<int>(
                      value: _rating,
                      items: List.generate(6, (i) => i)
                          .where((e) => e > 0)
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text('$e')))
                          .toList(),
                      onChanged: (v) => setState(() => _rating = v ?? 5),
                    ),
                  ],
                ),
                TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title')),
                TextField(
                    controller: _contentCtrl,
                    decoration: const InputDecoration(labelText: 'Review')),
                const SizedBox(height: 8),
                ElevatedButton(
                    onPressed: _posting ? null : _submit,
                    child: _posting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Submit')),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_items.isEmpty) return const Center(child: Text('No reviews yet'));
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final r = _items[index];
        final title = r['title']?.toString() ?? '';
        final content = r['content']?.toString() ?? '';
        final points = r['points']?.toString() ?? '';
        return ListTile(
          title: Text(title.isEmpty ? 'Rating: $points' : title),
          subtitle: Text(content),
        );
      },
    );
  }
}
