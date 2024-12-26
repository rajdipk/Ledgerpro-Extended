class SkuGenerator {
  static String generateSku(String name, String category, int itemCount) {
    // Get first 3 letters of category (or less if category is shorter)
    final categoryPrefix = (category.isEmpty ? 'GEN' : category)
        .replaceAll(RegExp(r'[^A-Za-z]'), '')
        .toUpperCase()
        .padRight(3, 'X')
        .substring(0, 3);

    // Get first 3 letters of name (or less if name is shorter)
    final namePrefix = name
        .replaceAll(RegExp(r'[^A-Za-z]'), '')
        .toUpperCase()
        .padRight(3, 'X')
        .substring(0, 3);

    // Add a sequential number padded to 4 digits
    final sequentialNumber = (itemCount + 1).toString().padLeft(4, '0');

    return '$categoryPrefix$namePrefix$sequentialNumber';
  }
}
