/// 성공 아니면 실패. 예외를 `catch (e) {}` 로 삼키지 않기 위한 것 (CLAUDE.md §5).
///
/// 실패는 **사용자에게 보여줄 한국어 문장**을 들고 다닌다. 스택트레이스를 그대로
/// 화면에 뿌리지 않으려면 실패 지점에서 문장을 만들어야 한다.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.failed(String message) = Failed<T>;

  R when<R>({required R Function(T value) ok, required R Function(String message) failed}) {
    return switch (this) {
      Ok<T>(:final value) => ok(value),
      Failed<T>(:final message) => failed(message),
    };
  }

  T? get valueOrNull => this is Ok<T> ? (this as Ok<T>).value : null;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Failed<T> extends Result<T> {
  const Failed(this.message);
  final String message;
}
