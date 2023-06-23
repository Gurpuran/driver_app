import 'package:driver_app/Utils/constants.dart';
import 'package:driver_app/model/user_model.dart';
import 'package:driver_app/provider/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'common_widget.dart';

class ShareAppEarnScreen extends StatefulWidget {
  const ShareAppEarnScreen({Key? key}) : super(key: key);

  @override
  State<ShareAppEarnScreen> createState() => _ShareAppEarnScreenState();
}

//share_app.png
class _ShareAppEarnScreenState extends State<ShareAppEarnScreen> {
  UserModel userModel = UserModel();

  @override
  void initState() {
    super.initState();
    readData();
  }

  void readData() async {
    UserModel model =
        Provider.of<UserModelProvider>(context, listen: false).data;
    setState(() {
      userModel = model;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Share & Earn"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 150,
              color: secondaryColor,
              child: Row(
                children: [
                  const Expanded(
                      flex: 2,
                      child: Text(
                        "Invite your friends & family get Rs.100 per referral",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      )),
                  Expanded(
                      flex: 1,
                      child: Image.asset("assets/images/share_app.png")),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Your invites"),
                  const SizedBox(
                    height: 20,
                  ),
                  cardDetailView(),
                  const SizedBox(
                    height: 200,
                  ),
                  Container(
                    color: Colors.grey[200],
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Referral Code"),
                          Text(
                            FirebaseAuth.instance.currentUser!.uid.toString().substring(1,6),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          )
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      String referral = FirebaseAuth.instance.currentUser!.uid.toString();
                      Share.share(referral,
                          subject: 'Share your referral Code');
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text("Share Code"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showReferAndBox(context, userModel.referred);
                      setState(() {
                        userModel.referred = true;
                      });
                      Provider.of<UserModelProvider>(context, listen: false)
                          .setData(userModel);
                    },
                    style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text("Have a referral Code."),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  cardDetailView() {
    return Card(
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  detailTextView("Rs. 500", "Pending"),
                  const VerticalDivider(
                    width: 2,
                    color: Colors.grey,
                    thickness: 2,
                  ),
                  detailTextView("Rs. 3000", "Earned"),
                ],
              ),
              InkWell(
                onTap: () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "See All",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    Icon(Icons.arrow_forward_ios)
                  ],
                ),
              )
            ],
          ),
        ));
  }

  detailTextView(String value, String title) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: secondaryColor),
        ),
        Text(title)
      ],
    );
  }
}
