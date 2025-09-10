class StockPicking {
  final int id;
  final String name;
  final String pickingType; // 'incoming' ou 'outgoing'
  final String state; // 'draft', 'assigned', 'done', etc.
  final int partnerId;
  final String partnerName;
  final DateTime scheduledDate;
  final List<StockMove> products;
  final String? origin;
  final String? note;
  final DateTime? dateCreated;
  final DateTime? dateDone;

  StockPicking({
    required this.id,
    required this.name,
    required this.pickingType,
    required this.state,
    required this.partnerId,
    required this.partnerName,
    required this.scheduledDate,
    required this.products,
    this.origin,
    this.note,
    this.dateCreated,
    this.dateDone,
  });

  factory StockPicking.fromJson(Map<String, dynamic> json) {
    return StockPicking(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      pickingType: json['picking_type'] ?? '',
      state: json['state'] ?? 'draft',
      partnerId: json['partner_id'] ?? 0,
      partnerName: json['partner_name'] ?? '',
      scheduledDate: json['scheduled_date'] != null 
          ? DateTime.parse(json['scheduled_date'])
          : DateTime.now(),
      products: (json['products'] as List<dynamic>?)
          ?.map((product) => StockMove.fromJson(product))
          .toList() ?? [],
      origin: json['origin'],
      note: json['note'],
      dateCreated: json['date_created'] != null 
          ? DateTime.parse(json['date_created'])
          : null,
      dateDone: json['date_done'] != null 
          ? DateTime.parse(json['date_done'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'picking_type': pickingType,
      'state': state,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'scheduled_date': scheduledDate.toIso8601String(),
      'products': products.map((product) => product.toJson()).toList(),
      'origin': origin,
      'note': note,
      'date_created': dateCreated?.toIso8601String(),
      'date_done': dateDone?.toIso8601String(),
    };
  }

  bool get isIncoming => pickingType == 'incoming';
  bool get isOutgoing => pickingType == 'outgoing';
  bool get isDraft => state == 'draft';
  bool get isAssigned => state == 'assigned';
  bool get isDone => state == 'done';

  String get displayState {
    switch (state) {
      case 'draft':
        return 'Brouillon';
      case 'assigned':
        return 'Prêt';
      case 'done':
        return 'Terminé';
      case 'cancel':
        return 'Annulé';
      default:
        return state;
    }
  }

  String get displayType {
    return isIncoming ? 'Réception' : 'Livraison';
  }
}

class StockMove {
  final int id;
  final String productName;
  final int productId;
  final double quantity;
  final double quantityDone;
  final String uomName;
  final List<String> serialNumbers;
  final bool requiresSerialNumber;

  StockMove({
    required this.id,
    required this.productName,
    required this.productId,
    required this.quantity,
    required this.quantityDone,
    required this.uomName,
    required this.serialNumbers,
    required this.requiresSerialNumber,
  });

  factory StockMove.fromJson(Map<String, dynamic> json) {
    return StockMove(
      id: json['id'] ?? 0,
      productName: json['product_name'] ?? '',
      productId: json['product_id'] ?? 0,
      quantity: (json['quantity'] ?? 0).toDouble(),
      quantityDone: (json['quantity_done'] ?? 0).toDouble(),
      uomName: json['uom_name'] ?? '',
      serialNumbers: (json['serial_numbers'] as List<dynamic>?)
          ?.map((sn) => sn.toString())
          .toList() ?? [],
      requiresSerialNumber: json['requires_serial_number'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'product_id': productId,
      'quantity': quantity,
      'quantity_done': quantityDone,
      'uom_name': uomName,
      'serial_numbers': serialNumbers,
      'requires_serial_number': requiresSerialNumber,
    };
  }

  bool get isComplete => quantityDone >= quantity;
  double get remainingQuantity => quantity - quantityDone;
  int get missingSerialNumbers => requiresSerialNumber 
      ? (quantity - serialNumbers.length).round().clamp(0, quantity.round())
      : 0;
}
