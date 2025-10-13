import 'package:flutter/material.dart';
import 'package:Maya/core/network/api_client.dart';
import 'package:get_it/get_it.dart';

class GoogleSearchBar extends StatefulWidget {
  const GoogleSearchBar({super.key});

  @override
  State<GoogleSearchBar> createState() => _GoogleSearchBarState();
}

class _GoogleSearchBarState extends State<GoogleSearchBar> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  String? selectedMode = 'standard';
  bool isLoading = false;
  String? searchResult;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  String statusMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward(); // Ensure animation starts
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> performSearch() async {
    if (_controller.text.isEmpty) {
      setState(() {
        errorMessage = 'Please enter a query to begin the conversation';
        searchResult = null;
        statusMessage = '';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      searchResult = null;
      statusMessage = 'Initializing AI...';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => statusMessage = 'Thinking...');

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => statusMessage = 'Analyzing query...');

      final response = await getIt<ApiClient>().googleSearch(
        _controller.text,
        mode: selectedMode,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => statusMessage = 'Processing results...');

      if (response['statusCode'] == 200) {
        setState(() {
          searchResult = response['data']['message']?.toString() ?? 'No insights found';
          statusMessage = '';
        });
      } else {
        setState(() {
          errorMessage = response['data']['message']?.toString() ?? 'Unable to process query';
          statusMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        statusMessage = '';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Talk to AI',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).primaryColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: _glowAnimation.value / 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: 'Ask me anything...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(
                                  Icons.chat_bubble_outline,
                                  color: Theme.of(context).primaryColor,
                                  size: 24,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(fontSize: 16),
                              onSubmitted: (_) => performSearch(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: selectedMode,
                            items: const [
                              DropdownMenuItem(
                                value: 'standard',
                                child: Text('Standard Mode'),
                              ),
                              DropdownMenuItem(
                                value: 'deep',
                                child: Text('DeepSearch'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedMode = value;
                              });
                            },
                            underline: const SizedBox(),
                            icon: Icon(
                              Icons.tune,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : performSearch,
                        icon: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.send, size: 20),
                        label: const Text('Ask AI'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        if (isLoading && statusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Safety check
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    statusMessage,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (errorMessage != null)
          Card(
            color: Colors.red[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else if (searchResult != null)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Response',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    searchResult!,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}