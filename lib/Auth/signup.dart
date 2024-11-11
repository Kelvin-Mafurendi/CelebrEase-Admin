// ignore_for_file: use_build_context_synchronously

import 'package:celebrease_manager/Auth/authservice.dart';
import 'package:celebrease_manager/States/changemanger.dart';
import 'package:celebrease_manager/main.dart';
import 'package:celebrease_manager/modules/add_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  Future<void> register(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authService = AuthService();
      try {
        // Check for unique fields
        if (await isFieldUnique('username', usernameController.text) &&
            await isFieldUnique('phone number', phoneNumberController.text)) {
          UserCredential cred = await authService.signUpwithEmailPassword(
              emailController.text, passwordController.text);

          // Create a new document in the 'Vendors' or 'Customers' collection
          Map<String, dynamic> userData = {
            'name': nameController.text,
            'surname': surnameController.text,
            'phone number': phoneNumberController.text,
            'username': usernameController.text,
            'email': emailController.text,
            'userId': cred.user!.uid,
            'userType': 'Manager',
          };

          // Add additional fields for vendors

          Provider.of<ChangeManager>(context, listen: false).handleData(
              collection: 'Management',
              dataType: 'profile',
              newData: userData,
              operation: OperationType.create,
              fileFields: {'profilePic': 'Profile Images'});
          setState(() {
            _formKey.currentState!.reset();
            emailController.clear();
            passwordController.clear();
            confirmPasswordController.clear();
            nameController.clear();
            surnameController.clear();
            usernameController.clear();
            phoneNumberController.clear();
          });

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: backgroundColor,
              icon: const Icon(
                FluentSystemIcons.ic_fluent_checkmark_circle_regular,
                size: 100,
              ),
              title: Text(
                'Congratulations!\n You can now sign in.',
                style: GoogleFonts.lateef(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/log_in');
                  },
                  child: const Text('Sign In'),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => const AlertDialog(
              title: Text('Username or phone number already in use'),
            ),
          );
        }
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(e.toString()),
          ),
        );
      }}}

    Future<bool> isFieldUnique(String field, String value) async {
      final QuerySnapshot result = await _firestore
          .collection('Management')
          .where(field, isEqualTo: value)
          .limit(1)
          .get();
      return result.docs.isEmpty;
    }

    dynamic image;

    getImage(context) async {
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(type: FileType.image, allowMultiple: false);

      if (result != null) {
        setState(() {
          image = result.files.first.bytes;
        });
      }
    }

    @override
    Widget build(BuildContext context) {
      return CustomScrollView(
        scrollDirection: Axis.vertical,
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            floating: true,
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      secondaryColor,
                      accentColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all()),
                      child: Text(
                        'CelebrEase',
                        style: GoogleFonts.merienda(fontSize: 40),
                      )),
                ),
              ),
              title: Text('Celebrease'),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  Text('Create a management Account',
                      style: const TextStyle(fontSize: 25)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Stack(children: [
                      AddImage(dataType: 'profile', fieldName: 'profilePic'),
                    ]),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              hintText: 'Name',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: surnameController,
                            decoration: const InputDecoration(
                              hintText: 'Surname',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your surname';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: IntlPhoneField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      initialCountryCode: 'ZA',
                      onChanged: (phone) {
                        phoneNumberController.text =
                            '${phone.countryCode}${phone.number}';
                      },
                      validator: (phone) {
                        if (phone == null || phone.number.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        hintText: 'Username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters long';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Confirm Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextButton(
                      onPressed: () => register(context),
                      child: Text(
                        'Register',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 150,
            ),
          )
        ],
      );
    }

    Widget buildTextField(TextEditingController controller, String label,
        {int maxLines = 1}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
    }
  }
