import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/clipboard_guard.dart';
import '../../core/crypto/password_generator.dart';

class PasswordGenScreen extends ConsumerStatefulWidget {
  const PasswordGenScreen({super.key});
  @override
  ConsumerState<PasswordGenScreen> createState() => _PasswordGenState();
}

class _PasswordGenState extends ConsumerState<PasswordGenScreen> {
  int _length = 20;
  bool _upper = true;
  bool _lower = true;
  bool _digits = true;
  bool _symbols = true;
  bool _passphraseMode = false;
  int _words = 4;
  String _locale = 'en';
  String _output = '';

  Future<void> _generate() async {
    final gen = ref.read(passwordGeneratorProvider);
    final result = _passphraseMode
        ? await gen.generatePassphrase(wordCount: _words, locale: _locale)
        : gen.generate(
            length: _length,
            upper: _upper,
            lower: _lower,
            digits: _digits,
            symbols: _symbols,
          );
    setState(() => _output = result);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generatore password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  SelectableText(
                    _output,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Rigenera'),
                        onPressed: _generate,
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copia'),
                        onPressed: () async {
                          await ref
                              .read(clipboardGuardProvider)
                              .copySensitive(_output);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copiato')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Modalità passphrase'),
            value: _passphraseMode,
            onChanged: (v) => setState(() => _passphraseMode = v),
          ),
          if (_passphraseMode) ...<Widget>[
            ListTile(
              title: const Text('Numero parole'),
              subtitle: Slider(
                min: 3,
                max: 8,
                divisions: 5,
                value: _words.toDouble(),
                label: '$_words',
                onChanged: (v) => setState(() => _words = v.round()),
              ),
            ),
            ListTile(
              title: const Text('Dizionario'),
              trailing: DropdownButton<String>(
                value: _locale,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'en', child: Text('EN')),
                  DropdownMenuItem(value: 'it', child: Text('IT')),
                ],
                onChanged: (v) => setState(() => _locale = v ?? 'en'),
              ),
            ),
          ] else ...<Widget>[
            ListTile(
              title: Text('Lunghezza: $_length'),
              subtitle: Slider(
                min: 4,
                max: 64,
                divisions: 60,
                value: _length.toDouble(),
                label: '$_length',
                onChanged: (v) => setState(() => _length = v.round()),
              ),
            ),
            SwitchListTile(
              title: const Text('Maiuscole'),
              value: _upper,
              onChanged: (v) => setState(() => _upper = v),
            ),
            SwitchListTile(
              title: const Text('Minuscole'),
              value: _lower,
              onChanged: (v) => setState(() => _lower = v),
            ),
            SwitchListTile(
              title: const Text('Numeri'),
              value: _digits,
              onChanged: (v) => setState(() => _digits = v),
            ),
            SwitchListTile(
              title: const Text('Simboli'),
              value: _symbols,
              onChanged: (v) => setState(() => _symbols = v),
            ),
          ],
        ],
      ),
    );
  }
}
