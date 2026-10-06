// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidationErrorBody _$ValidationErrorBodyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ValidationErrorBody', json, ($checkedConvert) {
      final val = ValidationErrorBody(
        detail: $checkedConvert(
          'detail',
          (v) => (v as List<dynamic>)
              .map(
                (e) => ValidationErrorItem.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

ValidationErrorItem _$ValidationErrorItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ValidationErrorItem', json, ($checkedConvert) {
      final val = ValidationErrorItem(
        loc: $checkedConvert(
          'loc',
          (v) => (v as List<dynamic>).map((e) => e as Object).toList(),
        ),
        type: $checkedConvert('type', (v) => v as String),
      );
      return val;
    });

ConflictErrorBody _$ConflictErrorBodyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ConflictErrorBody', json, ($checkedConvert) {
      final val = ConflictErrorBody(
        detail: $checkedConvert(
          'detail',
          (v) => ConflictErrorDetail.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

ConflictErrorDetail _$ConflictErrorDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ConflictErrorDetail', json, ($checkedConvert) {
      final val = ConflictErrorDetail(
        message: $checkedConvert('message', (v) => v as String),
      );
      return val;
    });
