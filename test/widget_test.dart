import 'package:flutter_test/flutter_test.dart';
import 'package:manage_notif_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ManageNotifApp());
    expect(find.text('Manage Notif'), findsOneWidget);
  });
}
