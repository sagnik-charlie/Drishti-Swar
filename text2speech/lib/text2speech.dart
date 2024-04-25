import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; 

class Text2Speech extends StatefulWidget {
  Text2Speech({
    Key? key, this.speech
  }):super(key: key);
  String? speech;
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<Text2Speech> {

  final TextEditingController _textFieldController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;

void initState() {
  super.initState();
  flutterTts.setLanguage("en-GB");
  flutterTts.setVolume(0.8);
  flutterTts.setSpeechRate(0.3);
  flutterTts.setPitch(1.0);
  _textFieldController.text = widget.speech!;
  flutterTts.setStartHandler(() {
    setState(() {
      isSpeaking = true;
    });
  });
  flutterTts.setCompletionHandler(() {
    setState(() {
      isSpeaking = false;
    });
  });
}
void _speak(String text) async {
  if (text.isNotEmpty) {
    await flutterTts.speak(text);
  }
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Text to Speech'),
        ),
        body: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextField(
                controller: _textFieldController,
                decoration: InputDecoration(
                  hintText: 'Enter your text here',
                ),
              ),
              SizedBox(height: 10.0),
              ElevatedButton(
                onPressed: isSpeaking ? null : () => _speak(_textFieldController.text),
                child: Text(isSpeaking ? 'Stop Speaking' : 'Speak'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
