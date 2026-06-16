import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'core/formatters.dart';
import 'data/app_controller.dart';
import 'domain/finance_calculator.dart';
import 'domain/models.dart';

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  return AppController();
});

final routerProvider = Provider<GoRouter>((ref) {
  final controller = ref.watch(appControllerProvider);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: controller,
    redirect: (context, state) {
      final isAuth = controller.isAuthenticated;
      final authRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot' ||
          state.matchedLocation == '/reset';
      if (!isAuth && !authRoute) return '/login';
      if (isAuth && authRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot',
        builder: (context, state) => const ForgotScreen(),
      ),
      GoRoute(path: '/reset', builder: (context, state) => const ResetScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/category',
                builder: (context, state) => const CategoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transaction',
                builder: (context, state) => const TransactionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saving',
                builder: (context, state) => const SavingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/setting',
                builder: (context, state) => const SettingScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class FinUApp extends ConsumerStatefulWidget {
  const FinUApp({super.key});

  @override
  ConsumerState<FinUApp> createState() => _FinUAppState();
}

class _FinUAppState extends ConsumerState<FinUApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(appControllerProvider).initialize());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FinU',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

ThemeData _theme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0F766E),
    brightness: brightness,
  );
  final subtleBorder = BorderSide(color: scheme.outlineVariant);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surfaceContainerLowest,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: subtleBorder,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: subtleBorder,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.primaryContainer,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
        );
      }),
    ),
  );
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.home_rounded),
            icon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.category_rounded),
            icon: Icon(Icons.category_outlined),
            label: 'Kategori',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.receipt_long_rounded),
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Transaksi',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.savings_rounded),
            icon: Icon(Icons.savings_outlined),
            label: 'Tabungan',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person_rounded),
            icon: Icon(Icons.settings_outlined),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    return AuthScaffold(
      title: 'Masuk',
      subtitle: 'Kelola pemasukan, pengeluaran, dan target tabungan kamu.',
      children: [
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'nama@email.com',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Kata sandi',
            hintText: 'Minimal 8 karakter',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: controller.loading
              ? null
              : () => _submit(
                  context,
                  () => controller.login(email.text, password.text),
                ),
          child: controller.loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Masuk'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: controller.loading
              ? null
              : () => _submit(
                  context,
                  () => controller.login('demo@finu.app', 'password123'),
                ),
          icon: const Icon(Icons.play_circle_outline),
          label: const Text('Masuk sebagai demo'),
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          child: const Text('Belum punya akun? Daftar'),
        ),
        TextButton(
          onPressed: () => context.go('/forgot'),
          child: const Text('Lupa password?'),
        ),
      ],
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    return AuthScaffold(
      title: 'Daftar',
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nama'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Kata sandi'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: confirm,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Konfirmasi kata sandi'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: controller.loading
              ? null
              : () => _submit(
                  context,
                  () => controller.register(
                    name.text,
                    email.text,
                    password.text,
                    confirm.text,
                  ),
                ),
          child: const Text('Daftar'),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Sudah punya akun? Masuk'),
        ),
      ],
    );
  }
}

class ForgotScreen extends ConsumerStatefulWidget {
  const ForgotScreen({super.key});

  @override
  ConsumerState<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends ConsumerState<ForgotScreen> {
  final email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    return AuthScaffold(
      title: 'Lupa kata sandi',
      children: [
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: controller.loading
              ? null
              : () => _submit(
                  context,
                  () => controller.forgotPassword(email.text),
                  success: 'Kode reset dikirim ke email kamu',
                ),
          child: const Text('Kirim Kode Reset'),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Kembali ke masuk'),
        ),
      ],
    );
  }
}

class ResetScreen extends ConsumerStatefulWidget {
  const ResetScreen({super.key});

