import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/CBWTF/apiservice.dart';
import 'package:mpcb_bio_waste/CBWTF/view_detail.dart';
import 'package:mpcb_bio_waste/network/offline.dart';
import 'package:provider/provider.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_routes.dart';
import '../Global/app_textfield.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';


class GetBioWasteData extends StatefulWidget {
  List<dynamic> filteredList;
  GetBioWasteData(this.filteredList,{super.key});
  @override
  State<GetBioWasteData> createState() => _GetBioWasteDataState();
}

class _GetBioWasteDataState extends State<GetBioWasteData> {

   List<bool>? isSelectedList=[];
  bool selectAll = false;
  TextEditingController vehicle=new TextEditingController();
  List <dynamic>selectedHcfs = [];
   final _formKey = GlobalKey<FormState>();



   @override
  void initState() {
    super.initState();
    isSelectedList = List.filled(widget.filteredList!.length, false);
  }
   void resetForm() {
     setState(() {
       // Clear vehicle text
       vehicle.clear();

       // Uncheck all checkboxes
       for (int i = 0; i < isSelectedList!.length; i++) {
         isSelectedList![i] = false;
       }

       // Clear selected HCF list
       selectedHcfs.clear();

       // Unselect the selectAll toggle
       selectAll = false;

       // If using Form
       //_formKey.currentState?.reset();
     });
   }

   void toggleSelectAll(bool? value) {
     setState(() {
       selectAll = value ?? false;

       for (int i = 0; i < isSelectedList!.length; i++) {
         isSelectedList![i] = selectAll;
       }

       // Update selectedHcfs list
       selectedHcfs.clear();
       if (selectAll) {
         selectedHcfs.addAll(widget.filteredList); // assuming widget.hcfList is your full list
       }
     });
   }


   void toggleSelection(int index, bool? value) {
     setState(() {
       isSelectedList![index] = value ?? false;

       final hcf = widget.filteredList[index];
       if (value == true) {
         if (!selectedHcfs.contains(hcf)) {
           selectedHcfs.add(hcf);
         }
       } else {
         selectedHcfs.removeWhere((element) => element['surveyId'] == hcf['surveyId']);
       }

       selectAll = isSelectedList!.every((e) => e);
     });

     print(selectedHcfs.length);
     print(selectedHcfs);

   }


