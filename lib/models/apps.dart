import 'dart:typed_data';
import 'package:charts_flutter/flutter.dart' as charts;


class AppData{
   final String appName;
   final int minutes;
   final Uint8List icons;
   final int percent;
   final charts.Color color;

   AppData(this.appName,this.minutes,this.icons,this.percent,this.color);
}