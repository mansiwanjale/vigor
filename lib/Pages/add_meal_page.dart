import 'package:flutter/material.dart';
import '../Pages/Diet.dart';

class AddMealPage extends StatefulWidget {
  final MealService service;

  const AddMealPage({super.key, required this.service});

  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  final TextEditingController itemsController = TextEditingController();
  String selectedType = "breakfast";

  final List<String> mealTypes = [
    "breakfast",
    "lunch",
    "dinner",
    "snack"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Meal")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Meal Type
            DropdownButtonFormField<String>(
              value: selectedType,
              items: mealTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Meal Type",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Meal Items
            TextField(
              controller: itemsController,
              decoration: const InputDecoration(
                labelText: "What did you eat?",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.service.addMeal(
                    selectedType,
                    itemsController.text,
                    DateTime.now().toString().split(" ")[0],
                    TimeOfDay.now().format(context),
                  );

                  Navigator.pop(context);
                },
                child: const Text("Save Meal"),
              ),
            )
          ],
        ),
      ),
    );
  }
}