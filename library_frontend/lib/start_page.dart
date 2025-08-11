import 'package:flutter/material.dart';
import 'package:library_frontend/api_service.dart';
import 'package:provider/provider.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  // ← form key
  final _formKey = GlobalKey<FormState>();

  // controllers for both login & register
  final TextEditingController nameController     = TextEditingController();
  final TextEditingController emailController    = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isRegister = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final pass  = passwordController.text;
      final email = emailController.text;

      String? token = await ApiService.login(pass, email);
      if (token != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User logged in successfully!')),
        );
        
        //Navigator.of(context).pushReplacement(MaterialPageRoute(builder: builder));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
            'Failed to login. Check your email and password!'
          )),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final name  = nameController.text.trim();
      final email = emailController.text.trim();
      final pass  = passwordController.text.trim();

      final status = await ApiService.addUser(
        name, email, pass
      );

      if (status == 201 || status == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User registered successfully!'))
        );
        // Navigator.of(context)… go to login or home
      } else if (status == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That email is already registered.'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to register user.'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.89),
      body: Center(
        child: Container(
          height: 450,
          width: 450,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Top tabs
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isRegister = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isRegister
                                ? Colors.white
                                : const Color.fromARGB(255, 14, 12, 63),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              color: !isRegister
                                  ? Colors.white
                                  : const Color.fromARGB(255, 14, 12, 63),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isRegister = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isRegister
                                ? const Color.fromARGB(255, 14, 12, 63)
                                : Colors.white,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 16,
                              color: !isRegister
                                  ? const Color.fromARGB(255, 14, 12, 63)
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom content
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: isRegister
                        ? _buildRegisterForm()
                        : _buildLoginForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Please log in', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter your email' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter your password' : null,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 14, 12, 63),
            ),
            child: const Text('Login'),
          ),
        ],
      );

  Widget _buildRegisterForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Create an account', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter your email' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter a password' : null,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 14, 12, 63),
            ),
            child: const Text('Register'),
          ),
        ],
      );
}
