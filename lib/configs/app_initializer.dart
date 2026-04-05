// class AppInitializer {
//   static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
//     await ConnectivityService().initialize();
//
//     await FirebaseInitializer.init();
//
//     await setupServiceLocator();
//
//     await SharedPrefsService.handleFirstRun();
//
//     await CallKitService.init();
//
//     await NotificationService.init(navigatorKey);
//
//     await CameraService.init();
//
//     OrientationHelper.lockPortrait();
//   }
// }
