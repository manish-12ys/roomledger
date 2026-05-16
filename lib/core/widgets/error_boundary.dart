import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_components.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space400),
            child: GlassCard(
              accentColor: AppTheme.error,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.error,
                    size: 64,
                  ),
                  const AppSpacing.vertical(AppTheme.space300),
                  Text(
                    'Something went wrong',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.error,
                        ),
                  ),
                  const AppSpacing.vertical(AppTheme.space200),
                  Text(
                    'The application encountered an unexpected error and couldn\'t continue.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const AppSpacing.vertical(AppTheme.space300),
                  ActionButton(
                    label: 'Try Again',
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _stackTrace = null;
                      });
                    },
                    variant: ActionButtonVariant.primary,
                  ),
                  const AppSpacing.vertical(AppTheme.space150),
                  ActionButton(
                    label: 'Show Details',
                    icon: Icons.code_rounded,
                    onPressed: () {
                      _showErrorDetails(context);
                    },
                    variant: ActionButtonVariant.ghost,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  void _showErrorDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceVariant,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.bug_report_outlined, color: AppTheme.error),
                  const SizedBox(width: 12),
                  Text(
                    'Error Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Text(
                    _error.toString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: AppTheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _stackTrace.toString(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Global error builder to catch exceptions during build phase
class GlobalErrorCatch {
  static void initialize() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return _GlobalErrorScreen(details: details);
    };
  }
}

class _GlobalErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;

  const _GlobalErrorScreen({required this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space400),
          child: GlassCard(
            accentColor: AppTheme.error,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.error,
                  size: 64,
                ),
                const AppSpacing.vertical(AppTheme.space300),
                Text(
                  'UI Render Error',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.error,
                      ),
                ),
                const AppSpacing.vertical(AppTheme.space200),
                Text(
                  'A component failed to render correctly. This is likely a developer error.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const AppSpacing.vertical(AppTheme.space300),
                ActionButton(
                  label: 'Back to Safety',
                  icon: Icons.home_rounded,
                  onPressed: () {
                    // Try to navigate back or restart
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  variant: ActionButtonVariant.primary,
                ),
                const AppSpacing.vertical(AppTheme.space150),
                ActionButton(
                  label: 'View Crash Log',
                  icon: Icons.code_rounded,
                  onPressed: () {
                    _showErrorDetails(context);
                  },
                  variant: ActionButtonVariant.ghost,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceVariant,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.bug_report_outlined, color: AppTheme.error),
                  const SizedBox(width: 12),
                  Text(
                    'Crash Log',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Text(
                    details.exceptionAsString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: AppTheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    details.stack.toString(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
