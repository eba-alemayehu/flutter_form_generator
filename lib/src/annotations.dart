class Field {
  final name;
  final String type;
  final validators;
  final hint;
  final decoration;

  const Field(
      {this.name,
      this.type = "text",
      this.validators = const [],
      this.decoration = const {},
      this.hint = ''});
}

class FormWidget {
  const FormWidget();
}
