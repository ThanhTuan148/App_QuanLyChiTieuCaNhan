/// Helper để map category icon sang emoji
import 'package:flutter/material.dart';

class CategoryEmojiMapper {
  static final Map<int, String> _iconToEmoji = {
    Icons.restaurant.codePoint: '🍔',
    Icons.shopping_cart.codePoint: '🛍️',
    Icons.directions_car.codePoint: '🚌',
    Icons.movie.codePoint: '🎬',
    Icons.receipt.codePoint: '💡',
    Icons.home.codePoint: '🏠',
    Icons.flight.codePoint: '✈️',
    Icons.school.codePoint: '📚',
    Icons.medical_services.codePoint: '💊',
    Icons.fitness_center.codePoint: '💪',
    Icons.card_giftcard.codePoint: '🎁',
    Icons.attach_money.codePoint: '💰',
    Icons.emoji_events.codePoint: '🏆',
    Icons.sports_esports.codePoint: '🎮',
    Icons.devices.codePoint: '💻',
    Icons.pets.codePoint: '🐾',
  };

  static String getEmojiForIcon(IconData icon) {
    return _iconToEmoji[icon.codePoint] ?? '📝';
  }

  static Color getColorForCategory(String categoryName) {
    final colorMap = {
      'Food': Colors.orange,
      'Travel': Colors.blue,
      'Shopping': Colors.pink,
      'Fun': Colors.purple,
      'Health': Colors.red,
      'Learn': Colors.yellow,
      'Bills': Colors.teal,
    };
    return colorMap[categoryName] ?? Colors.grey;
  }
}

