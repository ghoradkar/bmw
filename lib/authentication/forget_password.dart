import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mpcb_bio_waste/Global/url.dart';
import 'package:mpcb_bio_waste/authentication/login_screen.dart';
import 'package:provider/provider.dart';



import 'package:shared_preferences/shared_preferences.dart';

import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';


class ForgotPassword extends StatefulWidget {
  Map<String,dynamic>value={};
  ForgotPassword(this.value,{super.key});

  @override
  ForgotPasswordState createState() => ForgotPasswordState();
}

class ForgotPasswordState extends State<ForgotPassword> {



  @override
  void initState() {
    //print(widget.value);
    // fetchLab();

    super.initState();
  }

  final formKey = GlobalKey<FormState>();
  FocusNode femail = new FocusNode();
  FocusNode fpassword = new FocusNode();
  TextEditingController email = new TextEditingController();
  TextEditingController password = new TextEditingController();

  Reset_Password(password) async {
    Map<String,dynamic> data=widget.value;
    //print('hgfg');
    //print(data);
    final uri = Uri.parse('${masterurl}${RESET_PASSWORD}');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json ; charset=UTF-8',
      'Authorization': 'Bearer ${data['jwtToken']}',
    };
    final body =
    {
      "userId":data['tmUsers']['userId'],

      "password": password,
      "floginPwreset": "N"

    };
    final jsonbody = json.encode(body);
    //print(jsonbody);
    final response = await http.post(uri, headers: headers, body: jsonbody

      //encoding: encoding,
    );



