import 'package:timeago/timeago.dart' as timeago;

class NumberMethods {
  String shortenNum(int n) {
    String divN;
    List divSplit;
    List divSplit2;
    String sym;

    if (n < 1000) {
      return n.toString();
    } else if (n < 1000000) {
      divN = (n / 1000).toString();
      sym = 'K';
    } else if (n > 999999 && n < 1000000000) {
      divN = (n / 1000000).toString();
      sym = 'M';
    } else if (n < 1000000000000) {
      divN = (n / 1000000000).toString();
      sym = 'B';
    } else if (n < 1000000000000000) {
      divN = (n / 1000000000000).toString();
      sym = 'T';
    }

    divSplit = divN.split('.');
    divSplit2 = divSplit[1].split('');

    return divSplit[0] + '.' + divSplit2[0] + sym;
  }

  String convertTime(time) {

    DateTime dateTime = DateTime.parse(time);

    String converted = timeago.format(dateTime, locale: 'en_short').replaceAll(new RegExp(r'~'), '');

    return converted;
  }
}

NumberMethods numberMethods = new NumberMethods();
