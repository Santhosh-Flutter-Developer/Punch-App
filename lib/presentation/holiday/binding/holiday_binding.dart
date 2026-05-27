import 'package:get/get.dart';
import 'package:punch_app/presentation/company/controller/company_controller.dart';
import 'package:punch_app/presentation/holiday/controller/holiday_controller.dart';

class HolidayBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HolidayController());
    Get.lazyPut(() => CompanyController());
  }
}
