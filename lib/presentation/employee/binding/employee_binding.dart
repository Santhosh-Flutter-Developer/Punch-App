import 'package:get/get.dart';
import 'package:punch_app/presentation/company/controller/company_controller.dart';
import 'package:punch_app/presentation/department/controller/department_controller.dart';
import 'package:punch_app/presentation/designation/controller/role_controller.dart';
import 'package:punch_app/presentation/employee/controller/employee_controller.dart';
import 'package:punch_app/presentation/employee_status/controller/employee_status_controller.dart';
import 'package:punch_app/presentation/salary_type/controller/salary_type_controller.dart';


class EmployeeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmployeeController());
    Get.lazyPut(() => DepartmentController());
    Get.lazyPut(() => RoleController());
    Get.lazyPut(() => EmployeeStatusController());
    Get.lazyPut(() => SalaryTypeController());
    Get.lazyPut(() => CompanyController());
  }
}