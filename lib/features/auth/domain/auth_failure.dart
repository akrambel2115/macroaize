sealed class AuthFailure {
  const AuthFailure();
}

class NetworkFailure extends AuthFailure {
  final String message;
  const NetworkFailure(this.message);
}

class CredentialFailure extends AuthFailure {
  final String code;
  final String message;
  const CredentialFailure(this.code, this.message);
}

class UnknownFailure extends AuthFailure {
  final String message;
  const UnknownFailure(this.message);
}
