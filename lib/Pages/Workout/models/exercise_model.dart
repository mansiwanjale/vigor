class ExerciseModel {
  final String name;
  final int sets;
  final int reps;
  final String image;
  final String description;

  ExerciseModel({
    required this.name,
    required this.sets,
    required this.reps,
    required this.image,
    this.description = "",
  });

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      name: map['name'] ?? '',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
      image: map['image'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'image': image,
      'description': description,
    };
  }
}
