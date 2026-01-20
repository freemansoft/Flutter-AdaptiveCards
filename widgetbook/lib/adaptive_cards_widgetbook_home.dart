import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdaptiveCardsWidgetbookHome extends StatelessWidget {
  const AdaptiveCardsWidgetbookHome({super.key});

  // The original page used WidgetbookTheme.of(context) to get the theme.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Adaptive Cards for Flutter',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Text(
              'New',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const Wrap(
              children: [
                _Card(
                  title: '🚀 Adaptive Cards Hub',
                  url: 'https://adaptivecards.microsoft.com/',
                  description: 'The "new" Adaptive Cards hub.',
                ),
                _Card(
                  title: '📝 Layout Designer',
                  url: 'https://adaptivecards.microsoft.com/designer.html',
                  description: 'Experiment with in the designer.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Legacy',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const Wrap(
              children: [
                _Card(
                  title: '📖 Microsoft Docs',
                  url: 'https://adaptivecards.io/',
                  description: 'Learn more about Adaptive Cards.',
                ),
                _Card(
                  title: '📍 Schema Explorer',
                  url: 'https://adaptivecards.io/explorer/',
                  description: 'Learn more about Adaptive Cards.',
                ),
                _Card(
                  title: '🔬 Samples and Templates',
                  url: 'https://adaptivecards.io/samples/',
                  description: 'Learn more about Adaptive Cards.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This repository',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const Wrap(
              children: [
                _Card(
                  title: '✨ Flutter-AdaptiveCards',
                  url: 'https://github.com/freemansoft/Flutter-AdaptiveCards',
                  description: 'This project and examples on GitHub',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.description,
    required this.url,
  });

  final String title;
  final String description;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 360,
      ),
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withAlpha(100),
          ),
        ),
        child: InkWell(
          onTap: () => launchUrl(Uri.parse(url)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.titleMedium,
                    children: [
                      TextSpan(
                        text: title,
                      ),
                      const TextSpan(text: ' '),
                      const WidgetSpan(
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(120),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
