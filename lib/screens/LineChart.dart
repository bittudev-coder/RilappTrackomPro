import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../Config.dart';

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

class LineChartSample5 extends StatefulWidget {
  LineChartSample5(
      this.value,this.fromDate,this.Todate, this.ChartType,{
        Key? key,
        Color? gradientColor1,
        Color? gradientColor2,
        Color? gradientColor3,
        Color? indicatorStrokeColor,
      })  : gradientColor1 = gradientColor1 ?? Colors.blue,
        gradientColor2 = gradientColor2 ?? Colors.pink,
        gradientColor3 = gradientColor3 ?? Colors.red,
        indicatorStrokeColor = indicatorStrokeColor ?? Colors.black,
        super(key: key);

  final String? value;
  final String? fromDate;
  final String? Todate;
  final String? ChartType;
  final Color gradientColor1;
  final Color gradientColor2;
  final Color gradientColor3;
  final Color indicatorStrokeColor;

  @override
  State<LineChartSample5> createState() => _LineChartSample5State();
}

class _LineChartSample5State extends State<LineChartSample5> {
  List<ChartData> _data = [];
  bool _isLoading = true;
  String? _error;
  Timer? _timer;
  String? _previousValue;
  String? _previousfromDate;
  String? _previoustoDate;
  String? _previousChartYtpe;
  @override
  void initState() {
    super.initState();
    print('Hello');
    if (widget.value != null) {
      _loadData(widget.value,widget.fromDate,widget.Todate,widget.ChartType!);
    } else {
      setState(() {
        _isLoading = false;
        _error = 'Device ID is null';
      });
    }
    _startTimer();
  }


  @override
  void dispose() {
    _timer?.cancel();
    _previousValue = widget.value;
    super.dispose();
  }

  @override
  void didUpdateWidget(LineChartSample5 oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the value has changed
    if (widget.value != oldWidget.value) {
      _previousValue = oldWidget.value;
    }
  }


  void _startTimer() {
    _timer = Timer.periodic(Duration(microseconds: 300), (Timer timer) {
      if (widget.value != null || widget.Todate!=null || widget.fromDate!=null || widget.ChartType!=null) {
        if (widget.value != _previousValue || widget.fromDate != _previousfromDate || widget.Todate != _previoustoDate || widget.ChartType != _previousChartYtpe) {
          _loadData(widget.value!, widget.fromDate, widget.Todate,widget.ChartType!);
          _previousValue = widget.value; // Update previous value
          _previoustoDate = widget.Todate;
          _previousfromDate = widget.fromDate;
          _previousChartYtpe = widget.ChartType;
        }
      }
    });
  }

  Future<void> _loadData(String? deviceid,String? fromdate,String? ToDate ,String ChartType) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await fetchChartData(deviceid!,fromdate!,ToDate!,ChartType);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<FlSpot> get allSpots {
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
      fontSize: 10 * chartWidth / 500,
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
      return Center(child: Text('No Data'));
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
              minY: 0,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: null,
                  axisNameSize: 0,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    // interval: 50,
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

  Future<List<ChartData>> fetchChartData(String deviceid,String fromdate,String ToDate, String ChartType) async {
    final url = Uri.parse(SERVER_FETCH);
    // Create the request body
    Map<String, String> body = {
      "deviceid": deviceid,
      "fromdate": fromdate,
      "todate": ToDate,
      "chart":ChartType,
    };
      print(jsonEncode(body));
    // Perform the POST request
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "api-key": "ndeweidjwekdiwwednddw"},
      body: jsonEncode(body),
    );

    // Handle the response
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (!data['error'] == true) {
        throw Exception(data['message']);
      }

      if (data['data'] is List) {
        return List<ChartData>.from(
            data['data'].map((item) => ChartData.fromJson(item))
        );
      } else {
        throw Exception('Unexpected data format');
      }
    } else {
      throw Exception('Failed to load data: ${response.reasonPhrase}');
    }
  }
}
