import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/detection.dart';
import '../core/scan_engine.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'review_screen.dart';
import 'settings_screen.dart';

/// Home: one big honest number (space you can free), five colour-coded
/// category cards, and a scan button. Everything is on the home screen
/// -- no buried menus, no unrelated tools. Compare: Clever Cleaner
/// keeps every tool front and centre; CleanMyPhone buries the same job
/// under Declutter / Organize / Health tabs and reviewers call it
/// bloated. We copy the first, not the second.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state});

  final AppState state;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ScanResult? _result;
  bool _scanning = false;
  double _progress = 0;
  String? _error;

  Future<void> _scan() async {
    final engine = ScanEngine(
      similarityThreshold: widget.state.similarityThreshold,
    );
    if (!await engine.ensurePermission()) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.permissionDenied),
          action: SnackBarAction(
            label: t.grantPermission,
            onPressed: _scan,
          ),
        ),
      );
      return;
    }
    setState(() {
      _scanning = true;
      _error = null;
      _progress = 0;
    });
    try {
      final result = await engine.scan(
        onProgress: (scanned, total) {
          if (mounted && total > 0) {
            setState(() => _progress = scanned / total);
          }
        },
      );
      await widget.state.recordScan(result.totalPhotos, 0);
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) setState(() => _error = 'scan');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(state: widget.state),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.tagline, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            t.offlineNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CleanTokens.muted,
                ),
          ),
          if (result == null) ...[
            const SizedBox(height: 8),
            Text(
              t.permissionExplain,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CleanTokens.muted,
                  ),
            ),
          ],
          const SizedBox(height: 20),
          if (_scanning) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text('${t.scanning} ${(_progress * 100).toInt()}%'),
          ] else
            FilledButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(result == null ? t.scan : t.rescan),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(t.errorScan),
            TextButton(onPressed: _scan, child: Text(t.retry)),
          ],
          if (result != null) ...[
            const SizedBox(height: 20),
            Text(
              '${t.scanDone} · ${result.totalPhotos} ${t.scanned}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _MeterCard(result: result),
            const SizedBox(height: 16),
            Text(
              t.categories,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _CategoryCard(
              color: CleanTokens.duplicates,
              icon: Icons.copy_all_outlined,
              title: t.duplicates,
              subtitle:
                  '${result.exactGroups.length} ${t.groups}',
              onTap: () => _openGroups(context, result.exactGroups),
            ),
            _CategoryCard(
              color: CleanTokens.similars,
              icon: Icons.photo_outlined,
              title: t.similars,
              subtitle:
                  '${result.similarGroups.length} ${t.groups}',
              onTap: () => _openGroups(context, result.similarGroups),
            ),
            _CategoryCard(
              color: CleanTokens.screenshots,
              icon: Icons.screenshot_monitor_outlined,
              title: t.screenshots,
              subtitle:
                  '${result.screenshots.length} ${t.items}',
              onTap: () => _openList(
                context,
                result.screenshots,
                t.screenshots,
                CleanTokens.screenshots,
              ),
            ),
            _CategoryCard(
              color: CleanTokens.blurry,
              icon: Icons.blur_on_outlined,
              title: t.blurry,
              subtitle: '${result.blurry.length} ${t.items}',
              onTap: () => _openList(
                context,
                result.blurry,
                t.blurry,
                CleanTokens.blurry,
              ),
            ),
            _CategoryCard(
              color: CleanTokens.videos,
              icon: Icons.videocam_outlined,
              title: t.largeVideos,
              subtitle: '${result.largeVideos.length} ${t.items}',
              onTap: () => _openList(
                context,
                result.largeVideos,
                t.largeVideos,
                CleanTokens.videos,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${result.totalPhotos} ${t.totalPhotos}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CleanTokens.muted,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  void _openGroups(BuildContext context, List<PhotoGroup> groups) {
    final result = _result;
    if (result == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          groups: groups,
          entities: result.entities,
          state: widget.state,
        ),
      ),
    );
  }

  void _openList(
    BuildContext context,
    List<ScannedAsset> items,
    String title,
    Color color,
  ) {
    final result = _result;
    if (result == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          groups: items.isEmpty
              ? <PhotoGroup>[]
              : <PhotoGroup>[
                  PhotoGroup(items, 0, GroupKind.similar),
                ],
          entities: result.entities,
          state: widget.state,
          flatTitle: title,
          flatColor: color,
        ),
      ),
    );
  }
}

/// The before/after meter, borrowed from Cleanup's best screen and
/// made honest: it shows only what this scan actually found, never a
/// demo number like "250 GB used, 50 GB left".
class _MeterCard extends StatelessWidget {
  const _MeterCard({required this.result});

  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatBytes(result.bytesFreeable),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: CleanTokens.accentInk,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(t.spaceToFree),
            const SizedBox(height: 8),
            Text(
              '${result.totalGroups} ${t.groups} · ${t.reviewBeforeDelete}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CleanTokens.muted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
