import 'package:Maya/core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _volume = 75;
  double _micVolume = 80;
  bool _wifiConnected = true;
  bool _bluetoothEnabled = false;
  bool _wakeWordEnabled = true;
  bool _showShutdownModal = false;
  bool _showRestartModal = false;
  bool _isLoading = false; // To show loading state during API calls



  final ApiClient _apiClient = GetIt.instance<ApiClient>(); // Get ApiClient instance

  final List<Map<String, dynamic>> wifiNetworks = [
    {'name': 'Home Network', 'signal': 'Excellent', 'connected': true},
    {'name': 'Guest WiFi', 'signal': 'Good', 'connected': false},
    {'name': 'Office_5G', 'signal': 'Fair', 'connected': false},
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialAudioSettings(); // Fetch initial speaker, mic volumes, and wake word status
  }

  // Fetch initial speaker, microphone volumes, and wake word status
  Future<void> _fetchInitialAudioSettings() async {
    setState(() => _isLoading = true);
    try {
      // Fetch speaker volume
      final volumeResponse = await _apiClient.getVolume();
      if (volumeResponse['statusCode'] == 200) {
        final volumeData = volumeResponse['data'];
        if (volumeData != null && volumeData['level'] != null) {
          setState(() {
            _volume = (volumeData['level'] as num).toDouble();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch volume: ${volumeResponse['statusCode']}')),
        );
      }

      // Fetch microphone volume
      final micVolumeResponse = await _apiClient.getMicVolume();
      if (micVolumeResponse['statusCode'] == 200) {
        final micVolumeData = micVolumeResponse['data'];
        if (micVolumeData != null && micVolumeData['level'] != null) {
          setState(() {
            _micVolume = (micVolumeData['level'] as num).toDouble();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch mic volume: ${micVolumeResponse['statusCode']}')),
        );
      }

      // Fetch wake word status
      final wakeWordResponse = await _apiClient.getWakeWord();
      if (wakeWordResponse['statusCode'] == 200) {
        final wakeWordData = wakeWordResponse['data'];
        if (wakeWordData != null && wakeWordData['mode'] != null) {
          setState(() {
            _wakeWordEnabled = wakeWordData['mode'] == 'on';
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch wake word status: ${wakeWordResponse['statusCode']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching audio settings: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Set the speaker volume on the device
  Future<void> _setVolume(double value) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.setVolume(value.round());
      if (response['statusCode'] == 200) {
        setState(() => _volume = value);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Volume updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set volume: ${response['statusCode']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting volume: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Set the microphone volume on the device
  Future<void> _setMicVolume(double value) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.setMicVolume(value.round());
      if (response['statusCode'] == 200) {
        setState(() => _micVolume = value);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone volume updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set mic volume: ${response['statusCode']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting mic volume: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Set wake word detection on or off
  Future<void> _setWakeWord(bool value) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.setWakeWord(value ? 'on' : 'off');
      if (response['statusCode'] == 200) {
        setState(() => _wakeWordEnabled = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wake word detection ${value ? 'enabled' : 'disabled'} successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set wake word: ${response['statusCode']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting wake word: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Wake Maya
  Future<void> _wakeMaya() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.wakeMaya();
      if (response['statusCode'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maya activated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to wake Maya: ${response['statusCode']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error waking Maya: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Reboot the device
  Future<void> _rebootDevice() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.rebootDevice();
      if (response['statusCode'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restarting Maya Doll...')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restart device: ${response['statusCode']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restarting device: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Shutdown the device
  Future<void> _shutdownDevice() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.shutdownDevice();
      if (response['statusCode'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shutting down Maya Doll...')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to shutdown device: ${response['statusCode']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error shutting down device: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE3F2FD), // blue-100
                  Color(0xFFF3E8FF), // purple-100
                  Color(0xFFFDE2F3), // pink-100
                ],
              ),
            ),
          ),
          // Radial gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  Color(0x66BBDEFB), // blue-200/40
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Doll Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937), // gray-800
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Configure your Maya AI Doll',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4B5563), // gray-600
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Device Status
                  _buildDeviceStatus(),
                  const SizedBox(height: 16),
                  // Audio Controls
                  _buildAudioControls(),
                  const SizedBox(height: 16),
                  // Wake Maya
                  _buildWakeMaya(),
                  const SizedBox(height: 16),
                  // WiFi Connection
                  _buildWifiConnection(),
                  const SizedBox(height: 16),
                  // Bluetooth
                  _buildBluetooth(),
                  const SizedBox(height: 16),
                  // Additional Settings
                  _buildAdditionalSettings(),
                  const SizedBox(height: 16),
                  // Power Management
                  _buildPowerManagement(),
                ],
              ),
            ),
          ),
          // Modals
          if (_showShutdownModal) _buildShutdownModal(),
          if (_showRestartModal) _buildRestartModal(),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x66BBDEFB), Color(0x66EDE9FE)], // blue-200/40 to purple-200/40
        ),
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
              const Text(
                'Device Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981), // emerald-500
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF047857), // emerald-700
                    ),
                  ),
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
              _buildStatusCard('v2.4.1', 'Firmware', const Color(0xFF3B82F6)), // blue-700
              _buildStatusCard('32°C', 'Temperature', const Color(0xFFA855F7)), // purple-700
              _buildStatusCard('18h', 'Uptime', const Color(0xFF059669)), // green-700
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
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4B5563),
            ),
          ),
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
                decoration: BoxDecoration(
                  color: const Color(0x66BFDBFE), // blue-200/60
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x6693C5FD)), // blue-300/40
                ),
                child: const Icon(
                  Icons.volume_up,
                  size: 20,
                  color: Color(0xFF3B82F6), // blue-700
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Audio Controls',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSlider(
            label: 'Speaker Volume',
            value: _volume,
            valueColor: const Color(0xFF3B82F6),
            onChanged: (value) {
              setState(() => _volume = value);
              _setVolume(value); // Call API to set speaker volume
            },
          ),
          const SizedBox(height: 16),
          _buildSlider(
            label: 'Microphone Sensitivity',
            value: _micVolume,
            valueColor: const Color(0xFFA855F7), // purple-700
            onChanged: (value) {
              setState(() => _micVolume = value);
              _setMicVolume(value); // Call API to set mic volume
            },
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Wake Word Detection',
            subtitle: 'Activate with "Hey Maya"',
            value: _wakeWordEnabled,
            activeColor: const Color(0xFF3B82F6),
            onChanged: (value) {
              _setWakeWord(value); // Call API to set wake word
            },
          ),
          if (!_wakeWordEnabled) ...[
            const SizedBox(height: 8),
            const Text(
              'When wake word detection is off, use the Wake Maya button below to activate Maya.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF4B5563),
              ),
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
                decoration: BoxDecoration(
                  color: const Color(0x66FECACA), // rose-200/60
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x66FCA5A5)), // rose-300/40
                ),
                child: const Icon(
                  Icons.mic,
                  size: 20,
                  color: Color(0xFFBE123C), // rose-700
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Wake Maya',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _wakeMaya,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x66FECACA), // rose-100/60
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x66FCA5A5)), // rose-200/60
              ),
              child: const Center(
                child: Text(
                  'Wake Maya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBE123C), // rose-700
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required Color valueColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              '${value.round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          activeColor: valueColor,
          inactiveColor: Colors.white.withOpacity(0.4),
          onChanged: onChanged,
        ),
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            activeThumbColor: activeColor,
            inactiveTrackColor: const Color(0xFFD1D5DB), // gray-300
            onChanged: onChanged,
          ),
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
                    decoration: BoxDecoration(
                      color: const Color(0x66BBF7D0), // green-200/60
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x669EF7AD)), // green-300/40
                    ),
                    child: const Icon(
                      Icons.wifi,
                      size: 20,
                      color: Color(0xFF047857), // green-700
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'WiFi Connection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              Switch(
                value: _wifiConnected,
                activeThumbColor: const Color(0xFF10B981),
                inactiveTrackColor: const Color(0xFFD1D5DB),
                onChanged: (value) => setState(() => _wifiConnected = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...wifiNetworks.map((network) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: network['connected']
                        ? const Color(0x66BBF7D0) // green-100/60
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: network['connected']
                          ? const Color(0x66BBF7D0) // green-300/60
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.wifi,
                            size: 20,
                            color: network['connected']
                                ? const Color(0xFF047857)
                                : const Color(0xFF4B5563),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                network['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                '${network['signal']} signal',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (network['connected'])
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x66BBF7D0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0x66BBF7D0)),
                          ),
                          child: const Text(
                            'Connected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF047857),
                            ),
                          ),
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
                    decoration: BoxDecoration(
                      color: const Color(0x66BFDBFE), // blue-200/60
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x6693C5FD)), // blue-300/40
                    ),
                    child: const Icon(
                      Icons.bluetooth,
                      size: 20,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Bluetooth',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              Switch(
                value: _bluetoothEnabled,
                activeThumbColor: const Color(0xFF3B82F6),
                inactiveTrackColor: const Color(0xFFD1D5DB),
                onChanged: (value) => setState(() => _bluetoothEnabled = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                _bluetoothEnabled ? 'Searching for devices...' : 'Bluetooth is turned off',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                ),
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
                decoration: BoxDecoration(
                  color: const Color(0x66E9D5FF), // purple-200/60
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x66D8B4FE)), // purple-300/40
                ),
                child: const Icon(
                  Icons.settings,
                  size: 20,
                  color: Color(0xFFA855F7), // purple-700
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Additional Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.tune,
            iconColor: const Color(0xFFA855F7),
            title: 'Voice Settings',
            subtitle: 'Customize voice and language',
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.lock,
            iconColor: const Color(0xFFF59E0B), // amber-700
            title: 'Privacy & Security',
            subtitle: 'Manage data and permissions',
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.cloud_download,
            iconColor: const Color(0xFF3B82F6), // blue-700
            title: 'Software Update',
            subtitle: 'Check for firmware updates',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: const Color(0xFF6B7280), // gray-500
            ),
          ],
        ),
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
                decoration: BoxDecoration(
                  color: const Color(0x66FECACA), // rose-200/60
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x66FCA5A5)), // rose-300/40
                ),
                child: const Icon(
                  Icons.power_settings_new,
                  size: 20,
                  color: Color(0xFFBE123C), // rose-700
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Power Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
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
                    decoration: BoxDecoration(
                      color: const Color(0x66FEF3C7), // amber-100/60
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x66FCD34D)), // amber-200/60
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.restart_alt,
                          size: 24,
                          color: Color(0xFFD97706), // amber-700
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Restart Doll',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD97706),
                          ),
                        ),
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
                    decoration: BoxDecoration(
                      color: const Color(0x66FECACA), // rose-100/60
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x66FCA5A5)), // rose-200/60
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.power_off,
                          size: 24,
                          color: Color(0xFFBE123C), // rose-700
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Shutdown Doll',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFBE123C),
                          ),
                        ),
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
              const Text(
                'Shutdown Maya Doll?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The doll will power off completely. You\'ll need to manually turn it back on.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _showShutdownModal = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x66E5E7EB), // gray-200/60
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _showShutdownModal = false);
                        _shutdownDevice(); // Call shutdown API
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x66FECACA), // rose-100/60
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x66FCA5A5)),
                        ),
                        child: const Text(
                          'Shutdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFBE123C),
                          ),
                        ),
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
              const Text(
                'Restart Maya Doll?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The doll will restart and be back online in about 30 seconds.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _showRestartModal = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x66E5E7EB), // gray-200/60
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _showRestartModal = false);
                        _rebootDevice(); // Call reboot API
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x66FEF3C7), // amber-100/60
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x66FCD34D)),
                        ),
                        child: const Text(
                          'Restart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD97706),
                          ),
                        ),
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