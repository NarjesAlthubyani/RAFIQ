import 'package:rafiq/models/alert_model.dart';
import 'package:rafiq/services/supabase_config.dart';
import 'package:rafiq/services/auth_service.dart';
// AlertRepository handles all data operations related to user alerts.
// It acts as a data access layer between the application and Supabase database.
class AlertRepository {

  static Future<List<AlertModel>> getUserAlerts() async {

    final user = AuthService.currentUser;

    if (user == null) {
      return [];
    }
    // Fetch alerts from Supabase filtered by user ID
    final response = await supabase
        .from('alerts')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
        
    // Convert JSON response into a list of AlertModel objects
    return (response as List)
        .map((json) => AlertModel.fromJson(json))
        .toList();
  }

}