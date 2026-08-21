import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'pages/calendar_page.dart';
import 'pages/ranking_page.dart';

void main() {
  runApp(const MyApp());
}

// ======================================================
// アプリ本体
// ======================================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '歌枠データベース',

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F0FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8061A8),
        ),
        cardColor: Colors.white,
        fontFamily: GoogleFonts.delaGothicOne().fontFamily,
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF18141D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9B72B5),
          brightness: Brightness.dark,
        ),
        cardColor: const Color(0xFF292230),
        fontFamily: GoogleFonts.delaGothicOne().fontFamily,

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Color(0xFFD8D0DC)),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF18141D),
          foregroundColor: Colors.white,
        ),

        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF292230),
          hintStyle: TextStyle(
            color: Color(0xFFC5B8CC),
          ),
        ),

        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF211B26),
          indicatorColor: Color(0xFF493556),
        ),

        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF9B72B5),
          foregroundColor: Colors.white,
        ),
      ),

      themeMode:
          isDarkMode ? ThemeMode.dark : ThemeMode.light,

      home: MainPage(
        isDarkMode: isDarkMode,
        onDarkModeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
    );
  }
}

// ======================================================
// メインページ
// ======================================================

class MainPage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const MainPage({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;

  List<List<String>> rows = [];

  bool isLoading = true;
  String errorMessage = '';

  Set<String> favorites = {};

  final String sheetUrl =
      'https://docs.google.com/spreadsheets/d/'
      '1vTK-QLcpU0Pfpd4IjKn91WE8dSgNMk8_radHWA_yUno'
      '/gviz/tq?tqx=out:csv&sheet=シート1';

  @override
  void initState() {
    super.initState();
    loadFavorites();
    loadSheet();
  }

  // ====================================================
  // お気に入り読み込み
  // ====================================================

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getStringList('favorites');

    if (saved != null) {
      setState(() {
        favorites = saved.toSet();
      });
    }
  }

  // ====================================================
  // お気に入り切り替え
  // ====================================================

  Future<void> toggleFavorite(String songName) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (favorites.contains(songName)) {
        favorites.remove(songName);
      } else {
        favorites.add(songName);
      }
    });

    await prefs.setStringList(
      'favorites',
      favorites.toList(),
    );
  }

  // ====================================================
  // スプレッドシート読み込み
  // ====================================================

  Future<void> loadSheet() async {
    try {
      final response = await http.get(
        Uri.parse(sheetUrl),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'スプレッドシートを読み込めませんでした',
        );
      }

      final text = utf8.decode(
        response.bodyBytes,
      );

      final parsedRows = parseCsv(text);

debugPrint('📊 CSV行数: ${parsedRows.length}');

for (final row in parsedRows) {
  if (row.length > 4 &&
      row[4].contains('833800903')) {
    debugPrint('🎯 833800903の行: $row');
    debugPrint('🎯 列数: ${row.length}');
    debugPrint('🎯 I列: ${row.length > 8 ? row[8] : 'なし'}');
  }
}

setState(() {
  rows = parsedRows;
  isLoading = false;
});
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ====================================================
  // CSV解析
  // ====================================================

  List<List<String>> parseCsv(String text) {
    final result = <List<String>>[];

    List<String> currentRow = [];
    final currentCell = StringBuffer();

    bool insideQuotes = false;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (char == '"') {
        if (insideQuotes &&
            i + 1 < text.length &&
            text[i + 1] == '"') {
          currentCell.write('"');
          i++;
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (char == ',' && !insideQuotes) {
        currentRow.add(
          currentCell.toString(),
        );
        currentCell.clear();
      } else if (
          (char == '\n' || char == '\r') &&
          !insideQuotes) {
        if (char == '\r' &&
            i + 1 < text.length &&
            text[i + 1] == '\n') {
          i++;
        }

        currentRow.add(
          currentCell.toString(),
        );
        currentCell.clear();

        if (currentRow.isNotEmpty) {
          result.add(
            List<String>.from(currentRow),
          );
        }

        currentRow = [];
      } else {
        currentCell.write(char);
      }
    }

    if (currentCell.isNotEmpty ||
        currentRow.isNotEmpty) {
      currentRow.add(
        currentCell.toString(),
      );

      result.add(
        List<String>.from(currentRow),
      );
    }

    return result;
  }

  // ====================================================
  // URLを開く
  // ====================================================

  Future<void> openUrl(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);

    if (uri != null) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ====================================================
  // 各列
  // ====================================================

  String getSongName(List<String> row) {
    return row.isNotEmpty ? row[0].trim() : '';
  }

  String getDate(List<String> row) {
    return row.length > 2 ? row[2].trim() : '';
  }

  String getStreamTitle(List<String> row) {
    return row.length > 3 ? row[3].trim() : '';
  }

  String getStreamUrl(List<String> row) {
    return row.length > 4 ? row[4].trim() : '';
  }

 String getThumbnailUrl(List<String> row) {
    final url = row.length > 8 ? row[8].trim() : '';

    debugPrint('🖼️ サムネイルURL: $url');

    return url;
  }

  // ====================================================
  // 曲数カウント
  // ====================================================

  Map<String, int> getSongCounts() {
    final counts = <String, int>{};

    if (rows.length <= 1) {
      return counts;
    }

    for (final row in rows.skip(1)) {
      final song = getSongName(row);

      if (song.isEmpty) continue;

      counts[song] =
          (counts[song] ?? 0) + 1;
    }

    return counts;
  }

  // ====================================================
  // 最新の歌枠
  // ★ 同じ配信は1件だけ
  // ====================================================

 List<String>? get latestStream {
  if (rows.length <= 1) {
    return null;
  }

  final data = rows.skip(1).toList();

  // まず、一番新しい配信URLを探す
  String latestUrl = '';

  for (final row in data.reversed) {
    final url = getStreamUrl(row);

    if (url.isNotEmpty) {
      latestUrl = url;
      break;
    }
  }

  if (latestUrl.isEmpty) {
    return null;
  }

  // 同じ配信URLの中から
  // サムネイルが入っている行を探す
  for (final row in data.reversed) {
    final url = getStreamUrl(row);

    if (url != latestUrl) {
      continue;
    }

    final thumbnail = getThumbnailUrl(row);

    if (thumbnail.isNotEmpty) {
      return row;
    }
  }

  // サムネイルが見つからなかった場合は
  // 最新の配信URLの行を返す
  for (final row in data.reversed) {
    final url = getStreamUrl(row);

    if (url == latestUrl) {
      return row;
    }
  }

  return null;
}

  // ====================================================
  // TOPページ
  // ====================================================

  Widget buildTopPage() {
    final counts = getSongCounts();

    final ranking = counts.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    final latest = latestStream;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final mainTextColor = isDark
        ? Colors.white
        : const Color(0xFF654680);

    final subTextColor = isDark
        ? const Color(0xFFD8D0DC)
        : const Color(0xFF887494);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          40,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // =================================================
            // タイトル
            // =================================================

            Center(
              child: Text(
                '歌枠データベース',
                style: GoogleFonts.mochiyPopOne(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: mainTextColor,
                ),
              ),
            ),

            const SizedBox(height: 5),

            Center(
              child: Text(
                'るかわさんの歌枠をまとめています 🎧',
                style: GoogleFonts.zenMaruGothic(
                  fontSize: 15,
                  color: subTextColor,
                ),
              ),
            ),

            const SizedBox(height: 22),

// =================================================
// 登録曲数・総歌唱回数
// =================================================

Row(
  children: [
    Expanded(
      child: _TopInfoCard(
        icon: Icons.music_note,
        title: '登録曲数',
        value: '${counts.length}曲',
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: _TopInfoCard(
        icon: Icons.mic,
        title: '総歌唱回数',
        value: '${rows.length > 1 ? rows.length - 1 : 0}回',
      ),
    ),
  ],
),

const SizedBox(height: 28),

// =================================================
// このサイトでできること
// =================================================

const _SectionTitle(
  icon: Icons.music_note,
  title: 'このサイトでできること',
),

            const SizedBox(height: 10),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3,
              children:  [

                _FeatureCard(
  icon: Icons.search,
  title: '曲をさがす',
  description: '曲名から検索',
  onTap: () {
    setState(() {
      selectedIndex = 1;
    });
  },
),

_FeatureCard(
  icon: Icons.calendar_month,
  title: '日付からさがす',
  description: '配信日から検索',
  onTap: () {
    setState(() {
      selectedIndex = 2;
    });
  },
),

_FeatureCard(
  icon: Icons.play_circle_outline,
  title: '歌を聴く',
  description: 'ワンクリック再生',
  onTap: () {
    setState(() {
      selectedIndex = 1;
    });
  },
),

_FeatureCard(
  icon: Icons.star_outline,
  title: 'お気に入り登録',
  description: '気になる曲を保存',
  onTap: () {
    setState(() {
      selectedIndex = 3;
    });
  },
),

// ★ ここでGridViewを閉じる
              ],
            ),

            const SizedBox(height: 28),

            // =================================================
            // 最新の歌枠
            // =================================================

            const _SectionTitle(
              icon: Icons.play_circle_outline,
              title: '最新の歌枠',
            ),

            const SizedBox(height: 12),

            if (latest != null)
              _LatestStreamCard(
                title: getStreamTitle(latest),
                date: getDate(latest),
                url: getStreamUrl(latest),
                thumbnailUrl:
                    getThumbnailUrl(latest),
                onOpen: openUrl,
              )
            else
              Text(
                '最新の歌枠がありません',
                style: TextStyle(
                  color: subTextColor,
                ),
              ),

            const SizedBox(height: 28),

            // =================================================
            // よく歌われる曲
            // =================================================

            const _SectionTitle(
              icon: Icons.bar_chart_rounded,
              title: 'よく歌われる曲',
            ),

            const SizedBox(height: 12),

            ...ranking
                .take(5)
                .toList()
                .asMap()
                .entries
                .map(
              (entry) {
                final index = entry.key;
                final item = entry.value;

                return _RankingCard(
                  rank: index + 1,
                  song: item.key,
                  count: item.value,
                  maxCount:
                      ranking.isNotEmpty
                          ? ranking.first.value
                          : 1,
                );
              },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    // ★ランキングは5番目
                    selectedIndex = 4;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? const Color(0xFFEBDDF2)
                      : const Color(0xFF8061A8),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF604B69)
                        : const Color(0xFFD5C4E4),
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'ランキングをすべて見る',
                  style: GoogleFonts.zenMaruGothic(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // =================================================
            // 公式リンク
            // =================================================

            const _SectionTitle(
              icon: Icons.link,
              title: '公式リンク',
            ),

            const SizedBox(height: 12),

            _LinkButton(
              icon: Icons.alternate_email,
              title: 'X（旧Twitter）',
              subtitle: '@rukawagod',
              url: 'https://x.com/rukawagod',
              onOpen: openUrl,
            ),

            const SizedBox(height: 10),

            _LinkButton(
              icon: Icons.live_tv,
              title: 'ツイキャス',
              subtitle: 'るかわさんの配信ページ',
              url:
                  'https://twitcasting.tv/rukawagod',
              onOpen: openUrl,
            ),

            const SizedBox(height: 30),

            // =================================================
            // このサイトについて
            // =================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF292230)
                    : const Color(0xFFEDE4F5),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    'このサイトについて',
                    style:
                        GoogleFonts.zenMaruGothic(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFEBDDF2)
                          : const Color(0xFF654680),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '当サイトは、るかわさんの歌枠をまとめた非公式データベースです。',
                    style:
                        GoogleFonts.zenMaruGothic(
                      fontSize: 12,
                      height: 1.7,
                      color:
                          isDark
                              ? Colors.white
                              : null,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '※当サイトはるかわさんご本人、及びるかわさんに関わりのある活動者の皆様とは一切関係がなく、完全非公式の歌枠まとめサイトとなっております。\n\n掲載内容は予告なく更新・削除する場合がございます。当サイトの利用によって生じたいかなるトラブル・損失・損害に対して、一切責任を負いかねますのでご了承ください。',
                    style:
                        GoogleFonts.zenMaruGothic(
                      fontSize: 10.5,
                      height: 1.7,
                      color: isDark
                          ? const Color(0xFFD8D0DC)
                          : const Color(0xFF887494),
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

  // ====================================================
  // 曲一覧
  // ====================================================

  Widget buildSongsPage() {
    return SongsPage(
      rows: rows,
      favorites: favorites,
      onToggleFavorite: toggleFavorite,
      onOpenUrl: openUrl,
    );
  }

  // ====================================================
  // build
  // ====================================================

  @override
  Widget build(BuildContext context) {

    final pages = <Widget>[
      buildTopPage(),

      buildSongsPage(),

      // ★ 日付検索は残す
      CalendarPage(
        rows: rows,
        onOpenUrl: openUrl,
      ),

      FavoritesPage(
        rows: rows,
        favorites: favorites,
        onToggleFavorite: toggleFavorite,
        onOpenUrl: openUrl,
      ),

      RankingPage(
        rows: rows,
        onOpenUrl: openUrl,
      ),
    ];

    return Scaffold(
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF9B72B5),
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(20),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : pages[selectedIndex],

      // ==================================================
      // ★ 下のメニューは5個
      // ==================================================

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        indicatorColor:
            Theme.of(context).brightness ==
                    Brightness.dark
                ? const Color(0xFF493556)
                : const Color(0xFFE4D5EC),

        destinations: const [

          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'TOP',
          ),

          NavigationDestination(
            icon:
                Icon(Icons.music_note_outlined),
            selectedIcon:
                Icon(Icons.music_note),
            label: '曲一覧',
          ),

          NavigationDestination(
            icon:
                Icon(Icons.calendar_month_outlined),
            selectedIcon:
                Icon(Icons.calendar_month),
            label: '日付検索',
          ),

          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'お気に入り',
          ),

          NavigationDestination(
            icon:
                Icon(Icons.bar_chart_outlined),
            selectedIcon:
                Icon(Icons.bar_chart),
            label: 'ランキング',
          ),
        ],
      ),

      // ==================================================
      // ダークモードボタン
      // ==================================================

      floatingActionButton:
          selectedIndex != 0
              ? FloatingActionButton.small(
                  onPressed: () {
                    widget.onDarkModeChanged(
                      !widget.isDarkMode,
                    );
                  },
                  backgroundColor:
                      const Color(0xFF9B72B5),
                  foregroundColor: Colors.white,
                  child: Icon(
                    widget.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                )
              : null,
    );
  }
}

// ======================================================
// このサイトでできることカード
// ======================================================

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF493B50)
                  : const Color(0xFFE3D5EC),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF493556)
                      : const Color(0xFFEDE4F5),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  color: isDark
                      ? const Color(0xFFEBDDF2)
                      : const Color(0xFF8061A8),
                  size: 17,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.zenMaruGothic(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF654680),
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 1),

                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.zenMaruGothic(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFFD8D0DC)
                            : const Color(0xFF887494),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// セクションタイトル
