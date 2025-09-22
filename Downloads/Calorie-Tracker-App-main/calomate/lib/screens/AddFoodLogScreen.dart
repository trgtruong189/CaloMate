import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../modals/Food.dart';
import '../../sevices/UserProvider.dart';

class AddFoodScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  final foodNameController = TextEditingController();
  final caloriesController = TextEditingController();
  final proteinController = TextEditingController();
  final fatController = TextEditingController();
  final carbsController = TextEditingController();
  final foodWeightController = TextEditingController();

  AddFoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thêm món ăn"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: foodNameController,
                  decoration: const InputDecoration(labelText: "Tên món ăn"),
                  validator: (value) =>
                  value!.isEmpty ? "Vui lòng nhập tên món ăn" : null,
                ),
                TextFormField(
                  controller: caloriesController,
                  decoration: const InputDecoration(labelText: "Calories"),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: proteinController,
                  decoration: const InputDecoration(labelText: "Protein (g)"),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: fatController,
                  decoration: const InputDecoration(labelText: "Fat (g)"),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: carbsController,
                  decoration: const InputDecoration(labelText: "Carbs (g)"),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: foodWeightController,
                  decoration: const InputDecoration(labelText: "Khối lượng (g)"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final foodName = foodNameController.text.trim();
                      final calories =
                          int.tryParse(caloriesController.text.trim()) ?? 0;
                      final protein =
                          double.tryParse(proteinController.text.trim()) ?? 0;
                      final fat =
                          double.tryParse(fatController.text.trim()) ?? 0;
                      final carbWeight =
                          double.tryParse(carbsController.text.trim()) ?? 0;
                      final foodWeight =
                          double.tryParse(foodWeightController.text.trim()) ?? 0;

                      userProvider.logFood(
                        Food(
                          foodName: foodName,
                          calories: calories,
                          protein: protein,
                          fat: fat,
                          carbs: carbWeight,
                          foodWeight: foodWeight,
                        ),
                      );

                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Thêm',
                    style: GoogleFonts.poppins(color: Colors.white),
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
