class CreditCardUserModel {

  String? id;
  String? cardName;
  String? customerId;
  String? lastFourDigits;
  String? creditCardToken;
  String? transationalType;
  String? cardType;
  int? expirationMonth;
  String? urlFlag;
  int? expirationYear;
  String? userId;
  String? cardId;
  String? tipoDocumento;
  String? numeroDocumento;
  String? flagCard;
  String? cvv;

  CreditCardUserModel({
    this.id,
    this.cardName,
    this.customerId,
    this.lastFourDigits,
    this.creditCardToken,
    this.transationalType,
    this.cardType,
    this.expirationMonth,
    this.expirationYear,
    this.urlFlag,
    this.userId,
    this.cardId,
    this.flagCard,
    this.tipoDocumento,
    this.numeroDocumento,
    this.cvv
  });

  CreditCardUserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    cardName = json['cardName'];
    customerId = json['customerId'];
    lastFourDigits = json['lastFourDigits'];
    creditCardToken = json['creditCardToken'];
    transationalType = json['transationalType'];
    cardType = json['cardType'];
    expirationMonth = json['expirationMonth'];
    expirationYear = json['expirationYear'];
    urlFlag = json['urlFlag'];
    userId = json['userId'];
    cardId = json['cardId'];
    numeroDocumento = json['numeroDocumento'];
    tipoDocumento = json['tipoDocumento'];
    flagCard = json['flagCard'];
    cvv = json['cvv'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['cardName'] = cardName;
    data['customerId'] = customerId;
    data['lastFourDigits'] = lastFourDigits;
    data['creditCardToken'] = creditCardToken;
    data['transationalType'] = transationalType;
    data['cardType'] = cardType;
    data['expirationMonth'] = expirationMonth;
    data['expirationYear'] = expirationYear;
    data['urlFlag'] = urlFlag;
    data['userId'] = userId;
    data['cardId'] = cardId;
    data['flagCard'] = flagCard;
    data['numeroDocumento'] = numeroDocumento;
    data['tipoDocumento'] = tipoDocumento;
    data['flagCard'] = flagCard;
    data['cvv'] = cvv;
    return data;
  }
}
