import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MyTestHttpOverrides();
  });

  testWidgets('Handle string backgroundImage', (WidgetTester tester) async {
    await tester.pumpWidget(getWidget('background_image_string.json'));
    await tester.pumpAndSettle();

    final containerFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).image != null,
    );

    expect(containerFinder, findsOneWidget);
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;
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
    await tester.pumpWidget(getWidget('background_image_object.json'));
    await tester.pumpAndSettle();

    final containerFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).image != null,
    );

    expect(containerFinder, findsOneWidget);
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;
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
}
