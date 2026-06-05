import 'package:get/get.dart';
import 'package:punch_app/data/services/connectivity_service.dart';
import 'package:punch_app/presentation/auth/controller/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Register connectivity monitor first so it runs on every screen
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}