  @override
  ConsumerState<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends ConsumerState<ResetScreen> {
  final email = TextEditingController();
  final code = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    return AuthScaffold(
      title: 'Atur ulang kata sandi',
      children: [
        TextField(
          controller: email,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: code,
          decoration: const InputDecoration(labelText: 'Kode Reset'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Kata sandi baru'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: controller.loading
              ? null
              : () => _submit(
                  context,
                  () => controller.resetPassword(
                    email.text,
                    code.text,
                    password.text,
                  ),
                  success: 'Kata sandi berhasil diatur ulang',
                  afterSuccess: () => context.go('/login'),
                ),
          child: const Text('Atur ulang kata sandi'),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Kembali ke masuk'),
        ),
      ],
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: FinULogo(size: 82)),
                  const SizedBox(height: 16),
                  Text(
                    'FinU',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final profile = controller.profile!;
    final now = DateTime.now();
    final budget = controller.calculator.budgetRemaining(
      controller.categories,
      controller.transactions,
      now,
    );
    final totalBalance = controller.calculator.totalBalance(
      controller.savings,
      controller.transactions,
    );
    final monthlyIncome = controller.calculator.monthlyIncome(
      controller.savings,
      now,
    );
    final monthlyExpense = controller.calculator.monthlyExpense(
      controller.transactions,
      now,
    );
    final recent = controller.recentActivities();

    return AppPage(
      title: 'Beranda',
      child: RefreshIndicator(
        onRefresh: () async => ref.read(appControllerProvider).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            DashboardHeader(profile: profile, now: now),
            const SizedBox(height: 16),
            BalanceOverviewCard(
              balance: totalBalance,
              income: monthlyIncome,
              expense: monthlyExpense,
            ),
            const SizedBox(height: 12),
            if (budget.budgetedCategoryCount == 0)
              EmptyPrompt(
                icon: Icons.flag_outlined,
                title: 'Budget pengeluaran belum diatur',
                body:
                    'Tambahkan batas bulanan di kategori pengeluaran supaya progres budget bisa dipantau.',
                actionLabel: 'Buka kategori',
                onPressed: () => context.go('/category'),
              )
            else
              BudgetProgressCard(budget: budget),
            const SizedBox(height: 18),
            SectionHeader(title: 'Aksi cepat'),
            const SizedBox(height: 8),
            QuickActionGrid(
              actions: [
                QuickAction(
                  icon: Icons.remove_circle_outline,
                  label: 'Tambah pengeluaran',
                  onTap: () {
                    if (controller.expenseCategories.isEmpty) {
                      _message(
                        context,
                        'Buat kategori pengeluaran terlebih dahulu',
                      );
                      context.go('/category');
                    } else {
                      _showTransactionForm(context, controller);
                    }
                  },
                ),
                QuickAction(
                  icon: Icons.add_circle_outline,
                  label: 'Tambah pemasukan',
                  onTap: () => _showSavingForm(
                    context,
                    controller,
                    initialType: SavingType.generalIncome,
                  ),
                ),
                QuickAction(
                  icon: Icons.savings_outlined,
                  label: 'Tambah tabungan',
                  onTap: () {
                    if (controller.savingCategories.isEmpty) {
                      _message(
                        context,
                        'Buat kategori tabungan terlebih dahulu',
                      );
                      context.go('/category');
                    } else {
                      _showSavingForm(
                        context,
                        controller,
                        initialType: SavingType.saving,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Aktivitas terbaru',
              actionLabel: 'Lihat semua',
              onAction: () => context.go('/transaction'),
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              EmptyPrompt(
                icon: Icons.auto_awesome_outlined,
                title: 'Belum ada aktivitas',
                body:
                    'Buat kategori pertama, lalu catat pemasukan dan pengeluaran.',
                actionLabel: 'Buat kategori',
                onPressed: () => context.go('/category'),
              )
            else
              ...recent.map(
                (item) => ActivityTile(item: item, controller: controller),
              ),
          ],
        ),
      ),
    );
  }
}

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  var type = CategoryType.expense;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final list = type == CategoryType.expense
        ? controller.expenseCategories
        : controller.savingCategories;
    return AppPage(
      title: 'Kategori',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryForm(context, controller, type),
        child: const Icon(Icons.add),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<CategoryType>(
            segments: const [
              ButtonSegment(
                value: CategoryType.expense,
                label: Text('Pengeluaran'),
                icon: Icon(Icons.payments_outlined),
              ),
              ButtonSegment(
                value: CategoryType.saving,
                label: Text('Tabungan'),
                icon: Icon(Icons.savings_outlined),
              ),
            ],
            selected: {type},
            onSelectionChanged: (value) => setState(() => type = value.first),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            EmptyPrompt(
              icon: Icons.category_outlined,
              title:
                  'Belum ada kategori ${type == CategoryType.expense ? 'pengeluaran' : 'tabungan'}',
              body:
                  'Kelompokkan catatan keuangan agar laporan lebih mudah dibaca.',
              actionLabel: 'Tambah kategori',
              onPressed: () => _showCategoryForm(context, controller, type),
            )
          else
            ...list.map(
              (cat) => Dismissible(
                key: ValueKey(cat.id),
                direction: DismissDirection.endToStart,
                background: const DeleteBackground(),
                confirmDismiss: (_) async {
                  final affected = await controller.softDeleteCategory(cat.id);
                  if (!context.mounted) return false;
                  _undo(
                    context,
                    'Dihapus. Batalkan?',
                    () async => controller.restoreCategory(cat.id),
                  );
                  if (affected > 0) {
                    _message(
                      context,
                      'Kategori ini memiliki $affected data yang menjadi Tanpa kategori.',
                    );
                  }
                  return false;
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CategoryTile(
                    category: cat,
                    onTap: () => _showCategoryForm(
                      context,
                      controller,
                      type,
                      category: cat,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  DateTime? month = DateTime.now();
  String? categoryId;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    var list = controller.activeTransactions;
    if (month != null) {
      list = list
          .where(
            (tx) =>
                tx.date.year == month!.year && tx.date.month == month!.month,
          )
          .toList();
    }
    if (categoryId != null) {
      list = list.where((tx) => tx.categoryId == categoryId).toList();
    }
    final total = list.fold(0, (sum, tx) => sum + tx.amount);
    return AppPage(
      title: 'Transaksi',
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (controller.expenseCategories.isEmpty) {
            _message(context, 'Buat kategori pengeluaran terlebih dahulu');
            context.go('/category');
            return;
          }
          _showTransactionForm(context, controller);
        },
        child: const Icon(Icons.add),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Semua'),
                selected: month == null && categoryId == null,
                onSelected: (_) => setState(() {
                  month = null;
                  categoryId = null;
                }),
              ),
              FilterChip(
                label: Text(month == null ? 'Per Bulan' : formatMonth(month!)),
                selected: month != null,
                onSelected: (_) => setState(
                  () => month = month == null ? DateTime.now() : null,
                ),
              ),
              DropdownMenu<String?>(
                width: 220,
                label: const Text('Kategori'),
                initialSelection: categoryId,
                dropdownMenuEntries: [
                  const DropdownMenuEntry(value: null, label: 'Semua kategori'),
                  ...controller.expenseCategories.map(
                    (cat) => DropdownMenuEntry(value: cat.id, label: cat.name),
                  ),
                ],
                onSelected: (value) => setState(() => categoryId = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SummaryStrip(
            value: '-${formatIdr(total)}',
            label: 'Total pengeluaran',
            positive: false,
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            EmptyPrompt(
              icon: Icons.receipt_long_outlined,
              title: controller.activeTransactions.isEmpty
                  ? 'Belum ada transaksi'
                  : 'Tidak ada transaksi untuk filter ini',
              body: 'Catat pengeluaran supaya budget bulanan tetap terpantau.',
              actionLabel: 'Tambah transaksi',
              onPressed: () => _showTransactionForm(context, controller),
            )
          else
            ...list.map(
              (tx) => TransactionTile(entry: tx, controller: controller),
            ),
        ],
      ),
    );
  }
}

class SavingScreen extends ConsumerStatefulWidget {
  const SavingScreen({super.key});

  @override
  ConsumerState<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends ConsumerState<SavingScreen> {
  var tab = EntryTab.all;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    var list = controller.activeSavings;
    if (tab == EntryTab.generalIncome) {
      list = list
          .where((item) => item.type == SavingType.generalIncome)
          .toList();
    } else if (tab == EntryTab.saving) {
      list = list.where((item) => item.type == SavingType.saving).toList();
    }
    final total = list.fold(0, (sum, item) => sum + item.amount);
    return AppPage(
      title: 'Pemasukan & Tabungan',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSavingForm(context, controller),
        child: const Icon(Icons.add),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<EntryTab>(
            segments: const [
              ButtonSegment(value: EntryTab.all, label: Text('Semua')),
              ButtonSegment(
                value: EntryTab.generalIncome,
                label: Text('Pemasukan Umum'),
              ),
              ButtonSegment(value: EntryTab.saving, label: Text('Nabung')),
            ],
            selected: {tab},
            onSelectionChanged: (value) => setState(() => tab = value.first),
          ),
          const SizedBox(height: 12),
          SummaryStrip(
            value: '+${formatIdr(total)}',
            label: 'Total keseluruhan',
            positive: true,
          ),
          if (tab == EntryTab.saving) ...[
            const SizedBox(height: 12),
            ...controller.savingCategories
                .where((cat) => cat.savingTarget != null)
                .map(
                  (cat) =>
                      SavingProgressCard(category: cat, controller: controller),
                ),
          ],
          const SizedBox(height: 12),
          if (list.isEmpty)
            EmptyPrompt(
              icon: Icons.savings_outlined,
              title: 'Belum ada pemasukan atau tabungan',
              body:
                  'Catat pemasukan umum atau progres tabungan untuk mulai membangun saldo.',
              actionLabel: 'Tambah catatan',
              onPressed: () => _showSavingForm(context, controller),
            )
          else
            ...list.map(
              (item) => SavingTile(entry: item, controller: controller),
            ),
        ],
      ),
    );
  }
}

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  late final TextEditingController name;
  late final TextEditingController baseUrl;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(appControllerProvider);
    name = TextEditingController(text: controller.profile?.name);
    baseUrl = TextEditingController(text: controller.config.apiBaseUrl);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final profile = controller.profile!;
    return AppPage(
      title: 'Pengaturan',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle('Profil'),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(48),
              onTap: () async {
                try {
                  await controller.pickAndUploadProfilePhoto();
                  if (context.mounted) {
                    _message(context, 'Foto profil berhasil diperbarui');
                  }
                } catch (error) {
                  if (context.mounted) _message(context, _cleanError(error));
                }
              },
              child: ProfileAvatar(profile: profile, radius: 44),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nama'),
          ),
          const SizedBox(height: 12),
          TextField(
            enabled: false,
            controller: TextEditingController(text: profile.email),
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              try {
                await controller.updateProfile(name.text);
                if (context.mounted) {
                  _message(context, 'Profil berhasil diperbarui');
                }
              } catch (error) {
                if (context.mounted) _message(context, _cleanError(error));
              }
            },
            child: const Text('Simpan Perubahan'),
          ),
          const SizedBox(height: 24),
          SectionTitle('Notifikasi'),
          SwitchListTile(
            value: profile.budgetNotificationEnabled,
            onChanged: (value) async {
              await controller.updateNotification(value);
            },
            title: const Text('Notifikasi budget'),
            subtitle: const Text(
              'Diberitahu saat budget mendekati batas atau terlampaui',
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle('Konfigurasi aplikasi'),
          TextField(
            controller: baseUrl,
            decoration: const InputDecoration(labelText: 'API Base URL'),
          ),
          SwitchListTile(
            value: controller.config.mockMode,
            onChanged: (value) async {
              await controller.updateConfig(
                controller.config.copyWith(mockMode: value),
              );
            },
            title: const Text('Mode mock'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              await controller.updateConfig(
                controller.config.copyWith(apiBaseUrl: baseUrl.text.trim()),
              );
              if (context.mounted) _message(context, 'Konfigurasi tersimpan');
            },
            child: const Text('Simpan Konfigurasi'),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                final router = GoRouter.of(context);
                await controller.logout();
                router.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: floatingActionButton,
      body: child,
    );
  }
}

class FinULogo extends StatelessWidget {
  const FinULogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .24),
      child: SvgPicture.asset(
        'assets/images/finu_logo.svg',
        width: size,
        height: size,
        semanticsLabel: 'FinU',
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.radius = 24});

  final UserProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final source = profile.profilePhotoUrl;
    ImageProvider? image;
    if (source != null && source.isNotEmpty) {
      image = source.startsWith('http')
          ? NetworkImage(source)
          : FileImage(File(source)) as ImageProvider;
    }
    return CircleAvatar(
      radius: radius,
      backgroundImage: image,
      child: image == null ? Text(profile.initials) : null,
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.profile, required this.now});

  final UserProfile profile;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat ${greeting(now)},',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => context.go('/setting'),
          borderRadius: BorderRadius.circular(28),
          child: ProfileAvatar(profile: profile, radius: 26),
        ),
      ],
    );
  }
}

