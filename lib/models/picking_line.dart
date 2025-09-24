class PickingLine {
  final String displayName;
  final double productUomQty;
  final double quantityDone;

  PickingLine({
    required this.displayName,
    required this.productUomQty,
    required this.quantityDone,
  });

  factory PickingLine.fromJson(Map<String, dynamic> json) {
    return PickingLine(
      displayName: json['product_id'] is List && json['product_id'].length > 1
          ? json['product_id'][1] as String
          : 'N/A',
      // Odoo peut retourner false au lieu de 0
      productUomQty: (json['product_uom_qty'] is num)
          ? (json['product_uom_qty'] as num).toDouble()
          : 0.0,
      quantityDone: (json['quantity_done'] is num)
          ? (json['quantity_done'] as num).toDouble()
          : 0.0,
    );
  }
}
