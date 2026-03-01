// lib/scripts/seed_trigger.dart
// ============================================================
//  Drop this widget anywhere in your app to trigger seeding.
//  Recommended: add it temporarily inside AdminSettingsPage.
//
//  USAGE — paste inside AdminSettingsPage's build() Column:
//
//    const SeedTriggerWidget(),
//
//  REMOVE or comment out after seeding is done.
// ============================================================

import 'package:flutter/material.dart';
import 'package:forsee_demo_one/scripts/seed_demo_data.dart';

class SeedTriggerWidget extends StatefulWidget {
  const SeedTriggerWidget({super.key});

  @override
  State<SeedTriggerWidget> createState() => _SeedTriggerWidgetState();
}

class _SeedTriggerWidgetState extends State<SeedTriggerWidget> {
  bool _seeding  = false;
  bool _clearing = false;
  String _status = '';

  Future<void> _runSeed() async {
    setState(() { _seeding = true; _status = 'Seeding... this takes ~10 seconds'; });
    try {
      await SeedDemoData.run();
      setState(() { _status = '✅ Seed complete! 25 students, 5 teachers, 5 classrooms.'; });
    } catch (e) {
      setState(() { _status = '❌ Error: $e'; });
    } finally {
      setState(() => _seeding = false);
    }
  }

  Future<void> _runClear() async {
    // Confirm dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3B2028),
        title: const Text('Clear all seeded data?',
            style: TextStyle(color: Colors.white, fontFamily: 'Pridi')),
        content: const Text(
            'This deletes all docs in students, classrooms, staging, predictions, feedback and the seeded users. Real auth accounts are untouched.',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFE9C2D7)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Yes, Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() { _clearing = true; _status = 'Clearing...'; });
    try {
      await SeedDemoData.clear();
      setState(() { _status = '🗑️ Cleared. Ready to re-seed.'; });
    } catch (e) {
      setState(() { _status = '❌ Clear error: $e'; });
    } finally {
      setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B2028),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.science_outlined, color: Colors.orangeAccent, size: 18),
          SizedBox(width: 8),
          Text('Demo Data Seeding',
              style: TextStyle(color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold, fontFamily: 'Pridi', fontSize: 15)),
        ]),
        const SizedBox(height: 6),
        const Text('Seeds 1 admin · 5 teachers · 5 classrooms · 25 students\n'
            '15-day attendance logs · predictions · feedback entries',
            style: TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'Pridi')),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _seeding || _clearing ? null : _runSeed,
              icon: _seeding
                  ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF512D38)))
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(_seeding ? 'Seeding...' : 'Run Seed',
                  style: const TextStyle(fontFamily: 'Pridi', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE9C2D7),
                foregroundColor: const Color(0xFF512D38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _seeding || _clearing ? null : _runClear,
              icon: _clearing
                  ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.delete_outline, size: 18),
              label: Text(_clearing ? 'Clearing...' : 'Clear Data',
                  style: const TextStyle(fontFamily: 'Pridi', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(_status,
              style: TextStyle(
                  color: _status.startsWith('❌') ? Colors.redAccent : Colors.greenAccent,
                  fontSize: 12,
                  fontFamily: 'Pridi')),
        ],
      ]),
    );
  }
}