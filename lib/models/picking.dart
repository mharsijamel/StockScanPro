class Picking {
  final int id;
  final String name;
  final String operationType; // 'in' or 'out'
  final String state;
  final String? partnerId;
  final String? partnerName;
  final DateTime? scheduledDate;
  final DateTime? dateCreated;
  final List<Product>? products;
  final String syncStatus;

  Picking({
    required this.id,
    required this.name,
    required this.operationType,
    required this.state,
    this.partnerId,
    this.partnerName,
    this.scheduledDate,
    this.dateCreated,
    this.products,
    this.syncStatus = 'completed',
  });

  factory Picking.fromJson(Map<String, dynamic> json) {
    return Picking(
      id: json['id'] as int,
      name: json['name'] as String,
      operationType: json['operation_type'] as String,
      state: json['state'] as String,
      partnerId: json['partner_id']?.toString(),
      partnerName: json['partner_name'] as String?,
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : null,
      dateCreated: json['date_created'] != null
          ? DateTime.parse(json['date_created'])
          : null,
      products: json['products'] != null
          ? (json['products'] as List)
              .map((p) => Product.fromJson(p))
              .toList()
          : null,
      syncStatus: json['sync_status'] as String? ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'operation_type': operationType,
      'state': state,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'date_created': dateCreated?.toIso8601String(),
      'products': products?.map((p) => p.toJson()).toList(),
      'sync_status': syncStatus,
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': name,
      'operation_type': operationType,
      'state': state,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'scheduled_date': scheduledDate?.millisecondsSinceEpoch,
      'date_created': dateCreated?.millisecondsSinceEpoch,
      'sync_status': syncStatus,
    };
  }

  factory Picking.fromDatabase(Map<String, dynamic> map) {
    return Picking(
      id: map['id'] as int,
      name: map['name'] as String,
      operationType: map['operation_type'] as String,
      state: map['state'] as String,
      partnerId: map['partner_id'] as String?,
      partnerName: map['partner_name'] as String?,
      scheduledDate: map['scheduled_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduled_date'])
          : null,
      dateCreated: map['date_created'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date_created'])
          : null,
      syncStatus: map['sync_status'] as String? ?? 'completed',
    );
  }

  Picking copyWith({
    int? id,
    String? name,
    String? operationType,
    String? state,
    String? partnerId,
    String? partnerName,
    DateTime? scheduledDate,
    DateTime? dateCreated,
    List<Product>? products,
    String? syncStatus,
  }) {
    return Picking(
      id: id ?? this.id,
      name: name ?? this.name,
      operationType: operationType ?? this.operationType,
      state: state ?? this.state,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      dateCreated: dateCreated ?? this.dateCreated,
      products: products ?? this.products,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() {
    return 'Picking{id: $id, name: $name, operationType: $operationType, state: $state}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Picking &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Import for Product model
class Product {
  final int id;
  final String name;
  final String? defaultCode;
  final String? barcode;
  final int pickingId;
  final double quantity;
  final double quantityDone;
  final String? location;
  final List<ScannedSn>? scannedSns;

  Product({
    required this.id,
    required this.name,
    this.defaultCode,
    this.barcode,
    required this.pickingId,
    required this.quantity,
    this.quantityDone = 0.0,
    this.location,
    this.scannedSns,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      defaultCode: json['default_code'] as String?,
      barcode: json['barcode'] as String?,
      pickingId: json['picking_id'] as int,
      quantity: (json['quantity'] as num).toDouble(),
      quantityDone: (json['quantity_done'] as num?)?.toDouble() ?? 0.0,
      location: json['location'] as String?,
      scannedSns: json['scanned_sns'] != null
          ? (json['scanned_sns'] as List)
              .map((s) => ScannedSn.fromJson(s))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'default_code': defaultCode,
      'barcode': barcode,
      'picking_id': pickingId,
      'quantity': quantity,
      'quantity_done': quantityDone,
      'location': location,
      'scanned_sns': scannedSns?.map((s) => s.toJson()).toList(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': name,
      'default_code': defaultCode,
      'barcode': barcode,
      'picking_id': pickingId,
      'quantity': quantity,
      'quantity_done': quantityDone,
      'location': location,
    };
  }

  factory Product.fromDatabase(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      defaultCode: map['default_code'] as String?,
      barcode: map['barcode'] as String?,
      pickingId: map['picking_id'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      quantityDone: (map['quantity_done'] as num?)?.toDouble() ?? 0.0,
      location: map['location'] as String?,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? defaultCode,
    String? barcode,
    int? pickingId,
    double? quantity,
    double? quantityDone,
    String? location,
    List<ScannedSn>? scannedSns,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultCode: defaultCode ?? this.defaultCode,
      barcode: barcode ?? this.barcode,
      pickingId: pickingId ?? this.pickingId,
      quantity: quantity ?? this.quantity,
      quantityDone: quantityDone ?? this.quantityDone,
      location: location ?? this.location,
      scannedSns: scannedSns ?? this.scannedSns,
    );
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, pickingId: $pickingId}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ScannedSn model
class ScannedSn {
  final String id;
  final String serialNumber;
  final int productId;
  final int pickingId;
  final String? location;
  final DateTime scannedAt;
  final String syncStatus;

  ScannedSn({
    required this.id,
    required this.serialNumber,
    required this.productId,
    required this.pickingId,
    this.location,
    required this.scannedAt,
    this.syncStatus = 'pending',
  });

  factory ScannedSn.fromJson(Map<String, dynamic> json) {
    return ScannedSn(
      id: json['id'] as String,
      serialNumber: json['serial_number'] as String,
      productId: json['product_id'] as int,
      pickingId: json['picking_id'] as int,
      location: json['location'] as String?,
      scannedAt: DateTime.parse(json['scanned_at']),
      syncStatus: json['sync_status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serial_number': serialNumber,
      'product_id': productId,
      'picking_id': pickingId,
      'location': location,
      'scanned_at': scannedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'serial_number': serialNumber,
      'product_id': productId,
      'picking_id': pickingId,
      'location': location,
      'scanned_at': scannedAt.millisecondsSinceEpoch,
      'sync_status': syncStatus,
    };
  }

  factory ScannedSn.fromDatabase(Map<String, dynamic> map) {
    return ScannedSn(
      id: map['id'] as String,
      serialNumber: map['serial_number'] as String,
      productId: map['product_id'] as int,
      pickingId: map['picking_id'] as int,
      location: map['location'] as String?,
      scannedAt: DateTime.fromMillisecondsSinceEpoch(map['scanned_at']),
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  ScannedSn copyWith({
    String? id,
    String? serialNumber,
    int? productId,
    int? pickingId,
    String? location,
    DateTime? scannedAt,
    String? syncStatus,
  }) {
    return ScannedSn(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      productId: productId ?? this.productId,
      pickingId: pickingId ?? this.pickingId,
      location: location ?? this.location,
      scannedAt: scannedAt ?? this.scannedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() {
    return 'ScannedSn{id: $id, serialNumber: $serialNumber, productId: $productId}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannedSn &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
