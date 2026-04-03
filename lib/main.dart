import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/admin/admin_home.dart';
import 'features/user/user_home.dart';
import 'features/landing_page.dart';
import 'features/auth/verify_email_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'ui_helpers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      useMaterial3: true,
    ),
    home: const LandingPage(),
  );
  }
}

class LoginPage extends StatefulWidget {
  final bool initialIsLoginMode;
  const LoginPage({super.key, this.initialIsLoginMode = true});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isAdmin = false; // Default role selection
  late bool isLoginMode; // Toggle between login and signup

  @override
  void initState() {
    super.initState();
    isLoginMode = widget.initialIsLoginMode;
  }
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email address and we will send you a password reset link.'),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (resetEmailController.text.isEmpty) return;
                try {
                  await _authService.sendPasswordResetEmail(resetEmailController.text.trim());
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password reset email sent!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Send Link'),
            ),
          ],
        );
      },
    );
  }

  void _handleAuth() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (isLoginMode) {
          // Login Logic
          UserCredential cred = await _authService.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          
          if (cred.user != null) {
             String? role = await _databaseService.getUserRole(cred.user!.uid);
             
             // Log the login event for real-time notifications
             await _databaseService.logUserLogin(cred.user!.uid, cred.user!.email!);

             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Logged in successfully as $role')),
               );
               
               if (!cred.user!.emailVerified) {
                 Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (_) => VerifyEmailScreen(role: role ?? 'User')),
                 );
               } else if (role == 'Admin') {
                 Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (_) => const AdminHome()),
                 );
               } else {
                 Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (_) => const UserHome()),
                 );
               }
             }
          }

        } else {
          // Signup Logic
          UserCredential cred = await _authService.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

          if (cred.user != null) {
            String role = isAdmin ? 'Admin' : 'User';
            await _databaseService.saveUser(
              uid: cred.user!.uid,
              email: _emailController.text.trim(),
              name: _nameController.text.trim(),
              role: role,
            );
            
            // Also log login on signup? Maybe not strictly required but why not.
            // Requirement says "Whenever a user logs in". Signup is a form of login usually.
            await _databaseService.logUserLogin(cred.user!.uid, cred.user!.email!);

            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Account created successfully')),
               );
               
               if (!cred.user!.emailVerified) {
                 Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (_) => VerifyEmailScreen(role: role)),
                 );
               } else if (role == 'Admin') {
                 Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (_) => const AdminHome()),
                 );
               } else {
                 Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (_) => const UserHome()),
                 );
               }
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Theme Config (Crimson Command for Admin vs Clean Sky for User)
    final themeColor = isAdmin ? const Color(0xFFE11D48) : const Color(0xFF0EA5E9); // Crimson 600 vs Sky 500
    final accentColor = isAdmin ? const Color(0xFFFB7185) : const Color(0xFF2DD4BF); // Rose 400 vs Teal 400
    final scaffoldBg = isAdmin ? const Color(0xFF000000) : const Color(0xFFF8FAFC); // Pure Black vs Slate 50
    final cardBg = isAdmin ? const Color(0xFF111111) : Colors.white; // Dark Charcoal vs White
    final textColor = isAdmin ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isAdmin ? Colors.white70 : const Color(0xFF64748B);
    final fieldFillColor = isAdmin ? const Color(0xFF1A1A1A) : const Color(0xFFF1F5F9);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        color: scaffoldBg,
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: isMobile ? screenWidth * 0.9 : 450,
              margin: const EdgeInsets.symmetric(vertical: 40),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  color: cardBg.withOpacity(isAdmin ? 0.9 : 1.0),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isAdmin ? 0.4 : 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 24.0 : 40.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo and Title
                        _buildHeader(themeColor, accentColor, textColor, subtitleColor),
                        const SizedBox(height: 40),

                        // Role Selection (Show in both Login and Signup)
                        _buildRoleSelector(themeColor),
                        const SizedBox(height: 32),

                        // Name Field
                        if (!isLoginMode) ...[
                          _buildNameField(themeColor, fieldFillColor, textColor),
                          const SizedBox(height: 20),
                        ],

                        // Email Field
                        _buildEmailField(themeColor, fieldFillColor, textColor),
                        const SizedBox(height: 20),

                        // Password Field
                        _buildPasswordField(themeColor, fieldFillColor, textColor),

                        // Confirm Password
                        if (!isLoginMode) ...[
                          const SizedBox(height: 20),
                          _buildConfirmPasswordField(themeColor, fieldFillColor, textColor),
                        ],

                        const SizedBox(height: 12),

                        // Forgot Password
                        if (isLoginMode) _buildForgotPassword(themeColor),
                        const SizedBox(height: 32),

                        // Login/Signup Button
                        _buildActionButton(themeColor, accentColor),
                        const SizedBox(height: 20),

                        // Toggle between Login and Signup
                        _buildToggleAuthMode(themeColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color themeColor, Color accentColor, Color textColor, Color? subtitleColor) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeColor, accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            isAdmin ? Icons.admin_panel_settings_rounded : Icons.business_center_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isLoginMode ? 'Welcome Back' : 'Create Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isLoginMode ? (isAdmin ? 'Admin Portal Login' : 'Sign in to continue') : 'Sign up to get started',
          style: TextStyle(
            fontSize: 15,
            color: subtitleColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector(Color activeColor) {
    return Container(
      decoration: BoxDecoration(
        color: isAdmin ? Colors.white.withOpacity(0.1) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildRoleTab('User', !isAdmin, activeColor)),
          Expanded(child: _buildRoleTab('Admin', isAdmin, activeColor)),
        ],
      ),
    );
  }

  Widget _buildRoleTab(String label, bool isSelected, Color activeColor) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isAdmin = label == 'Admin';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (isAdmin ? activeColor : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              label == 'Admin' ? Icons.admin_panel_settings : Icons.person,
              size: 18,
              color: isSelected ? (isAdmin && label == 'Admin' ? Colors.white : activeColor) : Colors.grey[500],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? (isAdmin && label == 'Admin' ? Colors.white : activeColor) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField(Color themeColor, Color fillColor, Color textColor) {
    return TextFormField(
      controller: _nameController,
      keyboardType: TextInputType.name,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: 'Full Name',
        labelStyle: TextStyle(color: isAdmin ? Colors.white70 : Colors.grey[600]),
        hintText: 'Enter your full name',
        hintStyle: TextStyle(color: isAdmin ? Colors.white30 : Colors.grey[400]),
        prefixIcon: Icon(Icons.person_outline, size: 22, color: isAdmin ? Colors.white70 : Colors.grey[500]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isAdmin ? Colors.white24 : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isAdmin ? Colors.white24 : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColor, width: 2),
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField(Color themeColor, Color fillColor, Color textColor) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(color: isAdmin ? Colors.white70 : Colors.grey[600]),
        hintText: 'Enter your email',
        hintStyle: TextStyle(color: isAdmin ? Colors.white30 : Colors.grey[400]),
        prefixIcon: Icon(Icons.email_outlined, size: 22, color: isAdmin ? Colors.white70 : Colors.grey[500]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isAdmin ? Colors.white24 : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isAdmin ? Colors.white24 : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColor, width: 2),
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(Color themeColor, Color fillColor, Color textColor) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: isAdmin ? Colors.white70 : Colors.grey[600]),
        hintText: 'Enter your password',
        hintStyle: TextStyle(color: isAdmin ? Colors.white30 : Colors.grey[400]),
        prefixIcon: Icon(Icons.lock_outline, size: 22, color: isAdmin ? Colors.white70 : Colors.grey[500]),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 22,
            color: isAdmin ? Colors.white70 : Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isAdmin ? Colors.white24 : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isAdmin ? Colors.white24 : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColor, width: 2),
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (!isLoginMode && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField(Color themeColor, Color fillColor, Color textColor) {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        labelStyle: TextStyle(color: isAdmin ? Colors.white70 : Colors.grey[600]),
        hintText: 'Re-enter your password',
        hintStyle: TextStyle(color: isAdmin ? Colors.white30 : Colors.grey[400]),
        prefixIcon: Icon(Icons.lock_outline, size: 22, color: isAdmin ? Colors.white70 : Colors.grey[500]),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 22,
            color: isAdmin ? Colors.white70 : Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isAdmin ? Colors.white24 : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isAdmin ? Colors.white24 : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColor, width: 2),
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPassword(Color themeColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _showForgotPasswordDialog,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: themeColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(Color themeColor, Color accentColor) {
    return GradientButton(
      text: isLoginMode ? 'Login' : 'Sign Up',
      onPressed: _isLoading ? () {} : _handleAuth,
      gradient: LinearGradient(
        colors: [themeColor, accentColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  Widget _buildToggleAuthMode(Color themeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLoginMode ? "Don't have an account? " : "Already have an account? ",
          style: TextStyle(color: isAdmin ? Colors.white60 : Colors.grey[600], fontSize: 14),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              isLoginMode = !isLoginMode;
              _formKey.currentState?.reset();
            });
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          ),
          child: Text(
            isLoginMode ? 'Sign Up' : 'Login',
            style: TextStyle(
              color: themeColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
