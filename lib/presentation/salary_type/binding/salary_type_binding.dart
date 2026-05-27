import 'package:get/get.dart';
import 'package:punch_app/presentation/company/controller/company_controller.dart';
import 'package:punch_app/presentation/salary_type/controller/salary_type_controller.dart';

class SalaryTypeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SalaryTypeController());
    Get.lazyPut(() => CompanyController());
  }
}
