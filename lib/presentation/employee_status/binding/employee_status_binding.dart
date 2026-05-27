import 'package:get/get.dart';
import 'package:punch_app/presentation/company/controller/company_controller.dart';
import 'package:punch_app/presentation/employee_status/controller/employee_status_controller.dart';

class EmployeeStatusBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmployeeStatusController());
    Get.lazyPut(() => CompanyController());
  }
}
