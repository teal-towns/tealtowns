import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../app_scaffold.dart';

class PrivacyTerms extends StatefulWidget {
  String type;

  PrivacyTerms({ this.type = 'privacy', });

  @override
  _PrivacyTermsState createState() => _PrivacyTermsState();
}

class _PrivacyTermsState extends State<PrivacyTerms> {
  String _text = "";
  bool _inited = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return AppScaffoldComponent(
      body: ListView(
        children: [
          SizedBox(height: 30),
          MarkdownBody(
            selectable: true,
            data: _text,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              h1: Theme.of(context).textTheme.displayLarge,
              h2: Theme.of(context).textTheme.displayMedium,
              h3: Theme.of(context).textTheme.displaySmall,
              h4: Theme.of(context).textTheme.headlineMedium,
              h5: Theme.of(context).textTheme.headlineSmall,
              h6: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(height: 30),
        ]
      )
    );
  }

  void _init() async {
    if (!_inited) {
      if (widget.type == 'terms') {
        _text = await rootBundle.loadString('assets/files/terms_of_service.md');
        setState(() { _text = _text; });
      } else {
        _text = await rootBundle.loadString('assets/files/privacy_policy.md');
        setState(() { _text = _text; });
      }
      _inited = true;
    }
  }
}