class BalanceOverviewCard extends StatelessWidget {
  const BalanceOverviewCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  final int balance;
  final int income;
  final int expense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: scheme.onPrimary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saldo keseluruhan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatIdr(balance),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                final tiles = [
                  _MetricPill(
                    label: 'Pemasukan bulan ini',
                    value: '+${formatIdr(income)}',
                    icon: Icons.trending_up,
                    color: _incomeColor(context),
                  ),
                  _MetricPill(
                    label: 'Pengeluaran bulan ini',
                    value: '-${formatIdr(expense)}',
                    icon: Icons.trending_down,
                    color: _expenseColor(context),
                  ),
                ];
                if (compact) {
                  return Column(
                    children: [
                      tiles.first,
                      const SizedBox(height: 8),
                      tiles.last,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: tiles.first),
                    const SizedBox(width: 8),
                    Expanded(child: tiles.last),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({super.key, required this.budget});

  final BudgetSummary budget;

  @override
  Widget build(BuildContext context) {
    final isHealthy = budget.remaining >= 0;
    final color = isHealthy ? _incomeColor(context) : _expenseColor(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'Budget bulan ini'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: budget.progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
              color: color,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sisa budget',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatIdr(budget.remaining),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${budget.budgetedCategoryCount} kategori',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 360;
        if (narrow) {
          return Column(
            children: [
              for (final action in actions) ...[
                _QuickActionButton(action: action, fullWidth: true),
                if (action != actions.last) const SizedBox(height: 8),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (final action in actions) ...[
              Expanded(child: _QuickActionButton(action: action)),
              if (action != actions.last) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action, this.fullWidth = false});

  final QuickAction action;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: fullWidth ? 56 : 96,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: fullWidth
                ? Row(
                    children: [
                      Icon(action.icon, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          action.label,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(action.icon, color: scheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        action.label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.positive,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? Colors.green : Colors.red;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryStrip extends StatelessWidget {
  const SummaryStrip({
    super.key,
    required this.value,
    required this.label,
    required this.positive,
  });

  final String value;
  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class EmptyPrompt extends StatelessWidget {
  const EmptyPrompt({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 172,
              height: 104,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                'assets/images/empty_state.svg',
                semanticsLabel: title,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(height: 14),
              FilledButton.tonal(
                onPressed: onPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detail = category.type == CategoryType.expense
        ? category.monthlyBudget == null
              ? 'Budget belum diatur'
              : 'Budget ${formatIdr(category.monthlyBudget!)}'
        : category.savingTarget == null
        ? 'Target belum diatur'
        : 'Target ${formatIdr(category.savingTarget!)}';
    return FinanceListItem(
      icon: iconFor(category.iconKey),
      title: category.name,
      subtitle: detail,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class FinanceListItem extends StatelessWidget {
  const FinanceListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.item, required this.controller});

  final Object item;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (item is TransactionEntry) {
      return TransactionTile(
        entry: item as TransactionEntry,
        controller: controller,
      );
    }
    return SavingTile(entry: item as SavingEntry, controller: controller);
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.entry,
    required this.controller,
  });

  final TransactionEntry entry;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final category = controller.categories
        .where((cat) => cat.id == entry.categoryId)
        .firstOrNull;
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: const DeleteBackground(),
      confirmDismiss: (_) async {
        await controller.softDeleteTransaction(entry.id);
        if (!context.mounted) return false;
        _undo(
          context,
          'Dihapus. Batalkan?',
          () async => controller.restoreTransaction(entry.id),
        );
        return false;
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FinanceListItem(
          icon: iconFor(category?.iconKey ?? 'uncategorized'),
          title: entry.name,
          subtitle:
              '${category?.name ?? 'Tanpa kategori'} · ${formatDate(entry.date)}',
          trailing: AmountText(amount: entry.amount, type: AmountType.expense),
          onTap: () => _showTransactionForm(context, controller, entry: entry),
        ),
      ),
    );
  }
}

class SavingTile extends StatelessWidget {
  const SavingTile({super.key, required this.entry, required this.controller});

  final SavingEntry entry;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final category = controller.categories
        .where((cat) => cat.id == entry.categoryId)
        .firstOrNull;
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: const DeleteBackground(),
      confirmDismiss: (_) async {
        await controller.softDeleteSaving(entry.id);
        if (!context.mounted) return false;
        _undo(
          context,
          'Dihapus. Batalkan?',
          () async => controller.restoreSaving(entry.id),
        );
        return false;
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FinanceListItem(
          icon: iconFor(category?.iconKey ?? 'income'),
          title: entry.name,
          subtitle:
              '${entry.type == SavingType.saving ? 'Tabungan' : 'Pemasukan umum'}'
              '${entry.type == SavingType.saving ? ' · ${category?.name ?? 'Tanpa kategori'}' : ''}'
              ' · ${formatDate(entry.date)}',
          trailing: AmountText(amount: entry.amount, type: AmountType.income),
          onTap: () => _showSavingForm(context, controller, entry: entry),
        ),
      ),
    );
  }
}

enum AmountType { income, expense }

class AmountText extends StatelessWidget {
  const AmountText({super.key, required this.amount, required this.type});

  final int amount;
  final AmountType type;

  @override
  Widget build(BuildContext context) {
    final isIncome = type == AmountType.income;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '${isIncome ? '+' : '-'}${formatIdr(amount)}',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: isIncome ? _incomeColor(context) : _expenseColor(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class SavingProgressCard extends StatelessWidget {
  const SavingProgressCard({
    super.key,
    required this.category,
    required this.controller,
  });

  final Category category;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final progress = controller.calculator.savingProgress(
      category.id,
      controller.savings,
    );
    final target = category.savingTarget ?? 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${((progress / target).clamp(0, 1) * 100).round()}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (progress / target).clamp(0, 1),
              minHeight: 9,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            Text(
              '${formatIdr(progress)} terkumpul dari ${formatIdr(target)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeleteBackground extends StatelessWidget {
  const DeleteBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.red,
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }
}

class SheetTitle extends StatelessWidget {
  const SheetTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class InfoStrip extends StatelessWidget {
  const InfoStrip({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

IconData iconFor(String key) => switch (key) {
  'food' => Icons.restaurant_outlined,
  'transport' => Icons.directions_bus_outlined,
  'emergency' => Icons.health_and_safety_outlined,
  'income' => Icons.payments_outlined,
  'uncategorized' => Icons.help_outline,
  _ => Icons.category_outlined,
};

Color _incomeColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF7DD3A8)
    : const Color(0xFF15803D);

Color _expenseColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFFCA5A5)
    : const Color(0xFFB91C1C);

Future<void> _submit(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
  VoidCallback? afterSuccess,
}) async {
  try {
    await action();
    if (!context.mounted) return;
    if (success != null) _message(context, success);
    afterSuccess?.call();
  } catch (error) {
    if (context.mounted) _message(context, _cleanError(error));
  }
}

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _undo(BuildContext context, String message, VoidCallback onUndo) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(label: 'Batalkan', onPressed: onUndo),
    ),
  );
}

String _cleanError(Object error) =>
    error.toString().replaceFirst('Invalid argument(s): ', '');

void _showCategoryForm(
  BuildContext context,
  AppController controller,
  CategoryType type, {
  Category? category,
}) {
  final name = TextEditingController(text: category?.name);
  final nominal = TextEditingController(
    text:
        (type == CategoryType.expense
                ? category?.monthlyBudget
                : category?.savingTarget)
            ?.toString() ??
        '',
  );
  var iconKey =
      category?.iconKey ??
      (type == CategoryType.expense ? 'food' : 'emergency');
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 4,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(
                title: category == null ? 'Tambah kategori' : 'Edit kategori',
                subtitle: type == CategoryType.expense
                    ? 'Atur kelompok dan budget pengeluaran bulanan.'
                    : 'Atur kelompok dan target tabungan.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama kategori',
                  hintText: 'Contoh: Makan, Transport',
                ),
              ),
              const SizedBox(height: 12),
              DropdownMenu<String>(
                width: MediaQuery.sizeOf(context).width - 32,
                initialSelection: iconKey,
                label: const Text('Ikon'),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'food', label: 'Makan'),
                  DropdownMenuEntry(value: 'transport', label: 'Transport'),
                  DropdownMenuEntry(value: 'emergency', label: 'Dana darurat'),
                  DropdownMenuEntry(value: 'category', label: 'Umum'),
                ],
                onSelected: (value) =>
                    setState(() => iconKey = value ?? iconKey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nominal,
                enabled:
                    type == CategoryType.saving || controller.hasGeneralIncome,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: type == CategoryType.expense
                      ? 'Budget bulanan'
                      : 'Target tabungan',
                  prefixText: 'Rp ',
                  helperText:
                      type == CategoryType.expense &&
                          !controller.hasGeneralIncome
                      ? 'Catat pemasukan umum terlebih dahulu untuk mengaktifkan budget.'
                      : 'Opsional, isi nominal tanpa titik atau koma.',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () async {
                  try {
                    await controller.saveCategory(
                      id: category?.id,
                      type: type,
                      name: name.text,
                      iconKey: iconKey,
                      monthlyBudget: type == CategoryType.expense
                          ? int.tryParse(nominal.text)
                          : null,
                      savingTarget: type == CategoryType.saving
                          ? int.tryParse(nominal.text)
                          : null,
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (error) {
                    if (context.mounted) _message(context, _cleanError(error));
                  }
                },
                child: const Text('Simpan kategori'),
              ),
              if (category != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await controller.softDeleteCategory(category.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Hapus kategori'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

void _showTransactionForm(
  BuildContext context,
  AppController controller, {
  TransactionEntry? entry,
}) {
  final name = TextEditingController(text: entry?.name);
  final amount = TextEditingController(text: entry?.amount.toString() ?? '');
  final note = TextEditingController(text: entry?.note);
  var categoryId = entry?.categoryId ?? controller.expenseCategories.first.id;
  var date = entry?.date ?? DateTime.now();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final category = controller.expenseCategories.firstWhere(
          (cat) => cat.id == categoryId,
        );
        final spent = controller.calculator.categorySpending(
          category.id,
          controller.transactions,
          date,
        );
        final remaining = (category.monthlyBudget ?? 0) - spent;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 4,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetTitle(
                  title: entry == null ? 'Tambah transaksi' : 'Edit transaksi',
                  subtitle:
                      'Catat pengeluaran dan pantau sisa budget kategori.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nama transaksi',
                    hintText: 'Contoh: Makan siang',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nominal',
                    prefixText: 'Rp ',
                    helperText: 'Isi angka tanpa titik atau koma.',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownMenu<String>(
                  width: MediaQuery.sizeOf(context).width - 32,
                  initialSelection: categoryId,
                  label: const Text('Kategori'),
                  dropdownMenuEntries: controller.expenseCategories
                      .map(
                        (cat) =>
                            DropdownMenuEntry(value: cat.id, label: cat.name),
                      )
                      .toList(),
                  onSelected: (value) =>
                      setState(() => categoryId = value ?? categoryId),
                ),
                const SizedBox(height: 12),
                InfoStrip(
                  icon: Icons.flag_outlined,
                  text: 'Sisa budget bulan ini: ${formatIdr(remaining)}',
                  color: remaining >= 0
                      ? _incomeColor(context)
                      : _expenseColor(context),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: date,
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                  icon: const Icon(Icons.event),
                  label: Text(formatDate(date)),
                ),
                TextField(
                  controller: note,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    hintText: 'Opsional',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () async {
                    try {
                      await controller.saveTransaction(
                        id: entry?.id,
                        name: name.text,
                        amount: int.parse(amount.text),
                        categoryId: categoryId,
                        date: date,
                        note: note.text,
                      );
                      final warning = controller.lastWarning;
                      controller.lastWarning = null;
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (warning != null) _message(context, warning);
                      }
                    } catch (error) {
                      if (context.mounted) {
                        _message(context, _cleanError(error));
                      }
                    }
                  },
                  child: const Text('Simpan transaksi'),
                ),
                if (entry != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await controller.softDeleteTransaction(entry.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Hapus transaksi'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

void _showSavingForm(
  BuildContext context,
  AppController controller, {
  SavingEntry? entry,
  SavingType? initialType,
}) {
  final name = TextEditingController(text: entry?.name);
  final amount = TextEditingController(text: entry?.amount.toString() ?? '');
  final note = TextEditingController(text: entry?.note);
  var type = entry?.type ?? initialType ?? SavingType.generalIncome;
  var categoryId =
      entry?.categoryId ?? controller.savingCategories.firstOrNull?.id;
  var date = entry?.date ?? DateTime.now();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 4,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(
                title: entry == null ? 'Tambah pemasukan' : 'Edit pemasukan',
                subtitle:
                    'Catat pemasukan umum atau setoran ke target tabungan.',
              ),
              const SizedBox(height: 16),
              SegmentedButton<SavingType>(
                segments: const [
                  ButtonSegment(
                    value: SavingType.generalIncome,
                    label: Text('Pemasukan umum'),
                  ),
                  ButtonSegment(
                    value: SavingType.saving,
                    label: Text('Tabungan'),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (value) => setState(() {
                  type = value.first;
                  categoryId ??= controller.savingCategories.firstOrNull?.id;
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Nama catatan',
                  hintText: 'Contoh: Gaji, Dana darurat',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                  helperText: 'Isi angka tanpa titik atau koma.',
                ),
              ),
              if (type == SavingType.saving) ...[
                const SizedBox(height: 12),
                DropdownMenu<String>(
                  width: MediaQuery.sizeOf(context).width - 32,
                  initialSelection: categoryId,
                  label: const Text('Kategori tabungan'),
                  dropdownMenuEntries: controller.savingCategories
                      .map(
                        (cat) =>
                            DropdownMenuEntry(value: cat.id, label: cat.name),
                      )
                      .toList(),
                  onSelected: (value) => setState(() => categoryId = value),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDate: date,
                  );
                  if (picked != null) setState(() => date = picked);
                },
                icon: const Icon(Icons.event),
                label: Text(formatDate(date)),
              ),
              TextField(
                controller: note,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  hintText: 'Opsional',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () async {
                  try {
                    await controller.saveSaving(
                      id: entry?.id,
                      type: type,
                      name: name.text,
                      amount: int.parse(amount.text),
                      categoryId: categoryId,
                      date: date,
                      note: note.text,
                    );
                    final warning = controller.lastWarning;
                    controller.lastWarning = null;
                    if (context.mounted) {
                      Navigator.pop(context);
                      if (warning != null) _message(context, warning);
                    }
                  } catch (error) {
                    if (context.mounted) _message(context, _cleanError(error));
                  }
                },
                child: const Text('Simpan catatan'),
              ),
              if (entry != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await controller.softDeleteSaving(entry.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Hapus catatan'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
