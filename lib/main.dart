import 'package:finaltasktastic/scripts/data_handler.dart';
import 'package:finaltasktastic/pages/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initMarketplace();
  await Supabase.initialize(
    url: 'https://jarkleengajbahlqwhwn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphcmtsZWVuZ2FqYmFobHF3aHduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNTc3NTgsImV4cCI6MjA4NzkzMzc1OH0.ITXQ3kIitZKqyPKtJ9E45TbNro9K6imnZiHxyCRAEzQ',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskTable()),
        ChangeNotifierProvider(create: (_) => Player()),
        ChangeNotifierProvider(create: (_) => PetHolder()),
      ],
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(
          seedColor: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: LandingPage(),
    );
  }
}
