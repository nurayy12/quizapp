import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'signup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    kullaniciErisim();
  }

  Future<void> kullaniciErisim() async {
    if (user == null) return;

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user!.email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı.')));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: $e')));
    }
  }

  Future<void> pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });

    await uploadImage(_selectedImage!);
  }

  Future<void> uploadImage(File image) async {
    if (user == null) return;

    try {
      String filePath = 'profile_images/${user!.uid}.jpg';
      Reference storageRef =
      FirebaseStorage.instance.ref().child(filePath);
      UploadTask uploadTask = storageRef.putFile(image);

      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'profileImageUrl': imageUrl});

      setState(() {
        userData?['profileImageUrl'] = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil resmi güncellendi!')));
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')));
    }
  }

  Future<void> resetScore() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'score': 0,
      });
    } catch (e) {
      print('Error resetting score: $e');
    }
  }


  Future<void> updateScoreBasedOnTest(int testScore) async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'score': testScore,
      });

    } catch (e) {
      print('Error updating score: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text('Kullanıcı bulunamadı.'))
          : SingleChildScrollView(
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: userData!['profileImageUrl'] != null
                            ? NetworkImage(userData!['profileImageUrl'])
                            : const AssetImage('assets/default_profile_image.jpg')
                        as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2)),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    userData?['name'] ?? 'İsim bulunamadı.',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events_sharp, color: Colors.amber, size: 24),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        '${userData?['score'] ?? 0}',
                        style: const TextStyle(fontSize: 22, color: Colors.black54),
                      )
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.email,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        child: Text(
                          userData?['email'] ?? 'No Email',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
              child: GestureDetector(
                onTap: () async {

                  await FirebaseAuth.instance.signOut();


                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                      color: Colors.green, borderRadius: BorderRadius.circular(30)),
                  child: const Center(
                    child: Text(
                      'Çıkış Yap',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}