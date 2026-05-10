import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kdbx/kdbx.dart';

import '../../core/kdbx/kdbx_service.dart';

/// Motore di ricerca semplice: filtra per Titolo / Username / URL / Notes /
/// custom fields (mai per Password — non vogliamo ricercare segreti in chiaro).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchState();
}

class _SearchState extends ConsumerState<SearchScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(currentVaultProvider);
    final entries = vault?.file.body.rootGroup.getAllEntries() ?? const <KdbxEntry>[];
    final q = _q.trim().toLowerCase();
    final filtered = q.isEmpty
        ? const <KdbxEntry>[]
        : entries.where((e) => _matches(e, q)).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Cerca...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
      ),
      body: filtered.isEmpty
          ? Center(
              child: Text(q.isEmpty ? 'Inizia a digitare' : 'Nessun risultato'),
            )
          : ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = filtered[i];
                return ListTile(
                  title: Text(e.getString(KdbxKeyCommon.TITLE)?.getText() ?? ''),
                  subtitle:
                      Text(e.getString(KdbxKeyCommon.USER_NAME)?.getText() ?? ''),
                  onTap: () => context.go('/entries/${e.uuid.uuid}'),
                );
              },
            ),
    );
  }

  bool _matches(KdbxEntry e, String q) {
    bool has(KdbxKey k) {
      final v = e.getString(k)?.getText();
      return v != null && v.toLowerCase().contains(q);
    }
    if (has(KdbxKeyCommon.TITLE)) return true;
    if (has(KdbxKeyCommon.USER_NAME)) return true;
    if (has(KdbxKeyCommon.URL)) return true;
    if (has(KdbxKeyCommon.NOTES)) return true;
    // custom fields (skip Password)
    for (final kv in e.stringEntries) {
      if (kv.key == KdbxKeyCommon.PASSWORD) continue;
      final v = kv.value?.getText();
      if (v != null && v.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}
