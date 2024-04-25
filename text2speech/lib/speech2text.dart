import 'dart:convert';
import 'package:path/path.dart' as Path;
//import 'dart:typed_data';
//import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:text2speech/text2speech.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';


class SpeechtoTextScreen extends StatefulWidget {
  SpeechtoTextScreen({super.key});

  @override
  _SpeechtoTextScreenState createState() => _SpeechtoTextScreenState();
}

class _SpeechtoTextScreenState extends State<SpeechtoTextScreen> {
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool isloading=false;
  String _lastWords = '';
  bool cameraViewEnabled=false;
  final audioPlayer = AudioPlayer();
  List<CameraDescription>? cameras;
  XFile? cameraPicture;
  CameraController? controller;
  @override
  void initState() {
    super.initState();
    initializeCamera();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void initializeCamera() async {
  // Fetch available cameras
  cameras = await availableCameras();
  // Set up the first camera for preview
  controller = CameraController(cameras!.first, ResolutionPreset.medium);
  // Initialize the camera controller
  await controller!.initialize();
  // Update the state to re-render the widget with the camera preview
  setState(() {});
}

  /// Each time to start a speech recognition session
  void _startListening() async {
    await audioPlayer.play(AssetSource('sound_start_speak.mp3'));
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }
  

  
  Future<void> getCaption(context, ImageSource? source,XFile? img) async{
    if(source!=null){
     img = await ImagePicker().pickImage(source: source);
     }
    if(img!=null){
    print('Image Picked');
      try {
    // Prepare the image file
    var imageFile = await MultipartFile.fromFile(img.path, filename: img.name);

    // Create FormData with a single file entry
    var data = FormData.fromMap({
      'file': imageFile,
    });

    // Create a Dio instance
    var dio = Dio();
    setState((){
                isloading=true;
              });
    // Send the POST request with error handling
    var response = await dio.post(
      'http://34.16.230.86:9090/upload_file', 
      data: data,
      options: Options(method: 'POST'),
    );

    if (response.statusCode == 200) {
      var decodedJson=(json.encode(response.data));
      _lastWords=decodedJson.replaceAll(RegExp(r'{'), '').replaceAll(RegExp(r']'), '').replaceAll(RegExp(r'"'), '').replaceAll(RegExp(r'caption'), '');
      Navigator.of(context).push(MaterialPageRoute(
  builder: (context) => Text2Speech(speech: _lastWords,),
));
    } else {
      print(response.statusMessage);
    }
  } on DioError catch (e) {
    // Handle specific DioError types (optional)
    if (DioErrorType.connectionTimeout == e.type) {
      print('Connection timed out.');
    } else if (DioErrorType.badResponse == e.type) {
      // Handle server-side errors (e.g., status code not 200)
      print('Server error: ${e.response!.statusCode}');
    } else {
      // Handle other DioError types
      print('Error uploading image: ${e.message}');
    }
    rethrow; // Re-throw for potential caller handling (optional)
  } catch (e) {
    // Catch other general exceptions (optional)
    print('Unexpected error: $e');
  }
      // } 
  }
  }

  void takePicture(context) async {
  try {
    // Construct the path where the image will be saved
    final path = Path.join(
      (await getApplicationDocumentsDirectory()).path,
      '${DateTime.now()}.png',
    );
    // Capture the image and save it to the path
    await controller!.takePicture().then((value)  {
      getCaption(context, null, value);
      setState(() {
    cameraPicture=value;
    cameraViewEnabled=false;  
    });
    });
    // Show a message indicating the image was saved successfully
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Picture saved to: $path'),
      ),
    );
  } catch (e) {
    // Handle errors
    print('Error taking picture: $e');
  }
}

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome!'),
          backgroundColor: Colors.blue,),
      body: cameraViewEnabled?cameraPreview():Center(
        child:SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
                padding: EdgeInsets.all(16),
                child:isloading?Lottie.asset('assets/loading_animation.json'): Text(
                  // If listening is active show the recognized words
                  _speechToText.isListening
                      ? '$_lastWords'
                      
                      : _speechEnabled
                          ? 'Tap the microphone to start listening...'
                          : 'Speech not available',
                ),
              ),
              ElevatedButton(
  onPressed: () {
    _speechToText.isNotListening ? _startListening : _stopListening;
  },
  style: ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50.0), // Adjust for desired roundness
    ),
    padding: EdgeInsets.all(20.0), // Adjust padding for button size
    minimumSize: Size(80.0, 80.0), // Set minimum size for the button
   // primary: Colors.red, // Change color as desired
  ),
            // If not yet listening for speech start, otherwise stop
            
        child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic, size: 60.0,),
      ),
          
            ElevatedButton(onPressed: ()=>{
            getCaption(context,ImageSource.camera,null)
            }, style: ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50.0), // Adjust for desired roundness
    ),
    padding: EdgeInsets.all(20.0), // Adjust padding for button size
    minimumSize: Size(80.0, 80.0), // Set minimum size for the button
   // primary: Colors.red, // Change color as desired
  ),
  child: Icon(Icons.camera_alt, size: 60.0))
          ],
        )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){

           getCaption(context,ImageSource.gallery,null);},
        tooltip: 'Listen',
        child: Icon(Icons.photo_library),
      ),
    );
  }

  Widget cameraPreview() {
  if (controller == null || !controller!.value.isInitialized) {
    return Container();
  }
  return AspectRatio(
    aspectRatio: controller!.value.aspectRatio,
    child: CameraPreview(controller!),
  );
}
}