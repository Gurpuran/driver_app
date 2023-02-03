import 'package:driver_app/Utils/constants.dart';
import 'package:driver_app/provider/otp_listener.dart';
import 'package:driver_app/screens/phone_verification_screens/otp_verify_screen.dart';
import 'package:driver_app/service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

Future<User?> doGmailLogin() async {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
  if (googleSignInAccount != null) {
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;
    final AuthCredential authCredential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken);

    UserCredential result = await _auth.signInWithCredential(authCredential);
    User? user = result.user;

    if (result != null) {
      return user;
    }
    return null;
  }
}

Future<void> signOut() async {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  try {
    if (!kIsWeb) {
      await googleSignIn.signOut();
    }
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    print("There is some error");
  }
}

String verificationCode = "";
String phoneNumber = "";
Future<void> signInWithPhoneNumber(String number, BuildContext context) async {
  phoneNumber = number;
  List<String>? values = await readData();

  await _auth.verifyPhoneNumber(
    phoneNumber: number,
    verificationCompleted: (PhoneAuthCredential credential) async {
      await _auth.signInWithCredential(credential).then((dynamic result) async {
        Provider.of<OtpProvider>(context,listen: false).setString(credential.smsCode.toString());

      });
    },
    verificationFailed: (FirebaseAuthException e) {
      print("verification failed ${e.code}");
    },
    codeSent: (String verificationId, int? resendToken) async {
      Navigator.push(context,MaterialPageRoute(builder: (BuildContext context)=> OTPVerifyScreen(phoneNumber: number)));
      verificationCode = verificationId;
    },
    codeAutoRetrievalTimeout: (String verificationId) {
      print("Auto reterival time out");
    },
  );
}

Future<void> checkOTP(String smsCode,BuildContext context) async {
  try{
    List<String>? values = await readData();
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationCode, smsCode: smsCode);
    await addUserToDatabase(phoneNumber);
    await _auth.signInWithCredential(credential).then((dynamic result) {
      if(values.contains(phoneNumber)){
        Navigator.of(context).pushNamed("/permissionScreen");
      }
      else{
        Navigator.of(context).pushReplacementNamed("/registrationScreen");
      }
    });
  }catch(e){
    context.showErrorSnackBar(message: "Please enter correct OTP");
  }
}
