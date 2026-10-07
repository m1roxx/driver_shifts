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

T? _tryParse<T>(Object? json, T Function(Map<String, dynamic> json) fromJson) {
  if (json is! Map<String, dynamic>) return null;
  try {
    return fromJson(json);
  } on CheckedFromJsonException {
    return null;
  }
}
