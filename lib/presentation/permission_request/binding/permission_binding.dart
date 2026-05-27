import 'package:get/get.dart';
import 'package:punch_app/presentation/company/controller/company_controller.dart';
import 'package:punch_app/presentation/employee/controller/employee_controller.dart';
import 'package:punch_app/presentation/permission_request/controller/permission_request_controller.dart';

class PermissionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PermissionRequestController());
    Get.lazyPut(() => EmployeeController());
    Get.lazyPut(() => CompanyController());
  }
}
