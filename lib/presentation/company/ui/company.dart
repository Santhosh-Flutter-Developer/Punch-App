import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punch_app/data/models/subscription_model.dart';
import 'package:punch_app/presentation/auth/controller/auth_controller.dart';
import 'package:punch_app/presentation/company/controller/company_controller.dart';
import 'package:punch_app/presentation/company/ui/company_body.dart';
import 'package:punch_app/presentation/company/widgets/error_widget.dart';
import 'package:punch_app/widgets/app_shell.dart';
import 'package:punch_app/widgets/loading_overlay.dart';
import 'package:punch_app/widgets/sri_button.dart';

class Company extends StatelessWidget {
  Company({super.key});

  final controller = Get.isRegistered<CompanyController>()
      ? Get.find<CompanyController>()
      : Get.put(CompanyController());

  final auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SafeArea(
      top: false,
      child: AppShell(
        currentModule: 'company',
        title: 'Company',
        actions: [
          if (auth.canAdd('company') &&
              auth.subscription.value!.plan != SubscriptionPlan.trial)
            isWide
                ? SriButton(
                    label: 'Add Branch',
                    icon: Icons.add,
                    onPressed: () =>
                        controller.showAddBranchDialog(context, controller),
                  )
                : IconButton(
                    onPressed: () =>
                        controller.showAddBranchDialog(context, controller),
                    icon: Icon(Icons.add),
                  ),
        ],
        child: Obx(() {
          if (controller.isLoading.value && controller.companies.isEmpty) {
            return const LoadingOverlay();
          }
          if (controller.errorMessage.value.isNotEmpty &&
              controller.companies.isEmpty) {
            return ErrorrWidget(
              message: controller.errorMessage.value,
              onRetry: controller.loadAllCompanies,
            );
          }
          return CompanyBody(controller: controller, auth: auth);
        }),
      ),
    );
  }
}
