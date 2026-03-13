import 'package:rafiq/models/alert_model.dart';
import 'package:rafiq/services/supabase_config.dart';
import 'package:rafiq/services/auth_service.dart';

class AlertRepository {

  static Future<List<AlertModel>> getUserAlerts() async {

    final user = AuthService.currentUser;

    if (user == null) {
      return [];
    }

    final response = await supabase
        .from('alerts')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AlertModel.fromJson(json))
        .toList();
  }

}