@echo off
echo Running all tests with coverage...

:: Run tests with coverage
flutter test --coverage

:: Generate coverage report
genhtml coverage/lcov.info -o coverage/html

:: Open coverage report
start coverage/html/index.html

echo Test execution completed. Coverage report has been generated and opened in your browser.