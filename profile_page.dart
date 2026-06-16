import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = "Jatin";
  int points = 450;

  final TextEditingController nameController = TextEditingController();

  String getBadge() {
    if (points >= 1000) {
      return "🥇 City Guardian";
    } else if (points >= 500) {
      return "🥈 Community Hero";
    } else {
      return "🥉 Civic Helper";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.blue,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),

            const SizedBox(height: 15),

            Text(
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text("⭐ $points Points", style: const TextStyle(fontSize: 20)),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                getBadge(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Enter New Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("Update Name"),
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    setState(() {
                      userName = nameController.text;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Name Updated Successfully"),
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add 50 Points"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  setState(() {
                    points += 50;
                  });
                },
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Reset Points"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  setState(() {
                    points = 0;
                  });
                },
              ),
            ),

            const SizedBox(height: 30),

            const Divider(),

            const Text(
              "Leaderboard",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            leaderboardTile("Rahul", 620),
            leaderboardTile("Jatin", 450),
            leaderboardTile("Anjali", 390),
            leaderboardTile("Kiran", 300),
          ],
        ),
      ),
    );
  }

  Widget leaderboardTile(String name, int score) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: Colors.orange),
        title: Text(name),
        trailing: Text(
          "$score ⭐",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
