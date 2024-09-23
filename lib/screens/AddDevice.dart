import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../traccar_gennissi.dart';

class AddDevicePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _AddPageState();
}

class _AddPageState extends State<AddDevicePage> {
  late SharedPreferences prefs;
  String selectedCategory = "Categories";
  final TextEditingController _name = new TextEditingController();
  final TextEditingController _identifier = new TextEditingController();
  final TextEditingController _phone = new TextEditingController();
  final TextEditingController _model = new TextEditingController();
  final TextEditingController _contact = new TextEditingController();
  final TextEditingController _category = new TextEditingController();

  List<CategoryModel> _categories = [];

  bool isLoading = true;

  @override
  initState() {
    super.initState();

    _categories = <CategoryModel>[
      new CategoryModel(0, 'arrow'),
      new CategoryModel(1, 'default'),
      new CategoryModel(2, 'animal'),
      new CategoryModel(3, 'bicycle'),
      new CategoryModel(4, 'boat'),
      new CategoryModel(5, 'bus'),
      new CategoryModel(6, 'car'),
      new CategoryModel(7, 'crane'),
      new CategoryModel(8, 'helicopter'),
      new CategoryModel(9, 'motorcycle'),
      new CategoryModel(10, 'offroad'),
      new CategoryModel(11, 'person'),
      new CategoryModel(12, 'pickup'),
      new CategoryModel(13, 'plane'),
      new CategoryModel(14, 'ship'),
      new CategoryModel(15, 'tractor'),
      new CategoryModel(16, 'trolleybus'),
      new CategoryModel(17, 'truck'),
      new CategoryModel(18, 'van'),
      new CategoryModel(19, 'scooter'),
    ];
  }

  void addDevice() {
    Device device = new Device();
    device.name = _name.text;
    device.uniqueId = _identifier.text;
    device.phone = _phone.text;
    device.model = _model.text;
    device.contact = _contact.text;
    device.category = _category.text.toLowerCase();

    PositionModel positionObj = new PositionModel();

    String deviceObj = json.encode(device.toJson());
    List<Device> devList = [];
    List<PositionModel> posList = [];
    try {
      _showProgress(true);
      Traccar.addDevice(deviceObj).then((value) => {
            if (value.statusCode == 200)
              {
                _showProgress(false),
                devList.add(Device.fromJson(json.decode(value.body))),
                positionObj.deviceId = devList.single.id,
                positionObj.latitude = 0,
                positionObj.longitude = 0,
                positionObj.id = 1,
                positionObj.attributes = {},
                positionObj.speed = 0,
                posList.add(positionObj),
                Fluttertoast.showToast(
                    msg: ('deviceRegistered').tr,
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.black54,
                    textColor: Colors.white,
                    fontSize: 16.0),
                Navigator.pop(context)
              }
            else
              {
                _showProgress(false),
                if (value.body ==
                    "Duplicate entry '' for key 'uniqueid' - SQLIntegrityConstraintViolationException (... < QueryBuilder:446 < DataManager:425 < BaseObjectManager:123 < ...)")
                  {
                    Fluttertoast.showToast(
                        msg: ('alreadyRegistered').tr,
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.black54,
                        textColor: Colors.white,
                        fontSize: 16.0)
                  }
              }
          });
    } catch (e) {
      _showProgress(false);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
                child: Scaffold(
              appBar: new AppBar(
                title: new Text(
                    ('addDevice').tr,
                    style: TextStyle(color: CustomColor.secondaryColor)),
                centerTitle: true,
              ),
              body: new Container(
                  padding: EdgeInsets.all(16.0),
                  child: ListView(shrinkWrap: true, children: <Widget>[
                    new Column(
                      children: <Widget>[_buildTextFields()],
                    )
                  ])),
            ));
  }

  Widget _buildTextFields() {
    return new Container(
      child: new Column(
        children: <Widget>[
          new Container(
            child: new TextField(
              controller: _name,
              decoration: new InputDecoration(
                  labelText: ('reportDeviceName').tr),
            ),
          ),
          new Container(
            child: new TextField(
              controller: _identifier,
              decoration: new InputDecoration(
                  labelText: ('deviceIdentifier').tr),
            ),
          ),
          new Container(
            child: new TextField(
              controller: _phone,
              decoration: new InputDecoration(
                  labelText: ('phone').tr),
            ),
          ),
          new Container(
            child: new TextField(
              controller: _model,
              decoration: new InputDecoration(
                  labelText:('deviceModel').tr),
            ),
          ),
          new Container(
            child: new TextField(
              controller: _contact,
              decoration: new InputDecoration(
                  labelText:('deviceContact').tr),
            ),
          ),
          new Container(
              width: 500,
              child: new DropdownButton<String>(
                hint: Text(selectedCategory != "Categories"
                    ? (selectedCategory).tr
                    : "Categories"),
                items: _categories.map((CategoryModel value) {
                  return new DropdownMenuItem<String>(
                    value: value.category,
                    child: new Text((value.category).tr),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              )),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return new Container(
      child: new Column(
        children: <Widget>[
          new Container(
              child: ElevatedButton(
            onPressed: () {
              addDevice();
            },
            child: Text(('addDevice').tr,
                style: TextStyle(fontSize: 18)),
          )),
//            new FlatButton(
//              child: new Text('Register'),
//              onPressed: _formChange,
//            ),
        ],
      ),
    );
  }

  // These functions can self contain any user auth logic required, they all have access to _email and _password

  Future<void> _showProgress(bool status) async {
    if (status) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: [
                CircularProgressIndicator(),
                Container(
                    margin: EdgeInsets.only(left: 5),
                    child: Text(('sharedLoading').tr)),
              ],
            ),
          );
        },
      );
    } else {
      Navigator.pop(context);
    }
  }
}

class CategoryModel {
  int id;
  String category;
  CategoryModel(this.id, this.category);
}
