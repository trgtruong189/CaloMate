class BMI {
  double weight; // Weight in kilograms
  double height; // Height in meters

  BMI({required this.weight, required this.height});

  /// Tính chỉ số BMI
  double calculateBMI() {
    return weight / (height * height);
  }

  /// Xác định thể trang dựa trên BMI
  String getBMICategory() {
    double bmiValue = calculateBMI();
    if (bmiValue < 18.5) {
      return 'Gầy';
    } else if (bmiValue >= 18.5 && bmiValue < 24.9) {
      return 'Bình thường';
    } else if (bmiValue >= 25 && bmiValue < 29.9) {
      return 'Thừa cân';
    } else {
      return 'Béo phì';
    }
  }
}
