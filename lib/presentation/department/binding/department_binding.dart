import 'package:get/get.dart';
import 'package:punch_app/presentation/company/controller/company_controller.dart';
import 'package:punch_app/presentation/department/controller/department_controller.dart';

class DepartmentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DepartmentController());
    Get.lazyPut(() => CompanyController());
  }
}
