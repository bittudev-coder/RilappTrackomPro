import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../widgets/CustomButton.dart';
import 'CommonMethod.dart';
import 'LineChart.dart';
import 'defaultGraphLine.dart';

class Graph extends StatefulWidget {
  Graph(
       {
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

  final Color gradientColor1;
  final Color gradientColor2;
  final Color gradientColor3;
  final Color indicatorStrokeColor;

  @override
  State<Graph> createState() => _GraphState();
}


class _GraphState extends State<Graph> {


  DateTime currentDate = DateTime.now();
  DateTime _selectedFromDate = DateTime.now();
  DateTime _selectedToDate = DateTime.now();
  List dropDownListData = [
    {"title": "Distance", "value": "1"},
    {"title": "Ignition", "value": "2"},
    {"title": "Speed", "value": "3"},
  ];
  List DateRangeList = [

    {"title": "Last 7days", "value": "1"},
    {"title": "Last 30days", "value": "2"},
    {"title": "Last month", "value": "3"},
    {"title": "Select Date Range","value": "4"},
  ];
  String chartValue="";
  String dateRange="";
  String dateRangeData="";
  String chartRangeData="";
  late List<String> dateofsplit= ['', ''];
  late List<String> dateofShow= ['', ''];
  String chartData="";


  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // Extract the specific arguments you passed
    final deviceId = arguments['deviceid'];
    final deviceName = arguments['Name'];
    return Scaffold(
      appBar: AppBar(
        title: Text("Graph".tr),
      ),
      body: Center(
        child: SafeArea(child: Column(
          children: [
            SizedBox(height: 20,),
            SizedBox(
              height: 170,
              width: MediaQuery.of(context).size.width * 0.97, // Adjust width to 90% of screen width
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Set the background color
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5), // Blue shadow
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 4), // Shadow offset (horizontal, vertical)
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(5),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Select Date ranges
                            SizedBox(
                              height: 30,
                              width: 130,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10), // Adjust vertical padding
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isDense: true,
                                    value: dateRange,
                                    isExpanded: true,
                                    menuMaxHeight: 350,
                                    items: [
                                      DropdownMenuItem(
                                        child: Center(
                                          child: Text(
                                            "Select Date Range",
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                        value: "",
                                      ),
                                      ...DateRangeList.map<DropdownMenuItem<String>>((data) {
                                        return DropdownMenuItem(
                                          child: Center(
                                            child: Text(
                                              data['title'],
                                              style: TextStyle(fontSize: 10),
                                            ),
                                          ),
                                          value: data['value'],
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (value) {
                                      if(value=='1'){
                                        dateRangeData=yesterday_7daysDateCalculate(1,7);
                                        dateofShow=dateRangeData.split('/');
                                      }else if(value=='2'){
                                        dateRangeData=yesterday_7daysDateCalculate(1,30);
                                        dateofShow=dateRangeData.split('/');
                                      }else if(value=='3'){
                                        dateRangeData=getStartAndEndOfLastMonth(currentDate);
                                        dateofShow=dateRangeData.split('/');
                                      }else {
                                        print('costom');
                                        showReportDialog(context);

                                        }
                                      },
                                  ),
                                ),
                              ),
                            ),
                        // chart Types
                            SizedBox(
                              height: 30,
                              width: 100,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10), // Adjust vertical padding
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isDense: true,
                                    value: chartValue,
                                    isExpanded: true,
                                    menuMaxHeight: 350,
                                    items: [
                                      DropdownMenuItem(
                                        child: Center(
                                          child: Text(
                                            "Chart Type",
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                        value: "",
                                      ),
                                      ...dropDownListData.map<DropdownMenuItem<String>>((data) {
                                        return DropdownMenuItem(
                                          child: Center(
                                            child: Text(
                                              data['title'],
                                              style: TextStyle(fontSize: 10),
                                            ),
                                          ),
                                          value: data['value'],
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (value) {
                                      print("selected Value $value");
                                      setState(() {
                                        chartValue = value!;
                                      });

                                      if(value=='1'){
                                        chartRangeData='distance';
                                      }else if(value=='2'){
                                        chartRangeData='ignition';
                                      }else {
                                        chartRangeData='speed';
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width* 0.13,
                                height: 40,
                                child: Center(child: CustomButton(onTap: (){
                                  if(dateRangeData=="" && chartRangeData==""){
                                    _showErrorDialog(context,"Select DateRange and ChartType");
                                  }else if(dateRangeData==""){
                                    _showErrorDialog(context,"Select DateRange ");
                                  }else if(chartRangeData==""){
                                    _showErrorDialog(context,"Select ChartType");
                                  }
                                  else{
                                    dateofsplit = dateRangeData.split('/');
                                    chartData=chartRangeData;
                                    setState(() {
                                    });
                                  }
                                },text: "Show")),
                              ),
                            ),

                          ],
                        ),
                      ),
                          Divider(),
                          Row(
                            children: [
                              Text("Vehicle No.- "),
                              Text(deviceName,style: TextStyle(fontWeight: FontWeight.w600,fontSize: 15)),
                            ],
                          ),
                          SizedBox(height: 10,),
                      Row(
                          children: [
                            Text("Duration.- "),
                            Text(dateofShow[0] , style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            Text(' to '),
                            Text(dateofShow[1], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          ]
                      ),

                          SizedBox(height: 10,),
                      Row(
                        children: [
                          Text("Report Type.- "),
                          Text(capitalizeFirstLetter(chartRangeData),style: TextStyle(fontWeight: FontWeight.w600,fontSize: 15),),
                        ],
                      ),


                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 30,),
            SizedBox(
              height: 300,
              child: ChartLine(context,deviceId),
            ),

          ],
        ),

        ),
      ),
    );
  }

  ChartLine(BuildContext context,String deviceId) {
    if(dateofsplit[0]=="" && chartData==''){
      return LineChartSample();}
    else{
      return LineChartSample5(deviceId,dateofsplit[0],dateofsplit[1],chartData);
    }
  }

  String yesterday_7daysDateCalculate(int todate ,int fromdate){
    DateTime today = DateTime.now();
    // Calculate yesterday's date
    DateTime yesterday = today.subtract(Duration(days: 0));

    // Calculate the date 7 days before yesterday
    DateTime sevenDaysBeforeYesterday = yesterday.subtract(Duration(days: fromdate));

    // Manually format dates as strings
    String yesterdayStr = formatDate(yesterday);
    String sevenDaysBeforeYesterdayStr = formatDate(sevenDaysBeforeYesterday);
    return '$sevenDaysBeforeYesterdayStr'+'/'+'$yesterdayStr';
  }
// Function to manually format date in yyyy-MM-dd format
  String formatDate(DateTime date) {
    String year = date.year.toString().padLeft(4, '0');
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
  void  showReportDialog(BuildContext context) {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new Container(
            height: 200,
            width: 300.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding:
                      const EdgeInsets.only(left: 10, right: 10, top: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          new Container(
                              child: new Column(
                                children: <Widget>[
                                Text('The Date range can\'t exceed 31days '),
                                  SizedBox(height: 10,),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Text("Select From :",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),),
                                      ElevatedButton(
                                        onPressed: () => _selectFromDate(
                                            context, setState),
                                        child: Text(
                                            formatReportDate(
                                                _selectedFromDate),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(right: 20.0),
                                        child: Text("Select To :",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            _selectToDate(context, setState),
                                        child: Text(
                                            formatReportDate(_selectedToDate),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  )
                                ],
                              )),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.red, // background
                                  backgroundColor: Colors.white, // foreground
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  ('cancel').tr,
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.red),
                                ),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  dateRangeData=formatDate(_selectedFromDate).toString()+"/"+formatDate(_selectedToDate).toString();
                                  // dateofsplit = dateRangeData.split('/');
                                  dateofShow=dateRangeData.split('/');
                                  Navigator.of(context).pop();


                                },
                                child: Text(
                                  ('ok').tr,
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }



  String getStartAndEndOfLastMonth(DateTime fromDate) {
    DateTime firstDayOfCurrentMonth = DateTime(fromDate.year, fromDate.month, 1);
    DateTime lastDayOfPreviousMonth = firstDayOfCurrentMonth.subtract(Duration(days: 1));
    DateTime firstDayOfPreviousMonth = DateTime(lastDayOfPreviousMonth.year, lastDayOfPreviousMonth.month, 1);
    String startOfLastMonth = DateFormat('yyyy-MM-dd').format(firstDayOfPreviousMonth);
    String endOfLastMonth = DateFormat('yyyy-MM-dd').format(lastDayOfPreviousMonth);
    return '$startOfLastMonth/$endOfLastMonth';
  }








  Future<void> _selectFromDate(
      BuildContext context, StateSetter setState) async {
    DateTime currentDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFromDate,
      firstDate: DateTime(2015, 8),
      lastDate: currentDate,
    );

    if (picked != null && picked != _selectedFromDate) {
      setState(() {
        _selectedToDate = currentDate;
      });
      // Calculate the maximum selectable date (7 days after picked date)
      DateTime maxDate = picked.add(Duration(days: 0));

      // Check if _selectedToDate exceeds maxDate
      if (_selectedToDate.isAfter(maxDate)) {
        setState(() {
          _selectedToDate = maxDate;
        });
      }

      setState(() {
        _selectedFromDate = picked;
      });
    }
  }

  Future<void> _selectToDate(BuildContext context, StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedToDate,
      firstDate: _selectedFromDate,
      lastDate: _selectedFromDate.add(Duration(days: 31)),
    );

    if (picked != null && picked != _selectedToDate) {
      setState(() {
        _selectedToDate = picked;
      });
    }
  }
  void _showErrorDialog(BuildContext context, String errorMessage)
  {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismisses the dialog
              },
            ),
          ],
        );
      },
    );
  }



}

