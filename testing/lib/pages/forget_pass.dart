import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:testing/services/auth.dart';

class ForgotPassword extends StatefulWidget{
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  final Auth _auth = Auth();

  String? _message;
  bool _isSuccess = false;
  bool _isLoading = false;

  Future<void> _sendResetEmail() async {
    setState(() {
      _isLoading = true;
      _message = null; 
      _isSuccess = false;
    });

    try {
      await _auth.sendPasswordEmailLink(email: _emailController.text.trim());

      setState(() {
        _message = 'Password reset email sent! Check your inbox.';
        _isSuccess = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = 'Error: ${e.message ?? 'Failed to send email.'}';
        _isSuccess = false;
      });
    } catch (e) {
      setState(() {
        _message = 'An unexpected error occurred.';
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build (BuildContext context){
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter email to reset your password',
            textAlign: TextAlign.center,
            ),

            SizedBox(height: 24),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
              ),
            ),

            SizedBox(height: 14),
             if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSuccess ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isSuccess ? Colors.green[300]! : Colors.red[300]!),
                  ),
                  child: Text(
                    _message!,
                    style: TextStyle(color: _isSuccess ? Colors.green[700] : Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            ElevatedButton(
              onPressed:  (){
                _isLoading ? null:  _sendResetEmail();
                Text('Email has been sent!');
                
              },
               child: Text('Send Email')
               ),

            TextButton(
              onPressed: (){
                Navigator.pop(context);
              }, 
              child: Text('Go back to Login'),
              )
          ],
        ),
         ),
    );
  }
}
