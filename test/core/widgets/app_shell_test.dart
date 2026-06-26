import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildland_companion_v2/app/theme/app_theme.dart';
import 'package:wildland_companion_v2/core/navigation/app_destination.dart';
import 'package:wildland_companion_v2/core/widgets/app_shell.dart';
import 'package:wildland_companion_v2/core/widgets/app_sidebar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_ShellHarnessState> pumpShell(
    WidgetTester tester,
    Size size, {
    double textScaleFactor = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });

    final harnessKey = GlobalKey<_ShellHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: _ShellHarness(key: harnessKey),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return harnessKey.currentState!;
  }

  group('AppShell responsive navigation', () {
    for (final size in const [
      Size(390, 844),
      Size(844, 390),
      Size(600, 960),
      Size(768, 1024),
    ]) {
      testWidgets('${size.width} x ${size.height} uses overlay drawer', (
        tester,
      ) async {
        await pumpShell(tester, size);
        _expectOverlayDrawerMode(tester);

        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();
        expect(find.byType(AppSidebar), findsOneWidget);

        await tester.tap(find.text('Personnel'));
        await tester.pumpAndSettle();
        expect(find.text('Personnel'), findsOneWidget);
        expect(find.byType(AppSidebar), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    for (final size in const [
      Size(900, 600),
      Size(1024, 768),
      Size(1180, 820),
      Size(1194, 834),
      Size(1280, 800),
      Size(1366, 1024),
      Size(1399, 900),
    ]) {
      testWidgets('${size.width} x ${size.height} uses compact rail', (
        tester,
      ) async {
        await pumpShell(tester, size);
        _expectCompactRailMode(tester, size);

        await tester.tap(find.byTooltip('Personnel'));
        await tester.pumpAndSettle();
        expect(find.text('Personnel'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    for (final size in const [
      Size(1400, 900),
      Size(1440, 900),
      Size(1920, 1080),
    ]) {
      testWidgets('${size.width} x ${size.height} uses desktop sidebar', (
        tester,
      ) async {
        await pumpShell(tester, size);
        _expectDesktopSidebarMode(tester, size);

        await tester.tap(find.text('Fire Map'));
        await tester.pumpAndSettle();
        expect(find.text('Content Fire Map'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('rotation preserves selection and draft-like page state', (
      tester,
    ) async {
      final harness = await pumpShell(tester, const Size(768, 1024));
      harness.navigateTo(4);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('draft-probe')), 'draft');
      await tester.pumpAndSettle();

      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpAndSettle();

      expect(find.text('Tickets / OF-297'), findsOneWidget);
      expect(find.text('draft'), findsOneWidget);
      _expectCompactRailMode(tester, const Size(1024, 768));
      expect(tester.takeException(), isNull);
    });

    testWidgets('large accessibility text keeps one navigation mode visible', (
      tester,
    ) async {
      await pumpShell(
        tester,
        const Size(1024, 768),
        textScaleFactor: 1.8,
      );

      _expectCompactRailMode(tester, const Size(1024, 768));
      expect(tester.takeException(), isNull);
    });
  });
}

void _expectOverlayDrawerMode(WidgetTester tester) {
  expect(find.byKey(const ValueKey('app-navigation-rail')), findsNothing);
  expect(find.byKey(const ValueKey('app-desktop-sidebar')), findsNothing);
  expect(find.byType(AppSidebar), findsNothing);
  expect(find.byTooltip('Open navigation menu'), findsOneWidget);
}

void _expectCompactRailMode(WidgetTester tester, Size surfaceSize) {
  final railFinder = find.byKey(const ValueKey('app-navigation-rail'));

  expect(railFinder, findsOneWidget);
  expect(find.byKey(const ValueKey('app-desktop-sidebar')), findsNothing);
  expect(find.byTooltip('Open navigation menu'), findsNothing);
  expect(find.byType(AppSidebar), findsNothing);
  expect(find.text('Personnel'), findsNothing);

  final railTopLeft = tester.getTopLeft(railFinder);
  final railSize = tester.getSize(railFinder);
  expect(railTopLeft.dy, 0);
  expect(railTopLeft.dx, 0);
  expect(railSize.width, 80);
  expect(railSize.height, surfaceSize.height);
}

void _expectDesktopSidebarMode(WidgetTester tester, Size surfaceSize) {
  final sidebarFinder = find.byKey(const ValueKey('app-desktop-sidebar'));

  expect(sidebarFinder, findsOneWidget);
  expect(find.byKey(const ValueKey('app-navigation-rail')), findsNothing);
  expect(find.byTooltip('Open navigation menu'), findsNothing);

  final sidebarTopLeft = tester.getTopLeft(sidebarFinder);
  final sidebarSize = tester.getSize(sidebarFinder);
  expect(sidebarTopLeft.dy, 0);
  expect(sidebarTopLeft.dx, 0);
  expect(sidebarSize.width, 280);
  expect(sidebarSize.height, surfaceSize.height);
}

class _ShellHarness extends StatefulWidget {
  const _ShellHarness({super.key});

  @override
  State<_ShellHarness> createState() => _ShellHarnessState();
}

class _ShellHarnessState extends State<_ShellHarness> {
  int _selectedIndex = 0;
  late final List<GlobalKey> _pageKeys = List.generate(
    appDestinations.length,
    (_) => GlobalKey(),
  );

  void navigateTo(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final destination = appDestinations[_selectedIndex];
    return AppShell(
      title: destination.label,
      subtitle: destination.subtitle,
      currentIndex: _selectedIndex,
      onNavigate: navigateTo,
      constrainBodyWidth: _selectedIndex != 5,
      body: KeyedSubtree(
        key: _pageKeys[_selectedIndex],
        child: _DraftProbePage(label: destination.label),
      ),
    );
  }
}

class _DraftProbePage extends StatefulWidget {
  final String label;

  const _DraftProbePage({required this.label});

  @override
  State<_DraftProbePage> createState() => _DraftProbePageState();
}

class _DraftProbePageState extends State<_DraftProbePage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Content ${widget.label}'),
            TextField(
              key: const ValueKey('draft-probe'),
              controller: _controller,
            ),
          ],
        ),
      ),
    );
  }
}
