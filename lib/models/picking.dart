class Picking {
  final int id;
  final String name;
  final String scheduledDate;
  final List<dynamic> partnerId;
  final String state;
  final String? origin;
  final List<dynamic> pickingTypeId;

  Picking({
    required this.id,
    required this.name,
    required this.scheduledDate,
    required this.partnerId,
    required this.state,
    this.origin,
    required this.pickingTypeId,
  });

  String get partnerName => partnerId.length > 1 ? partnerId[1] as String : 'N/A';

  factory Picking.fromJson(Map<String, dynamic> json) {
    return Picking(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'N/A',
      scheduledDate: json['scheduled_date'] ?? 'N/A',
      partnerId: json['partner_id'] is List ? json['partner_id'] : [0, 'Invalid Partner'],
      state: json['state'] ?? 'N/A',
      origin: json['origin'] is String ? json['origin'] : null,
      pickingTypeId: json['picking_type_id'] is List ? json['picking_type_id'] : [0, 'N/A'],
    );
  }
}
