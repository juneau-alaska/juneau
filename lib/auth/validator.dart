class PasswordValidator {
  bool validate(String str){
    String pattern = r'\s+';
    RegExp regExp = new RegExp(pattern);
    int stringLen = str.length;
    return !regExp.hasMatch(str) && stringLen >= 6;
  }
}

class UsernameValidator {
  bool validate(String str) {
    String pattern = r'^[.\w]*$';
    RegExp regExp = new RegExp(pattern);
    int stringLen = str.length;
    return regExp.hasMatch(str) && stringLen >= 3 && stringLen <= 30;
  }
}

PasswordValidator passwordValidator = new PasswordValidator();
UsernameValidator usernameValidator = new UsernameValidator();