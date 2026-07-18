class CampusNode {
  final String id;
  final String name;
  final String type;
  final double latitude;
  final double longitude;

  CampusNode({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
  });

  factory CampusNode.fromJson(Map<String, dynamic> json) {
    return CampusNode(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
