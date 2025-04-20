import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> homeData = {};
  bool isLoading = true;
  String searchQuery = '';
  String selectedCategory = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchHomeData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchHomeData() async {
    final url = Uri.parse(
      "http://devapiv4.dealsdray.com/api/v2/user/home/withoutPrice",
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        homeData = data['data'];
        isLoading = false;
      });
    } else {
      throw Exception("Failed to load data");
    }
  }

  Widget buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Image.asset('assets/logo.png', height: 30),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: "Search here",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.notifications_none, color: Colors.black),
        ],
      ),
    );
  }

  Widget buildBanner(List<dynamic> banners) {
    return CarouselSlider(
      items:
          banners
              .map(
                (e) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    e['banner'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              )
              .toList(),
      options: CarouselOptions(
        height: 200,
        autoPlay: true,
        enlargeCenterPage: false,
        viewportFraction: 1.0,
      ),
    );
  }

  Widget buildKycBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7969FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "KYC Pending",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "You need to provide the required\ndocuments for your account activation.",
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("We will contact you"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              "Click Here",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCategory(List<dynamic> categories) {
    return SizedBox(
      height: 90,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          int itemCount = categories.length;
          double spacing = 4;
          double totalSpacing = spacing * (itemCount - 1);
          double itemWidth = (screenWidth - totalSpacing) / itemCount;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemBuilder: (_, i) {
              final item = categories[i];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selectedCategory == item['label']) {
                      selectedCategory = ''; // Toggle off if already selected
                    } else {
                      selectedCategory = item['label'];
                    }
                  });
                },
                child: Container(
                  width: itemWidth,
                  margin: EdgeInsets.only(
                    right: i == itemCount - 1 ? 0 : spacing,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            selectedCategory == item['label']
                                ? Colors.red.shade100
                                : Colors.grey[200],
                        radius: 25,
                        backgroundImage: NetworkImage(item['icon']),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selectedCategory == item['label']
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              selectedCategory == item['label']
                                  ? Colors.red
                                  : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<dynamic> filterProducts(List<dynamic> products) {
    if (searchQuery.isEmpty && selectedCategory.isEmpty) {
      return products;
    }

    return products.where((product) {
      bool matchesSearch =
          searchQuery.isEmpty ||
          product['label'].toString().toLowerCase().contains(searchQuery);
      bool matchesCategory =
          selectedCategory.isEmpty ||
          (product['category'] != null &&
              product['category'].toString().toLowerCase() ==
                  selectedCategory.toLowerCase());

      return matchesSearch && (selectedCategory.isEmpty || matchesCategory);
    }).toList();
  }

  Widget buildProductList(String title, List<dynamic> products) {
    final filteredProducts = filterProducts(products);

    if (filteredProducts.isEmpty &&
        (searchQuery.isNotEmpty || selectedCategory.isNotEmpty)) {
      return const SizedBox.shrink(); // Hide section if no products match filter
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child:
              filteredProducts.isEmpty
                  ? const Center(child: Text("No products found"))
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredProducts.length,
                    itemBuilder: (_, i) {
                      final item = filteredProducts[i];
                      return Container(
                        width: 150,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Image.network(
                                  item['icon'],
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                ),
                                if (item['offer'] != null)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Container(
                                      color: Colors.green,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      child: Text(
                                        item['offer']!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['label'],
                              maxLines: 2,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  void clearFilters() {
    setState(() {
      searchQuery = '';
      selectedCategory = '';
      searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const Icon(Icons.menu, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/redLogo.png',
                            height: 20,
                            width: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value.toLowerCase();
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: "Search here",
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (searchQuery.isNotEmpty ||
                            selectedCategory.isNotEmpty)
                          GestureDetector(
                            onTap: clearFilters,
                            child: const Icon(Icons.clear, color: Colors.grey),
                          )
                        else
                          const Icon(Icons.search, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.notifications_none, color: Colors.black),
              ],
            ),
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (searchQuery.isNotEmpty || selectedCategory.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            const Text(
                              "Active filters: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (searchQuery.isNotEmpty)
                              Chip(
                                label: Text("Search: $searchQuery"),
                                deleteIcon: const Icon(Icons.clear, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    searchQuery = '';
                                    searchController.clear();
                                  });
                                },
                              ),
                            const SizedBox(width: 5),
                            if (selectedCategory.isNotEmpty)
                              Chip(
                                label: Text("Category: $selectedCategory"),
                                deleteIcon: const Icon(Icons.clear, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    selectedCategory = '';
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    if (homeData['banner_one'] != null)
                      buildBanner(homeData['banner_one']),
                    buildKycBanner(),
                    if (homeData['category'] != null)
                      buildCategory(homeData['category']),
                    if (homeData['products'] != null)
                      buildProductList(
                        "EXCLUSIVE FOR YOU",
                        homeData['products'],
                      ),
                    if (homeData['new_arrivals'] != null)
                      buildProductList(
                        "New Arrivals",
                        homeData['new_arrivals'],
                      ),
                    if (homeData['categories_listing'] != null)
                      buildProductList(
                        "Categories",
                        homeData['categories_listing'],
                      ),
                    if (homeData['top_selling_products'] != null)
                      buildProductList(
                        "Top Selling",
                        homeData['top_selling_products'],
                      ),
                    if (homeData['featured_laptop'] != null)
                      buildProductList(
                        "Featured Laptops",
                        homeData['featured_laptop'],
                      ),
                    if (homeData['unboxed_deals'] != null)
                      buildProductList(
                        "Unboxed Deals",
                        homeData['unboxed_deals'],
                      ),
                    if (homeData['my_browsing_history'] != null)
                      buildProductList(
                        "My Browsing History",
                        homeData['my_browsing_history'],
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          const BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: "Categories",
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/dray.png', height: 44, width: 44),
            label: "Deals",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Cart",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.chat, color: Colors.white),
        label: const Text("Chat", style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
