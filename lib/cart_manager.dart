import 'package:digital_manu/cart_item_model.dart';
import 'package:digital_manu/menu_item_model.dart';

class Cart{
  static final List<CartItem> items = [];

  static void add (ManuItem item){
    final existing = items.where((c) =>  c.item.name == item.name);

    if(existing.isNotEmpty){
      existing.first.quantity++;
    }
    else{
      items.add(CartItem(item, 1));
    }
  }

  static double get total => items.fold(0, (sum , c) => sum + (c.item.price * c.quantity));

}