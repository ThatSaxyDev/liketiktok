import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:like_tiktok/constants.dart';
import 'package:like_tiktok/models/user_model.dart' as model;
import 'package:like_tiktok/views/screens/auth/login_screen.dart';
import 'package:like_tiktok/views/screens/auth/signup_screen.dart';
import 'package:like_tiktok/views/screens/home_screen.dart';

class AuthController extends GetxController {

  // Rx<User?>? firebaseUser;

  // @override
  // void onReady() {
  //   super.onReady();

  //   //!INSTANTIATE FIREBASE USER
  //   firebaseUser = Rx<User?>(firebaseAuth.currentUser);

  //   //!BIND FIREBASE USER TO USER CHANGES.
  //   firebaseUser!.bindStream(firebaseAuth.userChanges());

  //   //!SET EVENT TRIGGER CALLED EVER ...
  //   //!EVERY TIME A CHANGE IS MADE DUE TO THE EVENT LISTENER, RUN A CALL BACK FUNCTION
  //   ever(firebaseUser!, setUpInitialScreen);
  // }

  // //!SHOW INITIAL SCREEN
  // //!IF THERE IS NO USER, SHOW SIGN IN ELSE SHOW DASHBOARD
  // static setUpInitialScreen(User? user) {
  //   if (user == null) {
  //     Get.offAll(() => SignupScreen());
  //   } else {
  //     Get.offAll(() => HomeScreen());
  //   }
  // }

  static AuthController instance = Get.find();

  late Rx<User?> _user;
  late Rx<File?> _pickedImage;

  File? get profilePhoto => _pickedImage.value;
  User get user => _user.value!;

  @override
  void onReady() {
    super.onReady();
    _user = Rx<User?> (firebaseAuth.currentUser);
    _user.bindStream(firebaseAuth.authStateChanges());
    ever(_user, _setInitialScreen);
  }

  _setInitialScreen(User? user) {
    if (user == null) {
      Get.offAll(() => LoginScreen());
    } else {
      Get.offAll(() => const HomeScreen());
    }
  }

  void pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      Get.snackbar('Profile Picture', 'You have successfully selected your profile picture!');
    }

    _pickedImage = Rx<File?> (File(pickedImage!.path));
  }

  // UPLOAD TO FIREBASE STORAGE
  Future<String> _uploadToStorage(File image) async {
    Reference ref = firebaseStorage
        .ref()
        .child('profilePics')
        .child(firebaseAuth.currentUser!.uid);

    UploadTask uploadTask = ref.putFile(image);
    TaskSnapshot snap = await uploadTask;
    String downloadUrl = await snap.ref.getDownloadURL();
    return downloadUrl;
  }

  // REGISTERING USER
  void registerUser(
      String username, String email, String password, File? image) async {
    try {
      if (username.isNotEmpty &&
          email.isNotEmpty &&
          password.isNotEmpty &&
          image != null) {
        // SAVE USER TO THE AUTHENTICATION AND FIRESTORE
        UserCredential cred = await firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        String downloadUrl = await _uploadToStorage(image);
        model.User user = model.User(
          name: username,
          email: email,
          uid: cred.user!.uid,
          profilePhoto: downloadUrl,
        );
        await firestore.collection('users').doc(cred.user!.uid).set(user.toJson());
      } else {
        Get.snackbar(
        'Error Creating Account',
        'Please enter all the fields',
      );
      }
    } catch (e) {
      Get.snackbar(
        'Error Creating Account',
        e.toString(),
      );
    }
  }

  void loginUser(String email, String password) async {
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
        print('log success');
      } else {
        Get.snackbar(
        'Error logging in',
        'Please enter all the fields',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error Creating Account',
        e.toString(),
      );
    }
  }

  void signOut() async {
    await firebaseAuth.signOut();
  }
}
