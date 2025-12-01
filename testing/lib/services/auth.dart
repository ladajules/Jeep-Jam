import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';


class Auth{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
       );
       addUserToDatabase(userCredential.user!);
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

  Future<void> changeEmailLink({
    required String currentEmail,
    required String newEmail,
    required String password,

  }) async {
    try{
      final user = currentUser;
      if (user != null){
        final AuthCredential credential = EmailAuthProvider.credential(
          email: currentEmail, password: password
          );

          await user.reauthenticateWithCredential(credential);

          await user.verifyBeforeUpdateEmail(newEmail);

          logger.i('Verification email for new address ($newEmail) sent successfully');

      } 
        
      } on FirebaseAuthException catch (e) {
        logger.e('FirebaseAuthException during email change: ${e.code} - ${e.message}');
        rethrow;
      } catch (e) {
        logger.e('General error during email change: $e');
        rethrow;
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
Future<void> syncEmailIfChanged() async {
    final user = currentUser;
    if (user != null) {
      await user.reload(); // Get latest email from Auth
      
      final userDoc = await _firestore.collection('users').doc(user.email).get();
      final currentDbEmail = userDoc.data()?['email'];

      // Check if the Auth email differs from the Firestore email
      if (user.email != currentDbEmail) {
        // If they differ, and the new Auth email is verified (or null check passes), update Firestore.
        logger.w('Email mismatch detected. Syncing Firestore to Auth.');
        await _updateEmailInDatabase(user.email!);
      }
    }
  }

  Future<void> _updateEmailInDatabase(String newEmail) async {
    final user = currentUser;
    if (user != null) {
      // Find the document using the user's immutable UID
      final userDocRef = _firestore.collection('users').doc(user.email);

      await userDocRef.update({
        'email': newEmail,
        // Optional: Update isVerified status, though Auth usually handles this
        'isVerified': user.emailVerified, 
      });
      logger.i('Firestore user document updated with new email: $newEmail');
    }
  }

  Future <void> addUserToDatabase(User user) async {
    final userData = {
      'email': user.email,
      'isAdmin': false,
      'isVerified':user.emailVerified,
      'timestamp_joined': DateTime.now().millisecondsSinceEpoch.toString(),
      'uid':user.uid,
    };

    await _firestore.collection('users').doc(user.email).set(userData);
    
  }


  Future<void> signOut() async{
    await _firebaseAuth.signOut();
  }

  
}

