import 'package:json_annotation/json_annotation.dart';

part 'api_error.g.dart';

@JsonSerializable(createToJson: false, checked: true)
final class ValidationErrorBody {
  const ValidationErrorBody({required this.detail});

  factory ValidationErrorBody.fromJson(Map<String, dynamic> json) =>
      _$ValidationErrorBodyFromJson(json);

  final List<ValidationErrorItem> detail;

  static ValidationErrorBody? tryParse(Object? json) =>
      _tryParse(json, ValidationErrorBody.fromJson);
}

@JsonSerializable(createToJson: false, checked: true)
final class ValidationErrorItem {
  const ValidationErrorItem({required this.loc, required this.type});

  factory ValidationErrorItem.fromJson(Map<String, dynamic> json) =>
      _$ValidationErrorItemFromJson(json);

  final List<Object> loc;
  final String type;

  String? get field => switch (loc) {
    [_, final String field, ...] => field,
    _ => null,
  };
}

@JsonSerializable(createToJson: false, checked: true)
final class ConflictErrorBody {
  const ConflictErrorBody({required this.detail});

  factory ConflictErrorBody.fromJson(Map<String, dynamic> json) =>
      _$ConflictErrorBodyFromJson(json);

  final ConflictErrorDetail detail;

  static ConflictErrorBody? tryParse(Object? json) =>
      _tryParse(json, ConflictErrorBody.fromJson);
}

@JsonSerializable(createToJson: false, checked: true)
final class ConflictErrorDetail {
  const ConflictErrorDetail({required this.message});

  factory ConflictErrorDetail.fromJson(Map<String, dynamic> json) =>
      _$ConflictErrorDetailFromJson(json);

  final String message;
}

T? _tryParse<T>(Object? json, T Function(Map<String, dynamic> json) fromJson) {
  if (json is! Map<String, dynamic>) return null;
  try {
    return fromJson(json);
  } on CheckedFromJsonException {
    return null;
  }
}
