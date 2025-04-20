import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  int _activeStep = 0;
  String _paymentMethod = 'PayPal';
  bool _isLoading = false;
  
  final _shippingData = ShippingAddress(
    address: '',
    city: '',
    postalCode: '',
    country: '',
  );

  void _nextStep() {
    if (_activeStep == 0) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      _formKey.currentState!.save();
    }
    
    setState(() {
      _activeStep += 1;
    });
  }

  void _previousStep() {
    setState(() {
      _activeStep -= 1;
    });
  }

  Future<void> _placeOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final cartItems = cartProvider.items.values.toList();
      final totalAmount = cartProvider.totalAmount;
      final taxAmount = totalAmount * 0.1; // 10% tax
      final shippingAmount = totalAmount > 100 ? 0.0 : 10.0; // Free shipping over $100
      
      final order = await orderProvider.createOrder(
        cartItems: cartItems,
        shippingAddress: _shippingData,
        paymentMethod: _paymentMethod,
        itemsPrice: totalAmount,
        taxPrice: taxAmount,
        shippingPrice: shippingAmount,
        totalPrice: totalAmount + taxAmount + shippingAmount,
        token: authProvider.user!.token,
      );
      
      await cartProvider.clear();
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => OrderSuccessScreen(orderId: order.id),
        ),
      );
    } catch (error) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('An error occurred!'),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Okay'),
            ),
          ],
        ),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final totalAmount = cartProvider.totalAmount;
    final taxAmount = totalAmount * 0.1; // 10% tax
    final shippingAmount = totalAmount > 100 ? 0.0 : 10.0; // Free shipping over $100
    final finalAmount = totalAmount + taxAmount + shippingAmount;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.horizontal,
              currentStep: _activeStep,
              onStepContinue: _nextStep,
              onStepCancel: _activeStep > 0 ? _previousStep : null,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    children: [
                      if (_activeStep < 2)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: details.onStepContinue,
                            child: Text(_activeStep == 1 ? 'REVIEW ORDER' : 'NEXT'),
                          ),
                        ),
                      if (_activeStep == 2)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _placeOrder,
                            child: const Text('PLACE ORDER'),
                          ),
                        ),
                      if (_activeStep > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            child: const Text('BACK'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                // Step 1: Shipping Address
                Step(
                  title: const Text('Shipping'),
                  content: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Address'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your address';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _shippingData = ShippingAddress(
                              address: value!,
                              city: _shippingData.city,
                              postalCode: _shippingData.postalCode,
                              country: _shippingData.country,
                            );
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'City'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your city';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _shippingData = ShippingAddress(
                              address: _shippingData.address,
                              city: value!,
                              postalCode: _shippingData.postalCode,
                              country: _shippingData.country,
                            );
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Postal Code'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your postal code';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _shippingData = ShippingAddress(
                              address: _shippingData.address,
                              city: _shippingData.city,
                              postalCode: value!,
                              country: _shippingData.country,
                            );
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Country'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your country';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _shippingData = ShippingAddress(
                              address: _shippingData.address,
                              city: _shippingData.city,
                              postalCode: _shippingData.postalCode,
                              country: value!,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  isActive: _activeStep >= 0,
                  state: _activeStep > 0 ? StepState.complete : StepState.indexed,
                ),
                
                // Step 2: Payment Method
                Step(
                  title: const Text('Payment'),
                  content: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('PayPal'),
                        value: 'PayPal',
                        groupValue: _paymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _paymentMethod = value!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Credit Card'),
                        value: 'Credit Card',
                        groupValue: _paymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _paymentMethod = value!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Cash on Delivery'),
                        value: 'Cash on Delivery',
                        groupValue: _paymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _paymentMethod = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  isActive: _activeStep >= 1,
                  state: _activeStep > 1 ? StepState.complete : StepState.indexed,
                ),
                
                // Step 3: Order Summary
                Step(
                  title: const Text('Review'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartProvider.items.length,
                        itemBuilder: (ctx, i) {
                          final cartItem = cartProvider.items.values.toList()[i];
                          return ListTile(
                            leading: Image.network(
                              cartItem.image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            title: Text(cartItem.name),
                            subtitle: Text('${cartItem.quantity} x \$${cartItem.price.toStringAsFixed(2)}'),
                            trailing: Text('\$${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}'),
                          );
                        },
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text('\$${totalAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (10%)'),
                          Text('\$${taxAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Shipping'),
                          Text(shippingAmount > 0 
                              ? '\$${shippingAmount.toStringAsFixed(2)}'
                              : 'FREE'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '\$${finalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Shipping Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_shippingData.address),
                      Text('${_shippingData.city}, ${_shippingData.postalCode}'),
                      Text(_shippingData.country),
                      const SizedBox(height: 20),
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_paymentMethod),
                    ],
                  ),
                  isActive: _activeStep >= 2,
                  state: StepState.indexed,
                ),
              ],
            ),
    );
  }
}