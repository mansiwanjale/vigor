import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Pages/Diet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Pages/add_meal_page.dart';

class MealService {
  final CollectionReference meals =
      FirebaseFirestore.instance.collection('meals');

  Future<void> addMeal(String type, String items, String date, String time) async {
    await meals.add({
      'type': type,
      'items': items,
      'date': date,
      'time': time,
    });
  }

  Stream<QuerySnapshot> getMeals() {
    return meals.orderBy('date', descending: true).snapshots();
  }

  Future<void> deleteMeal(String id) async {
    await meals.doc(id).delete();
  }
}
class DietPage extends StatelessWidget {
  DietPage({super.key});

  final MealService service = MealService();
  IconData _getMealIcon(String type) {
  switch (type) {
    case "breakfast":
      return Icons.free_breakfast;
    case "lunch":
      return Icons.lunch_dining;
    case "dinner":
      return Icons.dinner_dining;
    default:
      return Icons.fastfood;
  }
}

Color _getMealColor(String type) {
  switch (type) {
    case "breakfast":
      return Colors.orange;
    case "lunch":
      return Colors.green;
    case "dinner":
      return Colors.blue;
    default:
      return Colors.purple;
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Diet Planner"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: service.getMeals(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No meals added yet 🍽️"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index];

              return Container(
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        blurRadius: 6,
        spreadRadius: 2,
      )
    ],
  ),
  child: Row(
    children: [

      // Meal Icon
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _getMealColor(data['type']),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _getMealIcon(data['type']),
          color: Colors.white,
        ),
      ),

      const SizedBox(width: 12),

      // Meal Info
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['items'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${data['type']} • ${data['date']} • ${data['time']}",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),

      // Delete Button
      IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          service.deleteMeal(data.id);
        },
      ),
    ],
  ),
);
              
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMealPage(service: service),
      ),
    );
  },
  child: const Icon(Icons.add),
),
    );
  }
  
}
class AddMealDialog extends StatefulWidget {
  final MealService service;

  const AddMealDialog({super.key, required this.service});

  @override
  State<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  final TextEditingController itemsController = TextEditingController();
  String selectedType = "breakfast";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Meal"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: selectedType,
            items: ["breakfast", "lunch", "dinner", "snack"]
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedType = value!;
              });
            },
          ),

          TextField(
            controller: itemsController,
            decoration: const InputDecoration(
              labelText: "Meal Items",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),

        ElevatedButton(
          onPressed: () {
            widget.service.addMeal(
              selectedType,
              itemsController.text,
              DateTime.now().toString().split(" ")[0],
              TimeOfDay.now().format(context),
            );

            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}