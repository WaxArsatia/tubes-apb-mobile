import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tubes_apb_mobile/src/app.dart';
import 'package:tubes_apb_mobile/src/data/app_controller.dart';
import 'package:tubes_apb_mobile/src/data/local_services.dart';
import 'package:tubes_apb_mobile/src/domain/models.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Future<AppController> pumpMockApp(
    WidgetTester tester, {
    bool emptyData = false,
  }) async {
    final persistence = MemoryPersistenceService()
      ..storedConfig = const AppConfig(
        apiBaseUrl: AppConfig.defaultApiBaseUrl,
        mockMode: true,
      );
    final controller = AppController(
      persistence: persistence,
      notifications: RecordingNotificationGateway(),
      imagePicker: FixedImagePickerGateway(null),
    );
    if (emptyData) {
      controller.categories.clear();
      controller.transactions.clear();
      controller.savings.clear();
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: const FinUApp(),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('unauthenticated users land on polished login', (tester) async {
    await pumpMockApp(tester);

    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Masuk sebagai demo'), findsOneWidget);
    expect(find.text('nama@email.com'), findsOneWidget);
    expect(find.text('Minimal 8 karakter'), findsOneWidget);
  });

  testWidgets('demo login reaches Beranda with Indonesian navigation', (
    tester,
  ) async {
    await pumpMockApp(tester);

    await tester.tap(find.text('Masuk sebagai demo'));
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Transaksi'), findsOneWidget);
    expect(find.text('Tabungan'), findsOneWidget);
    expect(find.text('Akun'), findsOneWidget);
    expect(find.textContaining('Selamat'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -280));
    await tester.pumpAndSettle();

    expect(find.text('Aksi cepat'), findsOneWidget);
    expect(find.text('Tambah pengeluaran'), findsOneWidget);
    expect(find.text('Tambah pemasukan'), findsOneWidget);
    expect(find.text('Tambah tabungan'), findsOneWidget);
  });

  testWidgets('dashboard empty states render when data is absent', (
    tester,
  ) async {
    await pumpMockApp(tester, emptyData: true);

    await tester.tap(find.text('Masuk sebagai demo'));
    await tester.pumpAndSettle();

    expect(find.text('Budget pengeluaran belum diatur'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Belum ada aktivitas'),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Belum ada aktivitas'), findsOneWidget);
    expect(find.text('Buat kategori'), findsOneWidget);
  });

  testWidgets('dashboard fits common Android phone widths', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in const [Size(360, 800), Size(412, 915)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await pumpMockApp(tester);
      await tester.tap(find.text('Masuk sebagai demo'));
      await tester.pumpAndSettle();

      expect(find.text('Beranda'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Aktivitas terbaru'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Aktivitas terbaru'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
