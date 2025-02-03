import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String category;

  const QuizScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> soru = [];
  int cevap = 0;
  int score = 0;
  bool isLoading = true;
  bool hasAnswered = false;
  int? selectedOption;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('sorular')
          .doc('sorular')
          .get();

      if (snapshot.exists) {
        List<
            dynamic> soruListesi = snapshot['soru'];

        List<Map<String, dynamic>> parsedQuestions = soruListesi.map<
            Map<String, dynamic>>((q) {
          return {
            'soruText': q['soruText'] ?? 'NO Question Text',
            'sec': List<String>.from(q['sec'] ?? []),
            'cevap': q['cevap'] ?? 0,
            'metin': q['metin'] ?? 'No text available',
          };
        }).toList();

        setState(() {
          soru = parsedQuestions;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching questions: $e');
    }
  }

  void checkAnswer(int selectOptionIndex) {
    setState(() {
      hasAnswered = true;
      selectedOption = selectOptionIndex;
      int correctIndex = soru[cevap]['cevap'];

      if (correctIndex == selectOptionIndex) {
        score++;
      }
    });

    Future.delayed(const Duration(seconds: 2), () async {
      if (cevap < soru.length - 1) {
        setState(() {
          cevap++;
          hasAnswered = false;
          selectedOption = null;
        });
      } else {
        await updateUserScore();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>
              ResultScreen(score: score, tumSorular: soru.length)),
        );
      }
    });
  }

  Future<void> updateUserScore() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection('users')
          .doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);
        if (!snapshot.exists) throw Exception("Kullanıcı bulunamadı.");

        int existingScore = snapshot['score'] ?? 0;
        transaction.update(userRef, {'score': existingScore + score});
      });
    } catch (e) {
      print('Error updating user score: $e');
    }
  }

  Color getOptionColor(int index) {
    if (!hasAnswered) {
      return Colors.grey.shade200;
    }

    int correctIndex = soru[cevap]['cevap'];

    if (index == correctIndex) {
      return Colors.green.shade300;
    }

    if (index == selectedOption && index != correctIndex) {
      return Colors.red.shade300;
    }

    return Colors.grey.shade200;
  }

  Color getOptionTextColor(int index) {
    if (!hasAnswered) {
      return Colors.black;
    }

    int correctIndex = soru[cevap]['cevap'];

    if (index == correctIndex) {
      return Colors.green;
    }

    if (index == selectedOption) {
      return Colors.red;
    }

    return Colors.black;
  }

  void _showTextDialog(String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Metin'),
          content: Text(text),
          actions: <Widget>[
            TextButton(
              child: const Text('Kapat'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (soru.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              widget.category, style: const TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Soru yok.'),
        ),
      );
    }

    final currentQuestion = soru[cevap];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.category} (${cevap + 1}/${soru.length})',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (cevap + 1) / soru.length,
              backgroundColor: Colors.green,
              color: Colors.blueAccent,
              minHeight: 8,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      currentQuestion['soruText'],
                      style: const TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.blue),
                  onPressed: () {
                    _showTextDialog(currentQuestion['metin']);
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.separated(
                itemCount: currentQuestion['sec'].length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  Color bgColor = getOptionColor(index);
                  Color txtColor = getOptionTextColor(index);

                  return Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bgColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius
                            .circular(10)),
                      ),
                      onPressed: hasAnswered ? null : () => checkAnswer(index),
                      child: Text(
                        currentQuestion['sec'][index],
                        style: TextStyle(color: txtColor, fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: cevap > 0
                      ? () {
                    setState(() {
                      cevap--;
                      hasAnswered = false;
                      selectedOption = null;
                    });
                  }
                      : null,
                  child: const Text('Önceki'),
                ),
                ElevatedButton(
                  onPressed: cevap < soru.length - 1 && !hasAnswered
                      ? () {
                    setState(() {
                      cevap++;
                      hasAnswered = false;
                      selectedOption = null;
                    });
                  }
                      : null,
                  child: const Text('Sonraki'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}