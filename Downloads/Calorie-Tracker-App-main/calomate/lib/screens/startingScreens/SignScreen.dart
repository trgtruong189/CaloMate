import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../sevices/ThameProvider.dart';
import '../../sevices/UserProvider.dart'; // Thêm import UserProvider

class SignScreen extends StatefulWidget {
  const SignScreen({super.key});

  @override
  State<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> {
  bool isLoading = false; // Thêm trạng thái loading

  void _showBottomSheet(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      context: context,
      builder: (BuildContext context) {
        return SlideInUp(
          duration: Duration(milliseconds: 700),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                _buildSignInButton(
                  icon: Image.asset('assets/images/googleIcon.png', height: 24),
                  label: 'Đăng nhập với Google',
                  onPressed: isLoading
                      ? () {} // Vô hiệu hóa khi đang loading
                      : () async {
                    setState(() => isLoading = true); // Bật loading
                    bool success = await Provider.of<UserProvider>(context, listen: false)
                        .loginWithGoogle();
                    setState(() => isLoading = false); // Tắt loading
                    if (success) {
                      Navigator.pushReplacementNamed(context, '/recipeScreen');
                    } else {
                      _showSnackBar(context, 'Đăng nhập Google thất bại.', Colors.redAccent);
                    }
                  },
                ),
                SizedBox(height: 10.0),
                _buildSignInButton(
                  icon: Icon(CupertinoIcons.mail, color: Colors.blue),
                  label: 'Đăng nhập với Email',
                  onPressed: isLoading
                      ? () {} // Vô hiệu hóa khi đang loading
                      : () => Navigator.pushNamed(context, '/login'),
                ),
                SizedBox(height: 20.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignInButton({
    required Widget icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            side: BorderSide(color: Colors.blueAccent, width: 1.5),
            padding: EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading && label == 'Đăng nhập với Google'
                  ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              )
                  : icon,
              SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 14.0)),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElasticIn(
              duration: Duration(milliseconds: 800),
              child: Column(
                children: [
                  SizedBox(height: 250.0),
                  Image.asset('assets/images/logo.png', height: 120),
                  Text(
                    'Chào mừng',
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.greenAccent : Colors.black87,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Text(
                      'Đăng nhập hoặc đăng kí để bắt đầu',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontSize: 16.0,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FadeInUp(
              duration: Duration(milliseconds: 800),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: isLoading
                            ? null // Vô hiệu hóa khi đang loading
                            : () => _showBottomSheet(context),
                        style: TextButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.greenAccent[700] : Color(0xff006d77),
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          'Đăng nhập',
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0, bottom: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Bạn không có tài khoản?',
                          style: GoogleFonts.poppins(fontSize: 14.0),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/signUp'),
                          child: Text(
                            'Đăng kí',
                            style: GoogleFonts.poppins(
                              color: isDarkMode ? Colors.greenAccent : Color(0xff006d77),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}