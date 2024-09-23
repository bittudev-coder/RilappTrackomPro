import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<String> dataLabels = [
    "All",
    "Moving",
    "Stopped",
    "Engine On",
    "Engine Off",
    "Offline",
    "Online"
  ];

  List<Color> colorList = [
    Color(0xFF2A9D8F),
    Color(0xFF72bad5),
    Color(0xFFfa7aa6),
    Color(0xFF03324e),
    Color(0xFFf68080),
    Color(0xFFb5c6e0),
    Color(0xFF066839),
  ];

  int? _tappedIndex;
  List<int> _animatedIndices = []; // To keep track of animated indices

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start sequential animation after widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSequentialAnimation();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startSequentialAnimation() async {
    for (int i = 0; i < dataLabels.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80 ));
      setState(() {
        _animatedIndices.add(i);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double valuePerSection = 100.0 / dataLabels.length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return PieChart(
              PieChartData(
                sections: dataLabels.asMap().entries.map((entry) {
                  final index = entry.key;
                  final label = entry.value;
                  final colorIndex = index % colorList.length;
                  bool isTapped = _tappedIndex != null && _tappedIndex == index;
                  bool isVisible = _animatedIndices.contains(index);
                  return isVisible
                      ? PieChartSectionData(
                    color: colorList[colorIndex],
                    value: valuePerSection,
                    title: label,
                    radius: isTapped ? 80 * _animation.value : 80,
                    titleStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  )
                      : PieChartSectionData(
                    color: Colors.transparent, // Hide the section until animated
                    value: 0,
                    title: '',
                    radius: 0,
                  );
                }).toList(),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.black, width: 20, style: BorderStyle.solid),
                ),
                sectionsSpace: 0,
                centerSpaceRadius: 50,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (event is FlTapUpEvent && pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                      final sectionIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      final sectionLabel = dataLabels[sectionIndex];
                      setState(() async{
                        _tappedIndex = sectionIndex;
                        _animationController.forward().then((_) {
                          _animationController.reverse();
                        });
                        await Future.delayed(const Duration(milliseconds: 800 ));
                        _showDialog(context, sectionLabel);
                      });

                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, String sectionLabel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pie Chart Section'),
          content: Text('You clicked on $sectionLabel'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
