import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Settings + Pro. No account screen, no analytics toggle (there is
/// nothing to toggle: the app collects nothing), no network settings.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final state = widget.state;
    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(t.proTitle),
            subtitle: Text(t.freeTier),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(t.similarity),
            subtitle: Text(t.similarityHint),
          ),
          Slider(
            value: state.similarityThreshold.toDouble(),
            min: 4,
            max: 16,
            divisions: 12,
            label: '${state.similarityThreshold}',
            onChanged: (v) async {
              await state.setSimilarityThreshold(v.round());
              setState(() {});
            },
          ),
          SwitchListTile(
            title: Text(t.proPreview),
            subtitle: Text(t.proPreviewHint),
            value: state.proPreview,
            onChanged: (v) async {
              await state.setProPreview(v);
              setState(() {});
            },
          ),
          const Divider(),
          ListTile(
            title: Text(t.about),
            subtitle: Text(
              '${t.offlineNote}\n${t.languageNote}\n${t.keepOne}',
            ),
          ),
        ],
      ),
    );
  }
}

/// Pro: one screen, one price, no trial, no subscription.
/// Price is undecided (candidates $19.99 / $29.99-$39.99) -- the
/// constant in AppState is a placeholder and must be set before
/// release. The store purchase is wired up in M2; V1 only needs the
/// screen and the gating logic to exist so testers can review them.
class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.proTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${AppState.proPriceUsdPlaceholder.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: CleanTokens.accentInk,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(t.proPriceNote),
            const SizedBox(height: 16),
            Text(t.proBody),
            const SizedBox(height: 16),
            Text(t.freeTier),
          ],
        ),
      ),
    );
  }
}
