import 'package:flutter/material.dart';

class FloatingButtonWithMenu extends StatefulWidget {
  final VoidCallback onExcel; // Renamed from excel to onExcel for clarity
  final VoidCallback onPdf;   // Renamed from Pdf to onPdf for clarity

  const FloatingButtonWithMenu({
    Key? key,
    required this.onExcel,
    required this.onPdf,
  }) : super(key: key);

  @override
  _FloatingButtonWithMenuState createState() => _FloatingButtonWithMenuState();
}

class _FloatingButtonWithMenuState extends State<FloatingButtonWithMenu> {
  bool _showMenu = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedCrossFade(
          duration: Duration(milliseconds: 200),
          crossFadeState: _showMenu ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: FloatingActionButton(
            onPressed: () {
              setState(() {
                _showMenu = true;
              });
            },
            tooltip: 'Show options',
            child: Icon(Icons.file_download),
          ),
          secondChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _showMenu = false;
                  });
                  widget.onPdf(); // Correctly reference the onPdf function
                },
                tooltip: 'PDF',
                child: Icon(Icons.picture_as_pdf),
              ),
              SizedBox(height: 16),
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _showMenu = false;
                  });
                  widget.onExcel(); // Correctly reference the onExcel function
                },
                tooltip: 'Excel',
                child: Icon(Icons.table_chart),
              ),
              SizedBox(height: 16),
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _showMenu = false;
                  });
                },
                tooltip: 'Close options',
                child: Icon(Icons.close),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
