// lib/screens/det_selector_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../widgets/det_selector.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

int? detToParamNumber(String detName) {
  // use case-insensitive flag via the RegExp constructor
  final re = RegExp(r'det\s*0*(\d+)', caseSensitive: false);
  final m = re.firstMatch(detName);
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}

Future<Map<String, dynamic>?> fetchSensorInfoFromServerByParam(
  String apiHost,
  int param,
) async {
  try {
    final uri = Uri.parse(
      '$apiHost/api/sensorinfo',
    ).replace(queryParameters: {'param': param.toString()});
    final resp = await http.get(uri).timeout(const Duration(seconds: 6));
    if (resp.statusCode == 200) {
      final j = json.decode(resp.body);
      if (j is Map && j['found'] == true && j['sensor'] is Map) {
        return Map<String, dynamic>.from(j['sensor']);
      }
    }
  } catch (e) {
    print('fetchSensorInfoFromServerByParam error: $e');
  }
  return null;
}

Future<Map<String, String>?> loadLocalSensorInfo(int param) async {
  final prefs = await SharedPreferences.getInstance();
  final k = 'sensor_local_$param';
  final s = prefs.getString(k);
  if (s == null) return null;
  final j = json.decode(s) as Map<String, dynamic>;
  return j.map((k, v) => MapEntry(k, v?.toString() ?? ''));
}

Future<void> saveLocalSensorInfo(int param, Map<String, String> info) async {
  final prefs = await SharedPreferences.getInstance();
  final k = 'sensor_local_$param';
  await prefs.setString(k, json.encode(info));
}

class DetSelectorScreen extends StatefulWidget {
  final WebSocketChannel? channel;
  final String apiHost;

  const DetSelectorScreen({Key? key, required this.apiHost, this.channel})
    : super(key: key);

  @override
  State<DetSelectorScreen> createState() => _DetSelectorScreenState();
}

class _DetSelectorScreenState extends State<DetSelectorScreen> {
  String? selectedDet;
  bool loadingSensor = false;
  bool saving = false;

  final _workstationCtrl = TextEditingController();
  final _probeCtrl = TextEditingController();
  final _calDateCtrl = TextEditingController();
  final _calDueCtrl = TextEditingController();

  @override
  void dispose() {
    _workstationCtrl.dispose();
    _probeCtrl.dispose();
    _calDateCtrl.dispose();
    _calDueCtrl.dispose();
    super.dispose();
  }

  // helper: format DateTime -> "YYYY-MM-DD"
  String _formatDateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  // show date picker and write ISO date (YYYY-MM-DD) into controller
  Future<void> _pickDate(TextEditingController ctrl) async {
    DateTime initial;
    try {
      // try parse existing yyyy-mm-dd or fallback to today
      final current = ctrl.text.trim();
      if (current.isNotEmpty) {
        initial = DateTime.parse(current);
      } else {
        initial = DateTime.now();
      }
    } catch (_) {
      initial = DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      ctrl.text = _formatDateOnly(picked);
    }
  }

  Future<void> _loadSensorInfoFor(String? col) async {
    if (col == null) return;
    setState(() => loadingSensor = true);
    try {
      final param = detToParamNumber(col);
      Map<String, dynamic>? master;
      if (param != null) {
        master = await fetchSensorInfoFromServerByParam(widget.apiHost, param);
      }

      Map<String, String>? local;
      if (param != null) {
        local = await loadLocalSensorInfo(param);
      }

      if (local != null) {
        _workstationCtrl.text = local['workstation'] ?? '';
        _probeCtrl.text = local['probeId'] ?? '';
        _calDateCtrl.text = local['calibrationDate'] ?? '';
        _calDueCtrl.text = local['calibrationDue'] ?? '';
      } else if (master != null) {
        _workstationCtrl.text = master['ChannelName']?.toString() ?? '';
        _probeCtrl.text = master['SenID']?.toString() ?? '';

        String stripDate(dynamic v) {
          if (v == null) return '';
          final s = v.toString();
          final idx = s.indexOf('T');
          return idx > 0 ? s.substring(0, idx) : s;
        }

        // ensure we store/display only YYYY-MM-DD (no T00:00)
        _calDateCtrl.text = stripDate(master['Cali.Date']);
        _calDueCtrl.text = stripDate(master['Cali.Due']);
      } else {
        _workstationCtrl.text = '';
        _probeCtrl.text = '';
        _calDateCtrl.text = '';
        _calDueCtrl.text = '';
      }
    } catch (e) {
      print('loadSensorInfo error: $e');
    } finally {
      if (mounted) setState(() => loadingSensor = false);
    }
  }

  Future<void> _saveLocalOnly() async {
    final col = selectedDet;
    if (col == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a DET first')));
      return;
    }
    final param = detToParamNumber(col);
    if (param == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid DET selected')));
      return;
    }

    setState(() => saving = true);
    final map = {
      'workstation': _workstationCtrl.text.trim(),
      'probeId': _probeCtrl.text.trim(),
      'calibrationDate': _calDateCtrl.text.trim(),
      'calibrationDue': _calDueCtrl.text.trim(),
    };
    await saveLocalSensorInfo(param, map);
    // optional: notify via WS that this tablet saved a local override (server will ignore for DB)
    try {
      widget.channel?.sink.add(
        json.encode({'action': 'sensorinfo_local_saved', 'param': param}),
      );
    } catch (_) {}
    if (mounted) {
      setState(() => saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved locally on tablet')));
    }
  }

  void _onDetChanged(String? col) {
    setState(() => selectedDet = col);
    _loadSensorInfoFor(col);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select DET & Sensor Info'),
        automaticallyImplyLeading: false, // hide default back button too if they rely on keys, or just remove explicit leading
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DetSelector(
              apiHost: widget.apiHost,
              wsChannel: widget.channel,
              onChanged: _onDetChanged,
              onSensorInfo: (map) {
                if (map != null) {
                  _workstationCtrl.text = map['ChannelName']?.toString() ?? '';
                  _probeCtrl.text = map['SenID']?.toString() ?? '';

                  String stripDate(dynamic v) {
                    if (v == null) return '';
                    final s = v.toString();
                    final idx = s.indexOf('T');
                    return idx > 0 ? s.substring(0, idx) : s;
                  }

                  _calDateCtrl.text = stripDate(map['Cali.Date']);
                  _calDueCtrl.text = stripDate(map['Cali.Due']);
                }
              },
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _workstationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Workstation name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _probeCtrl,
                      decoration: const InputDecoration(labelText: 'Probe ID'),
                    ),
                    const SizedBox(height: 12),
                    // Calibration Date (read-only; opens date picker)
                    InkWell(
                      onTap: () => _pickDate(_calDateCtrl),
                      child: IgnorePointer(
                        child: TextField(
                          controller: _calDateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Calibration Date',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Calibration Due (read-only; opens date picker)
                    InkWell(
                      onTap: () => _pickDate(_calDueCtrl),
                      child: IgnorePointer(
                        child: TextField(
                          controller: _calDueCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Calibration Due',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: (selectedDet == null || loadingSensor)
                              ? null
                              : () => _loadSensorInfoFor(selectedDet),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Load from PC DB'),
                        ),
                        ElevatedButton.icon(
                          onPressed: saving ? null : _saveLocalOnly,
                          icon: saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Save locally'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text('Selected: ${selectedDet ?? "—"}'),
          ],
        ),
      ),
    );
  }
}
