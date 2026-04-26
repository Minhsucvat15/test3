import 'package:flutter/material.dart';

/// Theo dõi route hiện tại trên cùng của Navigator để các widget overlay
/// (như MiniPlayer) có thể quyết định hiển thị/ẩn.
class AppRouteTracker extends NavigatorObserver {
  AppRouteTracker._();
  static final instance = AppRouteTracker._();

  final ValueNotifier<String?> currentName = ValueNotifier(null);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentName.value = route.settings.name;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentName.value = previousRoute?.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    currentName.value = newRoute?.settings.name;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentName.value = previousRoute?.settings.name;
  }
}