// ======================================================

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Row(
      children: [

        Icon(
          icon,
          color: isDark
              ? const Color(0xFFC7A9D8)
              : const Color(0xFF8061A8),
          size: 23,
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style: GoogleFonts.zenMaruGothic(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: isDark
                ? const Color(0xFFF0E7F7)
                : const Color(0xFF654680),
          ),
        ),
      ],
    );
  }
}

// ======================================================
// 最新の歌枠カード
// ======================================================

class _LatestStreamCard
    extends StatelessWidget {

  final String title;
  final String date;
  final String url;
  final String thumbnailUrl;

  final Future<void> Function(String url)
      onOpen;

  const _LatestStreamCard({
    required this.title,
    required this.date,
    required this.url,
    required this.thumbnailUrl,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return InkWell(
      onTap: url.isEmpty
          ? null
          : () => onOpen(url),

      borderRadius:
          BorderRadius.circular(20),

      child: Container(
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? const Color(0xFF493B50)
                : const Color(0xFFE3D5EC),
          ),
        ),
        clipBehavior: Clip.antiAlias,

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

           Container(
  height: 55,
  width: double.infinity,
  color: isDark
      ? const Color(0xFF292230)
      : const Color(0xFFEDE4F5),
  child: Center(
    child: Icon(
      Icons.play_circle_outline,
      size: 38,
      color: isDark
          ? const Color(0xFFC7A9D8)
          : const Color(0xFF8061A8),
    ),
  ),
),

            Padding(
              padding:
                  const EdgeInsets.all(16),

              child: Row(
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        Text(
                          title.isEmpty
                              ? 'クリックで最新の歌枠配信に飛べます'
                              : title,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              GoogleFonts
                                  .zenMaruGothic(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(
                                    0xFF654680,
                                  ),
                          ),
                        ),

                        if (date.isNotEmpty) ...[
                          const SizedBox(height: 5),

                          Text(
                            date,
                            style:
                                GoogleFonts
                                    .zenMaruGothic(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(
                                      0xFFD8D0DC,
                                    )
                                  : const Color(
                                      0xFF887494,
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF493556)
                          : const Color(0xFFEDE4F5),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.open_in_new,
                      size: 19,
                      color: isDark
                          ? const Color(0xFFEBDDF2)
                          : const Color(0xFF8061A8),
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

// ======================================================
// サムネイルなし
// ======================================================

class _ThumbnailPlaceholder
    extends StatelessWidget {

  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      color: isDark
          ? const Color(0xFF292230)
          : const Color(0xFFEDE4F5),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 55,
          color: isDark
              ? const Color(0xFFC7A9D8)
              : const Color(0xFF8061A8),
        ),
      ),
    );
  }
}

// ======================================================
// ランキングカード
// ======================================================

class _RankingCard
    extends StatelessWidget {

  final int rank;
  final String song;
  final int count;
  final int maxCount;

  const _RankingCard({
    required this.rank,
    required this.song,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final progress =
        maxCount <= 0
            ? 0.0
            : count / maxCount;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF493B50)
              : const Color(0xFFE3D5EC),
        ),
      ),
      child: Row(
        children: [

          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color:
                  rank == 1
                      ? const Color(0xFF8061A8)
                      : rank == 2
                          ? const Color(
                              0xFF9B72B5,
                            )
                          : rank == 3
                              ? const Color(
                                  0xFFB99AC9,
                                )
                              : isDark
                                  ? const Color(
                                      0xFF493556,
                                    )
                                  : const Color(
                                      0xFFEDE4F5,
                                    ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                rank
                    .toString()
                    .padLeft(2, '0'),
                style:
                    GoogleFonts.zenMaruGothic(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                  color: rank <= 3
                      ? Colors.white
                      : isDark
                          ? const Color(
                              0xFFEBDDF2,
                            )
                          : const Color(
                              0xFF8061A8,
                            ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  song,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      GoogleFonts
                          .zenMaruGothic(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color: isDark
                        ? Colors.white
                        : const Color(
                            0xFF654680,
                          ),
                  ),
                ),

                const SizedBox(height: 9),

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),
                  child:
                      LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor:
                        isDark
                            ? const Color(
                                0xFF403443,
                              )
                            : const Color(
                                0xFFEDE4F5,
                              ),
                    valueColor:
                        const AlwaysStoppedAnimation<
                            Color>(
                      Color(0xFF9B72B5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Text(
            '${count}回',
            style:
                GoogleFonts.zenMaruGothic(
              fontSize: 13,
              fontWeight:
                  FontWeight.bold,
              color: isDark
                  ? const Color(0xFFEBDDF2)
                  : const Color(0xFF8061A8),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// X・ツイキャス
// ======================================================

class _LinkButton
    extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final String url;

  final Future<void> Function(String url)
      onOpen;

  const _LinkButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return InkWell(
      onTap: () => onOpen(url),
      borderRadius:
          BorderRadius.circular(18),

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? const Color(0xFF493B50)
                : const Color(0xFFE3D5EC),
          ),
        ),

        child: Row(
          children: [

            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF493556)
                    : const Color(0xFFEDE4F5),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isDark
                    ? const Color(0xFFEBDDF2)
                    : const Color(0xFF8061A8),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style:
                        GoogleFonts
                            .zenMaruGothic(
                      fontWeight:
                          FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : const Color(
                              0xFF654680,
                            ),
                    ),
                  ),

                  Text(
                    subtitle,
                    style:
                        GoogleFonts
                            .zenMaruGothic(
                      fontSize: 11,
                      color: isDark
                          ? const Color(
                              0xFFD8D0DC,
                            )
                          : const Color(
                              0xFF887494,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.open_in_new,
              color: isDark
                  ? const Color(0xFFEBDDF2)
                  : const Color(0xFF8061A8),
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// 曲一覧
// ======================================================

class SongsPage extends StatefulWidget {
  final List<List<String>> rows;
  final Set<String> favorites;

  final Future<void> Function(String songName)
      onToggleFavorite;

  final Future<void> Function(String url)
      onOpenUrl;

  const SongsPage({
    super.key,
    required this.rows,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onOpenUrl,
  });

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  final TextEditingController searchController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      setState(() {});
    });
  }

  // ====================================================
  // 曲名
  // A列：画面に表示する名前
  // ====================================================

  String songName(List<String> row) {
    return row.isNotEmpty ? row[0].trim() : '';
  }

  // ====================================================
  // 検索用よみがな
  // B列：検索にだけ使用
  // ※画面には表示しない
  // ====================================================

  String songReading(List<String> row) {
    return row.length > 1 ? row[1].trim() : '';
  }

  String date(List<String> row) {
    return row.length > 2 ? row[2].trim() : '';
  }

  String streamTitle(List<String> row) {
    return row.length > 3 ? row[3].trim() : '';
  }

  String streamUrl(List<String> row) {
    return row.length > 4 ? row[4].trim() : '';
  }

  String timestamp(List<String> row) {
    return row.length > 5 ? row[5].trim() : '';
  }

  String playUrl(List<String> row) {
    return row.length > 7 ? row[7].trim() : '';
  }

  // ====================================================
  // 曲詳細
  // ====================================================

  void showDetail(List<String> row) {
    final song = songName(row);
    bool isFavorite = widget.favorites.contains(song);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        final isDark =
            Theme.of(context).brightness ==
                Brightness.dark;

        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF493556)
                          : const Color(0xFFE8DDF2),
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: isDark
                          ? const Color(0xFFEBDDF2)
                          : const Color(0xFF76539B),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      song,
                      style:
                          GoogleFonts.zenMaruGothic(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF76539B),
                      ),
                    ),
                  ),

  IconButton(
  onPressed: () async {
    await widget.onToggleFavorite(song);

    if (mounted) {
      setState(() {});
    }
  },
  icon: Icon(
    widget.favorites.contains(song)
        ? Icons.star
        : Icons.star_border,
    color: widget.favorites.contains(song)
        ? Colors.amber
        : (isDark
            ? const Color(0xFFB9A8C4)
            : const Color(0xFF9B72B5)),
    size: 30,
  ),
),
                ],
              ),

              const SizedBox(height: 24),

              if (date(row).isNotEmpty)
                _InfoRow(
                  icon: Icons.calendar_month,
                  text: date(row),
                ),

              if (streamTitle(row).isNotEmpty)
                _InfoRow(
                  icon: Icons.live_tv,
                  text: streamTitle(row),
                ),

              if (timestamp(row).isNotEmpty)
                _InfoRow(
                  icon: Icons.access_time,
                  text: timestamp(row),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      playUrl(row).isEmpty
                          ? null
                          : () => widget.onOpenUrl(
                                playUrl(row),
                              ),
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    'この曲を聴く',
                    style:
                        GoogleFonts.zenMaruGothic(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF9B72B5),
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              if (streamUrl(row).isNotEmpty) ...[
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        widget.onOpenUrl(
                      streamUrl(row),
                    ),
                    icon: const Icon(
                      Icons.open_in_new,
                    ),
                    label: Text(
                      '配信を見る',
                      style:
                          GoogleFonts
                              .zenMaruGothic(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? const Color(0xFFEBDDF2)
                          : const Color(0xFF76539B),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ====================================================
  // 曲一覧画面
  // ====================================================

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    // 検索文字
    final searchText =
        searchController.text
            .trim()
            .toLowerCase();

    // ==================================================
    // 検索
    //
    // A列「曲名」
    // B列「ひらがな」
    //
    // どちらでも検索できる
    // ==================================================

    final data =
        widget.rows.length <= 1
            ? <List<String>>[]
            : widget.rows
                .skip(1)
                .where(
                  (row) {
                    final song =
                        songName(row)
                            .toLowerCase();

                    final reading =
                        songReading(row)
                            .toLowerCase();

                    return song.contains(
                          searchText,
                        ) ||
                        reading.contains(
                          searchText,
                        );
                  },
                )
                .toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              10,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '曲をさがす',
                  style:
                      GoogleFonts.zenMaruGothic(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF654680),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller:
                      searchController,

                  style:
                      GoogleFonts.zenMaruGothic(
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF654680),
                  ),

                  decoration:
                      InputDecoration(
                    hintText:
                        '曲名を検索する',

                    hintStyle:
                        GoogleFonts
                            .zenMaruGothic(
                      color: isDark
                          ? const Color(0xFFC5B8CC)
                          : const Color(0xFF887494),
                    ),

                    prefixIcon:
                        const Icon(
                      Icons.search,
                      color:
                          Color(0xFF9B72B5),
                    ),

                    suffixIcon:
                        searchText.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  searchController
                                      .clear();
                                },
                                icon:
                                    const Icon(
                                  Icons.close,
                                ),
                              )
                            : null,

                    filled: true,

                    fillColor:
                        Theme.of(context)
                            .cardColor,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFF9B72B5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child:
                data.isEmpty
                    ? Center(
                        child: Text(
                          '曲が見つかりませんでした',
                          style:
                              GoogleFonts
                                  .zenMaruGothic(
                            color: isDark
                                ? Colors.white
                                : const Color(
                                    0xFF654680,
                                  ),
                          ),
                        ),
                      )
                    : Scrollbar(
                        controller:
                            scrollController,
                        thumbVisibility:
                            true,
                        trackVisibility:
                            true,
                        interactive: true,
                        child:
                            ListView.builder(
                          controller:
                              scrollController,

                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            18,
                            8,
                            18,
                            24,
                          ),

                          itemCount:
                              data.length,

                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            final row =
                                data[index];

                            // ★ 表示するのはA列だけ
                            final song =
                                songName(row);

                            final favorite =
                                widget.favorites
                                    .contains(
                                  song,
                                );

                            return Container(
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom: 10,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    Theme.of(
                                  context,
                                ).cardColor,

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  18,
                                ),
                              ),

                              child:
                                  ListTile(
                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),

                                leading:
                                    Container(
                                  width: 44,
                                  height: 44,
                                  decoration:
                                      BoxDecoration(
                                    color: isDark
                                        ? const Color(
                                            0xFF493556,
                                          )
                                        : const Color(
                                            0xFFE9DDF1,
                                          ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      14,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons
                                        .music_note_rounded,
                                    color: isDark
                                        ? const Color(
                                            0xFFEBDDF2,
                                          )
                                        : const Color(
                                            0xFF8061A8,
                                          ),
                                  ),
                                ),

                                // ★ 画面には曲名だけ
                                // ★ B列のひらがなは表示しない
                                title:
                                    Text(
                                  song,
                                  style:
                                      GoogleFonts
                                          .zenMaruGothic(
                                    fontWeight:
                                        FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(
                                            0xFF654680,
                                          ),
                                  ),
                                ),

                                trailing:
                                    IconButton(
                                  onPressed:
                                      () async {
                                    await widget
                                        .onToggleFavorite(
                                      song,
                                    );

                                    setState(
                                      () {},
                                    );
                                  },

                                  icon: Icon(
                                    favorite
                                        ? Icons.star
                                        : Icons
                                            .star_border,
                                    color:
                                        favorite
                                            ? Colors
                                                .amber
                                            : null,
                                  ),
                                ),

                                onTap:
                                    () =>
                                        showDetail(
                                  row,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();

    super.dispose();
  }
}

// ======================================================
// お気に入りページ
// ======================================================

class FavoritesPage
    extends StatefulWidget {

  final List<List<String>> rows;
  final Set<String> favorites;

  final Future<void> Function(
    String songName,
  ) onToggleFavorite;

  final Future<void> Function(
    String url,
  ) onOpenUrl;

  const FavoritesPage({
    super.key,
    required this.rows,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onOpenUrl,
  });

  @override
  State<FavoritesPage> createState() =>
      _FavoritesPageState();
}

class _FavoritesPageState
    extends State<FavoritesPage> {

  String songName(List<String> row) {
    return row.isNotEmpty
        ? row[0].trim()
        : '';
  }

  String date(List<String> row) {
    return row.length > 2
        ? row[2].trim()
        : '';
  }

  String streamTitle(List<String> row) {
    return row.length > 3
        ? row[3].trim()
        : '';
  }

  String streamUrl(List<String> row) {
    return row.length > 4
        ? row[4].trim()
        : '';
  }

  String timestamp(List<String> row) {
    return row.length > 5
        ? row[5].trim()
        : '';
  }

  String playUrl(List<String> row) {
    return row.length > 7
        ? row[7].trim()
        : '';
  }

  void showDetail(List<String> row) {
  final song = songName(row);
  bool isFavorite = widget.favorites.contains(song);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),

      builder: (context) {
        final isDark =
            Theme.of(context).brightness ==
                Brightness.dark;

        return Padding(
          padding:
              const EdgeInsets.all(28),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Row(
                children: [

                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      color: isDark
                          ? const Color(
                              0xFF493556,
                            )
                          : const Color(
                              0xFFE8DDF2,
                            ),
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: isDark
                          ? const Color(
                              0xFFEBDDF2,
                            )
                          : const Color(
                              0xFF76539B,
                            ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      song,
                      style:
                          GoogleFonts
                              .zenMaruGothic(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(
                                0xFF76539B,
                              ),
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () async {
                      await widget
                          .onToggleFavorite(
                        song,
                      );

                      setState(() {});
                    },

                    icon: Icon(
                      widget.favorites
                              .contains(song)
                          ? Icons.star
                          : Icons.star_border,
                      color: widget.favorites
                              .contains(song)
                          ? Colors.amber
                          : null,
                      size: 30,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (date(row).isNotEmpty)
                _InfoRow(
                  icon:
                      Icons.calendar_month,
                  text: date(row),
                ),

              if (streamTitle(row).isNotEmpty)
                _InfoRow(
                  icon: Icons.live_tv,
                  text: streamTitle(row),
                ),

              if (timestamp(row).isNotEmpty)
                _InfoRow(
                  icon: Icons.access_time,
                  text: timestamp(row),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      playUrl(row).isEmpty
                          ? null
                          : () =>
                              widget.onOpenUrl(
                            playUrl(row),
                          ),
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    'この曲を聴く',
                    style:
                        GoogleFonts
                            .zenMaruGothic(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF9B72B5,
                    ),
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 16,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                ),
              ),

              if (streamUrl(row).isNotEmpty) ...[
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child:
                      OutlinedButton.icon(
                    onPressed: () =>
                        widget.onOpenUrl(
                      streamUrl(row),
                    ),
                    icon: const Icon(
                      Icons.open_in_new,
                    ),
                    label: Text(
                      '配信を見る',
                      style:
                          GoogleFonts
                              .zenMaruGothic(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? const Color(
                              0xFFEBDDF2,
                            )
                          : const Color(
                              0xFF76539B,
                            ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final favoriteRows =
        widget.rows.length <= 1
            ? <List<String>>[]
            : widget.rows
                .skip(1)
                .where(
                  (row) =>
                      widget.favorites.contains(
                    songName(row),
                  ),
                )
                .toList();

    return SafeArea(
      child: Column(
        children: [

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              12,
            ),

            child: Row(
              children: [

                Icon(
                  Icons.star,
                  color: isDark
                      ? const Color(0xFFEBDDF2)
                      : const Color(0xFF8061A8),
                  size: 30,
                ),

                const SizedBox(width: 10),

                Text(
                  'お気に入り',
                  style:
                      GoogleFonts
                          .zenMaruGothic(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                    color: isDark
                        ? Colors.white
                        : const Color(
                            0xFF654680,
                          ),
                  ),
                ),

                const Spacer(),

                Text(
                  '${widget.favorites.length}曲',
                  style:
                      GoogleFonts
                          .zenMaruGothic(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    color: isDark
                        ? const Color(
                            0xFFD8D0DC,
                          )
                        : const Color(
                            0xFF887494,
                          ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child:
                favoriteRows.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [

                            Icon(
                              Icons.star_border,
                              size: 70,
                              color: isDark
                                  ? const Color(
                                      0xFF604B69,
                                    )
                                  : const Color(
                                      0xFFD5C4E4,
                                    ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Text(
                              'お気に入りはまだありません',
                              style:
                                  GoogleFonts
                                      .zenMaruGothic(
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white
                                    : const Color(
                                        0xFF654680,
                                      ),
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              '曲一覧から☆を押して追加できます',
                              style:
                                  GoogleFonts
                                      .zenMaruGothic(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(
                                        0xFFD8D0DC,
                                      )
                                    : const Color(
                                        0xFF887494,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          18,
                          8,
                          18,
                          24,
                        ),

                        itemCount:
                            favoriteRows.length,

                        itemBuilder:
                            (
                          context,
                          index,
                        ) {

                          final row =
                              favoriteRows[index];

                          final song =
                              songName(row);

                          return Container(
                            margin:
                                const EdgeInsets
                                    .only(
                              bottom: 10,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  Theme.of(
                                context,
                              ).cardColor,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),
                            ),

                            child:
                                ListTile(
                              contentPadding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),

                              leading:
                                  Container(
                                width: 44,
                                height: 44,
                                decoration:
                                    BoxDecoration(
                                  color: isDark
                                      ? const Color(
                                          0xFF493556,
                                        )
                                      : const Color(
                                          0xFFE9DDF1,
                                        ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    14,
                                  ),
                                ),
                                child: Icon(
                                  Icons
                                      .music_note_rounded,
                                  color: isDark
                                      ? const Color(
                                          0xFFEBDDF2,
                                        )
                                      : const Color(
                                          0xFF8061A8,
                                        ),
                                ),
                              ),

                              title:
                                  Text(
                                song,
                                style:
                                    GoogleFonts
                                        .zenMaruGothic(
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(
                                          0xFF654680,
                                        ),
                                ),
                              ),

                              trailing:
                                  IconButton(
                                onPressed:
                                    () async {
                                  await widget
                                      .onToggleFavorite(
                                    song,
                                  );

                                  setState(
                                    () {},
                                  );
                                },
                                icon:
                                    const Icon(
                                  Icons.star,
                                  color:
                                      Colors.amber,
                                ),
                              ),

                              onTap: () =>
                                  showDetail(
                                row,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// 情報カード
// ======================================================

class _TopInfoCard
    extends StatelessWidget {

  final IconData icon;
  final String title;
  final String value;

  const _TopInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color:
            Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF493B50)
              : const Color(0xFFE3D5EC),
        ),
      ),

      child: Row(
        children: [

          Icon(
            icon,
            color: isDark
                ? const Color(0xFFC7A9D8)
                : const Color(0xFF8061A8),
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style:
                    GoogleFonts
                        .zenMaruGothic(
                  fontSize: 12,
                  color: isDark
                      ? const Color(
                          0xFFD8D0DC,
                        )
                      : const Color(
                          0xFF887494,
                        ),
                ),
              ),

              Text(
                value,
                style:
                    GoogleFonts
                        .zenMaruGothic(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                  color: isDark
                      ? Colors.white
                      : const Color(
                          0xFF654680,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================
// 詳細情報
// ======================================================

class _InfoRow
    extends StatelessWidget {

  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),

      child: Row(
        children: [

          Icon(
            icon,
            size: 19,
            color: isDark
                ? const Color(0xFFC7A9D8)
                : const Color(0xFF8061A8),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style:
                  GoogleFonts
                      .zenMaruGothic(
                color: isDark
                    ? Colors.white
                    : const Color(
                        0xFF654680,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
