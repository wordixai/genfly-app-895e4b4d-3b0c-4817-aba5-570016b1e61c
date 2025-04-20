import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  bool _isInit = true;
  bool _isLoading = false;
  int _quantity = 1;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });
      Provider.of<ProductProvider>(context)
          .fetchProductById(widget.productId)
          .then((_) {
        setState(() {
          _isLoading = false;
        });
      });
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final product = productProvider.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(product?.name ?? 'Product Details'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const CartScreen()),
                  );
                },
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : product == null
              ? const Center(child: Text('Product not found!'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            SizedBox(
                              height: 300,
                              width: double.infinity,
                              child: Image.network(
                                product.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Brand and Category
                                  Row(
                                    children: [
                                      Text(
                                        product.brand,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          product.category,
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Product Name
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Rating
                                  Row(
                                    children: [
                                      RatingBarIndicator(
                                        rating: product.rating,
                                        itemBuilder: (context, _) => const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                        itemCount: 5,
                                        itemSize: 20.0,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${product.rating.toStringAsFixed(1)} (${product.numReviews} reviews)',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Price
                                  Row(
                                    children: [
                                      Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        product.countInStock > 0
                                            ? 'In Stock'
                                            : 'Out of Stock',
                                        style: TextStyle(
                                          color: product.countInStock > 0
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Quantity Selector
                                  if (product.countInStock > 0)
                                    Row(
                                      children: [
                                        const Text(
                                          'Quantity:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                onPressed: _quantity > 1
                                                    ? () {
                                                        setState(() {
                                                          _quantity--;
                                                        });
                                                      }
                                                    : null,
                                                color: _quantity > 1
                                                    ? Theme.of(context).primaryColor
                                                    : Colors.grey,
                                              ),
                                              Text(
                                                '$_quantity',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: _quantity < product.countInStock
                                                    ? () {
                                                        setState(() {
                                                          _quantity++;
                                                        });
                                                      }
                                                    : null,
                                                color: _quantity < product.countInStock
                                                    ? Theme.of(context).primaryColor
                                                    : Colors.grey,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Add to Cart Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: product.countInStock > 0
                                          ? () {
                                              for (int i = 0; i < _quantity; i++) {
                                                cartProvider.addItem(product);
                                              }
                                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Added $_quantity ${_quantity > 1 ? 'items' : 'item'} to cart!'),
                                                  duration: const Duration(seconds: 2),
                                                  action: SnackBarAction(
                                                    label: 'VIEW CART',
                                                    onPressed: () {
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute(builder: (ctx) => const CartScreen()),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              );
                                            }
                                          : null,
                                      icon: const Icon(Icons.shopping_cart),
                                      label: Text(
                                        product.countInStock > 0
                                            ? 'ADD TO CART'
                                            : 'OUT OF STOCK',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 10),
                                  
                                  // Wishlist Button
                                  if (authProvider.isAuthenticated)
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          // Add to wishlist functionality
                                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Added to wishlist!'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.favorite_border),
                                        label: const Text('ADD TO WISHLIST'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Tabs for Description, Features, Reviews
                                  TabBar(
                                    controller: _tabController,
                                    labelColor: Theme.of(context).primaryColor,
                                    unselectedLabelColor: Colors.grey,
                                    indicatorColor: Theme.of(context).primaryColor,
                                    tabs: const [
                                      Tab(text: 'Description'),
                                      Tab(text: 'Features'),
                                      Tab(text: 'Reviews'),
                                    ],
                                  ),
                                  
                                  SizedBox(
                                    height: 300,
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: [
                                        // Description Tab
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                                          child: Text(
                                            product.description,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                        
                                        // Features Tab
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                                          child: product.features.isEmpty
                                              ? const Center(
                                                  child: Text('No features available'),
                                                )
                                              : ListView.builder(
                                                  shrinkWrap: true,
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  itemCount: product.features.length,
                                                  itemBuilder: (ctx, i) => Padding(
                                                    padding: const EdgeInsets.only(bottom: 8.0),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Icon(
                                                          Icons.check_circle,
                                                          color: Colors.green,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            product.features[i],
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              height: 1.5,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        
                                        // Reviews Tab
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                                          child: product.reviews.isEmpty
                                              ? const Center(
                                                  child: Text('No reviews yet'),
                                                )
                                              : ListView.builder(
                                                  shrinkWrap: true,
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  itemCount: product.reviews.length,
                                                  itemBuilder: (ctx, i) => Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            product.reviews[i].name,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${product.reviews[i].createdAt.day}/${product.reviews[i].createdAt.month}/${product.reviews[i].createdAt.year}',
                                                            style: const TextStyle(
                                                              color: Colors.grey,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      RatingBarIndicator(
                                                        rating: product.reviews[i].rating,
                                                        itemBuilder: (context, _) => const Icon(
                                                          Icons.star,
                                                          color: Colors.amber,
                                                        ),
                                                        itemCount: 5,
                                                        itemSize: 16.0,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        product.reviews[i].comment,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          height: 1.5,
                                                        ),
                                                      ),
                                                      const Divider(),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}