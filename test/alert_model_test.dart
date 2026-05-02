import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq/models/alert_model.dart';

void main() {

  group('AlertModel Unit Tests', () {

    test('should create AlertModel from JSON correctly', () {
      // sample json from database
      final json = {
        'id': '1',
        'user_id': 'user123',
        'title': 'Weather Alert',
        'description': 'Heavy rain expected',
        'type': 'weather',
        'is_read': false,
        'created_at': '2026-05-01T10:00:00.000'
      };

      // convert json to model
      final result = AlertModel.fromJson(json);

      // verify fields mapping
      expect(result.id, '1');
      expect(result.userId, 'user123');
      expect(result.title, 'Weather Alert');
      expect(result.type, 'weather');
      expect(result.isRead, false);
    });

    test('should convert AlertModel to JSON correctly', () {
      // create model instance
      final model = AlertModel(
        id: '1',
        userId: 'user123',
        title: 'Weather Alert',
        description: 'Heavy rain expected',
        type: 'weather',
        isRead: false,
        createdAt: DateTime.parse('2026-05-01T10:00:00.000'),
      );

      // convert model to json
      final json = model.toJson();

      // verify json mapping
      expect(json['user_id'], 'user123');
      expect(json['title'], 'Weather Alert');
      expect(json['type'], 'weather');
      expect(json['is_read'], false);
    });

  });

}