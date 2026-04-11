/// Initial Binding
/// Sets up all services and controllers for the app
library;

import 'package:get/get.dart';
import '../services/image_picker_service.dart';
import '../modules/splash/splash_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services (already initialized in main.dart)
    Get.lazyPut(() => ImagePickerService(), fenix: true);

    // Controllers
    Get.lazyPut(() => SplashController(), fenix: true);
  }
}
