import 'package:flutter/material.dart';
import 'loading_view.dart';
import 'error_view.dart';

/// Standard "fetch → loading / error / data" screen body used across every
/// role's pages, with pull-to-refresh baked in. Mirrors the repeated
/// `useEffect(() => fetch().then(setData).catch(setError).finally(...))`
/// pattern from the web app's pages.
class AsyncScreen<T> extends StatefulWidget {
  final Future<T> Function() loader;
  final Widget Function(BuildContext context, T data, Future<void> Function() refresh) builder;
  final bool scrollableOnError;
  final WidgetBuilder? loadingBuilder;

  const AsyncScreen({super.key, required this.loader, required this.builder, this.scrollableOnError = true, this.loadingBuilder});

  @override
  State<AsyncScreen<T>> createState() => _AsyncScreenState<T>();
}

class _AsyncScreenState<T> extends State<AsyncScreen<T>> {
  late Future<T> _future = widget.loader();

  Future<void> _refresh() async {
    final next = widget.loader();
    setState(() {
      _future = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ?? const LoadingView();
        }
        if (snap.hasError) {
          return ErrorView(message: snap.error.toString().replaceFirst('ApiException: ', ''), onRetry: _refresh);
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          color: Theme.of(context).colorScheme.primary,
          child: widget.builder(context, snap.data as T, _refresh),
        );
      },
    );
  }
}
