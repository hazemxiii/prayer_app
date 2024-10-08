import "package:flutter/material.dart";
import "package:geocoding/geocoding.dart";
import "package:geolocator/geolocator.dart";
import "package:shared_preferences/shared_preferences.dart";

class ColorPalette extends ChangeNotifier {
  /// The class is used to rebuild the pages when the color is changed
  Color _main = Colors.lightBlue;
  Color _second = Colors.white;
  Color _back = Colors.lightBlue[50]!;

  // getters
  Color get getMainC => _main;
  Color get getSecC => _second;
  Color get getBackC => _back;

  // setters
  void setMainC(Color c) {
    _main = c;
    // to update everything that uses this class
    notifyListeners();
  }

  void setSecC(Color c) {
    _second = c;
    notifyListeners();
  }

  void setBackC(Color c) {
    _back = c;
    notifyListeners();
  }
}

class Constants {
  static Map prayerNames = {
    0: "Fajr",
    1: "Sunrise",
    2: "Dhuhr",
    3: "Asr",
    4: "Maghrib",
    5: "Isha'a"
  };

  static SharedPreferences? prefs;
  static Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }
}

String getEnglishLanguageDate(String sdate) {
  // converts a date from numbers to weekday, day month
  DateTime dd = DateTime.parse(sdate);
  String day = "";
  int date = dd.day;

  switch (dd.weekday) {
    case 1:
      day = "Monday";
      break;
    case 2:
      day = "Tuesday";
      break;
    case 3:
      day = "Wednesday";
      break;
    case 4:
      day = "Thursday";
      break;
    case 5:
      day = "Friday";
      break;
    case 6:
      day = "Saturday";
      break;
    case 7:
      day = "Sunday";
      break;
  }

  var monthDict = {
    1: "January",
    2: "February",
    3: "March",
    4: "April",
    5: "May",
    6: "June",
    7: "July",
    8: "August",
    9: "September",
    10: "October",
    11: "November",
    12: "December"
  };
  String? month = monthDict[dd.month];

  return "$day, $date $month";
}

String getShortDate(DateTime date, bool toAmerican) {
  // returns the normal or american date as a string
  int day = date.day;
  int month = date.month;
  int year = date.year;

  if (toAmerican) {
    String monthPad = "$month".padLeft(2, "0");
    String dayPad = "$day".padLeft(2, "0");
    return "$year-$monthPad-$dayPad";
  } else {
    return "$day-$month-$year";
  }
}

Future<List> getPosition(bool isCached) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // return Future.error('Location services are disabled.');
    return [];
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // return Future.error('Location permissions are denied');
      return [];
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // return Future.error(
    //     'Location permissions are permanently denied, we cannot request permissions.');
    return [];
  }
  Position? position;
  // get cached position
  if (isCached) {
    if (!prefs.containsKey("lo") || !prefs.containsKey("la")) {
      position = await Geolocator.getCurrentPosition();
      prefs.setDouble("lo", position.longitude);
      prefs.setDouble("la", position.latitude);
    } else {
      // if there's a cached position, update it
      Geolocator.getCurrentPosition().then((updatePosition) {
        prefs.setDouble("lo", updatePosition.longitude);
        prefs.setDouble("la", updatePosition.latitude);
      });
    }
  } else {
    position = await Geolocator.getCurrentPosition();
  }

  List address = [];
  try {
    double la = prefs.getDouble("la")!;
    double lo = prefs.getDouble("lo")!;
    if (!isCached) {
      la = position!.latitude;
      lo = position.longitude;
    }
    var addressData = await placemarkFromCoordinates(la, lo);
    address.add(addressData[0].toJson()['country']);
    address.add(addressData[0].toJson()['administrativeArea']);
    address.add(addressData[0].toJson()['subAdministrativeArea']);
  } catch (e) {
    //
  }

  if (isCached) {
    return [prefs.getDouble("la"), prefs.getDouble("lo"), address];
  }
  return address;
}

Future<void> setPrefs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey("nextPrayerName")) {
    prefs.setString("nextPrayerName", "");
  }
  if (!prefs.containsKey("nextPrayerTime")) {
    prefs.setString("nextPrayerTime", DateTime.now().toString());
  }
}
