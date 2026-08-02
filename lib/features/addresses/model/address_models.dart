import '../../../utils/json_helpers.dart';

class SavedAddress {
  const SavedAddress({
    required this.id,
    this.label,
    this.addressLine,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final int id;
  final String? label;
  final String? addressLine;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: JsonHelpers.pickInt(json, ['id', 'Id']) ?? 0,
      label: JsonHelpers.pickString(json, ['label', 'Label']),
      addressLine: JsonHelpers.pickString(json, [
        'address_Line',
        'addressLine',
        'Address_Line',
      ]),
      latitude: JsonHelpers.pickDouble(json, ['latitude', 'Latitude']),
      longitude: JsonHelpers.pickDouble(json, ['longitude', 'Longitude']),
      isDefault:
          JsonHelpers.pickBool(json, ['is_Default', 'isDefault', 'Is_Default']) ??
              false,
    );
  }
}
