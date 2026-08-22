
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarPage extends StatefulWidget {
  final List<List<String>> rows;
  final Future<void> Function(String url) onOpenUrl;

  const CalendarPage({
    super.key,
    required this.rows,
    required this.onOpenUrl,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime? selectedDate;

  final List<int> availableYears = [2025, 2026];

  final Set<String> holidays = {
    '2026-01-01',
    '2026-01-12',
    '2026-02-11',
    '2026-02-23',
    '2026-03-20',
    '2026-04-29',
    '2026-05-03',
    '2026-05-04',
    '2026-05-05',
    '2026-05-06',
    '2026-07-20',
    '2026-08-11',
    '2026-09-21',
    '2026-09-22',
    '2026-09-23',
    '2026-10-12',
    '2026-11-03',
    '2026-11-23',
  };

  void selectYear(int year) {
    setState(() {
      displayedMonth = DateTime(year, 1);
      selectedDate = null;
    });
  }

  String dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime? parseDate(String text) {
    final match = RegExp(
      r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})',
    ).firstMatch(text);

    if (match == null) return null;

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);

    if (year == null || month == null || day == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  List<List<String>> rowsForDate(DateTime date) {
    final key = dateKey(date);

    if (widget.rows.length <= 1) {
      return [];
    }

    return widget.rows.skip(1).where((row) {
      if (row.length <= 2) return false;

      final rowDate = parseDate(row[2]);

      if (rowDate == null) return false;

      return dateKey(rowDate) == key;
    }).toList();
  }

  bool hasSongs(DateTime date) {
    return rowsForDate(date).isNotEmpty;
  }

  String songName(List<String> row) {
    return row.isNotEmpty ? row[0].trim() : '';
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

  void selectDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  void previousMonth() {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month - 1,
      );
      selectedDate = null;
    });
  }

  void nextMonth() {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month + 1,
      );
      selectedDate = null;
    });
  }

  void goToday() {
    final today = DateTime.now();

    setState(() {
      displayedMonth = DateTime(
        today.year,
        today.month,
      );
      selectedDate = today;
    });
  }

  List<DateTime?> buildCalendarDays() {
    final firstDay = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );

    final lastDay = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    );

    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7;

    final List<DateTime?> days = [];

    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }

    for (int day = 1; day <= daysInMonth; day++) {
      days.add(
        DateTime(
          displayedMonth.year,
          displayedMonth.month,
          day,
        ),
      );
    }

    while (days.length % 7 != 0) {
      days.add(null);
    }

    return days;
  }

  TextStyle softText({
    double size = 14,
    FontWeight weight = FontWeight.normal,
    Color? color,
  }) {
    return GoogleFonts.zenMaruGothic(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final today = DateTime.now();

    final selectedSongs = selectedDate == null
        ? <List<String>>[]
        : rowsForDate(selectedDate!);

    final calendarDays = buildCalendarDays();

    final mainTextColor = isDark
        ? Colors.white
        : const Color(0xFF654680);

    final subTextColor = isDark
        ? Colors.white70
        : const Color(0xFF887494);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 700,
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '日付検索',
                    style: softText(
                      size: 28,
                      weight: FontWeight.w900,
                      color: mainTextColor,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ==========================
                // カレンダー
                // ==========================

                Container(
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    12,
                    14,
                    14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF302838)
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(20),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: const Color(
                            0xFF8061A8,
                          ).withOpacity(0.07),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ==========================
                      // 年・月移動
                      // ==========================

                      Column(
                        children: [
                          // 年切り替え
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children:
                                availableYears.map((year) {
                              final isSelectedYear =
                                  displayedMonth.year == year;

                              return Padding(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 4,
                                ),
                                child: ChoiceChip(
                                  label: Text(
                                    '${year}年',
                                    style: softText(
                                      size: 12,
                                      weight:
                                          FontWeight.bold,
                                      color:
                                          isSelectedYear
                                              ? Colors.white
                                              : const Color(
                                                  0xFF8061A8,
                                                ),
                                    ),
                                  ),
                                  selected:
                                      isSelectedYear,
                                  selectedColor:
                                      const Color(
                                    0xFF8061A8,
                                  ),
                                  backgroundColor:
                                      isDark
                                          ? const Color(
                                              0xFF493B50,
                                            )
                                          : const Color(
                                              0xFFF0E8F6,
                                            ),
                                  side: BorderSide.none,
                                  onSelected: (_) {
                                    selectYear(year);
                                  },
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 6),

                          // 月移動
                          Row(
                            children: [
                              IconButton(
                                visualDensity:
                                    VisualDensity.compact,
                                onPressed:
                                    previousMonth,
                                icon: const Icon(
                                  Icons
                                      .chevron_left_rounded,
                                ),
                                color:
                                    const Color(0xFF8061A8),
                              ),

                              Expanded(
                                child: Center(
                                  child: Text(
                                    '${displayedMonth.month}月',
                                    style: softText(
                                      size: 19,
                                      weight:
                                          FontWeight.w900,
                                      color:
                                          mainTextColor,
                                    ),
                                  ),
                                ),
                              ),

                              IconButton(
                                visualDensity:
                                    VisualDensity.compact,
                                onPressed:
                                    nextMonth,
                                icon: const Icon(
                                  Icons
                                      .chevron_right_rounded,
                                ),
                                color:
                                    const Color(0xFF8061A8),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // ==========================
                      // 今日ボタン
                      // ==========================

                      Align(
                        alignment:
                            Alignment.centerRight,
                        child: SizedBox(
                          height: 30,
                          child: OutlinedButton(
                            onPressed: goToday,
                            style:
                                OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color(
                                0xFF8061A8,
                              ),
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 12,
                              ),
                              side:
                                  const BorderSide(
                                color:
                                    Color(0xFFD5C4E4),
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(10),
                              ),
                            ),
                            child: Text(
                              '今日',
                              style: softText(
                                size: 12,
                                weight:
                                    FontWeight.bold,
                                color:
                                    const Color(
                                  0xFF8061A8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ==========================
                      // 曜日
                      // ==========================

                      Row(
                        children: [
                          _Weekday(
                            text: '日',
                            color:
                                Colors.pink.shade300,
                          ),
                          const _Weekday(text: '月'),
                          const _Weekday(text: '火'),
                          const _Weekday(text: '水'),
                          const _Weekday(text: '木'),
                          const _Weekday(text: '金'),
                          _Weekday(
                            text: '土',
                            color:
                                Colors.blue.shade300,
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // ==========================
                      // 日付
                      // ==========================

                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount:
                            calendarDays.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 3,
                          crossAxisSpacing: 3,
                          childAspectRatio: 1.15,
                        ),
                        itemBuilder:
                            (context, index) {
                          final date =
                              calendarDays[index];

                          if (date == null) {
                            return const SizedBox();
                          }

                          final key = dateKey(date);

                          final isToday =
                              dateKey(today) == key;

                          final isSelected =
                              selectedDate != null &&
                                  dateKey(
                                        selectedDate!,
                                      ) ==
                                      key;

                          final isHoliday =
                              holidays.contains(key);

                          final hasSong =
                              hasSongs(date);

                          final weekday =
                              date.weekday;

                          Color textColor;

                          if (isHoliday ||
                              weekday == 7) {
                            textColor =
                                Colors.pink.shade400;
                          } else if (weekday == 6) {
                            textColor =
                                Colors.blue.shade400;
                          } else {
                            textColor = isDark
                                ? Colors.white
                                : const Color(
                                    0xFF5F5666,
                                  );
                          }

                          return GestureDetector(
                            onTap: () =>
                                selectDate(date),
                            child:
                                AnimatedContainer(
                              duration:
                                  const Duration(
                                milliseconds: 150,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: isSelected
                                    ? const Color(
                                        0xFF8061A8,
                                      )
                                    : hasSong
                                        ? const Color(
                                            0xFFF0E8F6,
                                          )
                                        : Colors
                                            .transparent,
                                borderRadius:
                                    BorderRadius
                                        .circular(12),
                                border:
                                    isToday &&
                                            !isSelected
                                        ? Border.all(
                                            color:
                                                const Color(
                                              0xFF8061A8,
                                            ),
                                            width: 1.5,
                                          )
                                        : null,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Text(
                                    '${date.day}',
                                    style: softText(
                                      size: 13,
                                      weight:
                                          isToday ||
                                                  hasSong
                                              ? FontWeight
                                                  .w800
                                              : FontWeight
                                                  .normal,
                                      color: isSelected
                                          ? Colors.white
                                          : textColor,
                                    ),
                                  ),

                                  if (hasSong)
                                    Container(
                                      width: 4,
                                      height: 4,
                                      margin:
                                          const EdgeInsets
                                              .only(
                                        top: 2,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            isSelected
                                                ? Colors
                                                    .white
                                                : const Color(
                                                    0xFF8061A8,
                                                  ),
                                        shape:
                                            BoxShape
                                                .circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      // ==========================
// 凡例
// ==========================

const _Legend(
  color: Color(0xFF8061A8),
  text: '歌枠あり',
),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ==========================
                // 選択日の曲
                // ==========================

                if (selectedDate != null)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF302838)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedDate!.year}年'
                          '${selectedDate!.month}月'
                          '${selectedDate!.day}日の歌枠',
                          style: softText(
                            size: 18,
                            weight: FontWeight.w900,
                            color: mainTextColor,
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (selectedSongs.isEmpty)
                          Text(
                            'この日の記録はありません。',
                            style: softText(
                              size: 13,
                              color: subTextColor,
                            ),
                          )
                        else
                          ...selectedSongs.map(
                            (row) => _SongTile(
                              song: songName(row),
                              streamTitle:
                                  streamTitle(row),
                              timestamp:
                                  timestamp(row),
                              onPlay:
                                  playUrl(row).isEmpty
                                      ? null
                                      : () =>
                                          widget
                                              .onOpenUrl(
                                            playUrl(row),
                                          ),
                              onStream:
                                  streamUrl(row).isEmpty
                                      ? null
                                      : () =>
                                          widget
                                              .onOpenUrl(
                                            streamUrl(row),
                                          ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================
// 曜日
// ======================================================

class _Weekday extends StatelessWidget {
  final String text;
  final Color? color;

  const _Weekday({
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.zenMaruGothic(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color:
                color ?? const Color(0xFF8061A8),
          ),
        ),
      ),
    );
  }
}

// ======================================================
// 凡例
// ======================================================

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.zenMaruGothic(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white70
                : const Color(0xFF5F5666),
          ),
        ),
      ],
    );
  }
}

// ======================================================
// 曲タイル
// ======================================================

class _SongTile extends StatelessWidget {
  final String song;
  final String streamTitle;
  final String timestamp;
  final VoidCallback? onPlay;
  final VoidCallback? onStream;

  const _SongTile({
    required this.song,
    required this.streamTitle,
    required this.timestamp,
    this.onPlay,
    this.onStream,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF3A3142)
            : const Color(0xFFF7F3F9),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.music_note,
            size: 20,
            color: Color(0xFF8061A8),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  song,
                  style:
                      GoogleFonts.zenMaruGothic(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? Colors.white
                        : const Color(
                            0xFF403747,
                          ),
                  ),
                ),

                if (streamTitle.isNotEmpty)
                  Text(
                    streamTitle,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        GoogleFonts.zenMaruGothic(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w500,
                      color: isDark
                          ? Colors.white70
                          : const Color(
                              0xFF887494,
                            ),
                    ),
                  ),

                if (timestamp.isNotEmpty)
                  Text(
                    timestamp,
                    style:
                        GoogleFonts.zenMaruGothic(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w500,
                      color: isDark
                          ? Colors.white70
                          : const Color(
                              0xFF887494,
                            ),
                    ),
                  ),
              ],
            ),
          ),

          if (onPlay != null)
            IconButton(
              visualDensity:
                  VisualDensity.compact,
              onPressed: onPlay,
              icon: const Icon(
                Icons.play_circle_outline,
              ),
              color:
                  const Color(0xFF8061A8),
              tooltip: '再生',
            ),

          if (onStream != null)
            IconButton(
              visualDensity:
                  VisualDensity.compact,
              onPressed: onStream,
              icon: const Icon(
                Icons.open_in_new,
              ),
              color:
                  const Color(0xFF8061A8),
              tooltip: '配信を見る',
            ),
        ],
      ),
    );
  }
}