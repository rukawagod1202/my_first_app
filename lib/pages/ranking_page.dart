import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RankingPage extends StatelessWidget {
  final List<List<String>> rows;
  final Future<void> Function(String url) onOpenUrl;

  const RankingPage({
    super.key,
    required this.rows,
    required this.onOpenUrl,
  });

  String songName(List<String> row) {
    return row.isNotEmpty ? row[0].trim() : '';
  }

  String streamUrl(List<String> row) {
    return row.length > 4 ? row[4].trim() : '';
  }

  Map<String, int> getSongCounts() {
    final counts = <String, int>{};

    if (rows.length <= 1) {
      return counts;
    }

    for (final row in rows.skip(1)) {
      final song = songName(row);

      if (song.isEmpty) continue;

      counts[song] = (counts[song] ?? 0) + 1;
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final counts = getSongCounts();

    // ==========================================
    // ランキングを回数順に並べて100位までに制限
    // ==========================================

    final ranking = counts.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    final top100 = ranking.take(100).toList();

    final maxCount =
        top100.isEmpty ? 1 : top100.first.value;

    // ==========================
    // カラーテーマ
    // ==========================

    final primaryText =
        isDark
            ? Colors.white
            : const Color(0xFF654680);

    final secondaryText =
        isDark
            ? const Color(0xFFD8CBE0)
            : const Color(0xFF887494);

    final accentText =
        isDark
            ? const Color(0xFFD9B9F0)
            : const Color(0xFF8061A8);

    final cardBorder =
        isDark
            ? const Color(0xFF51465A)
            : const Color(0xFFE3D5EC);

    final softBackground =
        isDark
            ? const Color(0xFF332B38)
            : const Color(0xFFEDE4F5);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          24,
          18,
          35,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==========================
            // タイトル
            // ==========================

            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: softBackground,
                  borderRadius:
                      BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 38,
                  color: accentText,
                ),
              ),
            ),

            const SizedBox(height: 13),

            Center(
              child: Text(
                'ランキング',
                style:
                    GoogleFonts.zenMaruGothic(
                  fontSize: 27,
                  fontWeight:
                      FontWeight.bold,
                  color: primaryText,
                ),
              ),
            ),

            const SizedBox(height: 3),

            Center(
              child: Text(
                'よく歌う曲TOP100',
                style:
                    GoogleFonts.zenMaruGothic(
                  fontSize: 12,
                  color: secondaryText,
                ),
              ),
            ),

            const SizedBox(height: 25),

            if (top100.isEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(30),
                decoration:
                    BoxDecoration(
                  color:
                      Theme.of(context)
                          .cardColor,
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: cardBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    'ランキングデータがありません',
                    style: TextStyle(
                      color: primaryText,
                    ),
                  ),
                ),
              )
            else ...[
              // ==========================
              // TOP 3
              // ==========================

              ...top100
                  .take(3)
                  .toList()
                  .asMap()
                  .entries
                  .map(
                (entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return _TopRankingCard(
                    rank: index + 1,
                    song: item.key,
                    count: item.value,
                    maxCount: maxCount,
                  );
                },
              ),

              // ==========================
              // 4位〜100位
              // ==========================

              if (top100.length > 3) ...[
                const SizedBox(height: 25),

                Text(
                  'OTHER RANKING',
                  style:
                      GoogleFonts
                          .zenMaruGothic(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 1.5,
                    color: accentText,
                  ),
                ),

                const SizedBox(height: 10),

                ...top100
                    .skip(3)
                    .toList()
                    .asMap()
                    .entries
                    .map(
                  (entry) {
                    final rank =
                        entry.key + 4;

                    final item =
                        entry.value;

                    return _OtherRankingCard(
                      rank: rank,
                      song: item.key,
                      count: item.value,
                      maxCount: maxCount,
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ======================================================
// TOP3カード
// ======================================================

class _TopRankingCard
    extends StatelessWidget {
  final int rank;
  final String song;
  final int count;
  final int maxCount;

  const _TopRankingCard({
    required this.rank,
    required this.song,
    required this.count,
    required this.maxCount,
  });

  // 01・02・03 のように表示
  String get rankNumber {
    return rank
        .toString()
        .padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final ratio =
        count / maxCount;

    final primaryText =
        isDark
            ? Colors.white
            : const Color(0xFF654680);

    final secondaryText =
        isDark
            ? const Color(0xFFD8CBE0)
            : const Color(0xFF887494);

    final accentText =
        isDark
            ? const Color(0xFFD9B9F0)
            : const Color(0xFF8061A8);

    // ==================================================
    // TOPページと同じ1・2・3位カラー
    // ==================================================

    final rankColor =
        rank == 1
            ? const Color(0xFF8061A8)
            : rank == 2
                ? const Color(0xFF9B72B5)
                : const Color(0xFFB99AC9);

    final rankBackground =
        rank == 1
            ? const Color(0xFF8061A8)
            : rank == 2
                ? const Color(0xFF9B72B5)
                : const Color(0xFFB99AC9);

    final countBackground =
        isDark
            ? const Color(0xFF3A3040)
            : const Color(0xFFF5F0FA);

    final progressBackground =
        isDark
            ? const Color(0xFF51465A)
            : const Color(0xFFEDE4F5);

    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(19),

      decoration:
          BoxDecoration(
        color:
            Theme.of(context).cardColor,

        borderRadius:
            BorderRadius.circular(22),

        border:
            Border.all(
          color: Colors.white,
        ),

        boxShadow: [
          BoxShadow(
            color:
                const Color(
              0xFF8061A8,
            ).withOpacity(
              isDark ? 0.15 : 0.07,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            children: [

              // ==========================
              // 順位数字
              // ==========================

              Container(
                width: 53,
                height: 53,

                decoration:
                    BoxDecoration(
                  color: rankBackground,

                  borderRadius:
                      BorderRadius.circular(
                    17,
                  ),
                ),

                child: Center(
                  child: Text(
                    rankNumber,

                    style:
                        GoogleFonts
                            .zenMaruGothic(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 13),

              // ==========================
              // 曲名
              // ==========================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      '$rank位',

                      style:
                          GoogleFonts
                              .zenMaruGothic(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            secondaryText,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      song,

                      maxLines: 2,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          GoogleFonts
                              .zenMaruGothic(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            primaryText,
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================
              // 回数
              // ==========================

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      countBackground,

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child: Text(
                  '$count回',

                  style:
                      GoogleFonts
                          .zenMaruGothic(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        accentText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ==========================
          // バー
          // ==========================

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              20,
            ),

            child:
                LinearProgressIndicator(
              value: ratio,

              minHeight: 7,

              backgroundColor:
                  progressBackground,

              valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                rankColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// 4位以下
// ======================================================

class _OtherRankingCard
    extends StatelessWidget {
  final int rank;
  final String song;
  final int count;
  final int maxCount;

  const _OtherRankingCard({
    required this.rank,
    required this.song,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context)
            .brightness ==
            Brightness.dark;

    final ratio =
        count / maxCount;

    final primaryText =
        isDark
            ? Colors.white
            : const Color(0xFF654680);

    final accentText =
        isDark
            ? const Color(0xFFD9B9F0)
            : const Color(0xFF8061A8);

    final cardBorder =
        isDark
            ? const Color(0xFF51465A)
            : const Color(0xFFE9DDF1);

    final rankBackground =
        isDark
            ? const Color(0xFF332B38)
            : const Color(0xFFF1EAF6);

    final progressBackground =
        isDark
            ? const Color(0xFF51465A)
            : const Color(0xFFF1EAF6);

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 9,
      ),

      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),

      decoration:
          BoxDecoration(
        color:
            Theme.of(context)
                .cardColor,

        borderRadius:
            BorderRadius.circular(17),

        border:
            Border.all(
          color: cardBorder,
        ),
      ),

      child: Column(
        children: [
          Row(
            children: [

              // ==========================
              // 順位
              // ==========================

              Container(
                width: 35,
                height: 35,

                decoration:
                    BoxDecoration(
                  color:
                      rankBackground,

                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),

                child: Center(
                  child: Text(
                    '$rank',

                    style:
                        GoogleFonts
                            .zenMaruGothic(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          accentText,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ==========================
              // 曲名
              // ==========================

              Expanded(
                child: Text(
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
                    color:
                        primaryText,
                  ),
                ),
              ),

              // ==========================
              // 回数
              // ==========================

              Text(
                '$count回',

                style:
                    GoogleFonts
                        .zenMaruGothic(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      accentText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ==========================
          // バー
          // ==========================

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              10,
            ),

            child:
                LinearProgressIndicator(
              value: ratio,

              minHeight: 4,

              backgroundColor:
                  progressBackground,

              valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                accentText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}