import 'dart:typed_data';

import 'package:activity_tracker/models/apps.dart';
import 'package:app_usage/app_usage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future loading;
  List<AppData> topThreeAppDetails = [];
  var totalMinutes = 0;
  var remainingMinutes = 0;
  List<charts.Series<dynamic, String>> seriesList = [];

  @override
  void initState() {
    loading = getAppUsage();
    super.initState();
  }

  List<charts.Series<AppData, String>> _createSampleData() {
    final data = [
      ...topThreeAppDetails,
      AppData(
          'Others',
          remainingMinutes,
          Uint8List(2),
          (remainingMinutes * 100) ~/ totalMinutes,
          const charts.Color(r: 110, g: 101, b: 101))
    ];

    return [
      charts.Series<AppData, String>(
        id: 'Usage',
        domainFn: (AppData appData, _) => appData.appName,
        measureFn: (AppData appData, _) => appData.minutes,
        colorFn: (AppData appData, _) => appData.color,
        data: data,
      )
    ];
  }

  Future<void> getAppUsage() async {
    bool isFirstLoad = true;
    if(topThreeAppDetails.isNotEmpty){
      isFirstLoad = false;
    }
    topThreeAppDetails = [];
    List<AppUsageInfo> info = [];
    List<Application> apps = [];
    List<String> usablePackageName = [];
    List<AppUsageInfo> updatedInfo = [];
    seriesList = [];
    List<charts.Color> colors = [
      const charts.Color(r: 255, g: 89, b: 100),
      const charts.Color(r: 175, g: 19, b: 232),
      const charts.Color(r: 19, g: 232, b: 179)
    ];


    totalMinutes = 0;
    remainingMinutes = 0;

    DateTime startDate = DateTime.now().subtract(
        Duration(hours: DateTime.now().hour, minutes: DateTime.now().minute));
    DateTime endDate = DateTime.now();

    info = await AppUsage.getAppUsage(startDate, endDate);

    apps = await DeviceApps.getInstalledApplications(
        includeSystemApps: true, onlyAppsWithLaunchIntent: true);
    for (var element in apps) {
      usablePackageName.add(element.appName.toLowerCase().replaceAll(' ', ''));
    }

    for (var element in info) {
      if (usablePackageName.contains(element.appName)) {
        updatedInfo.add(element);
      }
    }

    updatedInfo.sort((a, b) => (b.usage.compareTo(a.usage)));
    for (var element in updatedInfo) {
      totalMinutes += element.usage.inMinutes;
    }

    remainingMinutes = totalMinutes;
    int i = 0;
    for (var element in updatedInfo) {
      ApplicationWithIcon app =
          await DeviceApps.getApp(element.packageName, true)
              as ApplicationWithIcon;
      if (topThreeAppDetails.length < 3) {

        topThreeAppDetails.add(AppData(
            element.appName,
            element.usage.inMinutes,
            app.icon,
            element.usage.inMinutes * 100 ~/ totalMinutes,
            colors[i]));
        remainingMinutes -= element.usage.inMinutes;
        i++;
      }
    }


    seriesList = _createSampleData();

    List<Map> topTen = [];
    for (int i = 0; i < 10; i++) {
      topTen.add({
        updatedInfo[i].appName: updatedInfo[i].usage.toString().substring(0, 4)
      });
    }

    await FirebaseFirestore.instance
        .collection('usage')
        .doc('topTen')
        .set({"usageStats": topTen});

    if(!isFirstLoad){
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: loading,
        builder: (context, snapshot) => (snapshot.connectionState ==
                ConnectionState.done)
            ? Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0.0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('assets/images/head.png'),
                  ),
                  title: const Text("Ekam",style:TextStyle(color:Colors.black)),
                ),
                backgroundColor: Colors.white,
                body: Padding(
                  padding: const EdgeInsets.only(top:15.0),
                  child: SingleChildScrollView(
                    child: Center(
                      child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Total Time Spent on Mobile",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                      onPressed: () async {
                                        await getAppUsage();
                                      },
                                      icon: Image.asset('assets/images/reload.png')
                                  )
                                ],
                              ),
                              Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                width: MediaQuery.of(context).size.width * 0.9,
                                child: Stack(
                                  children: [
                                    charts.PieChart<String>(
                                      seriesList,
                                      animationDuration:
                                          const Duration(milliseconds: 500),
                                      animate: true,
                                      defaultRenderer: charts.ArcRendererConfig(
                                          arcWidth: 15),
                                    ),
                                    Center(
                                        child: Text(
                                      (totalMinutes ~/ 60).toString() +
                                          " Hours\n" +
                                          (totalMinutes % 60).toString() +
                                          " Mins",
                                      style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold),
                                    ))
                                  ],
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                child: const Text(
                                  "Top 3 Apps Killing Your Time:",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: ListTile(
                                  leading:
                                      Image.memory(topThreeAppDetails[0].icons),
                                  title: Text(topThreeAppDetails[0].appName),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      (topThreeAppDetails[0].minutes ~/ 60)
                                              .toString() +
                                          " Hours " +
                                          (topThreeAppDetails[0].minutes % 60)
                                              .toString() +
                                          " Mins",
                                      style: const TextStyle(
                                          color: Colors.redAccent),
                                    ),
                                  ),
                                  trailing: Text(
                                    topThreeAppDetails[0].percent.toString() +
                                        "%",
                                    style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: ListTile(
                                  leading:
                                      Image.memory(topThreeAppDetails[1].icons),
                                  title: Text(topThreeAppDetails[1].appName),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      (topThreeAppDetails[1].minutes ~/ 60)
                                              .toString() +
                                          " Hours " +
                                          (topThreeAppDetails[1].minutes % 60)
                                              .toString() +
                                          " Mins",
                                      style: const TextStyle(
                                          color: Colors.redAccent),
                                    ),
                                  ),
                                  trailing: Text(
                                    topThreeAppDetails[1].percent.toString() +
                                        "%",
                                    style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: ListTile(
                                  leading:
                                      Image.memory(topThreeAppDetails[2].icons),
                                  title: Text(topThreeAppDetails[2].appName),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      (topThreeAppDetails[2].minutes ~/ 60)
                                              .toString() +
                                          " Hours " +
                                          (topThreeAppDetails[2].minutes % 60)
                                              .toString() +
                                          " Mins",
                                      style: const TextStyle(
                                          color: Colors.redAccent),
                                    ),
                                  ),
                                  trailing: Text(
                                    topThreeAppDetails[2].percent.toString() +
                                        "%",
                                    style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            ],
                          )),
                    ),
                  ),
                ))
            : const Scaffold(
                body: Center(
                    child: SpinKitWave(
                  color: Colors.redAccent,
                )),
              ));
  }
}
