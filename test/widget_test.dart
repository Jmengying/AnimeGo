import 'package:flutter_test/flutter_test.dart';
import 'package:anime_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AnimeApp());
    expect(find.text('AnimeGo'), findsOneWidget);
  });
}
