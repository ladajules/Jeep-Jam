import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';


class Auth{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final logger =  Logger();
  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void>signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async{
    try{
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email, 
        password: password
        );
        logger.i('Sign in successful');
      } catch (e){
        logger.e('Sign in error');
        rethrow;
      }
    
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,

  })async{
    try{
      await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
       );
       await sendEmailVerification();
      logger.i('Sign in successful');
      
    } catch (e){
      logger.e('Sign in error');
      rethrow;
    }
    
  }
  Future<void> sendPasswordEmailLink({
    required String email,
  })async{
    try{
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    }catch(e){
      logger.e('error wid sending passwordemaillink');
    }
  }


  Future<void> sendEmailVerification() async {
    try {
      User? user = currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        logger.i('Verification email sent');
      }
    } catch (e) {
      logger.e('Error sending verification email: $e');
      rethrow;
    }
  }

    Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  bool get isEmailVerified => currentUser?.emailVerified ?? false;


  Future<void> signOut() async{
    await _firebaseAuth.signOut();
  }
}

