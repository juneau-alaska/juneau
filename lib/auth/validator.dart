class PasswordValidator {
  bool validate(String str){
    String pattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
    RegExp regExp = new RegExp(pattern);
    return regExp.hasMatch(str) && str.length >= 6;
  }
}

class UsernameValidator {
  bool validate(String str) {
    String pattern = r'^[a-zA-Z0-9]([._](?![._])|[a-zA-Z0-9]){6,18}[a-zA-Z0-9]$';
    RegExp regExp = new RegExp(pattern);
    print(regExp.hasMatch(str));
    return regExp.hasMatch(str) && str.length >= 3 && str.length <= 14;
  }
}

PasswordValidator passwordValidator = new PasswordValidator();
UsernameValidator usernameValidator = new UsernameValidator();