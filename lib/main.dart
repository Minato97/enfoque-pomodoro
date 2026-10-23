import 'package:flutter/material.dart';

import 'ads.dart';
import 'settings_page.dart';
import 'stats_page.dart';
import 'store.dart';
import 'timer_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.instance.load();
  AdService.instance.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFEF4444);
    return MaterialApp(
      title: 'Enfoque Pomodoro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  static const _titles = ['Temporizador', 'Estadísticas', 'Ajustes'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_tab])),
      body: ListenableBuilder(
        listenable: AppStore.instance,
        builder: (context, _) => IndexedStack(
          index: _tab,
          children: const [TimerPage(), StatsPage(), SettingsPage()],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.timer), label: 'Enfoque'),
              NavigationDestination(
                icon: Icon(Icons.bar_chart),
                label: 'Estadísticas',
              ),
              NavigationDestination(icon: Icon(Icons.tune), label: 'Ajustes'),
            ],
          ),
        ],
      ),
    );
  }
}
