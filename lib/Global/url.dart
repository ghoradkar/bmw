const String appVersion = "0.0.0";
//test
String baseurl='http://210.89.42.103:8080/MpcbAPi-Project/api/bioWaste/';//test
String login_baseurl='http://210.89.42.103:8080/MpcbAPi-Project/api/';
String masterurl='http://210.89.42.103:8080/MpcbAPi-Project/api/masters/';

//dev
String baseurl1='http://103.251.94.10:8080/MpcbAPi-Project/api/bioWaste/';//dev
String login_baseurl1='http://103.251.94.10:8080/MpcbAPi-Project/api/';
String masterurl1='http://103.251.94.10:8080/MpcbAPi-Project/api/masters/';


String LOGIN = "auth/login";
String LOGOUT='auth/logout';

//master
String RESET_PASSWORD='users/update-password-user';
String ROLE_TYPE='lookupdet/';

//biowaste

//hcf
String GET_CBWTF='getCBWTFData/';
String ADD_UPDATE_WASTE='save-waste';
String GET_BIO_WASTE_DATA_FOR_HCF='get-bio-waste-data-forhcf?';
String GENERATE_BARCODE='generate-barcode';
String CATEGORY_LOOKUP='colourTypeDropdown?lookupCode=CCD';
String FILTER='get-bio-waste-data-forhcf-byDate';
String MULTIPLE_BARCODE='generate-all-barcode';

//cbwtf
String CBWTF_MAP='get-biowaste-hcf-data';
String CBWTF_ASSIGN_VEHICLE='saveMultipleVehicleAssign';

//vehicleuser
String GET_BIO_WASTE_DATA='getBioWasteData-vehicle?userName=';
String GET_BARCODE_DATA='get-biowaste-data-byBarcode/';
String SAVE_WASTE='saveWasteRecivedData/';

//CBWTF Disposal
String GET_WASTE_RECEIVED_BY_VEHICLE='get-cbwtf-data-completed-vehicle-disposal/';
String GET_BIO_WASTE_DETAILS='getBioWasteDataDetails/';
String SAVE_WASTE_DISPOSAL='saveWasteRecivedData-cbwtf-disposal/';

//CBWTF Reception
String GET_VEHICLE_LIST='get-cbwtf-data-completed/';
String GET_VEHICLE_DETAILS='get-cbwtf-data-completed-vehicle/';
String GET_HCF_LIST='getHcfListByUserId/';
String FILTER_HCF_DATA='get-bio-waste-data-forReception-byDate';



