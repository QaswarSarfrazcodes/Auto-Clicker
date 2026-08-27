import 'package:flutter/foundation.dart';

/// Central Failure model for domain boundaries (§9.1 in PERFORMANCE_AND_EFFICIENCY.md).
@immutable
sealed class Failure {
  const Failure(this.message);

  final String message;

  const factory Failure.storage(String message) = StorageFailure;
  const factory Failure.validation(String message) = ValidationFailure;
  const factory Failure.permissionDenied([String message]) = PermissionDeniedFailure;
  const factory Failure.platformUnsupported(String reason) = PlatformUnsupportedFailure;
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure([super.message = 'Permission denied']);
}

final class PlatformUnsupportedFailure extends Failure {
  const PlatformUnsupportedFailure(super.message);
}

/// Generic Result type for explicit, non-throwing error handling.
@immutable
sealed class Result<F extends Failure, S> {
  const Result();

  const factory Result.success(S data) = Success<F, S>;
  const factory Result.failure(F failure) = FailureResult<F, S>;

  bool get isSuccess => this is Success<F, S>;
  bool get isFailure => this is FailureResult<F, S>;

  S? get dataOrNull => switch (this) {
        Success(:final data) => data,
        FailureResult() => null,
      };

  F? get failureOrNull => switch (this) {
        Success() => null,
        FailureResult(:final failure) => failure,
      };
}

final class Success<F extends Failure, S> extends Result<F, S> {
  const Success(this.data);
  final S data;
}

final class FailureResult<F extends Failure, S> extends Result<F, S> {
  const FailureResult(this.failure);
  final F failure;
}
