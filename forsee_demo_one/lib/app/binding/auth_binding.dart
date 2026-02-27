import 'package:get/get.dart';
import 'package:forsee_demo_one/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController is already registered permanently in main.dart via Get.put.
    // This binding exists as a safety net so Get.find() never fails
    // if a page is opened before main.dart's Get.put runs (edge case).
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}