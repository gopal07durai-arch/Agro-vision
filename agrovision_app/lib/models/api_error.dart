/// Typed API error returned from the FastAPI backend or network layer.
enum ApiErrorType {
  invalidImage,
  notLeaf,
  lowImageQuality,
  modelUnavailable,
  lowCropConfidence,
  lowDiseaseConfidence,
  unsupportedCrop,
  serverError,
  networkError,
  noInternet,
  timeout,
  backendStarting,
  unknown,
}

class ApiError implements Exception {
  final ApiErrorType type;
  final String message;
  final String? errorCode;
  final int? statusCode;

  const ApiError({
    required this.type,
    required this.message,
    this.errorCode,
    this.statusCode,
  });

  factory ApiError.fromErrorType(String errorType, String message,
      {int? statusCode}) {
    ApiErrorType type;
    switch (errorType.toUpperCase()) {
      case 'INVALID_IMAGE':
        type = ApiErrorType.invalidImage;
        break;
      case 'NOT_LEAF':
      case 'UNSUPPORTED_IMAGE':
        type = ApiErrorType.notLeaf;
        break;
      case 'LOW_IMAGE_QUALITY':
        type = ApiErrorType.lowImageQuality;
        break;
      case 'MODEL_UNAVAILABLE':
        type = ApiErrorType.modelUnavailable;
        break;
      case 'LOW_CROP_CONFIDENCE':
        type = ApiErrorType.lowCropConfidence;
        break;
      case 'LOW_DISEASE_CONFIDENCE':
        type = ApiErrorType.lowDiseaseConfidence;
        break;
      case 'UNSUPPORTED_CROP':
        type = ApiErrorType.unsupportedCrop;
        break;
      case 'NO_INTERNET':
        type = ApiErrorType.noInternet;
        break;
      case 'SERVER_ERROR':
        type = ApiErrorType.serverError;
        break;
      case 'NETWORK_ERROR':
        type = ApiErrorType.networkError;
        break;
      case 'TIMEOUT':
        type = ApiErrorType.timeout;
        break;
      case 'BACKEND_STARTING':
        type = ApiErrorType.backendStarting;
        break;
      default:
        type = ApiErrorType.unknown;
    }
    return ApiError(
      type: type,
      message: message,
      errorCode: errorType,
      statusCode: statusCode,
    );
  }

  /// No internet connection or network unavailable.
  factory ApiError.noInternet() => const ApiError(
        type: ApiErrorType.noInternet,
        errorCode: 'NO_INTERNET',
        message:
            'No internet connection.\n\n'
            'Please check your mobile data or Wi-Fi connection and try again.',
      );

  /// Backend is completely unreachable.
  factory ApiError.network([String? backendUrl]) => const ApiError(
        type: ApiErrorType.networkError,
        errorCode: 'NETWORK_ERROR',
        message:
            'Cannot connect to the AgroVision AI cloud server.\n\n'
            'Please check your internet connection or try again in a moment.',
      );

  /// Server was reached but took too long to respond.
  factory ApiError.timeout([String? backendUrl]) => const ApiError(
        type: ApiErrorType.timeout,
        errorCode: 'TIMEOUT',
        message:
            'The server took too long to respond.\n\n'
            'Please check your network signal and try again.',
      );

  /// Backend returned 503 — still initializing models.
  factory ApiError.backendStarting() => const ApiError(
        type: ApiErrorType.backendStarting,
        errorCode: 'BACKEND_STARTING',
        message:
            'The cloud AI service is warming up.\n'
            'Please wait a few moments and try again.',
      );

  /// Unsupported or non-leaf image.
  factory ApiError.unsupportedImage() => const ApiError(
        type: ApiErrorType.notLeaf,
        errorCode: 'UNSUPPORTED_IMAGE',
        message: 'The uploaded image is not a supported crop leaf. Please photograph a clear single leaf of a supported crop.',
      );

  /// True for errors caused by the uploaded image (user-fixable).
  bool get isUserError => [
        ApiErrorType.invalidImage,
        ApiErrorType.notLeaf,
        ApiErrorType.lowImageQuality,
        ApiErrorType.lowCropConfidence,
        ApiErrorType.lowDiseaseConfidence,
        ApiErrorType.unsupportedCrop,
      ].contains(type);

  /// True for errors caused by network / server (not the user's image).
  bool get isNetworkError => [
        ApiErrorType.networkError,
        ApiErrorType.noInternet,
        ApiErrorType.timeout,
        ApiErrorType.backendStarting,
        ApiErrorType.modelUnavailable,
        ApiErrorType.serverError,
      ].contains(type);

  @override
  String toString() => 'ApiError[$type]: $message';
}
