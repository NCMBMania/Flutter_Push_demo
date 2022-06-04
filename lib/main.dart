import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:push/push.dart';
import 'package:ncmb/ncmb.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() {
  NCMB("425e7448a1a92960631490f70cefcd3ca13a05b92d9a6a608044e3442bb26034",
      "7d6b81affe64be441ba8d7c158ac8fc4886f09974bcd2cfe072c32ccc2602f7c");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _deviceToken = "未取得";

  @override
  void initState() {
    super.initState();
    Push.instance.onNotificationTap.listen((data) {
      // プッシュ通知を開いた場合
      print('Notification was tapped:\n'
          'Data: ${data} \n');
      // tappedNotificationPayloads.value += [data];
    });
    Push.instance.onNewToken.listen((token) {
      debugPrint("token $token");
      setState(() {
        _deviceToken = token;
      });
      saveToken();
    });
    Push.instance.notificationTapWhichLaunchedAppFromTerminated.then((data) {
      if (data == null) {
        // アプリ起動時
        debugPrint("App was not launched by tapping a notification");
      } else {
        debugPrint('Notification tap launched app from terminated state:\n'
            'RemoteMessage: ${data} \n');
      }
    });
    Push.instance.onMessage.listen((message) {
      debugPrint('RemoteMessage received while app is in foreground:\n'
          'RemoteMessage.Notification: ${message.notification} \n'
          ' title: ${message.notification?.title.toString()}\n'
          ' body: ${message.notification?.body.toString()}\n'
          'RemoteMessage.Data: ${message.data}');
    });
    Push.instance.onBackgroundMessage.listen((message) async {
      debugPrint('RemoteMessage received while app is in background:\n'
          'RemoteMessage.Notification: ${message.notification} \n'
          ' title: ${message.notification?.title.toString()}\n'
          ' body: ${message.notification?.body.toString()}\n'
          // message.notification.title = message.data['title'] as String;

          'RemoteMessage.Data: ${message.data}');
      final title = message.data!['title'] as String;
      final body = message.data!['message'] as String;
      if (Platform.isAndroid) {
        const androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'remote_notification', 'リモート通知',
            channelDescription: 'リモートの通知です',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_notification',
            ticker: 'ticker');
        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(android: androidPlatformChannelSpecifics);
        await flutterLocalNotificationsPlugin.show(
            0, title, body, platformChannelSpecifics,
            payload: json.encode(message.data));
      }
    });
  }

  void getToken() async {
    var token = await Push.instance.token;
    debugPrint("token $token");
    if (token != null) {
      setState(() {
        _deviceToken = token;
      });
    }
  }

  void saveToken() async {
    try {
      var installation = NCMBInstallation();
      installation
        ..set("badge", 0)
        ..set("deviceToken", _deviceToken)
        ..set("deviceType", Platform.isIOS ? "ios" : "android");
      await installation.save();
    } catch (e) {
      debugPrint("エラー ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(onPressed: getToken, child: const Text("プッシュ通知を受け取る")),
            Text("トークン： $_deviceToken")
          ],
        ),
      ),
    );
  }
}