    //print(response.body);
    Map<String, dynamic> value=jsonDecode(response.body);
    value['status']=='success'?{
      // val= jsonDecode(response.body),
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => LoginScreen('yes'))),
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Please Login With New Password')),
    ),
    }:{
      //print(response.body),
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value['message'])),
      ),
    };

  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<NetworkStatus>(
        create: (context) =>
        NetworkStatusService().networkStatusController.stream,
        initialData: NetworkStatus.Online,
        child: NetworkAwareWidget(
        onlineChild:GestureDetector(
                onTap: () {
                  FocusScopeNode currentFocus = FocusScope.of(context);

                  if (!currentFocus.hasPrimaryFocus) {
                    currentFocus.unfocus();
                  }
                },
                child: Scaffold(
                    resizeToAvoidBottomInset: false,

                    body:Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/background.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child:





                        Column(children: [
                          //  Column(children: [SizedBox(height: MediaQuery.of(context).size.height*0.1),
                          //   Text('Sign In',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,
                          //       fontSize: 20),),
                          //   Text('Welcome! Enter username & password ',style: TextStyle(color: Colors.white),),
                          //   Text('to continue.',style: TextStyle(color: Colors.white),),]),
                          SizedBox(height: 40),
                          Align(
                            alignment: Alignment.topLeft,
                            child:IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_ios,color: Colors.white,)),),

                          //SizedBox(height: MediaQuery.of(context).size.height*0.01),
                          //  Image.asset('assets/reset.png'),
                          SizedBox(height:70),

                          Center(child:Container(
                              decoration: BoxDecoration(color: Colors.white,
                                  boxShadow: [
                                    // BoxShadow(
                                    //   color: Colors.black.withOpacity(0.5),
                                    //   offset: Offset(0, 4), // Shadow on top
                                    //   blurRadius: 10,
                                    // ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      offset: Offset(4, 0), // Shadow on the right
                                      blurRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      offset: Offset(-4, 0), // Shadow on the left
                                      blurRadius: 10,
                                    ),
                                  ],
                                  borderRadius: BorderRadius.only(topRight: Radius.circular(10),
                                      topLeft: Radius.circular(10))),
                              height: 649,
                              width:350,
                              child:Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 40,),

                                    // SizedBox(height: 150,width: 150,
                                    //     child:Image.asset('assets/logoo.png',)),
                                    //height: MediaQuery.of(context).size.height*0.2,width: MediaQuery.of(context).size.width*0.2,)),
                                    // Text('Maharashtra',style: TextStyle(fontWeight:FontWeight.w800,fontSize:15,fontFamily: 'Nunito',),),
                                    Text('Reset Password',style: TextStyle(fontWeight:FontWeight.w800,fontSize: 20,fontFamily: 'Nunito'),),
                                    SizedBox(height: 20,),
                                    Text('Set a new password to your account \n      and re login with the new one',style: TextStyle(fontSize: 12,fontFamily: 'Nunito'),),
                                    SizedBox(height: 40,),
                                    Padding(
                                        padding: EdgeInsets.all(10),
                                        child:TextFormField(

                                            textInputAction: TextInputAction.next,
                                            onEditingComplete: () => FocusScope.of(context).nextFocus(),
                                            focusNode: femail,
                                            autofocus: true,
                                            controller: email,
                                            validator: (value) {
                                              if (value!.isEmpty ) {
                                                return "Enter New Password";
                                              } else {
                                                return null;
                                              }
                                            },
                                            style: TextStyle(color: Colors.black,fontSize: 14),
                                            cursorColor: Colors.blue.shade800,
                                            decoration: InputDecoration(


                                              prefixIcon: Padding(padding: EdgeInsets.only(left: 5,right: 5),child:ShaderMask(
                                                shaderCallback: (bounds) {
                                                  return LinearGradient(
                                                    colors: [Color.fromRGBO(75, 197, 217, 1),Color.fromRGBO(21, 144, 207, 1)], // Gradient colors
                                                    begin: Alignment.topLeft,  // Gradient start
                                                    end: Alignment.bottomRight,  // Gradient end
                                                  ).createShader(bounds);
                                                },
                                                child: Icon(
                                                  Icons.password, // The icon to apply the gradient
                                                  size: 20,  // Icon size
                                                  color: Colors.white,  // Icon color (this will be overridden by the gradient)
                                                ),
                                              )),

                                              hintText: 'New Password',
                                              // labelText: 'Username',
                                              // labelStyle: TextStyle(color: Colors.grey),
                                              // floatingLabelStyle: TextStyle(color: Colors.white),

                                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                                              //hintStyle: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                                              contentPadding: EdgeInsets.only(bottom: -5),

                                              enabledBorder:  OutlineInputBorder(
                                                //<-- SEE HERE
                                                borderSide: BorderSide(color: Colors.grey.shade400),
                                              ),
                                            ))),
                                    SizedBox(height: 10,),


                                    Padding(
                                        padding: EdgeInsets.all(10),
                                        child:TextFormField(

                                          textInputAction: TextInputAction.next,
                                          onEditingComplete: () => FocusScope.of(context).nextFocus(),
                                          focusNode: fpassword,
                                          autofocus: true,
                                          controller: password,
                                          validator: (value) {
                                            // if (value!.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                            //   return "Enter Correct Email Address";
                                            // } else {
                                            //   return null;
                                            // }
                                          },
                                          style: TextStyle(color: Colors.black,fontSize: 14),
                                          cursorColor: Colors.blue.shade800,
                                          decoration: InputDecoration(

                                            prefixIcon: Padding(padding: EdgeInsets.only(left: 5,right: 5),child:ShaderMask(
                                              shaderCallback: (bounds) {
                                                return LinearGradient(
                                                  colors: [Color.fromRGBO(75, 197, 217, 1),Color.fromRGBO(21, 144, 207, 1)], // Gradient colors
                                                  begin: Alignment.topLeft,  // Gradient start
                                                  end: Alignment.bottomRight,  // Gradient end
                                                ).createShader(bounds);
                                              },
                                              child: Icon(
                                                Icons.password, // The icon to apply the gradient
                                                size: 20,  // Icon size
                                                color: Colors.white,  // Icon color (this will be overridden by the gradient)
                                              ),
                                            )),

                                            hintText: 'Confirm Password',
                                            // labelText: 'Username',
                                            // labelStyle: TextStyle(color: Colors.grey),
                                            // floatingLabelStyle: TextStyle(color: Colors.white),

                                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                                            //hintStyle: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                                            contentPadding: EdgeInsets.only(bottom: -5),

                                            enabledBorder:  OutlineInputBorder(
                                              //<-- SEE HERE
                                              borderSide: BorderSide(color: Colors.grey.shade400),
                                            ),
                                          ),
                                        )),
                                    SizedBox(height: 10,),
                                    Padding(padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                                      child:Text("Note : The password must contain alphabet with 8 characters long and included at "
                                          "least one number or \nspecial character. \nSpecial Characters allowed (@, !, #, \$, _)",
                                        style: TextStyle(fontSize: 10),
                                      ),),

                                    SizedBox(height: 30,),

                                    Center(
                                        child: SizedBox(
                                            width:300,
                                            height: 40,
                                            child: TextButton(
                                                style: ButtonStyle(
                                                  shape: WidgetStateProperty.all<
                                                      RoundedRectangleBorder>(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius.circular(
                                                            20.0),
                                                        // side: BorderSide(color: Colors.red)
                                                      )),
                                                  backgroundColor:
                                                  WidgetStateProperty.all<
                                                      Color>(
                                                      Colors.deepOrange),
                                                ),
                                                onPressed: (){
                                                  email.text==password.text?

                                                  Reset_Password(password.text)

                                                      :
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Please Check Input')),
                                                  );

                                                },
                                                child:  Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                    children: [
                                                      Padding(
                                                          padding:
                                                          EdgeInsets.only(
                                                              left: 10),
                                                          child: Text(
                                                            'Reset Password',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14),
                                                          )),
                                                      Icon(
                                                        Icons.arrow_forward,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ])

                                            ))),


                                  ])


                          )



                          ),

                        ])



                    ))
            ), offlineChild: Offline()));}}
