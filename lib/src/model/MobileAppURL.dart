class MobileAppUrl {
  String serverName;
  String serverUrl;
  String serverType;

  MobileAppUrl({
    required this.serverName,
    required this.serverUrl,
    required this.serverType,
  });

  factory MobileAppUrl.fromJson(Map<String, dynamic> json) {
    return MobileAppUrl(
      serverName: json['serverName'],
      serverUrl: json['serverUrl'],
      serverType: json['serverType'],
    );
  }
}