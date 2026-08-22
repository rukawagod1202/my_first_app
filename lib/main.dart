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

      debugPrint(
        '📊 CSV行数: ${parsedRows.length}',
      );

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

  String getSongReading(List<String> row) {
    return row.length > 1 ? row[1].trim() : '';
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

  String getTimestamp(List<String> row) {
    return row.length > 5 ? row[5].trim() : '';
  }

  String getThumbnailUrl(List<String> row) {
    final url =
        row.length > 8 ? row[8].trim() : '';

    debugPrint(
      '🖼️ サムネイルURL: $url',
    );

    return url;
  }

  String getPlayUrl(List<String> row) {
    return row.length > 7 ? row[7].trim() : '';
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

  // ====================================================

  List<String>? get latestStream {
    if (rows.length <= 1) {
      return null;
    }

    final data = rows.skip(1).where((row) {
      return getStreamUrl(row).isNotEmpty &&
          getDate(row).isNotEmpty;
    }).toList();

    if (data.isEmpty) {
      return null;
    }



    DateTime? parseDate(String value) {
      final normalized = value
          .trim()
          .replaceAll('/', '-')
          .replaceAll('.', '-');

      final match = RegExp(
        r'^(\d{4})-(\d{1,2})-(\d{1,2})',
      ).firstMatch(normalized);

      if (match != null) {


        return DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }

      return DateTime.tryParse(normalized);
    }



    data.sort((a, b) {
      final dateA = parseDate(getDate(a));
      final dateB = parseDate(getDate(b));

      if (dateA == null && dateB == null) {
        return 0;
      }

      if (dateA == null) {
        return 1;
      }

      if (dateB == null) {
        return -1;
      }

      return dateB.compareTo(dateA);
    });

    final latestUrl =
        getStreamUrl(data.first);

    final latestDate =
        parseDate(getDate(data.first));

    for (final row in data) {
      if (getStreamUrl(row) != latestUrl) {
        continue;
      }

      final rowDate =
          parseDate(getDate(row));

      if (latestDate != null &&
          rowDate != null &&
          rowDate != latestDate) {
        continue;
      }

      if (getThumbnailUrl(row).isNotEmpty) {
        return row;
      }
    }



    for (final row in data) {
      if (getStreamUrl(row) != latestUrl) {
        continue;
      }

      final rowDate =
          parseDate(getDate(row));

      if (latestDate == null ||
          rowDate == latestDate) {
        return row;
      }
    }

    return data.first;
  }

  // ====================================================
  // TOPページ
  // ====================================================

  Widget buildTopPage() {
    final counts = getSongCounts();

    final ranking = counts.entries.toList()
      ..sort(
        (a, b) =>
            b.value.compareTo(a.value),
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



            Center(
              child: Text(
                '歌枠データベース',
                style:
                    GoogleFonts.mochiyPopOne(
                  fontSize: 40,
                  fontWeight:
                      FontWeight.bold,
                  color: mainTextColor,
                ),
              ),
            ),

            const SizedBox(height: 5),

            Center(
              child: Text(
                'るかわさんの歌枠をまとめています 🎧',
                style:
                    GoogleFonts.zenMaruGothic(
                  fontSize: 15,
                  color: subTextColor,
                ),
              ),
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: _TopInfoCard(
                    icon: Icons.music_note,
                    title: '登録曲数',
                    value:
                        '${counts.length}曲',
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _TopInfoCard(
                    icon: Icons.mic,
                    title: '総歌唱回数',
                    value:
                        '${rows.length > 1 ? rows.length - 1 : 0}回',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

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
              children: [
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
                  icon:
                      Icons.calendar_month,
                  title: '日付からさがす',
                  description: '配信日から検索',
                  onTap: () {
                    setState(() {
                      selectedIndex = 2;
                    });
                  },
                ),

                _FeatureCard(
                  icon:
                      Icons.play_circle_outline,
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
              ],
            ),

            const SizedBox(height: 28),



            const _SectionTitle(
              icon:
                  Icons.play_circle_outline,
              title: '最新の歌枠',
            ),

            const SizedBox(height: 12),

            if (latest != null)
              _LatestStreamCard(
                title:
                    getStreamTitle(latest),
                date: getDate(latest),
                url:
                    getStreamUrl(latest),
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
                final index =
                    entry.key;
                final item =
                    entry.value;

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

                    selectedIndex = 4;
                  });
                },
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? const Color(
                          0xFFEBDDF2)
                      : const Color(
                          0xFF8061A8),
                  side: BorderSide(
                    color: isDark
                        ? const Color(
                            0xFF604B69)
                        : const Color(
                            0xFFD5C4E4),
                  ),
                  padding:
                      const EdgeInsets.symmetric(
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
                child: Text(
                  'ランキングをすべて見る',
                  style:
                      GoogleFonts
                          .zenMaruGothic(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),



            const _SectionTitle(
              icon: Icons.link,
              title: '公式リンク',
            ),

            const SizedBox(height: 12),

            _LinkButton(
              icon:
                  Icons.alternate_email,
              title: 'X（旧Twitter）',
              subtitle: '@rukawagod',
              url:
                  'https://x.com/rukawagod',
              onOpen: openUrl,
            ),

            const SizedBox(height: 10),

            _LinkButton(
              icon: Icons.live_tv,
              title: 'ツイキャス',
              subtitle:
                  'るかわさんの配信ページ',
              url:
                  'https://twitcasting.tv/rukawagod',
              onOpen: openUrl,
            ),

            const SizedBox(height: 30),



            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(20),
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
                        GoogleFonts
                            .zenMaruGothic(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color: isDark
                          ? const Color(
                              0xFFEBDDF2)
                          : const Color(
                              0xFF654680),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '当サイトは、るかわさんの歌枠をまとめた非公式データベースです。',
                    style:
                        GoogleFonts
                            .zenMaruGothic(
                      fontSize: 12,
                      height: 1.7,
                      color: isDark
                          ? Colors.white
                          : null,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '※当サイトはるかわさんご本人、及びるかわさんに関わりのある活動者の皆様とは一切関係がなく、完全非公式の歌枠まとめサイトとなっております。\n\n掲載内容は予告なく更新・削除する場合がございます。当サイトの利用によって生じたいかなるトラブル・損失・損害に対して、一切責任を負いかねますのでご了承ください。',
                    style:
                        GoogleFonts
                            .zenMaruGothic(
                      fontSize: 10.5,
                      height: 1.7,
                      color: isDark
                          ? const Color(
                              0xFFD8D0DC)
                          : const Color(
                              0xFF887494),
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
      onToggleFavorite:
          toggleFavorite,
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


      CalendarPage(
        rows: rows,
        onOpenUrl: openUrl,
      ),

      FavoritesPage(
        rows: rows,
        favorites: favorites,
        onToggleFavorite:
            toggleFavorite,
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
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF9B72B5),
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    child: Text(
                      errorMessage,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                      ),
                    ),
                  ),
                )
              : pages[selectedIndex],

      bottomNavigationBar:
          NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected:
            (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        indicatorColor:
            Theme.of(context).brightness ==
                    Brightness.dark
                ? const Color(0xFF493556)
                : const Color(0xFFE4D5EC),
                
        labelTextStyle: WidgetStateProperty.all(
  GoogleFonts.zenMaruGothic(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  ),
),

        destinations: const [

          NavigationDestination(
            icon: Icon(
                Icons.home_outlined),
            selectedIcon:
                Icon(Icons.home),
            label: 'TOP',
          ),

          NavigationDestination(
            icon: Icon(
                Icons.music_note_outlined),
            selectedIcon:
                Icon(Icons.music_note),
            label: '曲一覧',
          ),

          NavigationDestination(
            icon: Icon(
                Icons.calendar_month_outlined),
            selectedIcon:
                Icon(Icons.calendar_month),
            label: '日付検索',
          ),

          NavigationDestination(
            icon: Icon(
                Icons.star_border),
            selectedIcon:
                Icon(Icons.star),
            label: 'お気に入り',
          ),

          NavigationDestination(
            icon: Icon(
                Icons.bar_chart_outlined),
            selectedIcon:
                Icon(Icons.bar_chart),
            label: 'ランキング',
          ),
        ],
      ),



      floatingActionButton:
          selectedIndex != 0
              ? FloatingActionButton.small(
                  onPressed: () {
                    widget
                        .onDarkModeChanged(
                      !widget.isDarkMode,
                    );
                  },
                  backgroundColor:
                      const Color(
                    0xFF9B72B5,
                  ),
                  foregroundColor:
                      Colors.white,
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

class _FeatureCard
    extends StatelessWidget {
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
        Theme.of(context).brightness ==
            Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(14),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color:
                Theme.of(context).cardColor,
            borderRadius:
                BorderRadius.circular(14),
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
                decoration:
                    BoxDecoration(
                  color: isDark
                      ? const Color(
                          0xFF493556)
                      : const Color(
                          0xFFEDE4F5),
                  borderRadius:
                      BorderRadius.circular(
                    9,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDark
                      ? const Color(
                          0xFFEBDDF2)
                      : const Color(
                          0xFF8061A8),
                  size: 17,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style: GoogleFonts
                          .zenMaruGothic(
                        fontWeight:
                            FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(
                                0xFF654680),
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 1),

                    Text(
                      description,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style: GoogleFonts
                          .zenMaruGothic(
                        fontSize: 12,
                        color: isDark
                            ? const Color(
                                0xFFD8D0DC)
                            : const Color(
                                0xFF887494),
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

class _SectionTitle
    extends StatelessWidget {
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
          style:
              GoogleFonts.zenMaruGothic(
            fontSize: 21,
            fontWeight:
                FontWeight.bold,
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
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardColor,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? const Color(0xFF493B50)
                : const Color(0xFFE3D5EC),
          ),
        ),
        clipBehavior:
            Clip.antiAlias,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 55,
              width: double.infinity,
              child: thumbnailUrl.isNotEmpty
                  ? Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const _ThumbnailPlaceholder();
                      },
                    )
                  : const _ThumbnailPlaceholder(),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(16),

              child: Row(
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [

                        Text(
                          title.isEmpty
                              ? 'クリックで最新の歌枠配信に飛べます'
                              : title,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style: GoogleFonts
                              .zenMaruGothic(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(
                                    0xFF654680),
                          ),
                        ),

                        if (date.isNotEmpty) ...[
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            date,
                            style: GoogleFonts
                                .zenMaruGothic(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(
                                      0xFFD8D0DC)
                                  : const Color(
                                      0xFF887494),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration:
                        BoxDecoration(
                      color: isDark
                          ? const Color(
                              0xFF493556)
                          : const Color(
                              0xFFEDE4F5),
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                    child: Icon(
                      Icons.open_in_new,
                      size: 19,
                      color: isDark
                          ? const Color(
                              0xFFEBDDF2)
                          : const Color(
                              0xFF8061A8),
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
          const EdgeInsets.only(
        bottom: 10,
      ),
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

          Container(
            width: 45,
            height: 45,
            decoration:
                BoxDecoration(
              color: rank == 1
                  ? const Color(
                      0xFF8061A8)
                  : rank == 2
                      ? const Color(
                          0xFF9B72B5)
                      : rank == 3
                          ? const Color(
                              0xFFB99AC9)
                          : isDark
                              ? const Color(
                                  0xFF493556)
                              : const Color(
                                  0xFFEDE4F5),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Center(
              child: Text(
                rank
                    .toString()
                    .padLeft(2, '0'),
                style: GoogleFonts
                    .zenMaruGothic(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                  color: rank <= 3
                      ? Colors.white
                      : isDark
                          ? const Color(
                              0xFFEBDDF2)
                          : const Color(
                              0xFF8061A8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [

                Text(
                  song,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: GoogleFonts
                      .zenMaruGothic(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color: isDark
                        ? Colors.white
                        : const Color(
                            0xFF654680),
                  ),
                ),

                const SizedBox(height: 9),

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  child:
                      LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor:
                        isDark
                            ? const Color(
                                0xFF403443)
                            : const Color(
                                0xFFEDE4F5),
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
                  ? const Color(
                      0xFFEBDDF2)
                  : const Color(
                      0xFF8061A8),
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

            Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(
                color: isDark
                    ? const Color(
                        0xFF493556)
                    : const Color(
                        0xFFEDE4F5),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                icon,
                color: isDark
                    ? const Color(
                        0xFFEBDDF2)
                    : const Color(
                        0xFF8061A8),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [

                  Text(
                    title,
                    style: GoogleFonts
                        .zenMaruGothic(
                      fontWeight:
                          FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : const Color(
                              0xFF654680),
                    ),
                  ),

                  Text(
                    subtitle,
                    style: GoogleFonts
                        .zenMaruGothic(
                      fontSize: 11,
                      color: isDark
                          ? const Color(
                              0xFFD8D0DC)
                          : const Color(
                              0xFF887494),
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.open_in_new,
              color: isDark
                  ? const Color(
                      0xFFEBDDF2)
                  : const Color(
                      0xFF8061A8),
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

  final Future<void> Function(
    String songName,
  ) onToggleFavorite;

  final Future<void> Function(
    String url,
  ) onOpenUrl;

  const SongsPage({
    super.key,
    required this.rows,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onOpenUrl,
  });

  @override
  State<SongsPage> createState() =>
      _SongsPageState();
}

class _SongsPageState
    extends State<SongsPage> {
  final TextEditingController
      searchController =
      TextEditingController();



  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String songName(List<String> row) {
    return row.isNotEmpty
        ? row[0].trim()
        : '';
  }



  String songReading(List<String> row) {
    return row.length > 1
        ? row[1].trim()
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

  // ====================================================
  // 曲詳細
  // ====================================================

  void showDetail(
    String song,
    List<List<String>> songRows,
  ) {
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
        return SongDetailSheet(
          song: song,
          songRows: songRows,
          favorites: widget.favorites,
          onToggleFavorite:
              widget.onToggleFavorite,
          onOpenUrl: widget.onOpenUrl,
          getDate: date,
          getTimestamp: timestamp,
          getStreamTitle:
              streamTitle,
          getPlayUrl: playUrl,
          getStreamUrl: streamUrl,
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final query =
        searchController.text
            .trim()
            .toLowerCase();

    final Map<String, List<List<String>>>
        groups = {};

    for (final row
        in widget.rows.skip(1)) {
      final song = songName(row);

      if (song.isEmpty) continue;

      final reading =
          songReading(row);

      if (query.isNotEmpty &&
          !song.toLowerCase().contains(
                query,
              ) &&
          !reading.toLowerCase().contains(
                query,
              )) {
        continue;
      }

      groups.putIfAbsent(
        song,
        () => [],
      );

      groups[song]!.add(row);
    }

    final songs = groups.keys.toList()
      ..sort();

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
                  Icons.music_note,
                  color: isDark
                      ? const Color(
                          0xFFEBDDF2)
                      : const Color(
                          0xFF8061A8),
                  size: 30,
                ),

                const SizedBox(width: 10),

                Text(
                  '曲をさがす',
                  style: GoogleFonts
                      .zenMaruGothic(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.w800,
                    color: isDark
                        ? Colors.white
                        : const Color(
                            0xFF654680),
                  ),
                ),
              ],
            ),
          ),

          Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 18,
  ),
  child: TextField(
    controller: searchController,
    decoration: InputDecoration(
      hintText: '曲名で検索',
      prefixIcon: const Icon(
        Icons.search,
      ),
      suffixIcon: searchController.text.isNotEmpty
          ? IconButton(
              onPressed: () {
                searchController.clear();
                setState(() {});
              },
              icon: const Icon(
                Icons.clear,
              ),
            )
          : null,
      filled: true,
      fillColor: isDark
          ? const Color(0xFF2A2430)
          : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          16,
        ),
        borderSide: BorderSide.none,
      ),
    ),
  ),
),

          const SizedBox(height: 8),

          Expanded(
            child: songs.isEmpty
                ? Center(
                    child: Text(
                      query.isEmpty
                          ? '曲がありません'
                          : '曲が見つかりません',
                      style: GoogleFonts
                          .zenMaruGothic(
                        color: isDark
                            ? Colors.white
                            : const Color(
                                0xFF654680),
                      ),
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
                        songs.length,
                    itemBuilder:
                        (context, index) {
                      final song =
                          songs[index];

                      final songRows =
                          groups[song]!;

                      final isFavorite =
                          widget.favorites
                              .contains(
                        song,
                      );

                      return Card(
  color: isDark
      ? const Color(0xFF2A2430)
      : Colors.white,
                        elevation: 0,
                        margin:
                            const EdgeInsets
                                .only(
                          bottom: 10,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            18,
                          ),
                        ),
                        child: ListTile(
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
                                      0xFF493556)
                                  : const Color(
                                      0xFFE9DDF1),
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
                                      0xFFEBDDF2)
                                  : const Color(
                                      0xFF8061A8),
                            ),
                          ),
                          title: Text(
                            song,
                            style: GoogleFonts
                                .zenMaruGothic(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(
                                      0xFF403747),
                            ),
                          ),
                          subtitle: Text(
                            '${songRows.length}回歌唱',
                            style: GoogleFonts
                                .zenMaruGothic(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(
                                      0xFFD8D0DC)
                                  : const Color(
                                      0xFF887494),
                            ),
                          ),
                          trailing:
                              IconButton(
                            onPressed: () async {
                              await widget
                                  .onToggleFavorite(
                                song,
                              );
                              setState(() {});
                            },
                            icon: Icon(
                              isFavorite
                                  ? Icons.star
                                  : Icons
                                      .star_border,
                              color: isFavorite
                                  ? Colors.amber
                                  : const Color(
                                      0xFF9B72B5),
                            ),
                          ),
                          onTap: () {
                            showDetail(
                              song,
                              songRows,
                            );
                          },
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

  Map<String, List<List<String>>>
      getFavoriteGroups() {
    final groups =
        <String, List<List<String>>>{};

    for (final row
        in widget.rows.skip(1)) {
      final song = songName(row);

      if (song.isEmpty) continue;

      if (!widget.favorites
          .contains(song)) {
        continue;
      }

      groups.putIfAbsent(
        song,
        () => [],
      );

      groups[song]!.add(row);
    }

    return groups;
  }

  void showDetail(
    String song,
    List<List<String>> songRows,
  ) {
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
        return SongDetailSheet(
          song: song,
          songRows: songRows,
          favorites: widget.favorites,
          onToggleFavorite:
              widget.onToggleFavorite,
          onOpenUrl: widget.onOpenUrl,
          getDate: date,
          getTimestamp: timestamp,
          getStreamTitle:
              streamTitle,
          getPlayUrl: playUrl,
          getStreamUrl: streamUrl,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final groups =
        getFavoriteGroups();

    final songs =
        groups.keys.toList()..sort();

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
                      ? const Color(
                          0xFFEBDDF2)
                      : const Color(
                          0xFF8061A8),
                  size: 30,
                ),

                const SizedBox(width: 10),

                Text(
                  'お気に入り',
                  style: GoogleFonts
                      .zenMaruGothic(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.w800,
                    color: isDark
                        ? Colors.white
                        : const Color(
                            0xFF654680),
                  ),
                ),

                const Spacer(),

                Text(
                  '${songs.length}曲',
                  style: GoogleFonts
                      .zenMaruGothic(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                    color: isDark
                        ? const Color(
                            0xFFD8D0DC)
                        : const Color(
                            0xFF887494),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: songs.isEmpty
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
                                  0xFF604B69)
                              : const Color(
                                  0xFFD5C4E4),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Text(
                          'お気に入りはまだありません',
                          style: GoogleFonts
                              .zenMaruGothic(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(
                                    0xFF654680),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          '曲一覧から☆を押して追加できます',
                          style: GoogleFonts
                              .zenMaruGothic(
                            fontSize: 11,
                            color: isDark
                                ? const Color(
                                    0xFFD8D0DC)
                                : const Color(
                                    0xFF887494),
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
                        songs.length,
                    itemBuilder:
                        (context, index) {
                      final song =
                          songs[index];

                      final songRows =
                          groups[song]!;

                      return Card(
                        color:
                            Theme.of(
                          context,
                        ).cardColor,
                        elevation: 0,
                        margin:
                            const EdgeInsets
                                .only(
                          bottom: 10,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            18,
                          ),
                        ),
                        child: ListTile(
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
                                      0xFF493556)
                                  : const Color(
                                      0xFFE9DDF1),
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
                                      0xFFEBDDF2)
                                  : const Color(
                                      0xFF8061A8),
                            ),
                          ),
                          title: Text(
                            song,
                            style: GoogleFonts
                                .zenMaruGothic(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(
                                      0xFF403747),
                            ),
                          ),
                          subtitle: Text(
                            '${songRows.length}回歌唱',
                            style: GoogleFonts
                                .zenMaruGothic(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(
                                      0xFFD8D0DC)
                                  : const Color(
                                      0xFF887494),
                            ),
                          ),
                          trailing:
                              IconButton(
                            onPressed: () async {
                              await widget
                                  .onToggleFavorite(
                                song,
                              );
                              setState(() {});
                            },
                            icon:
                                const Icon(
                              Icons.star,
                              color:
                                  Colors.amber,
                            ),
                          ),
                          onTap: () {
                            showDetail(
                              song,
                              songRows,
                            );
                          },
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
// 共通・曲詳細
// ======================================================

class SongDetailSheet
    extends StatefulWidget {
  final String song;
  final List<List<String>> songRows;
  final Set<String> favorites;

  final Future<void> Function(
    String songName,
  ) onToggleFavorite;

  final Future<void> Function(
    String url,
  ) onOpenUrl;

  final String Function(List<String>)
      getDate;

  final String Function(List<String>)
      getTimestamp;

  final String Function(List<String>)
      getStreamTitle;

  final String Function(List<String>)
      getPlayUrl;

  final String Function(List<String>)
      getStreamUrl;

  const SongDetailSheet({
    super.key,
    required this.song,
    required this.songRows,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onOpenUrl,
    required this.getDate,
    required this.getTimestamp,
    required this.getStreamTitle,
    required this.getPlayUrl,
    required this.getStreamUrl,
  });

  @override
  State<SongDetailSheet> createState() =>
      _SongDetailSheetState();
}

class _SongDetailSheetState
    extends State<SongDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final isFavorite =
        widget.favorites.contains(
      widget.song,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (
        context,
        scrollController,
      ) {
        return Padding(
          padding:
              const EdgeInsets.fromLTRB(
            28,
            20,
            28,
            20,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration:
                        BoxDecoration(
                      color: isDark
                          ? const Color(
                              0xFF493556)
                          : const Color(
                              0xFFE8DDF2),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: isDark
                          ? const Color(
                              0xFFEBDDF2)
                          : const Color(
                              0xFF8061A8),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      widget.song,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: GoogleFonts
                          .zenMaruGothic(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.w800,
                        color: isDark
                            ? Colors.white
                            : const Color(
                                0xFF654680),
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () async {
                      await widget
                          .onToggleFavorite(
                        widget.song,
                      );

                      setState(() {});

                      if (context.mounted) {
                        Navigator.pop(
                          context,
                        );
                      }
                    },
                    icon: Icon(
                      isFavorite
                          ? Icons.star
                          : Icons.star_border,
                      color: isFavorite
                          ? Colors.amber
                          : const Color(
                              0xFF9B72B5),
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                '${widget.songRows.length}回歌われています',
                style: GoogleFonts
                    .zenMaruGothic(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                  color: isDark
                      ? const Color(
                          0xFFD8D0DC)
                      : const Color(
                          0xFF887494),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  controller:
                      scrollController,
                  itemCount:
                      widget.songRows.length,
                  itemBuilder:
                      (context, index) {
                    final row =
                        widget.songRows[index];

                    return _CompactSongHistoryCard(
                      date: widget.getDate(
                        row,
                      ),
                      timestamp:
                          widget.getTimestamp(
                        row,
                      ),
                      streamTitle:
                          widget.getStreamTitle(
                        row,
                      ),
                      playUrl:
                          widget.getPlayUrl(
                        row,
                      ),
                      streamUrl:
                          widget.getStreamUrl(
                        row,
                      ),
                      onOpenUrl:
                          widget.onOpenUrl,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
                style: GoogleFonts
                    .zenMaruGothic(
                  fontSize: 12,
                  color: isDark
                      ? const Color(
                          0xFFD8D0DC)
                      : const Color(
                          0xFF887494),
                ),
              ),

              Text(
                value,
                style: GoogleFonts
                    .zenMaruGothic(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                  color: isDark
                      ? Colors.white
                      : const Color(
                          0xFF654680),
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
// コンパクト歌唱履歴カード
// ======================================================

class _CompactSongHistoryCard
    extends StatelessWidget {
  final String date;
  final String timestamp;
  final String streamTitle;
  final String playUrl;
  final String streamUrl;

  final Future<void> Function(
    String url,
  ) onOpenUrl;

  const _CompactSongHistoryCard({
    required this.date,
    required this.timestamp,
    required this.streamTitle,
    required this.playUrl,
    required this.streamUrl,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final purple = isDark
        ? const Color(0xFFC7A9D8)
        : const Color(0xFF8061A8);

    final mainText = isDark
        ? Colors.white
        : const Color(0xFF654680);

    final subText = isDark
        ? const Color(0xFFD8D0DC)
        : const Color(0xFF887494);

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: isDark
              ? const Color(0xFF493B50)
              : const Color(0xFFE3D5EC),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (date.isNotEmpty)
                Flexible(
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 15,
                        color: purple,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Flexible(
                        child: Text(
                          date,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style: GoogleFonts
                              .zenMaruGothic(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
                            color: mainText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (date.isNotEmpty &&
                  timestamp.isNotEmpty)
                const SizedBox(width: 12),

              if (timestamp.isNotEmpty)
                Flexible(
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 15,
                        color: purple,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Flexible(
                        child: Text(
                          timestamp,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style: GoogleFonts
                              .zenMaruGothic(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
                            color: mainText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (streamTitle.isNotEmpty) ...[
            const SizedBox(height: 7),

            Row(
              children: [
                Icon(
                  Icons.live_tv,
                  size: 15,
                  color: purple,
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    streamTitle,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: GoogleFonts
                        .zenMaruGothic(
                      fontSize: 11,
                      color: subText,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        playUrl.isEmpty
                            ? null
                            : () {
                                onOpenUrl(
                                  playUrl,
                                );
                              },
                    icon: const Icon(
                      Icons
                          .play_arrow_rounded,
                      size: 17,
                    ),
                    label: Text(
                      '聴く',
                      style: GoogleFonts
                          .zenMaruGothic(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                              0xFF8061A8),
                      foregroundColor:
                          Colors.white,
                      padding:
                          EdgeInsets.zero,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: SizedBox(
                  height: 34,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        streamUrl.isEmpty
                            ? null
                            : () {
                                onOpenUrl(
                                  streamUrl,
                                );
                              },
                    icon: const Icon(
                      Icons.open_in_new,
                      size: 15,
                    ),
                    label: Text(
                      '配信',
                      style: GoogleFonts
                          .zenMaruGothic(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          isDark
                              ? const Color(
                                  0xFFEBDDF2)
                              : const Color(
                                  0xFF8061A8),
                      padding:
                          EdgeInsets.zero,
                      side: BorderSide(
                        color: isDark
                            ? const Color(
                                0xFF604B69)
                            : const Color(
                                0xFFD5C4E4),
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                    ),
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
