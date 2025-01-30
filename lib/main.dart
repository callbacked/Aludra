import 'package:aludra/ble_manager.dart';
import 'package:aludra/controllers/evenai_model_controller.dart';
import 'package:aludra/views/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


void main() {
  BleManager.get();
  Get.put(EvenaiModelController());
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aludra',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
          elevation: 1,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.purple,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF121212),
        cardColor: Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.purple,
          secondary: Colors.purpleAccent,
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
        ),
      ),
      themeMode: ThemeMode.system,
      home: HomePage(), 
    );
  }
}
