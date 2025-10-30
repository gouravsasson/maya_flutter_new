import 'package:Maya/core/network/api_client.dart';
import 'package:Maya/utils/debouncer.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Audio & Wake Word
  double _volume = 75;
  double _micVolume = 80;
  bool _wakeWordEnabled = true;

  // Connectivity
  bool _wifiConnected = true;
  bool _bluetoothEnabled = false;

  // Power Modals
  bool _showShutdownModal = false;
  bool _showRestartModal = false;

  // Loading
  bool _isLoading = false;

  // Notification Preferences
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _deviceNotifications = true;

  // API & Debouncers
  final ApiClient _apiClient = GetIt.instance<ApiClient>();
  final Debouncer _volumeDebouncer = Debouncer(delay: Duration(milliseconds: 500));
  final Debouncer _micVolumeDebouncer = Debouncer(delay: Duration(milliseconds: 500));
  final Debouncer _notiDebouncer = Debouncer(delay: Duration(milliseconds: 600));

  // Mock WiFi Networks
  final List<Map<String, dynamic>> wifiNetworks = [
    {'name': 'Home Network', 'signal': 'Excellent', 'connected': true},
    {'name': 'Guest WiFi', 'signal': 'Good', 'connected': false},
    {'name': 'Office_5G', 'signal': 'Fair', 'connected': false},
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialAudioSettings();
    _fetchNotificationPreferences(); // Fetch noti prefs
  }

  @override
  void dispose() {
    _volumeDebouncer.cancel();
    _micVolumeDebouncer.cancel();
    _notiDebouncer.cancel();
    super.dispose();
  }

  // MARK: - Fetch Initial Settings

  Future<void> _fetchInitialAudioSettings() async {
    setState(() => _isLoading = true);
    try {
      // Volume
      final volumeResponse = await _apiClient.getVolume();
      if (volumeResponse['statusCode'] == 200) {
        final data = volumeResponse['data'];
        if (data != null && data['level'] != null) {
          setState(() => _volume = (data['level'] as num).toDouble());
        }
      }

      // Mic Volume
      final micResponse = await _apiClient.getMicVolume();
      if (micResponse['statusCode'] == 200) {
        final data = micResponse['data'];
        if (data != null && data['level'] != null) {
          setState(() => _micVolume = (data['level'] as num).toDouble());
        }
      }

      // Wake Word
      final wakeResponse = await _apiClient.getWakeWord();
      if (wakeResponse['statusCode'] == 200) {
        final data = wakeResponse['data'];
        if (data != null && data['mode'] != null) {
          setState(() => _wakeWordEnabled = data['mode'] == 'on');
        }
      }
    } catch (e) {
      _showSnackBar('Error fetching audio settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNotificationPreferences() async {
    try {
      final resp = await _apiClient.updateNotificationPreferences(
        emailNotifications: true,
        pushNotifications: true,
        smsNotifications: true,
        deviceNotifications: true,
      );

      if (resp['statusCode'] == 200) {
        final data = resp['data'] as Map<String, dynamic>;
        setState(() {
          _emailNotifications = data['email_notifications'] ?? true;
          _pushNotifications = data['push_notifications'] ?? true;
          _smsNotifications = data['sms_notifications'] ?? false;
          _deviceNotifications = data['device_notifications'] ?? true;
        });
      }
    } catch (_) {
      // Silently use defaults
    }
  }

  // MARK: - API Actions

  Future<void> _setVolume(double value) async {
    setState(() => _isLoading = true);
    try {
      final resp = await _apiClient.setVolume(value.round());
      if (resp['statusCode'] == 200) {
        setState(() => _volume = value);
        _showSnackBar('Volume updated');
      } else {
        _showSnackBar('Failed to set volume');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setMicVolume(double value) async {
    setState(() => _isLoading = true);
    try {
      final resp = await _apiClient.setMicVolume(value.round());
      if (resp['statusCode'] == 200) {
        setState(() => _micVolume = value);
        _showSnackBar('Mic volume updated');
      } else {
        _showSnackBar('Failed to set mic volume');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setWakeWord(bool value) async {
    setState(() => _isLoading = true);
    try {
      final resp = await _apiClient.setWakeWord(value ? 'on' : 'off');
      if (resp['statusCode'] == 200) {
        setState(() => _wakeWordEnabled = value);
        _showSnackBar('Wake word ${value ? 'enabled' : 'disabled'}');
      } else {
        _showSnackBar('Failed to update wake word');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _wakeMaya() async {
    setState(() => _isLoading = true);
    try {
      final resp = await _apiClient.wakeMaya();
      if (resp['statusCode'] == 200) {
        _showSnackBar('Maya activated');
      } else {
        _showSnackBar('Failed to wake Maya');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rebootDevice() async {
    setState(() => _isLoading = true);
    try {
      final resp = await _apiClient.rebootDevice();
      if (resp['statusCode'] == 200) {
        _showSnackBar('Restarting Maya Doll...');
      } else {
        _showSnackBar('Failed to restart');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shutdownDevice() async {
    setState(() => _isLoading = true);
    try {
      final resp = await _apiClient.shutdownDevice();
      if (resp['statusCode'] == 200) {
        _showSnackBar('Shutting down Maya Doll...');
      } else {
        _showSnackBar('Failed to shutdown');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNotificationPrefs() async {
    setState(() => _isLoading = true);
    try {
      final resp = await _apiClient.updateNotificationPreferences(
        emailNotifications: _emailNotifications,
        pushNotifications: _pushNotifications,
        smsNotifications: _smsNotifications,
        deviceNotifications: _deviceNotifications,
      );

      if (resp['statusCode'] == 200) {
        _showSnackBar('Notification preferences saved');
      } else {
        _showSnackBar('Failed to save preferences');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // MARK: - Build UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE3F2FD),
                  Color(0xFFF3E8FF),
                  Color(0xFFFDE2F3),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [Color(0x66BBDEFB), Colors.transparent],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Doll Settings',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Configure your Maya AI Doll',
                    style: TextStyle(fontSize: 16, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 24),

                  _buildDeviceStatus(),
                  const SizedBox(height: 16),
                  _buildAudioControls(),
                  const SizedBox(height: 16),
                  _buildWakeMaya(),
                  const SizedBox(height: 16),
                  _buildWifiConnection(),
                  const SizedBox(height: 16),
                  _buildBluetooth(),
                  const SizedBox(height: 16),
                  _buildAdditionalSettings(),
                  const SizedBox(height: 16),
                  _buildNotificationPreferences(), // NEW
                  const SizedBox(height: 16),
                  _buildPowerManagement(),
                ],
              ),
            ),
          ),

          // Modals
          if (_showShutdownModal) _buildShutdownModal(),
          if (_showRestartModal) _buildRestartModal(),

          // Loading
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // MARK: - UI Components

  Widget _buildDeviceStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0x66BBDEFB), Color(0x66EDE9FE)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Device Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
                  const SizedBox(width: 8),
                  const Text('Online', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF047857))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatusCard('87%', 'Battery', const Color(0xFF1F2937)),
              _buildStatusCard('v2.4.1', 'Firmware', const Color(0xFF3B82F6)),
              _buildStatusCard('32°C', 'Temperature', const Color(0xFFA855F7)),
              _buildStatusCard('18h', 'Uptime', const Color(0xFF059669)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String value, String label, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: valueColor)),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0x66BFDBFE), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x6693C5FD))),
                child: const Icon(Icons.volume_up, size: 20, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 8),
              const Text('Audio Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 20),
          _buildSlider(
            label: 'Speaker Volume',
            value: _volume,
            valueColor: const Color(0xFF3B82F6),
            onChanged: (v) {
              setState(() => _volume = v);
              _volumeDebouncer.run(() => _setVolume(v));
            },
          ),
          const SizedBox(height: 16),
          _buildSlider(
            label: 'Microphone Sensitivity',
            value: _micVolume,
            valueColor: const Color(0xFFA855F7),
            onChanged: (v) {
              setState(() => _micVolume = v);
              _micVolumeDebouncer.run(() => _setMicVolume(v));
            },
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Wake Word Detection',
            subtitle: 'Activate with "Hey Maya"',
            value: _wakeWordEnabled,
            activeColor: const Color(0xFF3B82F6),
            onChanged: _setWakeWord,
          ),
          if (!_wakeWordEnabled) ...[
            const SizedBox(height: 8),
            const Text(
              'When wake word detection is off, use the Wake Maya button below to activate Maya.',
              style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWakeMaya() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0x66FECACA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x66FCA5A5))),
                child: const Icon(Icons.mic, size: 20, color: Color(0xFFBE123C)),
              ),
              const SizedBox(width: 8),
              const Text('Wake Maya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _wakeMaya,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0x66FECACA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x66FCA5A5))),
              child: const Center(child: Text('Wake Maya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFBE123C)))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({required String label, required double value, required Color valueColor, required ValueChanged<double> onChanged}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
            Text('${value.round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
          ],
        ),
        Slider(value: value, min: 0, max: 100, activeColor: valueColor, inactiveColor: Colors.white.withOpacity(0.4), onChanged: onChanged),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.4))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
            ],
          ),
          Switch(value: value, activeThumbColor: activeColor, inactiveTrackColor: const Color(0xFFD1D5DB), onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildWifiConnection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: const Color(0x66BBF7D0), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x669EF7AD))),
                    child: const Icon(Icons.wifi, size: 20, color: Color(0xFF047857)),
                  ),
                  const SizedBox(width: 8),
                  const Text('WiFi Connection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                ],
              ),
              Switch(value: _wifiConnected, activeThumbColor: const Color(0xFF10B981), inactiveTrackColor: const Color(0xFFD1D5DB), onChanged: (v) => setState(() => _wifiConnected = v)),
            ],
          ),
          const SizedBox(height: 12),
          ...wifiNetworks.map((net) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: net['connected'] ? const Color(0x66BBF7D0) : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: net['connected'] ? const Color(0x66BBF7D0) : Colors.white.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.wifi, size: 20, color: net['connected'] ? const Color(0xFF047857) : const Color(0xFF4B5563)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(net['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
                              Text('${net['signal']} signal', style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                            ],
                          ),
                        ],
                      ),
                      if (net['connected'])
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0x66BBF7D0), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0x66BBF7D0))),
                          child: const Text('Connected', style: TextStyle(fontSize: 12, color: Color(0xFF047857))),
                        ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBluetooth() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: const Color(0x66BFDBFE), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x6693C5FD))),
                    child: const Icon(Icons.bluetooth, size: 20, color: Color(0xFF3B82F6)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Bluetooth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                ],
              ),
              Switch(value: _bluetoothEnabled, activeThumbColor: const Color(0xFF3B82F6), inactiveTrackColor: const Color(0xFFD1D5DB), onChanged: (v) => setState(() => _bluetoothEnabled = v)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.4))),
            child: Center(
              child: Text(
                _bluetoothEnabled ? 'Searching for devices...' : 'Bluetooth is turned off',
                style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0x66E9D5FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x66D8B4FE))),
                child: const Icon(Icons.settings, size: 20, color: Color(0xFFA855F7)),
              ),
              const SizedBox(width: 8),
              const Text('Additional Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 12),
          _buildSettingTile(icon: Icons.tune, iconColor: const Color(0xFFA855F7), title: 'Voice Settings', subtitle: 'Customize voice and language'),
          const SizedBox(height: 8),
          _buildSettingTile(icon: Icons.lock, iconColor: const Color(0xFFF59E0B), title: 'Privacy & Security', subtitle: 'Manage data and permissions'),
          const SizedBox(height: 8),
          _buildSettingTile(icon: Icons.cloud_download, iconColor: const Color(0xFF3B82F6), title: 'Software Update', subtitle: 'Check for firmware updates'),
        ],
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required Color iconColor, required String title, required String subtitle}) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.4))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                  ],
                ),
              ],
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  // MARK: - NEW: Notification Preferences

  Widget _buildNotificationPreferences() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0x66FEF3C7), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x66FCD34D))),
                child: const Icon(Icons.notifications, size: 20, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 8),
              const Text('Notification Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Receive updates via email',
            value: _emailNotifications,
            activeColor: const Color(0xFFD97706),
            onChanged: (v) {
              setState(() => _emailNotifications = v);
              _notiDebouncer.run(_updateNotificationPrefs);
            },
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'In-app alerts',
            value: _pushNotifications,
            activeColor: const Color(0xFFD97706),
            onChanged: (v) {
              setState(() => _pushNotifications = v);
              _notiDebouncer.run(_updateNotificationPrefs);
            },
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            title: 'SMS Notifications',
            subtitle: 'Text message alerts',
            value: _smsNotifications,
            activeColor: const Color(0xFFD97706),
            onChanged: (v) {
              setState(() => _smsNotifications = v);
              _notiDebouncer.run(_updateNotificationPrefs);
            },
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            title: 'Device Notifications',
            subtitle: 'Doll-specific alerts',
            value: _deviceNotifications,
            activeColor: const Color(0xFFD97706),
            onChanged: (v) {
              setState(() => _deviceNotifications = v);
              _notiDebouncer.run(_updateNotificationPrefs);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPowerManagement() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0x66FECACA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x66FCA5A5))),
                child: const Icon(Icons.power_settings_new, size: 20, color: Color(0xFFBE123C)),
              ),
              const SizedBox(width: 8),
              const Text('Power Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showRestartModal = true),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0x66FEF3C7), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x66FCD34D))),
                    child: Column(
                      children: [
                        const Icon(Icons.restart_alt, size: 24, color: Color(0xFFD97706)),
                        const SizedBox(height: 8),
                        const Text('Restart Doll', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showShutdownModal = true),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0x66FECACA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x66FCA5A5))),
                    child: Column(
                      children: [
                        const Icon(Icons.power_off, size: 24, color: Color(0xFFBE123C)),
                        const SizedBox(height: 8),
                        const Text('Shutdown Doll', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFBE123C))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShutdownModal() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black26)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Shutdown Maya Doll?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const SizedBox(height: 12),
              const Text("The doll will power off completely. You'll need to manually turn it back on.", style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _showShutdownModal = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: const Color(0x66E5E7EB), borderRadius: BorderRadius.circular(16)),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _showShutdownModal = false);
                        _shutdownDevice();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: const Color(0x66FECACA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x66FCA5A5))),
                        child: const Text('Shutdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFBE123C))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestartModal() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black26)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Restart Maya Doll?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const SizedBox(height: 12),
              const Text('The doll will restart and be back online in about 30 seconds.', style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _showRestartModal = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: const Color(0x66E5E7EB), borderRadius: BorderRadius.circular(16)),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _showRestartModal = false);
                        _rebootDevice();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: const Color(0x66FEF3C7), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x66FCD34D))),
                        child: const Text('Restart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}