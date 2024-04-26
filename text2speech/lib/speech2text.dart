import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as Path;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
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
  double _currentVolume = 0.0;
  double _initialVolume = 0.0;
  bool cameraViewEnabled=false;
  late AudioPlayer player = AudioPlayer();
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;
  List<String> startToken=["Your image describes ","This image shows ","I can see an image of  ","I can visualize that "];
  String endToken=" . Thank You !!"; 

  List<CameraDescription> cameras=[];
  XFile? cameraPicture;
  CameraController? controller;
  @override
  void initState() {
    super.initState();
    _initSpeech();
    initializeCamera();
    player = AudioPlayer();
    // Set the release mode to keep the source after playback has completed.
    player.setReleaseMode(ReleaseMode.stop);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await player.setSource(AssetSource('start_sound.mp3'));
      player.resume();
    });
    FlutterVolumeController.addListener((volume) {
      if(_initialVolume>_currentVolume || _initialVolume<_currentVolume)
      {cameraViewEnabled=true;}
      setState(() {
        _currentVolume = volume;
      });
    });
    _initialVolume = _currentVolume;
    super.initState();
    flutterTts.setLanguage("en-GB");
    flutterTts.setVolume(0.8);
    flutterTts.setSpeechRate(0.3);
    flutterTts.setPitch(1.0);
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

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void initializeCamera() async {
  // Fetch available cameras
  cameras = await availableCameras();
  // Set up the first camera for preview
  controller = CameraController(cameras.first, ResolutionPreset.medium,enableAudio: false,);
  // Initialize the camera controller
  controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }});
  // Update the state to re-render the widget with the camera preview
  setState(() {});
}

  /// Each time to start a speech recognition session
  void _startListening() async {
    
    await _speechToText.listen(onResult: _onSpeechResult);
    _stopListening();
    setState(() {});
  }
  

  
  Future<void> getCaption(context, ImageSource? source,XFile? img) async{
    if(source!=null){
     img = await ImagePicker().pickImage(source: source);
     cameraPicture=img;
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
       String tospeak=startToken[Random().nextInt(3)]+_lastWords+endToken;
       flutterTts.speak(tospeak);
       isloading=false;
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
      flutterTts.speak("Picture Clicked.. Please Wait");
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
      body: cameraViewEnabled?cameraPreview(context):Center(
        child:SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
                padding: EdgeInsets.all(16),
                child:isloading?Lottie.asset('assets/loading_animation.json'): Text(_lastWords,
              maxLines: 3,
              selectionColor: Colors.greenAccent, // Allow text to wrap
              style: TextStyle(
                fontSize: 16.0, // Adjust font size as desired
                decoration: TextDecoration.underline, // Underline text
                decorationColor: Color.fromARGB(255, 147, 226, 20), // Color of the underline
              ),
            ),
              ),
              
          cameraPicture!=null?Container(
            // Adjust width and height as desired
           // width: 300.0,
            height: 300.0,
            decoration: BoxDecoration(
              // Background color for the container
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20.0), // Rounded corners
              boxShadow: [
                // Add inner shadow for depth
                BoxShadow(
                  color: Color.fromARGB(255, 90, 90, 90)!.withOpacity(0.2), // Shadow color
                  offset: Offset(5.0, 5.0), // Shadow offset
                  blurRadius: 10.0, // Shadow blur radius
                ),
                // Add outer glow for style
                BoxShadow(
                  color: Colors.lightBlueAccent.withOpacity(0.5), // Glow color
                  offset: Offset(-5.0, -5.0), // Glow offset (opposite direction)
                  blurRadius: 15.0, // Glow blur radius
                  spreadRadius: -2.0, // Negative spread for inner glow effect
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0), // Clip image to match container shape
              child: Image(image: FileImage(File(cameraPicture!.path)),
                 // Replace with your image URL
                fit: BoxFit.fill, // Fill the container
              ),
            ),
          ):
          Lottie.asset('assets/walking_animation.json'),
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
  child: Icon(Icons.camera_alt, size: cameraPicture!=null?50.0:30))
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

  Widget cameraPreview(context)=>
    GestureDetector(
    onTap:() async{takePicture(context);},
    child: Scaffold(
   body: (controller == null || !controller!.value.isInitialized)?Container()
                                  : CameraPreview(controller!),
  ),
  );
}