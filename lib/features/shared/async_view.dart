import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/strings.dart';

/// Loading / error / data for an AsyncValue with a Metro retry action.
class AsyncView<T> extends ConsumerWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.loading,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return value.when(
      data: builder,
      loading: () =>
          loading ??
          const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2, color: Mt.dim),
            ),
          ),
      error: (_, __) => EmptyState(
        message: S.error,
        actionLabel: onRetry == null ? null : 'try again',
        onAction: onRetry,
      ),
    );
  }
}
