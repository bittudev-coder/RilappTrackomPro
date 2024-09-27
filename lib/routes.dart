import 'package:flutter/material.dart';
import 'package:gpspro/screens/AddDevice.dart';
import 'package:gpspro/screens/DeviceInfo.dart';
import 'package:gpspro/screens/EditDevice.dart';
import 'package:gpspro/screens/EnableNotifications.dart';
import 'package:gpspro/screens/EventMap.dart';
import 'package:gpspro/screens/Geofence.dart';
import 'package:gpspro/screens/GeofenceAdd.dart';
import 'package:gpspro/screens/GeofenceList.dart';
import 'package:gpspro/screens/Graph.dart';
import 'package:gpspro/screens/Home.dart';
import 'package:gpspro/screens/Login.dart';
import 'package:gpspro/screens/Maintenance.dart';
import 'package:gpspro/screens/MaintenancePage.dart';
import 'package:gpspro/screens/NotificationMap.dart';
import 'package:gpspro/screens/Playback.dart';
import 'package:gpspro/screens/ReportEvent.dart';
import 'package:gpspro/screens/ReportRoute.dart';
import 'package:gpspro/screens/ReportStop.dart';
import 'package:gpspro/screens/ReportSummary.dart';
import 'package:gpspro/screens/ReportTrip.dart';
import 'package:gpspro/screens/ReportsList.dart';
import 'package:gpspro/screens/SplashScreen.dart';
import 'package:gpspro/screens/TrackDevice.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => SplashScreenPage(),
  '/login': (context) => LoginPage(),
  '/home': (context) => HomePage(),
  '/trackDevice': (context) => TrackDevicePage(),
  '/deviceInfo': (context) => DeviceInfo(),
  '/reportList': (context) => ReportListPage(),
  '/reportRoute': (context) => ReportRoutePage(),
  '/reportEvent': (context) => ReportEventPage(),
  '/reportTrip': (context) => ReportTripPage(),
  '/reportStop': (context) => ReportStopPage(),
  '/reportSummary': (context) => ReportSummaryPage(),
  '/playback': (context) => PlaybackPage(),
  '/enableNotifications': (context) => EnableNotificationPage(),
  '/eventMap': (context) => EventMapPage(),
  '/notificationMap': (context) => NotificationMapPage(),
  '/geofence': (context) => GeofencePage(),
  '/geofenceList': (context) => GeofenceListPage(),
  '/geofenceAdd': (context) => GeofenceAddPage(),
  '/addDevice': (context) => AddDevicePage(),
  '/maintenance': (context) => MaintenancePage(),
  '/graph': (context) => Graph(),
  '/deviceEdit': (context) => DeviceEdit(),
  '/maintenanceServer':(context) => MaintenanceServer()
};
