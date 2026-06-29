import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/widgets/rating_stars.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('useHalfStarDisplay renders full, half, and empty stars', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const RatingStars(
          value: 2.5,
          max: 5,
          starColor: Colors.amber,
          iconSize: 16,
          useHalfStarDisplay: true,
        ),
      ),
    );

    expect(find.byIcon(Icons.star), findsNWidgets(2));
    expect(find.byIcon(Icons.star_half), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
  });

  testWidgets('half-step tap on the left half reports a half value', (
    tester,
  ) async {
    double? captured;
    await tester.pumpWidget(
      _host(
        RatingStars(
          value: 0,
          max: 5,
          starColor: Colors.amber,
          iconSize: 24,
          readOnly: false,
          allowHalfSteps: true,
          onRatingChanged: (value) => captured = value,
        ),
      ),
    );

    final firstStar = find.byType(Icon).first;
    final topLeft = tester.getTopLeft(firstStar);
    final size = tester.getSize(firstStar);
    await tester.tapAt(topLeft + Offset(size.width * 0.25, size.height / 2));

    expect(captured, 0.5);
  });

  testWidgets('half-step tap on the right half reports a whole value', (
    tester,
  ) async {
    double? captured;
    await tester.pumpWidget(
      _host(
        RatingStars(
          value: 0,
          max: 5,
          starColor: Colors.amber,
          iconSize: 24,
          readOnly: false,
          allowHalfSteps: true,
          onRatingChanged: (value) => captured = value,
        ),
      ),
    );

    final firstStar = find.byType(Icon).first;
    final topLeft = tester.getTopLeft(firstStar);
    final size = tester.getSize(firstStar);
    await tester.tapAt(topLeft + Offset(size.width * 0.75, size.height / 2));

    expect(captured, 1.0);
  });
}
