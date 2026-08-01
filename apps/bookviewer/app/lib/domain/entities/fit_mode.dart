/// 쪽을 화면에 어떻게 맞출지 (techspec §6.3).
///
/// 폰 세로 화면에서 **세로 맞춤을 쓰면 좌우가 잘린다.** 쪽이 화면보다 가로로 길기
/// 때문이다. 그래서 기본은 폭 맞춤이고, 세로로 넘치는 부분은 밀어서 읽는다.
enum FitMode {
  /// 폭 맞춤 — 좌우가 잘리지 않는다. 세로로 넘치면 밀어서 본다 (기본)
  width,

  /// 화면 맞춤 — 쪽 전체가 한눈에 들어온다. 글자는 작아진다
  page,

  /// 세로 맞춤 — 세로를 꽉 채운다. 가로가 넘치면 밀어서 본다
  height;

  static FitMode parse(String? v) => switch (v) {
    'page' => FitMode.page,
    'height' => FitMode.height,
    'content' => FitMode.page,
    _ => FitMode.width,
  };

  String get storageValue => name;

  String get label => switch (this) {
    FitMode.width => '폭 맞춤',
    FitMode.page => '화면 맞춤',
    FitMode.height => '세로 맞춤',
  };
}
