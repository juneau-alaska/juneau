class PasswordValidator {
  bool validate(String value){
    String pattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
    RegExp regExp = new RegExp(pattern);
    return regExp.hasMatch(value) && value.length >= 6;
  }
}

PasswordValidator passwordValidator = new PasswordValidator();