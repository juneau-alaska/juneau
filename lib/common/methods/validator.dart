class Validator {
    bool validatePassword(String password){
        String pattern = r'\s+';
        RegExp regExp = new RegExp(pattern);
        int stringLen = password.length;
        return !regExp.hasMatch(password) && stringLen >= 6;
    }

    bool validateUsername(String username) {
        String pattern = r'^[.\w]*$';
        RegExp regExp = new RegExp(pattern);
        int stringLen = username.length;
        return regExp.hasMatch(username) && stringLen >= 3 && stringLen <= 30;
    }
}

Validator validator = new Validator();