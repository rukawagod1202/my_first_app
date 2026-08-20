import 'package:flutter/material.dart';

class TopPage extends StatelessWidget {
  final int songCount;
  final int favoriteCount;

  const TopPage({
    super.key,
    required this.songCount,
    required this.favoriteCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),

      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 900,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const SizedBox(
                height: 20,
              ),

              // タイトル
              Text(
                '歌枠まとめ',

                style:
                    TextStyle(
                  fontSize: 38,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      isDark
                          ? const Color(
                              0xFFD6BFE8,
                            )
                          : const Color(
                              0xFF654680,
                            ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                '歌枠で歌われた曲をまとめています。',

                style:
                    TextStyle(
                  fontSize: 15,
                  color:
                      isDark
                          ? Colors.white70
                          : const Color(
                              0xFF887494,
                            ),
                ),
              ),

              const SizedBox(
                height: 40,
              ),

              // 統計カード
              Row(
                children: [
                  Expanded(
                    child:
                        _InfoCard(
                      icon:
                          Icons.music_note,
                      title:
                          '登録曲数',
                      value:
                          '$songCount 曲',
                    ),
                  ),

                  const SizedBox(
                    width: 16,
                  ),

                  Expanded(
                    child:
                        _InfoCard(
                      icon:
                          Icons.star_border,
                      title:
                          'お気に入り',
                      value:
                          '$favoriteCount 曲',
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 32,
              ),

              // 説明
              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  24,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      isDark
                          ? const Color(
                              0xFF302838,
                            )
                          : Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      'このサイトについて',

                      style:
                          TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            isDark
                                ? const Color(
                                    0xFFD6BFE8,
                                  )
                                : const Color(
                                    0xFF76539B,
                                  ),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Text(
                      '歌枠で歌われた曲を検索したり、'
                      '配信日から探したり、'
                      '歌った回数のランキングを見ることができます。',
                      style:
                          TextStyle(
                        height: 1.7,
                        color:
                            isDark
                                ? Colors.white70
                                : const Color(
                                    0xFF655C6B,
                                  ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // シンプルな案内
              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  24,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      isDark
                          ? const Color(
                              0xFF302838,
                            )
                          : const Color(
                              0xFFF0E8F6,
                            ),

                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                ),

                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color:
                          isDark
                              ? const Color(
                                  0xFFD6BFE8,
                                )
                              : const Color(
                                  0xFF8061A8,
                                ),
                      size: 28,
                    ),

                    const SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child: Text(
                        '曲一覧から、'
                        '好きな曲を探してみてね。',

                        style:
                            TextStyle(
                          fontSize: 15,
                          color:
                              isDark
                                  ? Colors
                                      .white70
                                  : const Color(
                                      0xFF655C6B,
                                    ),
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
    );
  }
}

class _InfoCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
      BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      padding:
          const EdgeInsets.all(22),

      decoration:
          BoxDecoration(
        color:
            isDark
                ? const Color(
                    0xFF302838,
                  )
                : Colors.white,

        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,

            decoration:
                BoxDecoration(
              color:
                  isDark
                      ? const Color(
                          0xFF4A3A55,
                        )
                      : const Color(
                          0xFFE9DDF1,
                        ),

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child: Icon(
              icon,

              color:
                  isDark
                      ? const Color(
                          0xFFD6BFE8,
                        )
                      : const Color(
                          0xFF8061A8,
                        ),
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  title,

                  style:
                      TextStyle(
                    fontSize: 13,
                    color:
                        isDark
                            ? Colors
                                .white60
                            : const Color(
                                0xFF887494,
                              ),
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  value,

                  style:
                      TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        isDark
                            ? const Color(
                                0xFFD6BFE8,
                              )
                            : const Color(
                                0xFF654680,
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