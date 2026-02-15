import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/src/actions/generic_action.dart';
import 'package:flutter_adaptive_cards_plus/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_plus/src/elements/actions/icon_button.dart';
import 'package:flutter_adaptive_cards_plus/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

//
// https://adaptivecards.io/explorer/Action.OpenUrlDialog.html
// https://adaptivecards.microsoft.com/?topic=Action.OpenUrlDialog
/// It should fetch a card set from the URL
/// and display the adaptive card returned in a dialog
class AdaptiveActionOpenUrlDialog extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionOpenUrlDialog({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap));

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id = loadId(adaptiveMap);

  @override
  AdaptiveActionOpenUrlDialogState createState() =>
      AdaptiveActionOpenUrlDialogState();
}

class AdaptiveActionOpenUrlDialogState
    extends State<AdaptiveActionOpenUrlDialog>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  late String? url;
  late GenericActionOpenUrlDialog action;

  @override
  void initState() {
    super.initState();
    url = adaptiveMap['url'] as String?;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    action =
        actionTypeRegistry.getActionForType(
              map: adaptiveMap,
            )!
            as GenericActionOpenUrlDialog;
  }

  /// returns the content if a card
  /// returns the url if it is html
  /// returns null if it is neither html nor json
  /// rethrows otherwise
  Future<dynamic> _fetchContent(String url) async {
    final response = await http.get(Uri.parse(url));
    final contentType = response.headers['content-type'] ?? '';

    if (response.statusCode == 200) {
      // text/plain is used for the sample data files when fetched from GitHub
      if (contentType.contains('application/json') ||
          contentType.contains('text/plain')) {
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } on FormatException catch (e) {
          // If JSON parsing fails, fallback to browser
          developer.log('Could not parse JSON from $url: $e');
          rethrow;
        }
      } else if (contentType.contains('text/html')) {
        // If not JSON or error status, fallback to browser
        developer.log('Remote returned HTML instead of JSON from $url');
        return url;
      } else {
        // If not JSON, HTML, drop it
        developer.log(
          'Remote returned unexpected content type $contentType from $url',
        );
        return null;
      }
    } else {
      // not a 200 but not a ClientException (not an exception)
      developer.log(
        'Remote returned unexpected status ${response.statusCode} from $url',
      );
      return null;
    }
  }

  Future<void> _launchBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle error if needed, for now just log or do nothing
      developer.log('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButtonAction(
      adaptiveMap: adaptiveMap,
      onTapped: (BuildContext context) {
        if (url != null) {
          unawaited(
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FutureBuilder<dynamic>(
                        future: _fetchContent(url!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            // This path typically won't be reached because _fetchContent catches errors and returns url
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(height: 8),
                                Text(
                                  'Error loading content: ${snapshot.error}',
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                          } else if (snapshot.hasData) {
                            final data = snapshot.data;
                            if (data is Map<String, dynamic>) {
                              // We think this is card.
                              // This doesn't support templates
                              return SingleChildScrollView(
                                child: SelectionArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      RawAdaptiveCard.fromMap(
                                        map: data,
                                        hostConfigs: rawRootCardWidgetState
                                            .widget
                                            .hostConfigs,
                                      ),
                                      const SizedBox(height: 16),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (data is String) {
                              // Fallback to Browser: Auto-launch and close dialog
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                unawaited(_launchBrowser(data));
                                Navigator.pop(context);
                              });
                              return const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Opening in browser...'),
                                  ],
                                ),
                              );
                            } else {
                              // We don't know what this is, drop it
                              return const SizedBox.shrink();
                            }
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }
}
