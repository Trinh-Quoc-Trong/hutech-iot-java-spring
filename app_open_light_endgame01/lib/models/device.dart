class Device {
  final String id;
  final String name;
  final String broker;
  final int port;
  final String topic;
  bool isOn;

  Device({
    required this.id,
    required this.name,
    required this.broker,
    required this.port,
    required this.topic,
    this.isOn = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'broker': broker,
      'port': port,
      'topic': topic,
      'isOn': isOn,
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      broker: json['broker'],
      port: json['port'],
      topic: json['topic'],
      isOn: json['isOn'] ?? false,
    );
  }
}