   @override
   Widget build(BuildContext context) {
     SizeConfig().init(context);
     return StreamProvider<NetworkStatus>(
       create: (context) =>
       NetworkStatusService().networkStatusController.stream,
       initialData: NetworkStatus.Online,
       child: NetworkAwareWidget(
       onlineChild:Scaffold(
         body: Stack(
           children: [
           /// Custom Gradient AppBar
           mAppBar(
           scTitle: 'CBWTF Bio Waste Data',
           centerTile: true,
           showLeading: true,
           onLeadingIconClick: () => Navigator.pop(context),
         ),

         /// Body with tabs
         Positioned.fill(
         top: responsiveHeight(110),
     bottom: responsiveHeight(
     0,
     ), // offset to appear below custom app bar
     child: Container(
     decoration: BoxDecoration(
     color: kWhiteColor,
     borderRadius: const BorderRadius.only(
     topRight: Radius.circular(40),
     topLeft: Radius.circular(40),
     ),
     ),
     child:SingleChildScrollView(
        // scrollDirection: Axis.horizontal,
         child: Form(
           key: _formKey,
           child:Column(
           children: [
              SizedBox(height: responsiveHeight(30)),
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
               child: AppTextfield(
                 controller: vehicle,
                 prefixIcon: Icons.fire_truck_outlined,
                 obscureText: false,
                 hintText: 'Assign Vehicle',
                 validator: (value) {
                   if (value == null || value.isEmpty) {
                     return 'Enter vehicle number';
                   }

                   // Optional: Add pattern match for format like MH12AB1234
                   final pattern = r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$';
                   final regExp = RegExp(pattern);

                   if (!regExp.hasMatch(value.toUpperCase().replaceAll(' ', ''))) {
                     return 'Enter valid vehicle number (e.g., MH12AB1234)';
                   }

                   return null;
                 },
               ),
             ),
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 10),
               child: Row(
                 children: [
                   Checkbox(value: selectAll, onChanged: toggleSelectAll),
                   const Text("Select All"),
                 ],
               ),
             ),

             // Table Header
             Container(
               padding: EdgeInsets.symmetric(horizontal: 15),
                 color: Colors.transparent,
                 child: Table(
                   
                   border: TableBorder.symmetric(
                     borderRadius: BorderRadius.all(Radius.circular(20)),
                     inside: BorderSide(color: Colors.grey.shade300),
                   ),
                   columnWidths: const {
                     0: FixedColumnWidth(30),
                     1: FixedColumnWidth(50),
                     2: FixedColumnWidth(90),
                     3: FixedColumnWidth(40),
                     4: FixedColumnWidth(40),
                     5: FixedColumnWidth(40),
                     6: FixedColumnWidth(40),

                   },

                   children: [
                     TableRow(
                       decoration:  BoxDecoration(
                         borderRadius:BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),
                         gradient: LinearGradient(
                           colors: [kPrimaryColor, kPrimaryDarkColor],
                           begin: Alignment.topCenter,
                           end: Alignment.bottomCenter,
                         ),
                       ),
                       children: const [
                         _HeaderCell('Sr. No.'),
                         _HeaderCell('Date'),
                         _HeaderCell('HCF Name'),
                         _HeaderCell('Total\nno. of Bags'),
                         _HeaderCell('Quantity\n(in Kgs)'),
                         _HeaderCell('Action'),
                         _HeaderCell('View'),


                       ],
                     ),
                   ],
                 ),
               ),


             // Table Body
             Padding(padding: EdgeInsets.symmetric(horizontal: 15),
               child:Container(

               decoration: BoxDecoration(
                 border: Border.all(color: Colors.grey.shade300),
                 borderRadius: BorderRadius.circular(5),
               ),
               child: Table(
                 border: TableBorder.symmetric(
                   inside: BorderSide(color: Colors.grey.shade300),
                 ),
                 columnWidths: const {
                   0: FixedColumnWidth(30),
                   1: FixedColumnWidth(50),
                   2: FixedColumnWidth(90),
                   3: FixedColumnWidth(40),
                   4: FixedColumnWidth(40),
                   5: FixedColumnWidth(40),
                   6: FixedColumnWidth(40),

                 },

                 children: List.generate(widget.filteredList!.length, (index) {
                   final hcf = widget.filteredList![index];
                   return TableRow(
                     decoration: const BoxDecoration(color: Colors.white),
                     children: [

                       _DataCell('${index + 1}'),
                       _DataCell(hcf['wasteQtyDate'] ?? '15/07/2025'),
                       _DataCell(hcf['nameOfHcf'] ?? ''),
                       _DataCell('${hcf['totalNoBag'] ?? '50'}'),
                       _DataCell(
                         '${hcf['totalQtyinBag'] ?? '5'}',
                         isBold: true,
                       ),
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                         child: Checkbox(
                           value: isSelectedList![index],
                           onChanged: (val) {
                             setState(() {
                               isSelectedList![index] = val ?? false;
                               toggleSelection(index, val);
                             });
                           },
                         ),
                       ),
                        IconButton(onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HcfDetailsScreen(hcf['hcfCode'])
                            ),
                          );

                        }, icon: Icon(Icons.remove_red_eye_outlined,),)

                      // IconButton(onPressed: (){}, icon: Icon(Icons.remove_red_eye_outlined,color: kPrimaryColor,))

                     ],
                   );
                 }),
               ),
             )),
             SizedBox(height: responsiveHeight(130)),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                 SizedBox(
                   width: responsiveWidth(150),
                   child: AppButton(
                     padding: const EdgeInsets.symmetric(
                       vertical: 5,
                       horizontal: 15,
                     ),
                     text: 'Save',
                     onPressed: () async{
                       setState(() {
                         final vehicleNumber = vehicle.text.trim();

                         // Validate vehicle number field
                         if (!_formKey.currentState!.validate()) {
                           return;
                         }

                         // Validate at least one HCF is selected
                         if (selectedHcfs.isEmpty) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(
                               content: Text("Please select at least one HCF"),
                               backgroundColor: Colors.red,
                             ),
                           );
                           return;
                         }

                         // All validations passed
                         print("Vehicle Number: $vehicleNumber");
                         print("Selected HCF count: ${selectedHcfs.length}");




                       });
                       Map<String,dynamic> value=await ApiService.AssignVehicle(context, selectedHcfs);
                       ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                           content: Text('${value['message']}'),

                         ),
                       );
                      resetForm();



                     },
                     color: Colors.deepOrange,
                   ),
                 ),
                 SizedBox(
                   width: responsiveWidth(150),
                   child: AppButton(
                     padding: const EdgeInsets.symmetric(
                       vertical: 5,
                       horizontal: 15,
                     ),
                     text: 'Delete',
                     onPressed: () => {
                       Navigator.pop(context),},
                     color: Colors.grey.shade400,
                   ),
                 ),
               ],
             ),
           ],
         ),
       ),
     )))])), offlineChild: Offline()));
   }
}

// Header cell widget
class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Data cell widget
class _DataCell extends StatelessWidget {
  final String text;
  final bool isBold;

  const _DataCell(this.text, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Text(
        text,
        style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontSize: 9),
      ),
    );
  }
}