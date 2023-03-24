import 'dart:async';
import 'dart:math';
import 'package:driver_app/model/trip_model.dart';
import 'package:driver_app/model/user_model.dart';
import 'package:driver_app/provider/user_provider.dart';
import 'package:driver_app/service/push_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

final databaseReference = FirebaseDatabase(
        databaseURL:
            "https://book-my-etaxi-default-rtdb.asia-southeast1.firebasedatabase.app")
    .ref();

String customerKey = "";

Future<void> getUserInformation(BuildContext context, String uid) async {
  databaseReference.child("driver").child(uid).once().then((value) {
    Map map = value.snapshot.value as Map;
    UserModel model = UserModel().getDataFromMap(map);
    // debugPrint("Data fetching is finished");
    Provider.of<UserModelProvider>(context, listen: false).setData(model);
  });
}

Future<void> getUserInfo(
    BuildContext context, String uid, LocationData currentLocation) async {
  databaseReference.child("driver").child(uid).once().then((value) {
    Map map = value.snapshot.value as Map;
    // debugPrint("Values :- ${map.toString()}");
    UserModel model = UserModel().getDataFromMap(map);
    addDriverInfoInTrip(
        context,
        model,
        LatLng(currentLocation.latitude as double,
            currentLocation.longitude as double));
  });
}

Future<void> addUserToDatabase(String name, UserModel model) async {
  try {
    await databaseReference
        .child("driver")
        .child(name)
        .set(UserModel().toMap(model));
  } catch (e) {
    debugPrint(e.toString());
  }
}

Future<bool> checkDatabaseForUser(String uid) async {
  Completer<bool> completer = Completer();
  databaseReference.child("driver").child(uid).onValue.listen((event) {
    completer.complete(event.snapshot.exists);
  });
  return completer.future;
}

Future<void> addDriverInfoInTrip(
    BuildContext context, UserModel userData, LatLng driverLocation) async {
  // debugPrint("Uploading the data");
  int randomNumber = Random().nextInt(9000) + 1000;
  databaseReference.child("trips").child(customerKey).child("driver_info").set({
    "name": userData.name,
    "vehicleNumber": "UK4976 (NOT Store)",
    "phoneNumber": userData.phoneNumber,
    "rating": "4.6",
    "lat": driverLocation.latitude,
    "long": driverLocation.longitude,
    "otp": randomNumber,
    'id': FirebaseAuth.instance.currentUser!.uid.toString()
  });
}

Future<void> updateLatLng(LatLng driver) async {
  if (customerKey.isEmpty) {
    return;
  }
  // debugPrint("Updating LatLng");
  databaseReference
      .child("trips")
      .child(customerKey)
      .child("driver_info")
      .onValue
      .listen((event) {
    if (event.snapshot.exists) {
      databaseReference
          .child("trips")
          .child(customerKey)
          .child("driver_info")
          .update({"lat": driver.latitude, "long": driver.longitude});
    }
  });
}

Future<bool> checkTripOtp(String otp) async {
  Completer<bool> completer = Completer();
  // debugPrint("Checking otp");
  databaseReference
      .child("trips")
      .child(customerKey)
      .child("driver_info")
      .once()
      .then((value) {
    Map map = value.snapshot.value as Map;
    // debugPrint(((map["otp"] ?? 0) == otp).toString());
    completer.complete((map["otp"] ?? 0).toString() == otp);
  });
  return completer.future;
}

Future<void> uploadDummyData(Map map) async {
  databaseReference.child("trips").push().set(map);
}

Future<void> uploadDocumentPhoto(String key) async {
  await databaseReference
      .child("driver")
      .child(FirebaseAuth.instance.currentUser!.uid.toString())
      .child("documents")
      .update({key: true});
}

Future<void> uploadTripHistory(Map map) async {
  TripModel model = TripModel().convertFromTrip(map);
  await databaseReference
      .child("driver")
      .child(FirebaseAuth.instance.currentUser!.uid.toString())
      .child("history")
      .push()
      .set(TripModel().toMap(model));
}

Future<List<TripModel>> fetchHistoryTrip() async {
  Completer<List<TripModel>> completer = Completer();
  List<TripModel> list = [];
  await databaseReference
      .child("driver")
      .child(FirebaseAuth.instance.currentUser!.uid.toString())
      .child("history")
      .once()
      .then((value) {
    for (var data in value.snapshot.children) {
      Map map = data.value as Map;
      TripModel model = TripModel().fromMap(map);
      list.add(model);
    }
  });
  return completer.future;
}

Future<void> uploadRatingUser(
    Map map, double stars, String title, String name) async {
  await databaseReference
      .child("customer")
      .child(map["id"])
      .child("rating")
      .push()
      .set({"rating": stars, "description": title, "customerName": name});
}

Future<void> updateFinishTrip() async {
  await databaseReference
      .child("trips")
      .child(customerKey)
      .update({"isFinished": true});
}

Future<void> checkDataChanges(BuildContext context) async {
  databaseReference
      .child("trips")
      .child(customerKey)
      .onChildAdded
      .listen((event) {
        if(event.snapshot.key=="cancel_trip"){
            Map map = event.snapshot.value as Map;
            String reason = map["reason"];
            NotificationService().showNotification("Customer has cancelled the ride", "Reason $reason");
            Navigator.of(context).pop();
        }
  });
}

Future<void> uploadTripStartData() async {
  databaseReference
      .child("trips")
      .child(customerKey)
      .update({"tripStarted": true});
}
