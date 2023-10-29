import 'package:fluttertoast/fluttertoast.dart';

abstract class NotificationService {
  showToast(String message);
}

class DefaultNotificationService implements NotificationService {
  const DefaultNotificationService();

  @override
  showToast(String message) {
    Fluttertoast.showToast(msg: message);
  }
}
