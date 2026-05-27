import 'package:punch_app/data/models/company_model.dart';
import 'package:punch_app/data/services/supabase_service.dart';

class CompanyRepository {
  Future<CompanyModel?> getCompany(String companyId) async {
    final row = await SupabaseService.selectOne('companies', id: companyId);
    return row != null ? CompanyModel.fromJson(row) : null;
  }

  Future<CompanyModel> updateCompany(
    String id,
    Map<String, dynamic> data,
  ) async {
    final row = await SupabaseService.update('companies', id, data);
    return CompanyModel.fromJson(row);
  }
}
