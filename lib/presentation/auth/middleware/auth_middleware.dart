import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punch_app/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser == null) {
      return const RouteSettings(name: AppRoutes.routeLogin);
    }
    return null;
  }
}