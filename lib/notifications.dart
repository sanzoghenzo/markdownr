import 'package:fluttertoast/fluttertoast.dart';

abstract class NotificationService {
  void showToast(String message);
}

class DefaultNotificationService implements NotificationService {
  const DefaultNotificationService();

  @override
  void showToast(String message) {
    Fluttertoast.showToast(msg: message);
  }
}
