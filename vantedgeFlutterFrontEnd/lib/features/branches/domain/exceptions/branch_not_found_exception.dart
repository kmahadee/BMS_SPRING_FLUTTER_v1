import 'package:vantedge/core/exceptions/api_exceptions.dart';

/// Exception thrown when a branch is not found in the system
/// 
/// This exception is typically thrown when attempting to access
/// a branch that doesn't exist or is not accessible.
class BranchNotFoundException extends NotFoundException {
  /// The branch ID that was not found
  final int? branchId;
  
  /// The branch code that was not found
  final String? branchCode;
  
  /// The IFSC code that was not found
  final String? ifscCode;

  const BranchNotFoundException({
    super.message = 'Branch not found',
    this.branchId,
    this.branchCode,
    this.ifscCode,
    super.data,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('BranchNotFoundException: $message');
    if (branchId != null) {
      buffer.write(' (Branch ID: $branchId)');
    }
    if (branchCode != null) {
      buffer.write(' (Branch Code: $branchCode)');
    }
    if (ifscCode != null) {
      buffer.write(' (IFSC: $ifscCode)');
    }
    if (data != null) {
      buffer.write('\nAdditional Data: $data');
    }
    return buffer.toString();
  }

  /// Create BranchNotFoundException with custom message
  factory BranchNotFoundException.withMessage(String message, {
    int? branchId,
    String? branchCode,
    String? ifscCode,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return BranchNotFoundException(
      message: message,
      branchId: branchId,
      branchCode: branchCode,
      ifscCode: ifscCode,
      data: data,
      stackTrace: stackTrace,
    );
  }

  /// Create BranchNotFoundException for specific branch ID
  factory BranchNotFoundException.forBranchId(int branchId, {
    String? customMessage,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return BranchNotFoundException(
      message: customMessage ?? 'Branch with ID $branchId not found',
      branchId: branchId,
      data: data,
      stackTrace: stackTrace,
    );
  }

  /// Create BranchNotFoundException for specific branch code
  factory BranchNotFoundException.forBranchCode(String branchCode, {
    String? customMessage,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return BranchNotFoundException(
      message: customMessage ?? 'Branch with code $branchCode not found',
      branchCode: branchCode,
      data: data,
      stackTrace: stackTrace,
    );
  }

  /// Create BranchNotFoundException for specific IFSC code
  factory BranchNotFoundException.forIfscCode(String ifscCode, {
    String? customMessage,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return BranchNotFoundException(
      message: customMessage ?? 'Branch with IFSC code $ifscCode not found',
      ifscCode: ifscCode,
      data: data,
      stackTrace: stackTrace,
    );
  }
}