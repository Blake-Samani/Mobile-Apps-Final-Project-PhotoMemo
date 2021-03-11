import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:photomemoapp/screen/addphotomemo_screen.dart';
import 'package:photomemoapp/screen/signin_screen.dart';
import 'package:photomemoapp/screen/userhome_screen.dart';

import 'model/constant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(PhotoMemoApp());
}

class PhotoMemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: Constant.DEV, //from our model of constants
      initialRoute: SignInScreen.routeName,
      routes: {
        SignInScreen.routeName: (context) => SignInScreen(),
        UserHomeScreen.routeName: (context) => UserHomeScreen(),
        AddPhotoMemoScreen.routeName: (context) => AddPhotoMemoScreen(),
      },
    );
  }
}
