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

  final _formKey = GlobalKey<FormState>();

  String selectedType = "breakfast";

  // ⏰ Time Picker Variable
  TimeOfDay selectedTime = TimeOfDay.now();

  final List<String> mealTypes = [
    "breakfast",
    "lunch",
    "dinner",
    "snack",
  ];

  Map<String, List<String>> healthyFoods = {
    "breakfast": [
      "Poha",
      "Boiled Eggs",
      "Idli with Sambar",
      "Paratha with Curd",
    ],
    "lunch": [
      "Dal Rice",
      "Roti with Sabzi",
      "Paneer Bhurji with Roti",
      "Chicken Curry with Rice",
    ],
    "snack": [
      "Fruit Bowl",
      "Roasted Chana",
      "Peanuts",
      "Boiled Corn",
    ],
    "dinner": [
      "Roti with Sabzi",
      "Dal Khichdi",
      "Egg Curry",
    ],
  };

  Widget _buildHealthySection(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 4),
            child: Text(
              "• $item",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Meal"),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 LEFT SIDE (FORM)

              Expanded(
                flex: 1,

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

                  child: Form(
                    key: _formKey,

                    child: Column(
                      children: [
                        // 🍽 Meal Type

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

                        // 📌 Status

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

                        // 🍛 Meal Items

                        TextFormField(
                          controller: itemsController,

                          decoration: InputDecoration(
                            labelText: "What did you eat?",

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          validator: (value) =>
                              value!.isEmpty ? "Enter meal items" : null,
                        ),

                        const SizedBox(height: 16),

                        // 🔥 Calories

                        TextFormField(
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

                          validator: (value) =>
                              value!.isEmpty ? "Enter calories" : null,
                        ),

                        const SizedBox(height: 16),

                        // 💪 Protein

                        TextFormField(
                          controller: proteinController,
                          keyboardType: TextInputType.number,

                          decoration: InputDecoration(
                            labelText: "Protein (g)",

                            prefixIcon: Icon(
                              Icons.fitness_center,
                              color: Colors.blue,
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          validator: (value) =>
                              value!.isEmpty ? "Enter protein" : null,
                        ),

                        const SizedBox(height: 16),

                        // 📝 Note

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

                        const SizedBox(height: 16),

                        // ⏰ Time Picker

                        InkWell(
                          onTap: () async {
                            TimeOfDay? pickedTime =
                                await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );

                            if (pickedTime != null) {
                              setState(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },

                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),

                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),

                              borderRadius: BorderRadius.circular(12),
                            ),

                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.teal,
                                ),

                                const SizedBox(width: 10),

                                Text(
                                  selectedTime.format(context),

                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // 💾 Save Button

                        SizedBox(
                          width: 200,

                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),

                              backgroundColor: Colors.teal,
                            ),

                            onPressed: () {
                              if (!_formKey.currentState!.validate()) return;

                              widget.service.addMeal(
                                selectedType,
                                itemsController.text,
                                DateTime.now().toString().split(" ")[0],

                                // ⏰ Selected Time
                                selectedTime.format(context),

                                int.tryParse(calController.text) ?? 0,
                                int.tryParse(proteinController.text) ?? 0,
                                noteController.text,
                                selectedStatus,
                              );

                              Navigator.pop(context);
                            },

                            child: const Text(
                              "Save Meal",

                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // 🥗 RIGHT SIDE (HEALTHY SUGGESTIONS)

              Expanded(
                flex: 1,

                child: Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.05),

                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(
                      color: Colors.teal.withOpacity(0.2),
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "Healthy Meal Suggestions",

                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildHealthySection(
                        "Breakfast",
                        healthyFoods["breakfast"]!,
                        Icons.sunny,
                        Colors.orange,
                      ),

                      _buildHealthySection(
                        "Lunch",
                        healthyFoods["lunch"]!,
                        Icons.restaurant,
                        Colors.green,
                      ),

                      _buildHealthySection(
                        "Snack",
                        healthyFoods["snack"]!,
                        Icons.apple,
                        Colors.redAccent,
                      ),

                      _buildHealthySection(
                        "Dinner",
                        healthyFoods["dinner"]!,
                        Icons.nights_stay,
                        Colors.indigo,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}