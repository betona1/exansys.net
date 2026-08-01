/// 리딩 테마 (SPEC §2.1 · techspec §8)
enum ReadingTheme {
  light,
  dark,
  sepia,

  /// 시스템 설정을 따른다
  system;

  static ReadingTheme parse(String? v) => switch (v) {
    'light' => ReadingTheme.light,
    'dark' => ReadingTheme.dark,
    'sepia' => ReadingTheme.sepia,
    _ => ReadingTheme.system,
  };

  String get storageValue => name;

  String get label => switch (this) {
    ReadingTheme.light => '라이트',
    ReadingTheme.dark => '다크',
    ReadingTheme.sepia => '세피아',
    ReadingTheme.system => '시스템 따름',
  };
}
