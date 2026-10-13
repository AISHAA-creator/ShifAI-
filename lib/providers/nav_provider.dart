import 'package:flutter/foundation.dart';

/// Which bottom-bar tab is showing, so other screens (e.g. after saving a
/// result) can jump to Trends.
class NavProvider extends ChangeNotifier {
  int _tab = 0;
  int get tab => _tab;

  void setTab(int index) {
    if (index == _tab) return;
    _tab = index;
    notifyListeners();
  }
}
