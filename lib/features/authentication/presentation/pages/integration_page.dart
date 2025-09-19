import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:Maya/core/network/api_client.dart';
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
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class _IntegrationsPageState extends State<IntegrationsPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  GoogleSignInAccount? _currentUser;
  bool _isInitializing = true;
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
      id: 'gmail',
      name: 'Gmail',
      description: 'Send and receive emails automatically',
      icon: Icons.email,
      iconColor: const Color(0xFFEA4335),
      connected: false,
      category: 'communication',
      scopes: [
        'https://www.googleapis.com/auth/gmail.modify',
        'email',
        'profile',
      ],
    ),
    Integration(
      id: 'gohighlevel',
      name: 'GoHighLevel',
      description: 'Manage leads and automate marketing campaigns',
      icon: Icons.campaign,
      iconColor: const Color(0xFF00C4B4),
      connected: false,
      category: 'crm',
      scopes: ['api_key'], // GHL uses API keys
    ),
    Integration(
      id: 'salesforce',
      name: 'Salesforce',
      description: 'Streamline sales processes and customer data',
      icon: Icons.cloud,
      iconColor: const Color(0xFF00A1E0),
      connected: false,
      category: 'crm',
      scopes: ['api', 'refresh_token'], // Salesforce OAuth scopes
    ),
    Integration(
      id: 'hubspot',
      name: 'HubSpot',
      description: 'Sync contacts and automate marketing workflows',
      icon: Icons.hub,
      iconColor: const Color(0xFFFF7A59),
      connected: false,
      category: 'crm',
      scopes: ['crm.objects.contacts', 'crm.schemas.custom'], // HubSpot scopes
    ),
    Integration(
      id: 'ai-calling',
      name: 'AI Calling',
      description: 'Automate customer calls with AI-powered voice',
      icon: Icons.phone,
      iconColor: const Color(0xFF8B5CF6),
      connected: false,
      category: 'ai',
      scopes: ['ai.calling'], // Placeholder for AI calling service
    ),
    Integration(
      id: 'ai-widgets',
      name: 'AI Widgets',
      description: 'Add intelligent chatbots and widgets to your app',
      icon: Icons.smart_toy,
      iconColor: const Color(0xFFEC4899),
      connected: false,
      category: 'ai',
      scopes: ['ai.widgets'], // Placeholder for AI widgets service
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
      await _googleSignIn.initialize(
        clientId:
            '841387083562-45mis85tj8qs6338e9ukki1skpcbbcgv.apps.googleusercontent.com',
        serverClientId:
            '841387083562-l7oelrb7heenmek2kfs70d4tamee45a7.apps.googleusercontent.com',
      );
      await _checkStoredTokens();
      _googleSignIn.authenticationEvents.listen((event) {
        setState(() {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _currentUser = event.user;
            _updateIntegrationStatus(true, ['google-calendar', 'gmail']);
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            _currentUser = null;
            _updateIntegrationStatus(false, ['google-calendar', 'gmail']);
          } else if (event is Error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Google Sign-In error: $event')),
            );
          }
        });
      });

      final account = await _googleSignIn.attemptLightweightAuthentication();
      if (account != null) {
        setState(() {
          _currentUser = account;
          _updateIntegrationStatus(true, ['google-calendar', 'gmail']);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Initialization failed: $e')));
    } finally {
      setState(() {
        _isInitializing = false;
      });
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
      print(auth);

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
      final payload = getIt<ApiClient>().prepareGoogleAccessTokenMobilePayload(
        accessToken,
        serverAuthCode,
        scopes,
        integrationId,
      );
      print(payload);
      final response = await getIt<ApiClient>().googleAccessTokenMobile(
        payload,
      );
      print(response);
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
      if (integrationId == 'google-calendar' || integrationId == 'gmail') {
        await _googleSignIn.signOut();
        setState(() {
          _currentUser = null;
          _updateIntegrationStatus(false, ['google-calendar', 'gmail']);
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
      // appBar: AppBar(
      //   title: const Text('Integrations'),
      //   elevation: 0,
      //   backgroundColor: Theme.of(context).colorScheme.surface,
      // ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatCard(
                        number: integrations
                            .where((i) => i.connected)
                            .length
                            .toString(),
                        label: 'Connected',
                      ),
                      const SizedBox(width: 8),
                      StatCard(
                        number: integrations
                            .where((i) => !i.connected)
                            .length
                            .toString(),
                        label: 'Available',
                      ),
                      const SizedBox(width: 8),
                      StatCard(
                        number: integrations.length.toString(),
                        label: 'Total',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: groupedIntegrations.entries.map((entry) {
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
                              categoryTitles[entry.key] ?? 'Unknown Category',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          ...entry.value.map(
                            (integration) => IntegrationCard(
                              integration: integration,
                              onConnect: () {
                                if (integration.id == 'gohighlevel') {
                                  _launchURL(
                                    'https://marketplace.gohighlevel.com/oauth/chooselocation?response_type=code&redirect_uri=https://maya.ravan.ai/api/crm/leadconnector/code&client_id=68755e91a1a7f90cd15877d5-me8gas4x&scope=socialplanner%2Fpost.readonly+saas%2Flocation.write+socialplanner%2Foauth.readonly+saas%2Flocation.read+socialplanner%2Foauth.write+conversations%2Freports.readonly+calendars%2Fresources.write+campaigns.readonly+conversations.readonly+conversations.write+conversations%2Fmessage.readonly+conversations%2Fmessage.write+calendars%2Fgroups.readonly+calendars%2Fgroups.write+calendars%2Fresources.readonly+calendars%2Fevents.write+calendars%2Fevents.readonly+calendars.write+calendars.readonly+businesses.write+businesses.readonly+conversations%2Flivechat.write+contacts.readonly+contacts.write+objects%2Fschema.readonly+objects%2Fschema.write+objects%2Frecord.readonly+objects%2Frecord.write+associations.write+associations.readonly+associations%2Frelation.readonly+associations%2Frelation.write+courses.write+courses.readonly+forms.readonly+forms.write+invoices.readonly+invoices.write+invoices%2Fschedule.readonly+invoices%2Fschedule.write+invoices%2Ftemplate.readonly+invoices%2Ftemplate.write+invoices%2Festimate.readonly+invoices%2Festimate.write+links.readonly+lc-email.readonly+links.write+locations%2FcustomValues.readonly+medias.write+medias.readonly+locations%2Ftemplates.readonly+locations%2Ftags.write+funnels%2Fredirect.readonly+funnels%2Fpage.readonly+funnels%2Ffunnel.readonly+oauth.write+oauth.readonly+opportunities.readonly+opportunities.write+socialplanner%2Fpost.write+socialplanner%2Faccount.readonly+socialplanner%2Faccount.write+socialplanner%2Fcsv.readonly+socialplanner%2Fcsv.write+socialplanner%2Fcategory.readonly+socialplanner%2Ftag.readonly+store%2Fshipping.readonly+socialplanner%2Fstatistics.readonly+store%2Fshipping.write+store%2Fsetting.readonly+surveys.readonly+store%2Fsetting.write+workflows.readonly+emails%2Fschedule.readonly+emails%2Fbuilder.write+emails%2Fbuilder.readonly+wordpress.site.readonly+blogs%2Fpost.write+blogs%2Fpost-update.write+blogs%2Fcheck-slug.readonly+blogs%2Fcategory.readonly+blogs%2Fauthor.readonly+socialplanner%2Fcategory.write+socialplanner%2Ftag.write+blogs%2Fposts.readonly+blogs%2Flist.readonly+charges.readonly+charges.write+marketplace-installer-details.readonly+twilioaccount.read+documents_contracts%2Flist.readonly+documents_contracts%2FsendLink.write+documents_contracts_template%2FsendLink.write+documents_contracts_template%2Flist.readonly+products%2Fcollection.write+products%2Fcollection.readonly+products%2Fprices.write+products%2Fprices.readonly+products.write+products.readonly+payments%2Fcustom-provider.write+payments%2Fcoupons.write+payments%2Fcustom-provider.readonly+payments%2Fcoupons.readonly+payments%2Fsubscriptions.readonly+payments%2Ftransactions.readonly+payments%2Fintegration.write+payments%2Fintegration.readonly+payments%2Forders.write+payments%2Forders.readonly+funnels%2Fredirect.write+funnels%2Fpagecount.readonly&state=1',
                                  );
                                }
                              },
                              onReset: () => _resetConnection(integration.id),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
