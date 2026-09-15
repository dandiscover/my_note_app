// lib/services/richtext_adapter/errors.dart
// 适配层自定义异常

/// 适配层基础异常。
class RichtextAdapterException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  RichtextAdapterException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() {
    if (cause == null) return 'RichtextAdapterException: $message';
    return 'RichtextAdapterException: $message (cause: $cause)';
  }
}

/// 适配器遇到不支持的块类型时抛出。
class UnsupportedBlockTypeException extends RichtextAdapterException {
  final String blockType;
  final String direction;

  UnsupportedBlockTypeException(
    this.blockType,
    this.direction, {
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          '不支持的块类型 "$blockType"（方向：$direction）',
          cause: cause,
          stackTrace: stackTrace,
        );
}

/// 输入 Delta 结构非法时抛出。
///
/// ⚠️ 当前无使用方。第 7 文件 `DeltaToStructure` 的设计原则是
/// "未知块降级，保留用户数据"，不抛异常。
///
/// 保留本类为预留：将来若在**调用层**（编辑器拿到 Delta 前）加输入校验，
/// 可复用本类。届时再由调用层抛出。
///
/// 不要在适配层内部抛本异常——那会破坏"数据不丢"的边界。
class InvalidDeltaException extends RichtextAdapterException {
  final int? opIndex;

  InvalidDeltaException(
    String message, {
    this.opIndex,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          opIndex != null ? '$message（op 索引：$opIndex）' : message,
          cause: cause,
          stackTrace: stackTrace,
        );
}

/// 输入自定义结构非法时抛出。
class InvalidStructureException extends RichtextAdapterException {
  final String? blockId;

  InvalidStructureException(
    String message, {
    this.blockId,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          blockId != null ? '$message（块 id：$blockId）' : message,
          cause: cause,
          stackTrace: stackTrace,
        );
}