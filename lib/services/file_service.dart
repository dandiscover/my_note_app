// lib/services/file_service.dart
// 统一导出入口 — 根据平台自动选择实现

// ✅ 条件导出：Web 端用 web 实现，桌面端用 stub
export 'file_service_web.dart'
    if (dart.library.io) 'file_service_stub.dart';

// ✅ 同时导出接口，方便类型声明
export 'file_service_interface.dart';