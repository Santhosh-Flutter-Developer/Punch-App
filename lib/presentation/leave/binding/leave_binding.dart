import 'package:get/get.dart';
import 'package:punch_app/presentation/company/controller/company_controller.dart';
import 'package:punch_app/presentation/department/controller/department_controller.dart';
import 'package:punch_app/presentation/designation/controller/role_controller.dart';
import 'package:punch_app/presentation/employee/controller/employee_controller.dart';
import 'package:punch_app/presentation/leave/controller/leave_controller.dart';

class LeaveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LeaveController());
    Get.lazyPut(() => EmployeeController());
    Get.lazyPut(() => DepartmentController());
    Get.lazyPut(() => RoleController());
    Get.lazyPut(() => CompanyController());
  }
}
