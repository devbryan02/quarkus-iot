import 'package:flutter_test/flutter_test.dart';
import 'package:kivo_mobile/main.dart' as app;

void main() {
  testWidgets('muestra el inicio de Kivo sin presentar funciones operativas', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Kivo'), findsOneWidget);
    expect(find.text('Aplicación en preparación.'), findsOneWidget);
  });
}
