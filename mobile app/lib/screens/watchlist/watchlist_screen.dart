import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/watchlist.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_dropdown.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/common/loading_spinner.dart';
import '../../widgets/common/section_header.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WatchlistProvider>().fetchWatchlist();
    });
  }

  void _showAddItemModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddWatchlistItemModal(
        onAdd: (data) async {
          await context.read<WatchlistProvider>().addItem(data);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchlistProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddItemModal,
            backgroundColor: AppColors.cyan,
            child: const Icon(Icons.add, color: Colors.black),
          ),
          body: RefreshIndicator(
            color: AppColors.cyan,
            backgroundColor: AppColors.surface,
            onRefresh: () => provider.fetchWatchlist(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: MediaQuery.of(context).padding.top + 16,
                      bottom: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Watchlist',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Track companies and assets you want to keep an eye on.',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        if (provider.error != null) ...[
                          const SizedBox(height: 16),
                          ErrorBanner(
                            message: provider.error!,
                            onDismiss: provider.clearError,
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: LoadingSpinner()),
                  )
                else if (provider.items.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 64,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your watchlist is empty',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap + to add items manually, or run AI recommendations\nto get suggestions automatically.',
                            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (provider.highPriority.isNotEmpty) ...[
                          const SectionHeader(title: 'High Priority', icon: Icons.flag),
                          ...provider.highPriority.map(
                            (item) => _WatchlistItemCard(
                              item: item,
                              onDelete: () => provider.removeItem(item.id),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (provider.normalPriority.isNotEmpty) ...[
                          const SectionHeader(title: 'Normal', icon: Icons.bookmark_border),
                          ...provider.normalPriority.map(
                            (item) => _WatchlistItemCard(
                              item: item,
                              onDelete: () => provider.removeItem(item.id),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (provider.lowPriority.isNotEmpty) ...[
                          const SectionHeader(title: 'Low Priority', icon: Icons.bookmark_border),
                          ...provider.lowPriority.map(
                            (item) => _WatchlistItemCard(
                              item: item,
                              onDelete: () => provider.removeItem(item.id),
                            ),
                          ),
                        ],
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WatchlistItemCard extends StatelessWidget {
  final WatchlistItem item;
  final VoidCallback onDelete;

  const _WatchlistItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (item.priority) {
      'high' => AppColors.danger,
      'low' => AppColors.textMuted,
      _ => AppColors.cyan,
    };
    final priorityLabel = switch (item.priority) {
      'high' => 'High',
      'low' => 'Low',
      _ => 'Normal',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.symbol != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.symbol!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Priority badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  priorityLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Source icon
              Icon(
                item.isAiSuggested ? Icons.auto_awesome : Icons.person_outline,
                size: 14,
                color: item.isAiSuggested ? AppColors.purple : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              // Delete button
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
              ),
            ],
          ),
          if (item.sector != null || item.country != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (item.sector != null) ...[
                  const Icon(Icons.category_outlined, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    item.sector!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
                if (item.sector != null && item.country != null)
                  const Text(
                    '  ·  ',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                if (item.country != null) ...[
                  const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    item.country!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ],
          if (item.reason != null) ...[
            const SizedBox(height: 6),
            Text(
              item.reason!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _AddWatchlistItemModal extends StatefulWidget {
  final Future<void> Function(WatchlistItemCreate data) onAdd;

  const _AddWatchlistItemModal({required this.onAdd});

  @override
  State<_AddWatchlistItemModal> createState() => _AddWatchlistItemModalState();
}

class _AddWatchlistItemModalState extends State<_AddWatchlistItemModal> {
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _sectorController = TextEditingController();
  final _countryController = TextEditingController();
  final _reasonController = TextEditingController();
  String _priority = 'normal';
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _sectorController.dispose();
    _countryController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.onAdd(
        WatchlistItemCreate(
          name: _nameController.text.trim(),
          symbol: _symbolController.text.trim().isEmpty
              ? null
              : _symbolController.text.trim().toUpperCase(),
          sector: _sectorController.text.trim().isEmpty
              ? null
              : _sectorController.text.trim(),
          country: _countryController.text.trim().isEmpty
              ? null
              : _countryController.text.trim(),
          reason: _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
          priority: _priority,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add to Watchlist',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              ErrorBanner(
                message: _error!,
                onDismiss: () => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
            ],
            AppInput(
              label: 'Name',
              controller: _nameController,
              required: true,
              hintText: 'e.g., Tesla, iShares Clean Energy ETF',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppInput(
              label: 'Ticker Symbol',
              controller: _symbolController,
              hintText: 'e.g., TSLA',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppInput(
              label: 'Sector',
              controller: _sectorController,
              hintText: 'e.g., Technology',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppInput(
              label: 'Country',
              controller: _countryController,
              hintText: 'e.g., US',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppInput(
              label: 'Reason',
              controller: _reasonController,
              hintText: 'Why are you watching this?',
              maxLines: 2,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 12),
            AppDropdown(
              label: 'Priority',
              value: _priority,
              items: const [
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 'normal'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Cancel',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Add to Watchlist',
                    onPressed: _handleSubmit,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
