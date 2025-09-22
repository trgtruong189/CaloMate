import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> drinks = [
    {
      "foodName": "Trà đá",
      "calories": 2,
      "protein": 0.0,
      "fat": 0.0,
      "carbs": 0.5,
      "foodWeight": 200.0,
      "description": "Trà xanh pha loãng với đá, gần như không calo.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/7/70/Iced_tea_glass.jpg"
    },
    {
      "foodName": "Cà phê đen",
      "calories": 5,
      "protein": 0.3,
      "fat": 0.0,
      "carbs": 1.0,
      "foodWeight": 150.0,
      "description": "Cà phê đen nguyên chất, không đường.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/4/45/A_small_cup_of_coffee.JPG"
    },
    {
      "foodName": "Cà phê sữa đá",
      "calories": 120,
      "protein": 3.0,
      "fat": 3.0,
      "carbs": 20.0,
      "foodWeight": 200.0,
      "description": "Cà phê pha sữa đặc và đá, hương vị Việt Nam.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/4/45/Vietnamese_iced_coffee_with_condensed_milk.jpg"
    },
    {
      "foodName": "Sinh tố xoài",
      "calories": 150,
      "protein": 2.0,
      "fat": 1.0,
      "carbs": 35.0,
      "foodWeight": 250.0,
      "description": "Sinh tố xoài ngọt mát, giàu vitamin C.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/5/5d/Mango_smoothie.jpg"
    },
    {
      "foodName": "Sinh tố bơ",
      "calories": 220,
      "protein": 3.0,
      "fat": 15.0,
      "carbs": 18.0,
      "foodWeight": 250.0,
      "description": "Sinh tố bơ béo ngậy, giàu dinh dưỡng.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/d/d1/Avocado_smoothie.jpg"
    },
    {
      "foodName": "Nước mía",
      "calories": 180,
      "protein": 0.5,
      "fat": 0.0,
      "carbs": 45.0,
      "foodWeight": 250.0,
      "description": "Nước ép từ mía tươi, giải khát mùa hè.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/8/86/Sugarcane_juice.jpg"
    },
    {
      "foodName": "Nước dừa tươi",
      "calories": 60,
      "protein": 1.0,
      "fat": 0.2,
      "carbs": 14.0,
      "foodWeight": 200.0,
      "description": "Nước dừa tươi mát, bổ sung điện giải.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/5/5b/Coconut_water.jpg"
    },
    {
      "foodName": "Trà sữa trân châu",
      "calories": 300,
      "protein": 4.0,
      "fat": 8.0,
      "carbs": 55.0,
      "foodWeight": 350.0,
      "description": "Trà sữa ngọt, topping trân châu.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/9/9a/Bubble_tea.jpg"
    },
    {
      "foodName": "Sữa đậu nành",
      "calories": 80,
      "protein": 6.0,
      "fat": 3.5,
      "carbs": 8.0,
      "foodWeight": 200.0,
      "description": "Sữa đậu nành giàu protein thực vật.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/6/6e/Soy_milk.jpg"
    },
    {
      "foodName": "Sữa tươi",
      "calories": 100,
      "protein": 8.0,
      "fat": 4.0,
      "carbs": 12.0,
      "foodWeight": 200.0,
      "description": "Sữa tươi thanh trùng, giàu canxi.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/f/f0/Milk_glass.jpg"
    },
    {
      "foodName": "Trà xanh",
      "calories": 0,
      "protein": 0.0,
      "fat": 0.0,
      "carbs": 0.0,
      "foodWeight": 200.0,
      "description": "Trà xanh nguyên chất, không đường.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/5/5c/Green_tea_cup.jpg"
    },
    {
      "foodName": "Trà chanh",
      "calories": 60,
      "protein": 0.0,
      "fat": 0.0,
      "carbs": 15.0,
      "foodWeight": 200.0,
      "description": "Trà đá pha chanh, ngọt dịu.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/2/23/Lemon_iced_tea.jpg"
    },
    {
      "foodName": "Nước cam ép",
      "calories": 110,
      "protein": 2.0,
      "fat": 0.5,
      "carbs": 25.0,
      "foodWeight": 250.0,
      "description": "Nước cam ép giàu vitamin C.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/c/cd/Orange_juice_1.jpg"
    },
    {
      "foodName": "Nước ép cà rốt",
      "calories": 80,
      "protein": 2.0,
      "fat": 0.3,
      "carbs": 18.0,
      "foodWeight": 200.0,
      "description": "Nước ép cà rốt tốt cho mắt.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/b/b6/Carrot_Juice.jpg"
    },
    {
      "foodName": "Nước ép dưa hấu",
      "calories": 70,
      "protein": 1.0,
      "fat": 0.2,
      "carbs": 17.0,
      "foodWeight": 200.0,
      "description": "Nước ép dưa hấu giải khát, ít calo.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/5/5e/Watermelon_juice.jpg"
    },
    {
      "foodName": "Nước ép ổi",
      "calories": 90,
      "protein": 1.5,
      "fat": 0.5,
      "carbs": 20.0,
      "foodWeight": 200.0,
      "description": "Nước ép ổi giàu vitamin C, ít đường.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/9/95/Guava_juice.jpg"
    },
    {
      "foodName": "Sữa chua uống",
      "calories": 120,
      "protein": 5.0,
      "fat": 3.0,
      "carbs": 18.0,
      "foodWeight": 200.0,
      "description": "Sữa chua dạng lỏng, bổ sung lợi khuẩn.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/7/7b/Drinking_yogurt.jpg"
    },
    {
      "foodName": "Nước ngọt có gas (Cola)",
      "calories": 140,
      "protein": 0.0,
      "fat": 0.0,
      "carbs": 35.0,
      "foodWeight": 330.0,
      "description": "Nước giải khát có gas, nhiều đường.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/0/09/Coca_Cola_can.jpg"
    },
    {
      "foodName": "Bia",
      "calories": 150,
      "protein": 1.0,
      "fat": 0.0,
      "carbs": 13.0,
      "foodWeight": 330.0,
      "description": "Bia lon phổ biến, chứa cồn.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/f/f7/Beer_glass.jpg"
    },
    {
      "foodName": "Rượu vang đỏ",
      "calories": 125,
      "protein": 0.1,
      "fat": 0.0,
      "carbs": 4.0,
      "foodWeight": 150.0,
      "description": "Rượu vang đỏ, uống điều độ tốt cho tim mạch.",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/0/04/Red_Wine_Glass.jpg"
    },
  ];

  int count = 0;
  for (final drink in drinks) {
    await firestore.collection("Food").add(drink);
    print("✅ Đã thêm: ${drink['foodName']}");
    count++;
  }

  print("🎉 Hoàn tất! Đã thêm $count loại thức uống vào Firestore.");
}
