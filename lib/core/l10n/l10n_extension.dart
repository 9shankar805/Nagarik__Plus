import 'package:flutter/material.dart';
import 'package:nagarik_plus/core/l10n/app_localizations.dart';

/// Shorthand extension so widgets can use `context.l10n.key`
/// instead of `AppLocalizations.of(context).key`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
