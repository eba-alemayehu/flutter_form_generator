import 'package:flutter/material.dart';

class $FormForm extends StatefulWidget {
  const $FormForm({Key? key}) : super(key: key);

  @override
  _$FormFormState createState() => _$FormFormState();
}

class _$FormFormState extends State<$FormForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          FormBuilder(
            key: _formKey,
            autovalidate: true,
            child: Column(
              children: <Widget>[
                // #fields#
              ],
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: MaterialButton(
                  color: Theme.of(context).colorScheme.secondary,
                  child: Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    _formKey.currentState.save();
                    if (_formKey.currentState.validate()) {
                      print(_formKey.currentState.value);
                    } else {
                      print("validation failed");
                    }
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
