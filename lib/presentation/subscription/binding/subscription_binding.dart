import 'package:get/get.dart';
import 'package:punch_app/presentation/company/controller/company_controller.dart';
import 'package:punch_app/presentation/subscription/controller/subscription_controller.dart';

class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SubscriptionController());
    Get.lazyPut(() => CompanyController());
  }
}
