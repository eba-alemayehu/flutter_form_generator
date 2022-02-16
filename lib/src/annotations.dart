class Field {
  final name;
  final String type;
  final validators;
  final hint;
  final decoration;
  final bloc;
  final maxImages;
  final aspectRatio;
  final label;
  final double max;
  final double min;
  final String? template;
  final String? searchField;

  const Field(
      {this.name,
      this.type = "text",
      this.validators = const [],
      this.decoration = const {},
      this.hint = '',
      this.bloc = '',
      this.maxImages = 1,
      this.aspectRatio,
      this.max = 0,
      this.min = 0,
      this.template,
      this.searchField,
      this.label});
}

class FormWidget {
  const FormWidget();
}
