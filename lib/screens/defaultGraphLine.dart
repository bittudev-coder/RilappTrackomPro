import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// Define your ChartData model
class ChartData {
  final String formattedDate;
  final int odometerDifference;

  ChartData({required this.formattedDate, required this.odometerDifference});

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      formattedDate: json['formattedDate'] as String,
      odometerDifference: json['odometerDifference'] as int,
    );
  }
}

class LineChartSample extends StatefulWidget {
  LineChartSample( {
    super.key,
    Color? gradientColor1,
    Color? gradientColor2,
    Color? gradientColor3,
    Color? indicatorStrokeColor,
  })  : gradientColor1 = gradientColor1 ?? Colors.blue,
        gradientColor2 = gradientColor2 ?? Colors.pink,
        gradientColor3 = gradientColor3 ?? Colors.red,
        indicatorStrokeColor = indicatorStrokeColor ?? Colors.black;

  final Color gradientColor1;
  final Color gradientColor2;
  final Color gradientColor3;
  final Color indicatorStrokeColor;

  @override
  State<LineChartSample> createState() => _LineChartSample5State();
}

class _LineChartSample5State extends State<LineChartSample> {
  List<ChartData> _data = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Use default data
    _loadData();
  }

  // Remove API call and use default data instead
  void _loadData() {
    setState(() {
      _isLoading = false; // No loading state needed for default data
      _error = null;
      _data = [
        ChartData(formattedDate: "dd/mm", odometerDifference: 0),
        ChartData(formattedDate: "dd/mm", odometerDifference: 0),
        ChartData(formattedDate: "dd/mm", odometerDifference: 0),
        ChartData(formattedDate: "dd/mm", odometerDifference: 0),
        ChartData(formattedDate: "dd/mm", odometerDifference: 0),
        ChartData(formattedDate: "dd/mm", odometerDifference: 0),
        ChartData(formattedDate: "dd/mm", odometerDifference: 0),
      ];
    });
  }

  List<FlSpot> get allSpots {
    if (_data.isEmpty) {
      return [FlSpot(0, 0)];
    }

    const int decimalPlaces = 2; // Set the number of decimal places you want

    return _data.asMap().entries.map((entry) {
      int index = entry.key;
      ChartData item = entry.value;
      double x = index.toDouble();
      double y = item.odometerDifference.toDouble();

      // Round x and y values to the specified number of decimal places
      double roundedX = double.parse(x.toStringAsFixed(decimalPlaces));
      double roundedY = double.parse(y.toStringAsFixed(decimalPlaces));

      return FlSpot(roundedX, roundedY);
    }).toList();
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta, double chartWidth) {
    final style = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.indigo,
      fontFamily: 'Digital',
      fontSize: 15 * chartWidth / 500,
    );

    if (value.toInt() >= 0 && value.toInt() < _data.length) {
      String text = _data[value.toInt()].formattedDate;
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(text, style: style),
      );
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: SizedBox.shrink(),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    final style = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black,
      fontSize: 10, // Smaller font size for y-axis labels
    );

    String text = value.toInt().toString();

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    final lineBarsData = [
      LineChartBarData(
        spots: allSpots,
        isCurved: true,
        barWidth: 2,
        shadow: const Shadow(
          blurRadius: 40,
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              widget.gradientColor1.withOpacity(0.4),
              widget.gradientColor2.withOpacity(0.4),
              widget.gradientColor3.withOpacity(0.4),
            ],
          ),
        ),
        dotData: const FlDotData(show: true),
        gradient: LinearGradient(
          colors: [
            widget.gradientColor1,
            widget.gradientColor2,
            widget.gradientColor3,
          ],
          stops: const [0.1, 0.4, 0.9],
        ),
      ),
    ];

    return SizedBox(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        child: LayoutBuilder(builder: (context, constraints) {
          return LineChart(
            LineChartData(
              lineBarsData: lineBarsData,
              minY: -50,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: null,
                  axisNameSize: 0,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      return leftTitleWidgets(value, meta);
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return bottomTitleWidgets(value, meta, constraints.maxWidth);
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                    reservedSize: 0,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 0,
                  ),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Colors.black,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

// No need for fetchChartData function anymore
}
