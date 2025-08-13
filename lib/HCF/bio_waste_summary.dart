// bio_waste_mapper.dart

class BioWasteMapper {
  static Map<String, dynamic> buildPayload({
    required List<Map<String, dynamic>> tableData,
    required int hcfId,
    required String hcfCode,
    required String wasteQntyDate,
    required int userId,
    required String createdDate,
    required String updatedDate,
    required String macId,
    required String ipAddress,
  }) {
    final wasteList = _transformTableDataToWasteList(
      tableData: tableData,
      userId: userId,
      createdDate: createdDate,
      updatedDate: updatedDate,
      macId: macId,
      ipAddress: ipAddress,
    );

    final totalQty = tableData.fold<double>(
        0, (sum, row) => sum + (double.tryParse(row['quantity'].toString()) ?? 0));

    return {
      "hcfWasteId": null,
      "hcfId": hcfId,
      "hcfCode": hcfCode,
      "wasteQntyDate": wasteQntyDate,
      "totalNoOfBags": tableData.length,
      "totalQuantityBagKg": totalQty,
      "userId": userId,
      "status": 1,
      "createdBy": userId,
      "createdDate": createdDate,
      "updatedBy": userId,
      "updatedDate": updatedDate,
      "macId": macId,
      "ipAddress": ipAddress,
      "deviceFrom": "M",
      "wasteList": wasteList,
    };
  }

  static List<Map<String, dynamic>> _transformTableDataToWasteList({
    required List<Map<String, dynamic>> tableData,
    required int userId,
    required String createdDate,
    required String updatedDate,
    required String macId,
    required String ipAddress,
  }) {
    final Map<int, List<Map<String, dynamic>>> grouped = {};

    for (var entry in tableData) {
      final int id = entry['id'];
      grouped.putIfAbsent(id, () => []).add(entry);
    }

    return grouped.entries.map((entry) {
      final List<Map<String, dynamic>> groupRows = entry.value;

      double totalQuantity = 0;
      int bagCounter = 1;

      final wasteDetList = groupRows.map((row) {
        final double qty = double.tryParse(row['quantity'].toString()) ?? 0;
        totalQuantity += qty;
        print('roe');
        print(row['category'].toString().substring(0,1));

        return {
          "hcfWasteQntyDetId": null,
          "bagNo": bagCounter++,
          "quantityBag": qty,
          "status": 1,
          "createdBy": userId,
          "createdDate": createdDate,
          "updatedBy": userId,
          "updatedDate": updatedDate,
          "macId": macId,
          "ipAddress": ipAddress,
          "deviceFrom": "M",
          "colorType": row['category'].toString().substring(0,1), // must be present in tableData
        };
      }).toList();

      return {
        "hcfWasteQntyId": null,
        "lookupDetIdCategory": entry.key,
        "noOfBags": groupRows.length,
        "totalQuantityBagKg": totalQuantity,
        "status": 1,
        "createdBy": userId,
        "createdDate": createdDate,
        "updatedBy": userId,
        "updatedDate": updatedDate,
        "macId": macId,
        "ipAddress": ipAddress,
        "deviceFrom": "M",
        "wasteDetList": wasteDetList,
      };
    }).toList();
  }
}

class ColorCategory {
  final int id;
  final String name;
  final String code;

  ColorCategory({
    required this.id,
    required this.name,
    required this.code,
  });

  factory ColorCategory.fromJson(Map<String, dynamic> json) {
    return ColorCategory(
      id: json['lookupDetId'],
      name: json['lookupDetDescEn'],
      code: json['lookupDetValue'],
    );
  }
}
