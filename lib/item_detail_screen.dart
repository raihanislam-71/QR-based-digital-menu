import 'package:digital_manu/menu_item_model.dart';
import 'package:flutter/material.dart';

import 'cart_manager.dart';

class ItemDetailScreen extends StatelessWidget {

  final Map<String, dynamic> itemData;
  const ItemDetailScreen({super.key, required this.itemData});
  @override
  Widget build(BuildContext context) {
    double mainPrice = double.tryParse(itemData['price'].toString()) ?? 0.0;
    double discountPercent = double.tryParse(itemData['discount']?.toString() ?? '0') ?? 0.0;
    double finalPrice = mainPrice - (mainPrice * (discountPercent / 100));
    bool hasDiscount = discountPercent > 0;
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              Image.network(
                itemData['imageUrl'],
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
              SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(onPressed: (){
                            Navigator.pop(context);
                          }, icon: Icon(Icons.arrow_back,color: Colors.black,),
                            iconSize: 20,
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(onPressed: (){
                            Navigator.pop(context);
                          }, icon: Icon(Icons.favorite,color: Colors.redAccent,),
                            iconSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
              if(hasDiscount)
                Positioned(
                  bottom: 20,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      )
                    ),
                    child: Text("$discountPercent% OFF",style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
                  )
                ),
            ],
          ),
          Expanded(child: Container(
            padding: EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              )
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(
                          itemData['name'],
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.orange,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star,size: 16,color: Colors.white,),
                          SizedBox(width: 4,),
                          Text(
                            "${itemData['rating'] ?? '4.5'}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 8,),
                Text(
                  itemData['category'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 24,),
                Text(
                  "Description",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12,),
                Text(
                  itemData['description'] ?? "No description available,",
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Price",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if(hasDiscount)
                          Text(
                            "Tk $mainPrice",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          "Tk ${hasDiscount ? finalPrice.toStringAsFixed(0) : mainPrice}",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        )
                      ],
                    ),
                    SizedBox(width: 24,),
                    Expanded(
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              // shape: RoundedRectangleBorder(
                              //   borderRadius: BorderRadius.circular(15),
                              // ),
                              padding: EdgeInsets.symmetric(vertical: 16,),
                            ),
                            onPressed: (){
                              double mainPrice = double.tryParse(itemData['price'].toString()) ?? 0.0;
                              double discountPercent = double.tryParse(itemData['discount']?.toString() ?? '0') ?? 0.0;
                              double discountPrice = mainPrice - (mainPrice * (discountPercent / 100));

                              ManuItem item = ManuItem(
                                itemData['name'],
                                itemData['imageUrl'],
                                itemData['description'],
                                itemData['category'],
                                discountPrice,
                                double.tryParse(itemData['rating'].toString()) ?? 4.5,
                              );
                              Cart.add(item);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Add To Cart!")),
                              );
                              Navigator.pop(context, true);
                            },
                            child: Text(
                              'Add To Cart',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                        ),
                    ),
                  ],
                )
              ],
            ),
          ))
        ],
      ),
    );
  }
}
