import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/CBWTF/apiservice.dart';
import 'package:mpcb_bio_waste/CBWTF/view_detail.dart';
import 'package:mpcb_bio_waste/Localization/app_localization.dart';
import 'package:provider/provider.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_dialog.dart';
import '../Global/app_textfield.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

/// Pops with `true` when at least one HCF was assigned, so the map screen
/// knows to reload.
class SelectedHcfsAssignScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedHcfs;
  final Map<String, dynamic> vehicle;

  const SelectedHcfsAssignScreen({
    super.key,
    required this.selectedHcfs,
    required this.vehicle,
  });

  @override
  State<SelectedHcfsAssignScreen> createState() =>
      _SelectedHcfsAssignScreenState();
}

class _SelectedHcfsAssignScreenState extends State<SelectedHcfsAssignScreen> {
  late final List<Map<String, dynamic>> _rows;
  final Set<dynamic> _checkedIds = {};
  final TextEditingController _driverController = TextEditingController();
  bool _saving = false;
  bool _assignedAny = false;

  @override
  void initState() {
    super.initState();
    _rows = List<Map<String, dynamic>>.from(widget.selectedHcfs);
  }

  @override
  void dispose() {
    _driverController.dispose();
    super.dispose();
  }

  bool get _allChecked =>
      _rows.isNotEmpty && _rows.every((r) => _checkedIds.contains(r['hcfId']));

  String _formatDate(Map<String, dynamic> item) {
    final String? raw = (item['wasteQntyDate'] ?? item['wasteQtyDate'])?.toString();
    if (raw == null || raw.isEmpty) return '-';
    final date = raw.length > 10 ? raw.substring(0, 10) : raw;
    final parts = date.contains('-') ? date.split('-') : date.split('/');
    if (parts.length != 3) return raw;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '-';
    final n = value is num ? value : num.tryParse(value.toString());
    if (n == null) return value.toString();
    return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  }

  Future<void> _save(AppLocalizations t) async {
    if (_saving) return;

    final selected =
        _rows.where((r) => _checkedIds.contains(r['hcfId'])).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.translate('select_at_least_one_hcf')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final payloads = await ApiService.buildWastePayloadList(
      inputList: selected,
      vehicle: widget.vehicle,
      driverName: _driverController.text,
    );

    final assignedIds = <dynamic>[];
    String? failMessage;

    for (var i = 0; i < payloads.length; i++) {
      if (!mounted) return;
      try {
        final value = await ApiService.AssignVehicle(context, payloads[i]);
        if (value['status'] == 'Succes') {
          assignedIds.add(selected[i]['hcfId']);
        } else {
          failMessage = value['message']?.toString() ?? 'Vehicle assign failed';
        }
      } catch (e) {
        failMessage = 'Vehicle assign failed';
      }
    }

    if (!mounted) return;
    setState(() {
      _rows.removeWhere((r) => assignedIds.contains(r['hcfId']));
      _checkedIds.removeAll(assignedIds);
      if (assignedIds.isNotEmpty) _assignedAny = true;
      _saving = false;
    });

    if (failMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failMessage), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => SuccessDialog(
            buttonText: t.translate('ok'),
            message: t.translate('vehicle_assigned'),
            onOk: () => Navigator.pop(context, true),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final t = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _assignedAny);
      },
      child: StreamProvider<NetworkStatus>(
        create: (context) =>
            NetworkStatusService().networkStatusController.stream,
        initialData: NetworkStatus.Online,
        child: NetworkAwareWidget(
          onlineChild: Scaffold(
            body: Stack(
              children: [
                mAppBar(
                  scTitle: t.translate('selected_hcfs_for_assigning'),
                  centerTile: true,
                  leadingWidget: IconButton(
                    onPressed: () => Navigator.pop(context, _assignedAny),
                    icon: const Icon(Icons.arrow_back, color: kWhiteColor),
                  ),
                  showLeading: true,
                ),
                Positioned.fill(
                  top: responsiveHeight(110),
                  bottom: responsiveHeight(0),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      color: kWhiteColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(40),
                        topLeft: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildVehicleBox(t),
                                const SizedBox(height: 12),
                                _buildSelectAll(t),
                                const SizedBox(height: 8),
                                _buildTable(t),
                                const SizedBox(height: 20),
                                AppTextfield(
                                  hintText: t.translate('enter_driver_name'),
                                  controller: _driverController,
                                  prefixIcon: Icons.person_outline,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: responsiveWidth(200),
                          child: AppButton(
                            text: t.translate('save'),
                            isLoading: _saving,
                            onPressed: () => _save(t),
                            color: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          offlineChild: Offline(),
        ),
      ),
    );
  }

  Widget _buildVehicleBox(AppLocalizations t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          const Icon(Icons.fire_truck_outlined, color: kPrimaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              (widget.vehicle['vehicleNo'] ?? t.translate('assign_vehicle'))
                  .toString(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAll(AppLocalizations t) {
    return Row(
      children: [
        Checkbox(
          value: _allChecked,
          activeColor: kPrimaryColor,
          onChanged:
              (val) => setState(() {
                if (val == true) {
                  _checkedIds.addAll(_rows.map((r) => r['hcfId']));
                } else {
                  _checkedIds.clear();
                }
              }),
        ),
        Text(t.translate('select_all'), style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _cell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTable(AppLocalizations t) {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade300,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(0.8),
        1: FlexColumnWidth(2.0),
        2: FlexColumnWidth(2.0),
        3: FlexColumnWidth(1.3),
        4: FlexColumnWidth(1.4),
        5: FlexColumnWidth(2.5),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              topLeft: Radius.circular(10),
            ),
            gradient: LinearGradient(
              colors: [Color(0xFF00B4DB), Color(0xFF0099CC)],
            ),
          ),
          children: [
            _headerCell(t.translate('srno')),
            _headerCell(t.translate('date')),
            _headerCell(t.translate('hcf_name')),
            _headerCell(t.translate('total_bags')),
            _headerCell(t.translate('quantity_kgs')),
            _headerCell(t.translate('action')),
          ],
        ),
        for (int i = 0; i < _rows.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i % 2 == 0 ? Colors.white : Colors.grey.shade50,
            ),
            children: [
              _cell('${i + 1}'),
              _cell(_formatDate(_rows[i])),
              _cell((_rows[i]['nameOfHcf'] ?? '-').toString()),
              _cell(_formatNumber(_rows[i]['totalNoBag'])),
              _cell(_formatNumber(_rows[i]['totalQtyinBag']), bold: true),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.remove_red_eye_outlined,
                        color: kPrimaryColor,
                        size: 22,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => HcfDetailsScreen(_rows[i]['wasteId']),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _checkedIds.contains(_rows[i]['hcfId']),
                        activeColor: kPrimaryColor,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged:
                            (val) => setState(() {
                              if (val == true) {
                                _checkedIds.add(_rows[i]['hcfId']);
                              } else {
                                _checkedIds.remove(_rows[i]['hcfId']);
                              }
                            }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
