import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Pages/Diet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Pages/add_meal_page.dart';
import '../session.dart';

class MealService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String get userId {
    if (Session().currentUsername == null ||
        Session().currentUsername!.isEmpty) {
      throw Exception("User not logged in");
    }
    return Session().currentUsername!;
  }

  CollectionReference get meals => firestore.collection('meals');

  Future<void> addMeal(
    String type,
    String items,
    String date,
    String time,
    int calories,
    int protein,
    String note,
    String status,
    // 👈 ADD THIS
  ) async {
    await meals.add({
      'userId': Session().currentUsername,
      'type': type,
      'items': items,
      'calories': calories,
      'protein': protein,
      'status': status, // 👈 USE THIS
      'note': note,
      'date': date,
      'time': time,
    });
  }

  //Stream<QuerySnapshot> getMeals() {
  //return meals.snapshots();
  //}
  Stream<QuerySnapshot> getMeals() {
    return meals
        .where('userId', isEqualTo: Session().currentUsername)
        .snapshots();
  }

  Future<void> deleteMeal(String id) async {
    await meals.doc(id).delete();
  }

  Future<void> updateMeal(
    String id,
    String type,
    String items,
    int calories,
    int protein,
    String note,
    String status,
  ) async {
    await meals.doc(id).update({
      'type': type,
      'items': items,
      'calories': calories,
      'protein': protein,
      'note': note,
      'status': status,
    });
  }
}

class DietPage extends StatefulWidget {
  DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  Widget _summaryItem(String emoji, int? value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          "${value ?? 0}",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == "eaten" ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String selectedCategory = "all";
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

  Widget _categoryChip(String type) {
    bool isSelected = selectedCategory == type;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [Colors.black, Colors.teal])
                : null,
            color: isSelected ? null : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            type.toUpperCase(),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Map<String, int> getTodaySummary(List docs) {
    String today = DateTime.now().toString().split(" ")[0];

    int breakfast = 0;
    int lunch = 0;
    int dinner = 0;
    int snack = 0;

    for (var d in docs) {
      if (d['date'] == today) {
        switch (d['type']) {
          case "breakfast":
            breakfast++;
            break;
          case "lunch":
            lunch++;
            break;
          case "dinner":
            dinner++;
            break;
          case "snack":
            snack++;
            break;
        }
      }
    }

    return {
      "total": breakfast + lunch + dinner + snack,
      "breakfast": breakfast,
      "lunch": lunch,
      "dinner": dinner,
      "snack": snack,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Diet & Meal Planner")),

      body: StreamBuilder<QuerySnapshot>(
        stream: service.getMeals(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          const SizedBox(height: 20);

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final summary = getTodaySummary(docs);
          if (docs.isEmpty) {
            return Column(
              children: [
                // 🔥 KEEP ADD BUTTON VISIBLE
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMealPage(service: service),
                      ),
                    );
                  },


                  
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.teal],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 10),
                        
                        Text(
                          "Add New Meal",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                const Center(child: Text("No meals added yet 🍽️")),
              ],
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hey ${Session().currentUsername ?? "User"} 👋",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Let's track your meals today 🍎",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 🔥 SUMMARY CARD (NOW PROPERLY RETURNED)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.yellow, Colors.teal],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Summary",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _summaryItem("Total", summary['total']),
                        _summaryItem("Breakfast", summary['breakfast']),
                        _summaryItem("Lunch", summary['lunch']),
                        _summaryItem("Dinner", summary['dinner']),
                      ],
                    ),
                  ],
                ),
              ),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _categoryChip("all"),
                    _categoryChip("breakfast"),
                    _categoryChip("lunch"),
                    _categoryChip("dinner"),
                    _categoryChip("snack"),
                  ],
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMealPage(service: service),
                      ),
                    );
                  },
                  child: Container(
                    width: 200, // ✅ THIS is the real fix
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.teal],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Add Meal",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 🔥 LIST
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index];

                    if (selectedCategory != "all" &&
                        data['type'] != selectedCategory) {
                      return const SizedBox(); // hide item
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔥 ICON BOX
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getMealColor(
                                  data['type'],
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getMealIcon(data['type']),
                                color: _getMealColor(data['type']),
                                size: 26,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // 🔥 CONTENT
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // TITLE + STATUS
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          data['items'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      _buildStatusBadge(
                                        data['status'] ?? "planned",
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // TYPE + DATE + TIME
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${data['type']} • ${data['date']} • ${data['time']}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // CALORIES + PROTEIN
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "🔥 ${data['calories'] ?? 0} kcal",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "💪 ${data['protein'] ?? 0} g",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // NOTE
                                  if (data['note'] != null &&
                                      data['note'].toString().isNotEmpty)
                                    Text(
                                      "📝 ${data['note']}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // 🔥 ACTION BUTTONS
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return EditMealDialog(
                                          service: service,
                                          id: data.id,
                                          existingType: data['type'],
                                          existingItems: data['items'],
                                        );
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    service.deleteMeal(data.id);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class EditMealDialog extends StatefulWidget {
  final MealService service;
  final String id;
  final String existingType;
  final String existingItems;

  const EditMealDialog({
    super.key,
    required this.service,
    required this.id,
    required this.existingType,
    required this.existingItems,
  });

  @override
  State<EditMealDialog> createState() => _EditMealDialogState();
}

class _EditMealDialogState extends State<EditMealDialog> {
  late TextEditingController itemsController;
  late TextEditingController calController;
  late TextEditingController proteinController;
  late TextEditingController noteController;

  late String selectedType;
  String selectedStatus = "planned";

  @override
  void initState() {
    super.initState();

    itemsController = TextEditingController(text: widget.existingItems);
    calController = TextEditingController();
    proteinController = TextEditingController();
    noteController = TextEditingController();

    selectedType = widget.existingType;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Meal"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // TYPE
            DropdownButtonFormField<String>(
              value: selectedType,
              items: ["breakfast", "lunch", "dinner", "snack"]
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),

            const SizedBox(height: 10),

            // ITEMS
            TextField(
              controller: itemsController,
              decoration: const InputDecoration(labelText: "Items"),
            ),

            const SizedBox(height: 10),

            // CALORIES
            TextField(
              controller: calController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Calories"),
            ),

            const SizedBox(height: 10),

            // PROTEIN
            TextField(
              controller: proteinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Protein"),
            ),

            const SizedBox(height: 10),

            // NOTE
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Note"),
            ),

            const SizedBox(height: 10),

            // STATUS 🔥
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: [
                "planned",
                "eaten",
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
              },
              decoration: const InputDecoration(labelText: "Status"),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),

        ElevatedButton(
          onPressed: () {
            widget.service.updateMeal(
              widget.id,
              selectedType,
              itemsController.text,
              int.tryParse(calController.text) ?? 0,
              int.tryParse(proteinController.text) ?? 0,
              noteController.text,
              selectedStatus,
            );

            Navigator.pop(context);
          },
          child: const Text("Update"),
        ),
      ],
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
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedType = value!;
              });
            },
          ),

          TextField(
            controller: itemsController,
            decoration: const InputDecoration(labelText: "Meal Items"),
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
              0, // calories default
              0, // protein default
              "",
              "planned", // note default
            );

            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
