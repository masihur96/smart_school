// import 'package:flutter/material.dart';
//
// class AppProviders extends StatelessWidget {
//   final Widget child;
//   const AppProviders({required this.child});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => ThemeProvider()),
//
//         ChangeNotifierProvider(
//           create: (_) => AttendanceViewModel(
//             getAttendanceStatusUseCase: GetAttendanceStatusUseCase(
//               AttendanceRepositoryImpl(
//                 AttendanceRemoteDataSource(DataProvider()),
//               ),
//             ),
//             submitAttendanceActionUseCase: SubmitAttendanceActionUseCase(
//               AttendanceRepositoryImpl(
//                 AttendanceRemoteDataSource(DataProvider()),
//               ),
//             ),
//           ),
//         ),
//
//         ChangeNotifierProvider(
//           create: (_) => MeetingViewModel(
//             getMeetingsUseCase: GetMeetingsUseCase(
//               MeetingRepositoryImpl(
//                 MeetingRemoteDataSource(DataProvider()),
//               ),
//             ),
//           ),
//         ),
//
//         ChangeNotifierProvider(
//           create: (_) => sl<EmployeeViewModel>()..init(),
//         ),
//       ],
//       child: AppConnectivityWrapper(child: child),
//     );
//   }
// }
