import 'package:flutter_riverpod/flutter_riverpod.dart';

// Manages the selected tab index for the MainScreen's BottomNavigationBar.
class MainScreenTabNotifier extends StateNotifier<int> {
  MainScreenTabNotifier() : super(0);

  void changeTab(int index) {
    if (state != index) {
      print("MainScreenTabNotifier: Changing tab to index $index");
      state = index;
    }
  }
}

final mainScreenTabNotifierProvider =
    StateNotifierProvider<MainScreenTabNotifier, int>((ref) {
      return MainScreenTabNotifier();
    });
