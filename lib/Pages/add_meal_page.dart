import 'package:flutter/material.dart';
import '../Pages/Diet.dart';

class AddMealPage extends StatefulWidget {
  final MealService service;

  const AddMealPage({super.key, required this.service});

  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  String selectedStatus = "planned";
  final TextEditingController itemsController = TextEditingController();
  final TextEditingController calController = TextEditingController();
  final TextEditingController proteinController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String selectedType = "breakfast";

  final List<String> mealTypes = ["breakfast", "lunch", "dinner", "snack"];

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Meal"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),

            child: Column(
              children: [
                // 🔥 TYPE
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
                  decoration: InputDecoration(
                    labelText: "Meal Type",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔥 STATUS
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items: ["planned", "eaten"].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Status",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔥 ITEMS
                TextField(
                  controller: itemsController,
                  decoration: InputDecoration(
                    labelText: "What did you eat?",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔥 CALORIES
                TextField(
                  controller: calController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Calories",
                    prefixIcon: Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔥 PROTEIN
                TextField(
                  controller: proteinController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Protein (g)",
                    prefixIcon: Icon(Icons.fitness_center, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔥 NOTE
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Note (optional)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // 🔥 SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      widget.service.addMeal(
                        selectedType,
                        itemsController.text,
                        DateTime.now().toString().split(" ")[0],
                        TimeOfDay.now().format(context),
                        int.tryParse(calController.text) ?? 0,
                        int.tryParse(proteinController.text) ?? 0,
                        noteController.text,
                        selectedStatus,
                      );

                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Save Meal",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
