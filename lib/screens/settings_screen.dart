import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../services/update_service.dart';
import 'package:ota_update/ota_update.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ConfigService _configService = ConfigService();
  final UpdateService _updateService = UpdateService();
  String? _selectedMachine;
  bool _isLoading = true;
  bool _isCheckingUpdate = false;
  String _updateStatus = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final machine = await _configService.getSavedMachineType();
    if (mounted) {
      setState(() {
        _selectedMachine = machine;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings(String? newValue) async {
    if (newValue != null) {
      setState(() {
        _selectedMachine = newValue;
      });
      await _configService.saveMachineType(newValue);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved as $newValue. Please restart app or navigate to apply changes.')),
        );
      }
    }
  }

  Future<void> _showUpdateDialog() async {
    final savedToken = await _configService.getGitHubToken();
    final TextEditingController tokenCtrl = TextEditingController(text: savedToken ?? '');
    
    // ignore: use_build_context_synchronously
    await showDialog(
      context: context,
      builder: (context) {
        bool checking = false;
        String status = '';
        Map<String, dynamic>? updateInfo;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Check for Updates'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     const Text('Updates are fetched from GitHub.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                     const SizedBox(height: 5),
                     const Text('If the repo is Private, enter your Personal Access Token (PAT).', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    TextField(
                      controller: tokenCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'GitHub Token',
                        hintText: 'ghp_xxxxxxxxxxxx',
                        helperText: 'Leave empty for Public repos',
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (checking) const LinearProgressIndicator(),
                    if (status.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(status),
                      ),
                    if (updateInfo != null) ...[
                      const SizedBox(height: 10),
                      Text('New Version: ${updateInfo!['latestVersion']}'),
                      Text('Current: ${updateInfo!['currentVersion']}'),
                      const SizedBox(height: 5),
                      const Text('Release Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 100),
                        child: SingleChildScrollView(
                          child: Text(updateInfo!['releaseNotes'] ?? ''),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                if (updateInfo == null)
                  TextButton(
                    onPressed: checking ? null : () async {
                      setState(() {
                         checking = true;
                         status = 'Checking GitHub...';
                      });
                      
                      final token = tokenCtrl.text.trim();
                      await _configService.saveGitHubToken(token); // Save for next time
                      
                      final info = await _updateService.checkForUpdate(token: token);
                      // ignore: use_build_context_synchronously
                      if (context.mounted) {
                        setState(() {
                          checking = false;
                          if (info != null && info['updateAvailable'] == true) {
                             status = 'Update found!';
                             updateInfo = info;
                          } else {
                             if (info != null && info.containsKey('error')) {
                               status = 'Error: ${info['error']}';
                             } else {
                               status = 'No updates available';
                               if (info != null && info.containsKey('currentVersion')) {
                                 status += ' (Current: ${info['currentVersion']})';
                               }
                             }
                          }
                        });
                      }
                    },
                    child: const Text('Check'),
                  ),
                if (updateInfo != null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _performUpdate(
                         updateInfo!['downloadUrl'], 
                         token: tokenCtrl.text.trim(),
                         isPrivate: updateInfo!['isPrivate'] ?? false
                      );
                    },
                    child: const Text('Install Update'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performUpdate(String apkUrl, {String? token, bool isPrivate = false}) async {
    setState(() {
      _isCheckingUpdate = true;
      _updateStatus = 'Downloading from GitHub...';
    });

    try {
      // ignore: cancel_subscriptions
      _updateService.runUpdate(apkUrl, token: token, isPrivate: isPrivate).listen(
        (OtaEvent event) {
          if (mounted) {
            setState(() {
              _updateStatus = 'Status: ${event.status} ${event.value ?? ""}%';
            });
          }
        },
        onError: (error) {
           if (mounted) {
            setState(() {
              _updateStatus = 'Update Error: $error';
              _isCheckingUpdate = false;
            });
           }
        },
        onDone: () {
           if (mounted) {
             setState(() {
               _isCheckingUpdate = false; 
             });
           }
        }
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _updateStatus = 'Error starting update: $e';
          _isCheckingUpdate = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Select Machine Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: ConfigService.machineUrls.entries.map((entry) {
                        return RadioListTile<String>(
                          title: Text(entry.key),
                          subtitle: Text(entry.value),
                          value: entry.key,
                          groupValue: _selectedMachine,
                          onChanged: _saveSettings,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_updateStatus.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(_updateStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                         ElevatedButton.icon(
                          onPressed: _isCheckingUpdate ? null : () => _showUpdateDialog(), // implementing dialog below
                          icon: _isCheckingUpdate 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : const Icon(Icons.system_update),
                          label: const Text('Check for Updates'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
