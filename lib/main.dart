import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'services/player_handler.dart';
import 'providers/player_provider.dart';
import 'theme/app_theme.dart';
import 'screens/library_screen.dart';
import 'screens/lyrics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/now_playing_screen.dart';
import 'widgets/mini_player.dart';

late final QPlayerHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  audioHandler = await AudioService.init(
    builder: () => QPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.qplayer.music.audio',
      androidNotificationChannelName: 'QPlayer',
      androidNotificationOngoing: true,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlayerProvider(audioHandler)..loadLibrary(),
      child: MaterialApp(
        title: 'QPlayer',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const HomePage(),
      ),
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
  final List<Widget> _screens = const [
    LibraryScreen(),
    LyricsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final audioHandler =
        Provider.of<PlayerProvider>(context, listen: false).audioHandler;
    return Scaffold(
      appBar: AppBar(title: const Text('QPlayer')),
      body: Column(
        children: [
          Expanded(child: _screens[_tab]),
          MiniPlayer(
            audioHandler: audioHandler,
            onOpen: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NowPlayingScreen())),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.library_music), label: '资料库'),
          NavigationDestination(icon: Icon(Icons.lyrics), label: '歌词'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
