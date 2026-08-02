import 'package:drift/drift.dart';

/// 여기 오면 플랫폼 판정이 잘못된 것이다
QueryExecutor openConnection() =>
    throw UnsupportedError('이 플랫폼에서는 데이터베이스를 열 수 없습니다');
