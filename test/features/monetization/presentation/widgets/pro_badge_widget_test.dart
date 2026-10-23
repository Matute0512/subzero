import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subzero/core/theme/app_theme.dart';
import 'package:subzero/features/monetization/presentation/widgets/pro_badge_widget.dart';

void main() {
  group('ProBadgeWidget Tests', () {
    testWidgets('debe renderizar el texto PRO y el icono de estrella', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: ProBadgeWidget(),
          ),
        ),
      );

      expect(find.text('PRO'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('debe disparar onTap al ser pulsado', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ProBadgeWidget(onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(ProBadgeWidget));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}

