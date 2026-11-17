import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../core/app_state.dart';
import '../core/detection.dart';
import '../core/scan_engine.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Group review: the safety-critical screen.
///
/// - The Best pick is pre-selected as keeper; tap any photo to make
///   it the keeper instead.
/// - Nothing is deleted without a confirmation dialog, and the dialog
///   says where the photos go (Recently Deleted, 30 days).
/// - At least one photo in every group is always kept.
/// - Free tier: up to 100 deletes a day. Pro: unlimited.
///
/// Flat lists (screenshots / blurry / large videos) reuse the same
/// screen with [flatTitle]: the whole list is one group and the first
/// item is the keeper, so the user reviews each item before deleting.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.groups,
    required this.entities,
    required this.state,
    this.flatTitle,
    this.flatColor,
  });

  final List<PhotoGroup> groups;
  final Map<String, AssetEntity> entities;
  final AppState state;
  final String? flatTitle;
  final Color? flatColor;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late List<int> _keepers;
  final Set<String> _toDelete = {};

  bool get _isFlat => widget.flatTitle != null;

  @override
  void initState() {
    super.initState();
    _keepers = widget.groups.map((g) => g.keeperIndex).toList();
    _rebuildDeleteSet();
    // Flat lists (screenshots / blurry / large videos) are not groups:
    // every item starts selected for deletion, and tapping one toggles
    // it back to "keep". Group mode instead always keeps one keeper.
    if (_isFlat) {
      for (final group in widget.groups) {
        _toDelete.addAll(group.assets.map((a) => a.id));
      }
    }
  }

  void _toggleFlat(int groupIndex, int itemIndex) {
    final id = widget.groups[groupIndex].assets[itemIndex].id;
    setState(() {
      if (_toDelete.contains(id)) {
        _toDelete.remove(id);
      } else {
        _toDelete.add(id);
      }
    });
  }

  void _rebuildDeleteSet() {
    _toDelete.clear();
    for (var gi = 0; gi < widget.groups.length; gi++) {
      final group = widget.groups[gi];
      for (var i = 0; i < group.assets.length; i++) {
        if (i != _keepers[gi]) _toDelete.add(group.assets[i].id);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final t = AppLocalizations.of(context)!;
    if (_toDelete.isEmpty) return;
    if (_toDelete.length > widget.state.deletesRemainingToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.dailyLimitReached)),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteConfirmTitle),
        content: Text(
          '${_toDelete.length} ${t.items}\n\n${t.deleteConfirmBody}\n\n${t.trashNote}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ids = _toDelete.toList();
    await ScanEngine.deleteIds(ids);
    await widget.state.recordDeletes(ids.length);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.deleteDone)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final title = widget.flatTitle ??
        (widget.groups.isNotEmpty &&
                widget.groups.first.kind == GroupKind.exact
            ? t.duplicates
            : t.similars);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: widget.groups.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.noResults),
                  Text(t.noResultsHint),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.groups.length + 1,
              itemBuilder: (context, index) {
                if (index == widget.groups.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 32),
                    child: FilledButton.icon(
                      onPressed:
                          _toDelete.isEmpty ? null : _confirmDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        '${t.deleteSelected} (${_toDelete.length})',
                      ),
                    ),
                  );
                }
                final group = widget.groups[index];
                return _GroupCard(
                  group: group,
                  keeperIndex: _isFlat ? -1 : _keepers[index],
                  entities: widget.entities,
                  flat: _isFlat,
                  deletedIds: _toDelete,
                  onKeeperChanged: (i) {
                    setState(() {
                      _keepers[index] = i;
                      _rebuildDeleteSet();
                    });
                  },
                  onToggle: (i) => _toggleFlat(index, i),
                );
              },
            ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.keeperIndex,
    required this.entities,
    required this.onKeeperChanged,
    this.flat = false,
    this.deletedIds = const {},
    this.onToggle,
  });

  final PhotoGroup group;
  final int keeperIndex;
  final Map<String, AssetEntity> entities;
  final ValueChanged<int> onKeeperChanged;

  /// Flat-list mode: tap toggles delete/keep instead of picking a
  /// keeper, and there is no Best badge.
  final bool flat;
  final Set<String> deletedIds;
  final ValueChanged<int>? onToggle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${group.assets.length} ${t.items} · ${formatBytes(flat ? group.assets.where((a) => deletedIds.contains(a.id)).fold(0, (s, a) => s + a.fileSize) : group.bytesFreeable)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              t.changeKeeper,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CleanTokens.muted,
                  ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: group.assets.length,
              itemBuilder: (context, i) {
                final asset = group.assets[i];
                final entity = entities[asset.id];
                final isKeeper = i == keeperIndex;
                final isDeleted = flat && deletedIds.contains(asset.id);
                return GestureDetector(
                  onTap: () =>
                      flat ? onToggle?.call(i) : onKeeperChanged(i),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: entity == null
                            ? Container(color: CleanTokens.line)
                            : AssetEntityImage(
                                entity,
                                isOriginal: false,
                                thumbnailSize:
                                    const ThumbnailSize(200, 200),
                                fit: BoxFit.cover,
                              ),
                      ),
                      if (isKeeper)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CleanTokens.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t.best,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      else if (flat && !isDeleted)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.check_circle,
                            color: CleanTokens.accent,
                            size: 20,
                          ),
                        )
                      else
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
