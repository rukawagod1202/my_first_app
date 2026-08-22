import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  State<SongsPage> createState() =>
      _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  final TextEditingController searchController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  bool favoritesOnly = false;

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      setState(() {});
    });
  }

  // ====================================================
  // 各列
  // ====================================================

  String songName(List<String> row) {
    return row.isNotEmpty ? row[0].trim() : '';
  }

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
  // 同じ曲かどうか判定するための名前
  // ====================================================

  String normalizeSongName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '');
  }

  // ====================================================
  // 曲ごとにまとめる
  // 同じ曲は1つにして、歌唱履歴を全部まとめる
  // ====================================================

  Map<String, List<List<String>>> groupSongs() {
    final grouped =
        <String, List<List<String>>>{};

    if (widget.rows.length <= 1) {
      return grouped;
    }

    for (final row in widget.rows.skip(1)) {
      final song = songName(row);

      if (song.isEmpty) continue;

      // 表記ゆれをなくして比較
      final key = normalizeSongName(song);

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(row);
    }

    return grouped;
  }

  // ====================================================
// 曲の詳細・歌唱履歴
// ====================================================

void showSongDetail(
  String song,
  List<List<String>> songRows,
) {
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

      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (
          context,
          scrollController,
        ) {
          final isFavorite =
              widget.favorites.contains(song);

          return Padding(
            padding: const EdgeInsets.fromLTRB(
              28,
              20,
              28,
              20,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                // ==============================================
                // ヘッダー
                // ==============================================

                Row(
                  children: [

                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF493556)
                            : const Color(0xFFE8DDF2),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: isDark
                            ? const Color(0xFFEBDDF2)
                            : const Color(0xFF8061A8),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        song,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            GoogleFonts.zenMaruGothic(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(
                                  0xFF654680,
                                ),
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () async {
                        await widget
                            .onToggleFavorite(song);

                        if (mounted) {
                          setState(() {});
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      icon: Icon(
                        isFavorite
                            ? Icons.star
                            : Icons.star_border,
                        color: isFavorite
                            ? Colors.amber
                            : (isDark
                                ? const Color(
                                    0xFFB9A8C4,
                                  )
                                : const Color(
                                    0xFF9B72B5,
                                  )),
                        size: 28,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ==============================================
                // 歌唱回数
                // ==============================================

                Text(
                  '${songRows.length}回歌われています',
                  style:
                      GoogleFonts.zenMaruGothic(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFD8D0DC)
                        : const Color(0xFF887494),
                  ),
                ),

                const SizedBox(height: 12),

                // ==============================================
                // 歌唱履歴
                // ==============================================

                Expanded(
                  child: ListView.builder(
                    controller:
                        scrollController,
                    itemCount:
                        songRows.length,
                    itemBuilder:
                        (context, index) {
                      final row =
                          songRows[index];

                      return _CompactSongHistoryCard(
                        date: date(row),
                        streamTitle:
                            streamTitle(row),
                        timestamp:
                            timestamp(row),
                        playUrl:
                            playUrl(row),
                        streamUrl:
                            streamUrl(row),
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
    },
  );
}

  // ====================================================
  // 画面
  // ====================================================

  @override
  Widget build(BuildContext context) {
    final query =
        searchController.text.trim().toLowerCase();

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final grouped = groupSongs();

    // ==================================================
    // 検索＋お気に入り
    // ==================================================

    final filteredSongs =
        grouped.entries.where((entry) {
      final history = entry.value;

      // 代表として最初の行の曲名を表示
      final song = songName(history.first);

      final matchesSearch =
          query.isEmpty ||
          song.toLowerCase().contains(query) ||
          history.any(
            (row) => songReading(row)
                .toLowerCase()
                .contains(query),
          );

      final matchesFavorite =
          !favoritesOnly ||
          widget.favorites.contains(song);

      return matchesSearch &&
          matchesFavorite;
    }).toList();

    // ==================================================
    // 曲名順
    // ==================================================

    filteredSongs.sort(
      (a, b) {
        final songA =
            songName(a.value.first);

        final songB =
            songName(b.value.first);

        return songA.compareTo(songB);
      },
    );

    return Column(
      children: [
        // ==================================================
        // 検索
        // ==================================================

        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            10,
          ),
          child: TextField(
            controller: searchController,
            style: GoogleFonts.zenMaruGothic(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white
                  : const Color(0xFF403747),
            ),
            decoration: InputDecoration(
              hintText: '曲をさがす',
              hintStyle:
                  GoogleFonts.zenMaruGothic(
                fontSize: 14,
                color: isDark
                    ? Colors.white60
                    : const Color(0xFF887494),
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF8061A8),
              ),
              suffixIcon:
                  query.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                          },
                          icon: const Icon(
                            Icons.clear,
                          ),
                        )
                      : null,
              filled: true,
              fillColor:
                  Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFF8061A8),
                  width: 2,
                ),
              ),
            ),
          ),
        ),

        // ==================================================
        // 件数・お気に入りフィルター
        // ==================================================

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          child: Row(
            children: [
              Text(
                '${filteredSongs.length}曲',
                style:
                    GoogleFonts.zenMaruGothic(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color:
                      const Color(0xFF8061A8),
                ),
              ),

              const Spacer(),

              TextButton.icon(
                onPressed: () {
                  setState(() {
                    favoritesOnly =
                        !favoritesOnly;
                  });
                },
                icon: Icon(
                  favoritesOnly
                      ? Icons.star
                      : Icons.star_border,
                  color:
                      const Color(0xFF8061A8),
                ),
                label: Text(
                  'お気に入りのみ',
                  style:
                      GoogleFonts.zenMaruGothic(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        const Color(0xFF8061A8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ==================================================
        // 曲一覧
        // ==================================================

        Expanded(
          child: filteredSongs.isEmpty
              ? Center(
                  child: Text(
                    '曲が見つかりませんでした',
                    style:
                        GoogleFonts.zenMaruGothic(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white70
                          : const Color(
                              0xFF5F5666,
                            ),
                    ),
                  ),
                )
              : Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  radius:
                      const Radius.circular(10),
                  child: ListView.builder(
                    controller:
                        scrollController,
                    padding:
                        const EdgeInsets.fromLTRB(
                      18,
                      6,
                      18,
                      24,
                    ),
                    itemCount:
                        filteredSongs.length,
                    itemBuilder:
                        (context, index) {
                      final entry =
                          filteredSongs[index];

                      final history =
                          entry.value;

                      // 同じ曲をまとめたグループの
                      // 最初の曲名を表示名として使う
                      final song =
                          songName(history.first);

                      final isFavorite =
                          widget.favorites
                              .contains(song);

                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
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

                          // ============================
                          // アイコン
                          // ============================

                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration:
                                BoxDecoration(
                              color: isDark
                                  ? const Color(
                                      0xFF45384D,
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
                            child: const Icon(
                              Icons.music_note,
                              color:
                                  Color(0xFF8061A8),
                            ),
                          ),

                          // ============================
                          // 曲名＋歌唱回数
                          // ============================

                          title: Text(
                            song,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                GoogleFonts
                                    .zenMaruGothic(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(
                                      0xFF403747,
                                    ),
                            ),
                          ),

                          subtitle: Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              top: 3,
                            ),
                            child: Text(
                              '${history.length}回歌唱',
                              style: GoogleFonts
                                  .zenMaruGothic(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                                color: isDark
                                    ? const Color(
                                        0xFFD8D0DC,
                                      )
                                    : const Color(
                                        0xFF887494,
                                      ),
                              ),
                            ),
                          ),

                          // ============================
                          // お気に入り
                          // ============================

                          trailing:
                              IconButton(
                            onPressed: () async {
                              await widget
                                  .onToggleFavorite(
                                song,
                              );

                              if (mounted) {
                                setState(() {});
                              }
                            },
                            icon: Icon(
                              isFavorite
                                  ? Icons.star
                                  : Icons
                                      .star_border,
                              color: isFavorite
                                  ? Colors.amber
                                  : const Color(
                                      0xFF8061A8,
                                    ),
                            ),
                          ),

                          // ============================
                          // タップ → 履歴
                          // ============================

                          onTap: () {
                            showSongDetail(
                              song,
                              history,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
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
// コンパクト歌唱履歴カード
// ======================================================

class _CompactSongHistoryCard extends StatelessWidget {
  final String date;
  final String streamTitle;
  final String timestamp;
  final String playUrl;
  final String streamUrl;
  final Future<void> Function(String url) onOpenUrl;

  const _CompactSongHistoryCard({
    required this.date,
    required this.streamTitle,
    required this.timestamp,
    required this.playUrl,
    required this.streamUrl,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final mainColor = isDark
        ? const Color(0xFFEBDDF2)
        : const Color(0xFF654680);

    final subColor = isDark
        ? const Color(0xFFD8D0DC)
        : const Color(0xFF887494);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                size: 18,
                color: isDark
                    ? const Color(0xFFC7A9D8)
                    : const Color(0xFF8061A8),
              ),

              const SizedBox(width: 7),

              Text(
                date,
                style: GoogleFonts.zenMaruGothic(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  streamTitle.isEmpty
                      ? '配信タイトルなし'
                      : streamTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.zenMaruGothic(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: mainColor,
                  ),
                ),
              ),

              if (timestamp.isNotEmpty) ...[
                const SizedBox(width: 8),

                Icon(
                  Icons.access_time,
                  size: 16,
                  color: subColor,
                ),

                const SizedBox(width: 4),

                Text(
                  timestamp,
                  style: GoogleFonts.zenMaruGothic(
                    fontSize: 11,
                    color: subColor,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: playUrl.isEmpty
                        ? null
                        : () {
                            onOpenUrl(playUrl);
                          },
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    label: Text(
                      'この歌唱を聴く',
                      style: GoogleFonts.zenMaruGothic(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF8061A8),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),
              ),

              if (streamUrl.isNotEmpty) ...[
                const SizedBox(width: 7),

                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        onOpenUrl(streamUrl);
                      },
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 17,
                      ),
                      label: Text(
                        '配信を見る',
                        style: GoogleFonts.zenMaruGothic(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? const Color(0xFFEBDDF2)
                            : const Color(0xFF8061A8),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF604B69)
                              : const Color(0xFFD5C4E4),
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================
// 歌唱履歴カード
// ======================================================

class _HistoryCard extends StatelessWidget {
  final String date;
  final String streamTitle;
  final String timestamp;
  final String playUrl;
  final String streamUrl;

  final Future<void> Function(String url)
      onOpenUrl;

  const _HistoryCard({
    required this.date,
    required this.streamTitle,
    required this.timestamp,
    required this.playUrl,
    required this.streamUrl,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ==================================================
          // 日付
          // ==================================================

          if (date.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 18,
                  color: Color(0xFF8061A8),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    date,
                    style: GoogleFonts
                        .zenMaruGothic(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.bold,
                      color: isDark
                          ? const Color(
                              0xFFEBDDF2,
                            )
                          : const Color(
                              0xFF654680,
                            ),
                    ),
                  ),
                ),
              ],
            ),

          if (streamTitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.live_tv,
                  size: 18,
                  color: Color(0xFF8061A8),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    streamTitle,
                    style: GoogleFonts
                        .zenMaruGothic(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color: isDark
                          ? Colors.white
                          : const Color(
                              0xFF403747,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (timestamp.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 17,
                  color: Color(0xFF8061A8),
                ),
                const SizedBox(width: 7),
                Text(
                  timestamp,
                  style: GoogleFonts
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
              ],
            ),
          ],

          // ==================================================
          // ボタン
          // ==================================================

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: playUrl.isEmpty
                      ? null
                      : () {
                          onOpenUrl(playUrl);
                        },
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    size: 19,
                  ),
                  label: Text(
                    'この曲を聴く',
                    style: GoogleFonts
                        .zenMaruGothic(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF8061A8),
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 12,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: OutlinedButton.icon(
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
                    size: 17,
                  ),
                  label: Text(
                    '配信を見る',
                    style: GoogleFonts
                        .zenMaruGothic(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF8061A8),
                    side: BorderSide(
                      color: isDark
                          ? const Color(
                              0xFF604B69,
                            )
                          : const Color(
                              0xFFD5C4E4,
                            ),
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 12,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        13,
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