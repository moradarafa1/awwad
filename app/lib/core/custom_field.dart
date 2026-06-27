// User-customizable tracking field (add/edit/hide/reorder). P1 local; syncs to
// custom_field_defs/options in P2.

class CustomField {
  final String id;
  final String group; // competing_response | environment_action | mood
  final String label;
  final String? emoji;
  final bool hidden;
  final bool isSystem;
  final int sortOrder;

  const CustomField({
    required this.id,
    required this.group,
    required this.label,
    this.emoji,
    this.hidden = false,
    this.isSystem = false,
    this.sortOrder = 0,
  });

  CustomField copyWith({String? label, String? emoji, bool? hidden, int? sortOrder}) =>
      CustomField(
        id: id,
        group: group,
        label: label ?? this.label,
        emoji: emoji ?? this.emoji,
        hidden: hidden ?? this.hidden,
        isSystem: isSystem,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'group': group,
        'label': label,
        'emoji': emoji,
        'hidden': hidden,
        'isSystem': isSystem,
        'sortOrder': sortOrder,
      };

  factory CustomField.fromJson(Map<String, dynamic> j) => CustomField(
        id: j['id'] as String,
        group: j['group'] as String,
        label: j['label'] as String,
        emoji: j['emoji'] as String?,
        hidden: j['hidden'] as bool? ?? false,
        isSystem: j['isSystem'] as bool? ?? false,
        sortOrder: j['sortOrder'] as int? ?? 0,
      );
}
