class DocumentModel {
  bool? backSide;
  bool? enable;
  bool? expireAt;
  String? id;
  bool? frontSide;
  String? title;
  String? formatter;

  DocumentModel(
      {this.backSide,
      this.enable,
      this.formatter,
      this.id,
      this.frontSide,
      this.title,
      this.expireAt});

  DocumentModel.fromJson(Map<String, dynamic> json) {
    backSide = json['backSide'];
    enable = json['enable'];
    id = json['id'];
    frontSide = json['frontSide'];
    title = json['title'];
    expireAt = json['expireAt'];
    formatter = json['formatter'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['backSide'] = backSide;
    data['enable'] = enable;
    data['id'] = id;
    data['frontSide'] = frontSide;
    data['title'] = title;
    data['expireAt'] = expireAt;
    data['formatter'] = formatter;
    return data;
  }
}
