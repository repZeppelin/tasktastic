import 'package:finaltasktastic/scripts/data_handler.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GlobalAuditPage extends StatefulWidget {
  const GlobalAuditPage({super.key});

  @override
  State<GlobalAuditPage> createState() => _GlobalAuditPageState();
}

class _GlobalAuditPageState extends State<GlobalAuditPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _flaggedLogs = [];

  @override
  void initState() {
    super.initState();
    _scanForSecurityBreaches();
  }

  Future<void> _scanForSecurityBreaches() async {
    // Check mounted before starting the process
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('tasktastic')
          .select('id, username, task_history');

      List<Map<String, dynamic>> allFlagged = [];

      for (var row in response) {
        List<dynamic> history = row['task_history'] ?? [];
        for (var task in history) {
          if (task['is_suspicious'] == true) {
            allFlagged.add({
              'db_id': row['id'],
              'username': row['username'],
              'task': task,
            });
          }
        }
      }

      // CRITICAL: Check mounted after the async database call
      if (!mounted) return;

      setState(() {
        _flaggedLogs = allFlagged;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("SCAN_ERROR: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("SECURITY_AUDIT_TERMINAL", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_sharp, size: 20),
            onPressed: _scanForSecurityBreaches,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : RefreshIndicator(
            color: Colors.black,
            onRefresh: _scanForSecurityBreaches,
            child: _flaggedLogs.isEmpty 
              ? const Center(
                  child: Text("NO_SECURITY_BREACHES_DETECTED", 
                  style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _flaggedLogs.length,
                  itemBuilder: (context, index) => _buildAuditEntry(_flaggedLogs[index]),
                ),
          ),
    );
  }

  Widget _buildAuditEntry(Map<String, dynamic> log) {
    final task = log['task'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("OPERATIVE: ${log['username']}".toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                const Icon(Icons.security, color: Colors.red, size: 14),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task['title']?.toUpperCase() ?? "UNKNOWN_LOG", 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text("REWARD: ${task['coins']} CC | DATE: ${task['timestamp'].toString().substring(0, 10)}", 
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                const Divider(color: Colors.black, thickness: 1),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: () async {
                      // Call the approval method
                      await TaskTable().approveFraudulentTask(log['db_id'], task);
                      // Re-scan to update the UI
                      _scanForSecurityBreaches();
                    },
                    child: const Text("APPROVE_ENTRY", 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}