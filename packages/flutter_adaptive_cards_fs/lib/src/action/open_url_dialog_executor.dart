import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Fetches remote content for `Action.OpenUrlDialog`.
///
/// Returns parsed card JSON, a fallback URL string for HTML, or null.
Future<dynamic> fetchOpenUrlDialogContent(String url) async {
  final response = await http.get(Uri.parse(url));
  final contentType = response.headers['content-type'] ?? '';

  if (response.statusCode == 200) {
    if (contentType.contains('application/json') ||
        contentType.contains('text/plain')) {
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } on FormatException catch (e) {
        assert(() {
          developer.log('Could not parse JSON from $url: $e');
          return true;
        }());
        rethrow;
      }
    } else if (contentType.contains('text/html')) {
      assert(() {
        developer.log('Remote returned HTML instead of JSON from $url');
        return true;
      }());
      return url;
    } else {
      assert(() {
        developer.log(
          'Remote returned unexpected content type $contentType from $url',
        );
        return true;
      }());
      return null;
    }
  } else {
    assert(() {
      developer.log(
        'Remote returned unexpected status ${response.statusCode} from $url',
      );
      return true;
    }());
    return null;
  }
}

/// Opens [url] in the platform browser when dialog content is HTML.
Future<void> launchOpenUrlDialogBrowser(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    assert(() {
      developer.log('Could not launch $url');
      return true;
    }());
  }
}

/// Default OpenUrlDialog UX when no host handler is installed.
Future<void> showOpenUrlDialog({
  required BuildContext context,
  required String url,
  required HostConfigs hostConfigs,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<dynamic>(
              future: fetchOpenUrlDialogContent(url),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 8),
                      Text('Error loading content: ${snapshot.error}'),
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
                    return SingleChildScrollView(
                      child: SelectionArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RawAdaptiveCard.fromMap(
                              map: data,
                              hostConfigs: hostConfigs,
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (data is String) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      unawaited(launchOpenUrlDialogBrowser(data));
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
  );
}
