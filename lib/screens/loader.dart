import 'package:app_usage/app_usage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:usage_stats/usage_stats.dart';
import 'home_screen.dart';

class Loader extends StatefulWidget {
  const Loader({Key? key}) : super(key: key);

  @override
  _LoaderState createState() => _LoaderState();
}

class _LoaderState extends State<Loader> {
  late bool isGranted;
  
  Future<void> load() async{

    isGranted = await UsageStats.checkUsagePermission();
    if(!isGranted){
      await UsageStats.grantUsagePermission().timeout(Duration(seconds: 10));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:  load(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Scaffold(
            body: Center(
                child: SpinKitWave(
                  color: Colors.redAccent,
                )),
          );
        }
        else{
          return 
          (isGranted)?const HomeScreen():Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Center(
                    child: Text(
                      "Please enable usage access permissions in the settings. \n If enabled press the reload button",
                    )),
                const SizedBox(width: 10),
                IconButton(
                    onPressed: () {
                      setState(() {});
                    },
                    icon: Image.asset('assets/images/reload.png')
                )
              ],
            ),
          );
        }
      }
    );
  }
}
