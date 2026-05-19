import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

void main() {
  testWidgets('Handle string backgroundImage', (WidgetTester tester) async {
    await tester.pumpWidget(
      getTestWidgetFromPath(path: 'background_image_string.json'),
    );
    await tester.pumpAndSettle();

    final containerFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration != null &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).image != null,
    );

    expect(containerFinder, findsOneWidget);
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration! as BoxDecoration;
    final decorationImage = decoration.image!;

    expect(decorationImage.image, isA<NetworkImage>());
    expect(
      (decorationImage.image as NetworkImage).url,
      'https://adaptivecards.io/content/airplane.png',
    );
    expect(decorationImage.fit, BoxFit.cover);
    expect(decorationImage.repeat, ImageRepeat.noRepeat);
  });

  testWidgets('Handle object backgroundImage', (WidgetTester tester) async {
    await tester.pumpWidget(
      getTestWidgetFromPath(path: 'background_image_object.json'),
    );
    await tester.pumpAndSettle();

    final containerFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).image != null,
    );

    expect(containerFinder, findsOneWidget);
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration! as BoxDecoration;
    final decorationImage = decoration.image!;

    expect(decorationImage.image, isA<NetworkImage>());
    expect(
      (decorationImage.image as NetworkImage).url,
      'https://adaptivecards.io/content/airplane.png',
    );
    // fillMode: repeat maps to fit: BoxFit.none and repeat: ImageRepeat.repeat
    expect(decorationImage.fit, BoxFit.none);
    expect(decorationImage.repeat, ImageRepeat.repeat);
  });

  testWidgets(
    'Container with only backgroundImage renders it as a child for aspect ratio scaling',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        getTestWidgetFromString(
          jsonString: r'''
          {
            "type": "AdaptiveCard",
            "body": [
              {
                "type": "Container",
                "minHeight": "240px",
                "backgroundImage": "https://adaptivecards.io/content/airplane.png"
              }
            ],
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "version": "1.2"
          }''',
        ),
      );
      await tester.pumpAndSettle();

      // The Container should contain an Image or RawImage widget directly since it has no children
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<NetworkImage>());
      expect(
        (imageWidget.image as NetworkImage).url,
        'https://adaptivecards.io/content/airplane.png',
      );
    },
  );

  testWidgets(
    'Column with only backgroundImage renders it as a child for aspect ratio scaling',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        getTestWidgetFromString(
          jsonString: r'''
{
            "type": "AdaptiveCard",
            "body": [
              {
                "type": "ColumnSet",
                "columns": [
                  {
                    "type": "Column",
                    "width": "20px",
                    "minHeight": "20px",
                    "backgroundImage": "https://adaptivecards.io/content/airplane.png"
                  }
                ]
              }
            ],
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "version": "1.2"
          }''',
        ),
      );
      await tester.pumpAndSettle();

      // The Column should contain an Image or RawImage widget directly since it has no children
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<NetworkImage>());
      expect(
        (imageWidget.image as NetworkImage).url,
        'https://adaptivecards.io/content/airplane.png',
      );
    },
  );
}
