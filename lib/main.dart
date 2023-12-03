import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final String title;
  String? _latestVersion;
  AppUpdateInfo? _updateInfo;
  int? appVersion;
  String? _whatsNew;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      fetchIOSLatestVersion();
    } else {
      checkForAndroidUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("App Update"),
      ),
      body: const Center(
        child: Text(
          'App is UpToDate',
        ),
      ),
    );
  }

  //ios
  Future<void> fetchIOSLatestVersion() async {
    final response = await http.get(Uri.parse(
        'https://itunes.apple.com/lookup?bundleId=bundleID')); // Pass bundleID=com.example.app.update // your applicationID
    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);
      final appInfo = decodedResponse['results'][0];
      _latestVersion = appInfo['version'];
      _whatsNew = appInfo['releaseNotes'];
      checkIOSUpgrade();
    }
  }

  Future<void> checkIOSUpgrade() async {
    final currentVersion = await getAppVersion();
    final latestVersion = _latestVersion;
    if (latestVersion != null && latestVersion != currentVersion) {
      const appStoreLink = 'https://itunes.apple.com/app/id6459447979';
      if (mounted) {
        showUpgradeForIOSDialog(context, appStoreLink);
      }
    } else {
      // App is UpToDate next flow
    }
  }

  Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<void> showUpgradeForIOSDialog(
      BuildContext context, String appStoreLink) async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Upgrade Available"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  "A new version of the app is available. Do you want to upgrade?"),
              if (_whatsNew != null) const SizedBox(height: 10),
              if (_whatsNew != null) const Text('What\'s New:'),
              if (_whatsNew != null) Text(_whatsNew!),
            ],
          ),
          actions: [
            Column(
              children: [
                TextButton(
                  child: const Text(
                    "Update",
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    launchUrlString(appStoreLink);
                  },
                ),
                TextButton(
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {},
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Future<void> checkForAndroidUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      _updateInfo = info;
      appVersion = _updateInfo?.availableVersionCode;
      if (_updateInfo?.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        InAppUpdate.performImmediateUpdate().then((value) {
          if (mounted) {
            // After app update next flow
          }
        });
      } else {
        // if app is latest version next flow
      }
    } catch (e) {
      if (mounted) {
        // if error happens next flow
      }
    }
  }
}
