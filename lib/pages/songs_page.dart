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

  String songName(List<String> row) {
    return row.isNotEmpty ? row[0] : '';
  }

  String reading(List<String> row) {
    return row.length > 1 ? row[1] : '';
  }

  String date(List<String> row) {
    return row.length > 2 ? row[2] : '';
  }

  String streamTitle(List<String> row) {
    return row.length > 3 ? row[3] : '';
  }

  String streamUrl(List<String> row) {
    return row.length > 4 ? row[4] : '';
  }

  String timestamp(List<String> row) {
    return row.length > 5 ? row[5] : '';
  }

  String playUrl(List<String> row) {
    return row.length > 7 ? row[7] : '';
  }

  void showSongDetail(List<String> row) {
    final song = songName(row);

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
        final isFavorite =
            widget.favorites.contains(song);

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
                          ? const Color(0xFF45384D)
                          : const Color(0xFFE9DDF1),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Color(0xFF8061A8),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      song,
                      style:
                          GoogleFonts.zenMaruGothic(
                        fontSize: 24,
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

                      setState(() {});
                    },
                    icon: Icon(
                      isFavorite
                          ? Icons.star
                          : Icons.star_border,
                      color: isFavorite
                          ? Colors.amber
                          : const Color(
                              0xFF8061A8,
                            ),
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
                          : () {
                              widget.onOpenUrl(
                                playUrl(row),
                              );
                            },
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    'この曲を聴く',
                    style:
                        GoogleFonts.zenMaruGothic(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF8061A8),
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
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
                  child: OutlinedButton.icon(
                    onPressed: () {
                      widget.onOpenUrl(
                        streamUrl(row),
                      );
                    },
                    icon: const Icon(
                      Icons.open_in_new,
                    ),
                    label: Text(
                      '配信を見る',
                      style:
                          GoogleFonts.zenMaruGothic(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(
                        0xFF8061A8,
                      ),
                      side: const BorderSide(
                        color: Color(
                          0xFFD5C4E4,
                        ),
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
    final query =
        searchController.text.trim().toLowerCase();

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final songs =
        widget.rows.length <= 1
            ? <List<String>>[]
            : widget.rows
                .skip(1)
                .where((row) {
                  final name =
                      songName(row).toLowerCase();

                  final kana =
                      reading(row).toLowerCase();

                  final matchesSearch =
                      query.isEmpty ||
                          name.contains(query) ||
                          kana.contains(query);

                  final matchesFavorite =
                      !favoritesOnly ||
                          widget.favorites.contains(
                            songName(row),
                          );

                  return matchesSearch &&
                      matchesFavorite;
                })
                .toList();

    return Column(
      children: [
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
                            searchController
                                .clear();
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

        Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          child: Row(
            children: [
              Text(
                '${songs.length}曲',
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
                        const Color(
                      0xFF8061A8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: songs.isEmpty
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
                    itemCount: songs.length,
                    itemBuilder:
                        (context, index) {
                      final row =
                          songs[index];

                      final song =
                          songName(row);

                      final isFavorite =
                          widget.favorites
                              .contains(song);

                      return Card(
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
                                  Color(
                                0xFF8061A8,
                              ),
                            ),
                          ),
                          title: Text(
                            song,
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
                          trailing:
                              IconButton(
                            onPressed: () {
                              widget
                                  .onToggleFavorite(
                                song,
                              );
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
                          onTap: () {
                            showSongDetail(row);
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

class _InfoRow extends StatelessWidget {
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
          const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: const Color(0xFF8061A8),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style:
                  GoogleFonts.zenMaruGothic(
                fontSize: 16,
                fontWeight: FontWeight.w500,
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
    );
  }
}