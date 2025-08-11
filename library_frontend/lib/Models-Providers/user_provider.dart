import 'package:flutter/material.dart';
import 'package:library_frontend/Models-Providers/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  void setUser(User newUser){
    _user = newUser;
    notifyListeners();
  }

  void clearUser(){
    _user = null;
    notifyListeners();
  }
}