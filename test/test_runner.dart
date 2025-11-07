import 'package:flutter_test/flutter_test.dart';

// Import all test files
import '../test/unit/template_service_test.dart' as template_service_test;
import '../test/widget/template_composer_screen_test.dart'
    as template_composer_test;
import '../test/integration/template_management_test.dart'
    as template_management_test;
import '../test/performance/template_composer_performance_test.dart'
    as performance_test;
import '../test/security/template_security_test.dart' as security_test;

void main() {
  group('Unit Tests', () {
    template_service_test.main();
  });

  group('Widget Tests', () {
    template_composer_test.main();
  });

  group('Integration Tests', () {
    template_management_test.main();
  });

  group('Performance Tests', () {
    performance_test.main();
  });

  group('Security Tests', () {
    security_test.main();
  });
}
