import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_dropdown.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../Localization/app_localization.dart';
import '../localization/provider.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({Key? key}) : super(key: key);

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {

  String? uploadedFileName;


  Map<String, dynamic>? selectedDocType;
  List<Map<String, dynamic>> docTypes = [
    {'id': 1, 'name': 'Aadhar Card'},
    {'id': 2, 'name': 'PAN Card'},
    {'id': 3, 'name': 'Passport'},
  ];


  void _resetForm() {
    setState(() {
      selectedDocType = null;
      uploadedFileName = null;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        uploadedFileName = result.files.first.name;
      });
    }
  }

  void _saveDocument() {
    if (selectedDocType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a document type')),
      );
      return;
    }

    if (uploadedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a document')),
      );
      return;
    }

    // TODO: Add save/upload logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Document "$uploadedFileName" saved as "$selectedDocType"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final t = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();

    return Scaffold(
      body: Stack(
        children: [
        mAppBar(
        scTitle:  t.translate('need_help'),
        centerTile: false,
        showLeading: true,
        onLeadingIconClick: () => Navigator.pop(context),
      ),

      Positioned(
        top: responsiveHeight(100),
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          decoration: const BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child:  Column(
                children: [
                  // Document Type Dropdown
                  validatedApiDropdown(
                    hint:  t.translate('document_type'),
                    value: selectedDocType,
                    items: docTypes,
                    displayKey: 'name',
                    icon: Icons.folder_open,
                    errorText: "Please select a document type",
                    onChanged: (val) {
                      setState(() {
                        selectedDocType = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Upload Box
                  GestureDetector(
                    onTap: (){
                      //_pickFile;
                      },
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Center(
                        child: uploadedFileName == null
                            ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children:  [
                           // SizedBox(height: 10,),
                            Container(
                              padding:EdgeInsets.all(10),
                              
                              decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(30)),

                              border: Border.all(color: kPrimaryColor,width: 2)),
                                child:
                                Icon(Icons.upload_outlined, size: 30, color:kPrimaryColor)),
                            SizedBox(height: 8),
                            Text(
    t.translate('click_to_upload'),
                              style: TextStyle(
                                  color: kPrimaryColor, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${t.translate('max_file')}\n${t.translate('file_format')}',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                            : Text(
                          uploadedFileName!,
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 130,
                    child: AppButton(
                      text:  t.translate('cancel'),
                      color: Colors.grey.shade400,
                      onPressed: _resetForm, padding: EdgeInsets.all(10),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: AppButton(
                      text:  t.translate('save'),
                      color: Colors.deepOrange,
                      onPressed: () {



                      }, padding: EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),

                ],
              ),
            ),
          ),
        )) ],
      ),
    );
  }
}
