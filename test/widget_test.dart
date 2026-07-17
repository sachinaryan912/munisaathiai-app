import 'package:flutter_test/flutter_test.dart';
import 'package:munisaathiai/main.dart';

void main() {
  testWidgets('App boots to splash screen', (tester) async {
    await tester.pumpWidget(const MuniApp());
    await tester.pump();
    expect(find.text('Muni Saathi AI'), findsOneWidget);
  });
}
