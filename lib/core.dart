import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get supabase => Supabase.instance.client;

String todayStr() => DateTime.now().toIso8601String().substring(0, 10);

/// Bump to make admin tabs reload their data.
final refreshTick = ValueNotifier<int>(0);
void refresh() => refreshTick.value++;

String getDishImagePath(String itemName) {
  final name = itemName.toLowerCase();
  if (name.contains('vaghareli')) return 'assets/images/dishes/vaghareli_idli.png';
  if (name.contains('mendu') || name.contains('medu')) return 'assets/images/dishes/mendu_vada.png';
  if (name.contains('idli')) return 'assets/images/dishes/idli.png';
  if (name.contains('thepla')) return 'assets/images/dishes/thepla.png';
  if (name.contains('handvo') || name.contains('handva')) return 'assets/images/dishes/handvo.png';
  if (name.contains('poha')) return 'assets/images/dishes/poha.png';
  if (name.contains('dhokla') || name.contains('khaman')) return 'assets/images/dishes/dhokla.png';
  if (name.contains('dal vada') || name.contains('dalvada') || name.contains('vada')) return 'assets/images/dishes/dal_vada.png';
  if (name.contains('paratha')) return 'assets/images/dishes/paratha.png';
  return 'assets/images/dishes/thepla.png';
}

String getDishDescription(String itemName) {
  final name = itemName.toLowerCase();
  if (name.contains('vaghareli')) {
    return 'Tempered idli cubes sauteed with mustard seeds, curry leaves and fresh coriander.';
  }
  if (name.contains('mendu') || name.contains('medu')) {
    return 'Crispy golden medu vada served with warm sambhar and fresh coconut chutney.';
  }
  if (name.contains('idli')) {
    return 'Soft and healthy idli served with spicy sambar and chutney.';
  }
  if (name.contains('thepla')) {
    return 'Tasty methi thepla served with green chutney.';
  }
  if (name.contains('handvo') || name.contains('handva')) {
    return 'Savory tava handvo baked with mixed lentils and vegetables, served with green chutney.';
  }
  if (name.contains('poha')) {
    return 'Steamed flattened rice bowl garnished with crunchy peanuts, onions and lemon.';
  }
  if (name.contains('dhokla') || name.contains('khaman')) {
    return 'Soft, fluffy steamed dhokla tempered with mustard seeds and green chilies.';
  }
  if (name.contains('dal vada') || name.contains('dalvada')) {
    return 'Crispy crunchy dal vada fried fresh to golden perfection with spicy chutney.';
  }
  if (name.contains('paratha')) {
    return 'Crispy layered paratha roasted in pure butter, served with curd or pickle.';
  }
  return 'Fresh and delicious home-cooked breakfast prepared with premium ingredients.';
}
