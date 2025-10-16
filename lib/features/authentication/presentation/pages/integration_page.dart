import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:Maya/features/widgets/integration.dart';
import 'package:Maya/features/widgets/integration_card.dart';
import 'package:Maya/features/widgets/stat_card.dart';
import 'package:url_launcher/url_launcher.dart';

class IntegrationsPage extends StatefulWidget {
  const IntegrationsPage({super.key});

  @override
  _IntegrationsPageState createState() => _IntegrationsPageState();
}

Future<void> _launchURL(String url) async {
  try {
    final Uri uri = Uri.parse(Uri.encodeFull(url));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  } catch (e) {
    print('Error launching URL: $e');
  }
}

class _IntegrationsPageState extends State<IntegrationsPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  GoogleSignInAccount? _currentUser;
  bool _isInitializing = false;
  final _storage = const FlutterSecureStorage();

  final List<Integration> integrations = [
    Integration(
      id: 'google-calendar',
      name: 'Google Calendar',
      description: 'Schedule meetings and manage your calendar',
      icon: Icons.calendar_today,
      iconColor: const Color(0xFF4285F4),
      connected: false,
      category: 'calendar',
      scopes: ['https://www.googleapis.com/auth/calendar', 'email', 'profile'],
    ),
    Integration(
      id: 'gohighlevel',
      name: 'GoHighLevel',
      description: 'Manage leads and automate marketing campaigns',
      icon: Icons.campaign,
      iconColor: const Color(0xFF00C4B4),
      connected: false,
      category: 'crm',
      scopes: ['api_key'],
    ),
    Integration(
      id: 'salesforce',
      name: 'Salesforce',
      description: 'Streamline sales processes and customer data',
      icon: Icons.cloud,
      iconColor: const Color(0xFF00A1E0),
      connected: false,
      category: 'crm',
      scopes: ['api', 'refresh_token'],
    ),
    Integration(
      id: 'hubspot',
      name: 'HubSpot',
      description: 'Sync contacts and automate marketing workflows',
      icon: Icons.hub,
      iconColor: const Color(0xFFFF7A59),
      connected: false,
      category: 'crm',
      scopes: ['crm.objects.contacts', 'crm.schemas.custom'],
    ),
    Integration(
      id: 'ai-calling',
      name: 'AI Calling',
      description: 'Automate customer calls with AI-powered voice',
      icon: Icons.phone,
      iconColor: const Color(0xFF8B5CF6),
      connected: false,
      category: 'ai',
      scopes: ['ai.calling'],
    ),
    Integration(
      id: 'ai-widgets',
      name: 'AI Widgets',
      description: 'Add intelligent chatbots and widgets to your app',
      icon: Icons.smart_toy,
      iconColor: const Color(0xFFEC4899),
      connected: false,
      category: 'ai',
      scopes: ['ai.widgets'],
    ),
  ];

  Map<String, List<Integration>> get groupedIntegrations {
    final Map<String, List<Integration>> grouped = {};
    for (var integration in integrations) {
      grouped.putIfAbsent(integration.category, () => []).add(integration);
    }
    return grouped;
  }

  final categoryTitles = {
    'calendar': 'Calendar & Scheduling',
    'communication': 'Communication',
    'crm': 'CRM & Sales',
    'ai': 'AI & Automation',
  };

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      setState(() => _isInitializing = true);
      await _googleSignIn.initialize(
        clientId:
            '452755436213-5hcr78ntadqv75462th9qb3oue5hdgtg.apps.googleusercontent.com',
        serverClientId:
            '452755436213-5d2ujo6g7d4tthk86adluob7q4frege6.apps.googleusercontent.com',
      );
      await _checkStoredTokens();
      _googleSignIn.authenticationEvents.listen((event) {
        setState(() {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _currentUser = event.user;
            _updateIntegrationStatus(true, ['google-calendar', 'calendar']);
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            _currentUser = null;
            _updateIntegrationStatus(false, ['google-calendar', 'calendar']);
          } else if (event is Error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Google Sign-In error: $event')),
            );
          }
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Initialization failed: $e')));
    } finally {
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _checkStoredTokens() async {
    for (var integration in integrations) {
      final accessToken = await _storage.read(
        key: '${integration.id}_access_token',
      );
      if (accessToken != null) {
        setState(() {
          integration.connected = true;
        });
      }
    }
  }

  void _updateIntegrationStatus(bool connected, List<String> integrationIds) {
    setState(() {
      for (var integration in integrations) {
        if (integrationIds.contains(integration.id)) {
          integration.connected = connected;
        }
      }
    });
  }

  void _showTokensDialog(
    String integrationId,
    String accessToken,
    String? serverAuthCode,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.5)),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$integrationId Tokens',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        'Access Token: $accessToken',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF3B82F6)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: accessToken));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Access Token copied to clipboard'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (serverAuthCode != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          'Server Auth Code: $serverAuthCode',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Color(0xFF3B82F6)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: serverAuthCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Server Auth Code copied to clipboard',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x66E5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn(Integration integration) async {
    try {
      GoogleSignInAccount? account = _currentUser;
      if (account == null) {
        account = await _googleSignIn.authenticate(
          scopeHint: integration.scopes,
        );
        setState(() {
          _currentUser = account;
        });
      }

      final authClient = account.authorizationClient;
      final serverAuth = await authClient.authorizeServer(integration.scopes);
      final auth = await authClient.authorizeScopes(integration.scopes);
      if (serverAuth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to retrieve server auth code')),
        );
        return;
      }

      _showTokensDialog(
        integration.id,
        auth.accessToken,
        serverAuth.serverAuthCode
      );

      await _sendTokensToApi(
        integration.id,
        auth.accessToken,
        serverAuth.serverAuthCode,
        integration.scopes.join(' '),
      );
      await _storeTokens(
        integration.id,
        auth.accessToken,
        serverAuth.serverAuthCode,
      );

      setState(() {
        integration.connected = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Successfully connected!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign-in error: $e')));
    }
  }

  Future<void> _storeTokens(
    String integrationId,
    String accessToken,
    String? serverAuthCode,
  ) async {
    await _storage.write(
      key: '${integrationId}_access_token',
      value: accessToken,
    );
    if (serverAuthCode != null) {
      await _storage.write(
        key: '${integrationId}_server_auth_code',
        value: serverAuthCode,
      );
    }
  }

  Future<void> _sendTokensToApi(
    String integrationId,
    String accessToken,
    String serverAuthCode,
    String scopes,
  ) async {
    try {
      print("serverAuthCode: $serverAuthCode");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tokens sent for $integrationId')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending tokens to API: $e')),
      );
    }
  }

  Future<void> _resetConnection(String integrationId) async {
    try {
      await _storage.delete(key: '${integrationId}_access_token');
      await _storage.delete(key: '${integrationId}_server_auth_code');
      if (integrationId == 'google-calendar' || integrationId == 'calendar') {
        await _googleSignIn.signOut();
        setState(() {
          _currentUser = null;
          _updateIntegrationStatus(false, ['google-calendar', 'calendar']);
        });
      } else {
        setState(() {
          integrations.firstWhere((i) => i.id == integrationId).connected =
              false;
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Connection reset')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reset failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Integrations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF1F2937), // gray-800
          onPressed: () => context.pop(),
        ),
      ),
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
            child: _isInitializing
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Integrations',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937), // gray-800
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Connect Google, CRMs, and other services',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4B5563), // gray-600
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Stats
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            boxShadow: const [
                              BoxShadow(blurRadius: 10, color: Colors.black12),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatCard(
                                number: integrations
                                    .where((i) => i.connected)
                                    .length
                                    .toString(),
                                label: 'Connected',
                                color: const Color(0xFF10B981), // green-700
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                number: integrations
                                    .where((i) => !i.connected)
                                    .length
                                    .toString(),
                                label: 'Available',
                                color: const Color(0xFFA855F7), // purple-700
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                number: integrations.length.toString(),
                                label: 'Total',
                                color: const Color(0xFF3B82F6), // blue-700
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Integrations List
                        ...groupedIntegrations.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  top: 16,
                                  bottom: 8,
                                ),
                                child: Text(
                                  categoryTitles[entry.key] ??
                                      'Unknown Category',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              ...entry.value.map(
                                (integration) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: IntegrationCard(
                                    integration: integration,
                                    onConnect: () {
                                      if (integration.id == 'gohighlevel') {
                                        _launchURL(
                                          'https://marketplace.gohighlevel.com/oauth/chooselocation?response_type=code&redirect_uri=https://maya.ravan.ai/api/crm/leadconnector/code&client_id=68755e91a1a7f90cd15877d5-me8gas4x&scope=socialplanner%2Fpost.readonly+saas%2Flocation.edit+socialplanner%2Foauth.readonly+saas%2Flocation.read+socialplanner%2Foauth.edit+conversations%2Freports.readonly+calendars%2Fresources.edit+campaigns.readonly+conversations.readonly+conversations.edit+conversations%2Fmessage.readonly+conversations%2Fmessage.edit+calendars%2Fgroups.readonly+calendars%2Fgroups.edit+calendars%2Fresources.readonly+calendars%2Fevents.edit+calendars%2Fevents.readonly+calendars.edit+calendars.readonly+businesses.edit+businesses.readonly+conversations%2Flivechat.edit+contacts.readonly+contacts.edit+objects%2Fschema.readonly+objects%2Fschema.edit+objects%2Frecord.readonly+objects%2Frecord.edit+associations.edit+associations.readonly+associations%2Frelation.readonly+associations%2Frelation.edit+courses.edit+courses.readonly+forms.readonly+forms.edit+invoices.readonly+invoices.edit+invoices%2Fschedule.readonly+invoices%2Fschedule.edit+invoices%2Ftemplate.readonly+invoices%2Ftemplate.edit+invoices%2Festimate.readonly+invoices%2Festimate.edit+links.readonly+lc-email.readonly+links.edit+locations%2FcustomValues.readonly+medias.edit+medias.readonly+locations%2Ftemplates.readonly+locations%2Ftags.edit+funnels%2Fredirect.readonly+funnels%2Fpage.readonly+funnels%2Ffunnel.readonly+oauth.edit+oauth.readonly+opportunities.readonly+opportunities.edit+socialplanner%2Fpost.edit+socialplanner%2Faccount.readonly+socialplanner%2Faccount.edit+socialplanner%2Fcsv.readonly+socialplanner%2Fcsv.edit+socialplanner%2Fcategory.readonly+socialplanner%2Ftag.readonly+store%2Fshipping.readonly+socialplanner%2Fstatistics.readonly+store%2Fshipping.edit+store%2Fsetting.readonly+surveys.readonly+store%2Fsetting.edit+workflows.readonly+emails%2Fschedule.readonly+emails%2Fbuilder.edit+emails%2Fbuilder.readonly+wordpress.site.readonly+blogs%2Fpost.edit+blogs%2Fpost-update.edit+blogs%2Fcheck-slug.readonly+blogs%2Fcategory.readonly+blogs%2Fauthor.readonly+socialplanner%2Fcategory.edit+socialplanner%2Ftag.edit+blogs%2Fposts.readonly+blogs%2Flist.readonly+charges.readonly+charges.edit+marketplace-installer-details.readonly+twilioaccount.read+documents_contracts%2Flist.readonly+documents_contracts%2FsendLink.edit+documents_contracts_template%2FsendLink.edit+documents_contracts_template%2Flist.readonly+products%2Fcollection.edit+products%2Fcollection.readonly+products%2Fprices.edit+products%2Fprices.readonly+products.edit+products.readonly+payments%2Fcustom-provider.edit+payments%2Fcoupons.edit+payments%2Fcustom-provider.readonly+payments%2Fcoupons.readonly+payments%2Fsubscriptions.readonly+payments%2Ftransactions.readonly+payments%2Fintegration.edit+payments%2Fintegration.readonly+payments%2Forders.edit+payments%2Forders.readonly+funnels%2Fredirect.edit+funnels%2Fpagecount.readonly&state=1',
                                        );
                                      } else if (integration.id ==
                                          'google-calendar') {
                                        _handleGoogleSignIn(integration);
                                      }
                                    },
                                    onReset: () =>
                                        _resetConnection(integration.id),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String number,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
        ),
        child: Column(
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4B5563), // gray-600
              ),
            ),
          ],
        ),
      ),
    );
  }
}
