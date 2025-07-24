class HcfWasteModel {
  final int hcfWasteId;
  final int? hcfWasteQntyDetId;
  final int? hcfWasteQntyId;

  HcfWasteModel({
    required this.hcfWasteId,
    required this.hcfWasteQntyDetId,
    required this.hcfWasteQntyId,
  });

  Map<String, dynamic> toJson() => {
    'hcfWasteId': hcfWasteId,
    'hcfWasteQntyDetId': hcfWasteQntyDetId,
    'hcfWasteQntyId': hcfWasteQntyId,
  };

  factory HcfWasteModel.fromJson(Map<String, dynamic> json) {
    return HcfWasteModel(
      hcfWasteId: json['hcfWasteId'],
      hcfWasteQntyDetId: json['hcfWasteQntyDetId'],
      hcfWasteQntyId: json['hcfWasteQntyId'],
    );
  }
}
