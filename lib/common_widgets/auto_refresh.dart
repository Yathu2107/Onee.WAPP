import 'dart:async';

import 'package:flutter/material.dart';

/// Global observer — register on [GetMaterialApp.navigatorObservers].
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// Calls [onRefresh] when the route is first shown and whenever the user
/// navigates back to it.
class AutoRefresh extends StatefulWidget {
  const AutoRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final FutureOr<void> Function() onRefresh;
  final Widget child;

  @override
  State<AutoRefresh> createState() => _AutoRefreshState();
}

class _AutoRefreshState extends State<AutoRefresh> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    unawaited(Future.sync(widget.onRefresh));
  }

  @override
  void didPopNext() {
    unawaited(Future.sync(widget.onRefresh));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
