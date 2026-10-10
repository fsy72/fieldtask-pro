// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldtask_pro/features/auth/domain/entities/app_user.dart';
import 'package:fieldtask_pro/features/auth/presentation/auth_providers.dart';
import 'package:fieldtask_pro/main.dart';

class _UnauthenticatedAuthController extends AuthController {
  @override
  Future<AppUser?> build() async => null;
}

void main() {
  testWidgets('affiche l’écran de connexion sans session', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            _UnauthenticatedAuthController.new,
          ),
        ],
        child: const FieldTaskApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FieldTask Pro'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
  });
}
