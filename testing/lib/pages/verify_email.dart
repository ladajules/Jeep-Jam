
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:testing/services/auth.dart';

class EmailVerificationPage extends StatefulWidget{
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => EmailVerificationPageState();
}

class EmailVerificationPageState extends State<EmailVerificationPage>{
  final Auth _auth = Auth();

  bool _isEmailVerified = false;
  bool _isResending = false;
  Timer? _timer;
  Timer? _countDownTimer;
  int _countDown = 60;
  bool _canResend = true;

  @override
  void initState(){
    super.initState();
    _isEmailVerified = _auth.isEmailVerified;

    if (!_isEmailVerified){
      _timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkEmailVerified(),
      );
    }
  }

  @override
  void dispose(){
    _timer?.cancel();
    _countDownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async{
    await _auth.reloadUser();

    if (_auth.isEmailVerified){
      setState(() {
        _isEmailVerified = true;
      });
      _timer?.cancel();

      if (mounted){
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/intropage',
          (route) => false,
        );
      }
    }
  }

  Future<void> _resendVerificationEmail()async{
    if (!_canResend) return;

    setState(() {
      _isResending = true;
      _canResend = false;
      _countDown = 60;
    });

    try{
      await _auth.sendEmailVerification();

      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _countDownTimer = Timer.periodic(const Duration(seconds: 1), (timer){
        if (_countDown == 0){
          timer.cancel();
          if(mounted){
            setState(() {
              _canResend = true;
            });
          }
        } else {
          if (mounted){
            setState(() {
              _countDown--;
            });
          }
        }
      });


    } catch(e){
      if (mounted){
                ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send verification email. Try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      setState(() {
        _canResend = true;
      });
      }
    } finally{
      if (mounted){
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _signOut() async{
    await _auth.signOut();
    if (mounted){
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Email icon
                Icon(
                  Icons.email_outlined,
                  size: 100,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'We\'ve sent a verification email to:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // User's email
                Text(
                  _auth.currentUser?.email ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Please check your email and click the verification link to continue.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This page will automatically redirect once your email is verified.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Resend button
                ElevatedButton.icon(
                  onPressed: _canResend && !_isResending ? _resendVerificationEmail : null,
                  icon: _isResending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _canResend
                        ? 'Resend Verification Email'
                        : 'Resend in $_countDown seconds',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Check verification status button
                OutlinedButton.icon(
                  onPressed: _checkEmailVerified,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('I\'ve Verified My Email'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Sign out option
                TextButton(
                  onPressed: _signOut,
                  child: const Text('Sign out and use a different account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}