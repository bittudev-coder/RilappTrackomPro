class ChartData {
  final DateTime date;
  final double odometerDifference;

  ChartData({required this.date, required this.odometerDifference});

  factory ChartData.fromJson(Map<String, dynamic> json) {
    final dateParts = json['formattedDate'].split('/');
    final date = DateTime(2024, int.parse(dateParts[1]), int.parse(dateParts[0])); // Adjust year as needed
    return ChartData(
      date: date,
      odometerDifference: json['odometerDifference'].toDouble(),
    );
  }
}