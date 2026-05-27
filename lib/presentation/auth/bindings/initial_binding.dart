import 'package:get/get.dart';
import 'package:punch_app/presentation/auth/controller/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
