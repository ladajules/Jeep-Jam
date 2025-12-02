import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testing/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

const String kSeenTutorialKey = 'SeenTutorial';

class _LoginRegisterPageState extends State<LoginRegisterPage>{
  final Auth _auth = Auth();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final logger = Logger();
  bool _isLogin = true;
  bool _isLoading = false;
  String _errorMessage = '';


  Future<void> _handleAuth() async{
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try{
      if (_isLogin){
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(), 
          password: _passwordController.text.trim(),
          );
          logger.i('Login Successful');

          await _auth.reloadUser();
          if (!_auth.isEmailVerified){
             if (mounted) {
            Navigator.of(context).pushReplacementNamed('/verifyemail');
          }
            return;
          }
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(), 
          password: _passwordController.text.trim(),
          );
          
          logger.i('Registration Successful');

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(kSeenTutorialKey, false);

          if(mounted){
            Navigator.of(context).pushReplacementNamed('/verifyemail');
          }

          
      }
    } on FirebaseAuthException catch (e){
      setState(() {
        logger.e('FirebaseAuthException: ${e.code} - ${e.message}');
        setState(() {
          _errorMessage = _getErrorMessage(e.code);
        });
      });
    } catch (e){
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage (String code){
    switch (code){
      case 'user-not-found':
      return 'No user found with this email.';
      case 'wrong-password':
      return 'Wrong password provided';
      case 'email-already-in-use':
      return 'An account already exists with this email.';
      case 'weak-password':
      return 'Password should be at least 6 character';
      case 'invalid-email':
      return 'The email address is not valid';
      default:
      return 'Authentication failed. Please try again';
    }
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFFEF1D8),
      body: SafeArea(
        child:
         Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Jeep Jam', 
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,),

                const SizedBox(height: 24,),

                Text(
                  _isLogin ? 'Welcome Back!' : 'Create an account',
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email, color: Color(0xff632d1b)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xff632d1b)),
                    border: OutlineInputBorder( 
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 34),

                if (_errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Color(0xfffef1d8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(

                    backgroundColor: const Color(0xFF6E2D1B), // Your custom brown color
    
    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ), 
                  child: _isLoading ? 
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xff6e2d1b),),

                    )

                    : 
                    Text(
                      _isLogin ? 'Login' : 'Register',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: (){
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = '';
                      });
                    }, 
                    child: Text(
                      _isLogin ? "Dont't have an account? Register" : 'Already have an account? Login',
                      style: TextStyle(color: Color(0xff6e2d1b)),
                    ),
                    ),
                    
                  TextButton(
                    onPressed:() {
                      Navigator.pushNamed(context, '/forgotpass');
                    },
                    child: Text('Forgot your password? Click here', style: TextStyle(color: Color(0xff6e2d1b)),),
                    

                  )

                    
              ],
            ),
          ),
         )
         ),
    );
  }
  
  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

