const String appVersion = "1.5";
//test
String baseurl2='http://210.89.42.103:8080/MpcbAPi-Project/api/bioWaste/';//test
String login_baseurl2='http://210.89.42.103:8080/MpcbAPi-Project/api/';
String masterurl2='http://210.89.42.103:8080/MpcbAPi-Project/api/masters/';

//dev
String baseurl1='http://103.251.94.10:8080/MpcbAPi-Project/api/bioWaste/';//dev
String login_baseurl1='http://103.251.94.10:8080/MpcbAPi-Project/api/';
String masterurl1='http://103.251.94.10:8080/MpcbAPi-Project/api/masters/';

//prod

String baseurl='http://103.228.151.87:8080/MpcbAPi-Project/api/bioWaste/';//dev
String login_baseurl='http://103.228.151.87:8080/MpcbAPi-Project/api/';
String masterurl='http://103.228.151.87:8080/MpcbAPi-Project/api/masters/';


String LOGIN = "auth/login";
String LOGOUT='auth/logout';

//master
String RESET_PASSWORD='users/update-password-first-user';
String ROLE_TYPE='lookupdet/';
String HCF_TYPE='users/gethcfType';
String GET_DATA_BY_PINCODE='users/getDetByPincode/';
String NEW_HCF_REGISTRATION='users/saveNewHcf';

//biowaste

//hcf
String GET_CBWTF='getCBWTFData/';
String ADD_UPDATE_WASTE='save-waste';
String GET_BIO_WASTE_DATA_FOR_HCF='get-bio-waste-data-forhcf?';
String GENERATE_BARCODE='generate-barcode';
String CATEGORY_LOOKUP='colourTypeDropdown?lookupCode=CCD';
String FILTER='get-bio-waste-data-forhcf-byDate';
String MULTIPLE_BARCODE='generate-all-barcode';
String GENERATE_QRCODE='generate-qrCode';
String MULTIPLE_QR='generate-all-qrCode';
String SEND_TO_CBWTF='updateCbwtfFlag?wasteId=';

//cbwtf
String CBWTF_MAP_LIST='get-biowaste-hcf-data';
String CBWTF_ASSIGN_VEHICLE='saveMultipleVehicleAssign';
String CBWTF_MAP='getHcfListByUserId';
String CBWTF_MAP_MULTIPLE_HCF='getCBWTFDataByHcfId?hcfId=';
String CBWTF_MAP_DATA='getCBWTFData/';
String GET_VEHICLE_USERS='getVehicleUsers';
String CBWTF_DASHBOARD_COUNT='cbwtfDashboardCOunt';
String SEARCH_ASSIGNED_VEHICLE='vehicle-assign-search';

//vehicleuser
String GET_BIO_WASTE_DATA='getBioWasteData-vehicle?userName=';
String SAVE_WASTE='saveWasteRecivedData/';
String GET_QR_DATA='get-biowaste-data-byQrCode/';
String GET_VEHICLE_LIST_BYUSERID='getVehicleHcfListByUserId/';
String VEHICLE_DASHBOARD_COUNT='vehicleDashboardCOunt';
String SEARCH_ASSIGNED_VEHICLELIST='vehicle-bio-waste-data-pickup';

//CBWTF Disposal
String GET_WASTE_RECEIVED_BY_VEHICLE='get-cbwtf-data-completed-vehicle-disposal/';
String GET_BIO_WASTE_DETAILS='getBioWasteDataDetails/';
String GET_BARCODE_DATA='get-biowaste-data-byBarcode/';
String SAVE_WASTE_DISPOSAL='saveWasteRecivedData-cbwtf-disposal/';
String GET_DISPOSAL_DATA='get-cbwtf-disposal-data-completed?';
String VIEW_DATA='get-cbwtf-dispsoal-data-completed-vehicle-newflow';
String GET_OVERALL_DISPOSAL_DATA='get-cbwtf-dispsoal-data-completed-vehicle-newflow';
String SAVE_OVERALL_DISPOSAL_DATA='save-cbwtf-disposal-data-newlflow';
String GET_DATA_FROM_QR='getBioWastedisposalByQrcode/';
String DISPOSAL_SEARCH='get-cbwtf-data-completed-vehicle-disposal-search';

//CBWTF Reception
String GET_VEHICLE_LIST='get-cbwtf-data-completed/';
String GET_VEHICLE_DETAILS='get-cbwtf-data-completed-vehicle/';
String GET_HCF_LIST='getHcfListByUserId/';
String FILTER_HCF_DATA='get-bio-waste-data-forReception-byDate';
String GET_OVERALL_DATA='get-cbwtf-data-completed-vehicle-newflow/';
String SAVE_OVERALL_DATA='save-cbwtf-reception-data-newlflow';
String SCAN_QR_CODE='get-biowaste-rec-data-byQrCode/';
String SAVE_RECEPTION_DATA='saveWasteRecivedData-reception/';
String FILTER_RECEPTION_DATA='get-cbwtf-data-completed-vehicle-reception-search';



