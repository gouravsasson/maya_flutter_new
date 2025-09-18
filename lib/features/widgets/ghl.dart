// lib/features/widgets/ghl_webview_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GhlWebViewPage extends StatefulWidget {
  const GhlWebViewPage({super.key});

  @override
  State<GhlWebViewPage> createState() => _GhlWebViewPageState();
}

class _GhlWebViewPageState extends State<GhlWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse("https://marketplace.gohighlevel.com/oauth/chooselocation?response_type=code&redirect_uri=https%3A%2F%2Foauth.n8n.cloud%2Foauth2%2Fcallback&client_id=68755e91a1a7f90cd15877d5-me8gas4x&scope=socialplanner%2Fpost.readonly+saas%2Flocation.write+socialplanner%2Foauth.readonly+saas%2Flocation.read+socialplanner%2Foauth.write+conversations%2Freports.readonly+calendars%2Fresources.write+campaigns.readonly+conversations.readonly+conversations.write+conversations%2Fmessage.readonly+conversations%2Fmessage.write+calendars%2Fgroups.readonly+calendars%2Fgroups.write+calendars%2Fresources.readonly+calendars%2Fevents.write+calendars%2Fevents.readonly+calendars.write+calendars.readonly+businesses.write+businesses.readonly+conversations%2Flivechat.write+contacts.readonly+contacts.write+objects%2Fschema.readonly+objects%2Fschema.write+objects%2Frecord.readonly+objects%2Frecord.write+associations.write+associations.readonly+associations%2Frelation.readonly+associations%2Frelation.write+courses.write+courses.readonly+forms.readonly+forms.write+invoices.readonly+invoices.write+invoices%2Fschedule.readonly+invoices%2Fschedule.write+invoices%2Ftemplate.readonly+invoices%2Ftemplate.write+invoices%2Festimate.readonly+invoices%2Festimate.write+links.readonly+lc-email.readonly+links.write+locations%2FcustomValues.readonly+medias.write+medias.readonly+locations%2Ftemplates.readonly+locations%2Ftags.write+funnels%2Fredirect.readonly+funnels%2Fpage.readonly+funnels%2Ffunnel.readonly+oauth.write+oauth.readonly+opportunities.readonly+opportunities.write+socialplanner%2Fpost.write+socialplanner%2Faccount.readonly+socialplanner%2Faccount.write+socialplanner%2Fcsv.readonly+socialplanner%2Fcsv.write+socialplanner%2Fcategory.readonly+socialplanner%2Ftag.readonly+store%2Fshipping.readonly+socialplanner%2Fstatistics.readonly+store%2Fshipping.write+store%2Fsetting.readonly+surveys.readonly+store%2Fsetting.write+workflows.readonly+emails%2Fschedule.readonly+emails%2Fbuilder.write+emails%2Fbuilder.readonly+wordpress.site.readonly+blogs%2Fpost.write+blogs%2Fpost-update.write+blogs%2Fcheck-slug.readonly+blogs%2Fcategory.readonly+blogs%2Fauthor.readonly+socialplanner%2Fcategory.write+socialplanner%2Ftag.write+blogs%2Fposts.readonly+blogs%2Flist.readonly+charges.readonly+charges.write+marketplace-installer-details.readonly+twilioaccount.read+documents_contracts%2Flist.readonly+documents_contracts%2FsendLink.write+documents_contracts_template%2FsendLink.write+documents_contracts_template%2Flist.readonly+products%2Fcollection.write+products%2Fcollection.readonly+products%2Fprices.write+products%2Fprices.readonly+products.write+products.readonly+payments%2Fcustom-provider.write+payments%2Fcoupons.write+payments%2Fcustom-provider.readonly+payments%2Fcoupons.readonly+payments%2Fsubscriptions.readonly+payments%2Ftransactions.readonly+payments%2Fintegration.write+payments%2Fintegration.readonly+payments%2Forders.write+payments%2Forders.readonly+funnels%2Fredirect.write+funnels%2Fpagecount.readonly"), // ✅ GHL URL
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GoHighLevel"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
