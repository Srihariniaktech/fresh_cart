import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _activeBanner = 0;

  final List<_CategoryItem> _categories = const [
    _CategoryItem('Vegetable', Icons.eco_rounded, Color(0xFFE8F6E6)),
    _CategoryItem('Fruits', Icons.apple_rounded, Color(0xFFFFF0DE)),
    _CategoryItem('Frozen', Icons.ac_unit_rounded, Color(0xFFE9F6FF)),
    _CategoryItem('Drinks', Icons.local_drink_rounded, Color(0xFFFFEAF0)),
  ];

  final List<_ProductItem> _products = const [
    _ProductItem('Vegetables', 'Iceberg Fresh lettuce', '\$4.99', Icons.bakery_dining_rounded, Color(0xFFF8F6EE)),
    _ProductItem('Vegetables', 'Fresh chicken', '\$7.99', Icons.set_meal_rounded, Color(0xFFFFF5ED)),
    _ProductItem('Fruits', 'Organic red apple', '\$3.49', Icons.apple_rounded, Color(0xFFFFF3EF)),
    _ProductItem('Drinks', 'Orange juice pack', '\$2.99', Icons.local_cafe_rounded, Color(0xFFFFF8E8)),
  ];

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.popUntil(context, (route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(onLogout: _logout),
              const SizedBox(height: 18),
              const _SearchBar(),
              const SizedBox(height: 18),
              _OfferBanner(
                controller: _bannerController,
                activeIndex: _activeBanner,
                onChanged: (index) {
                  setState(() {
                    _activeBanner = index;
                  });
                },
              ),
              const SizedBox(height: 22),
              const _SectionHeader(title: 'Categories', actionLabel: 'See All'),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _categories
                    .map((category) => _CategoryCard(item: category))
                    .toList(),
              ),
              const SizedBox(height: 26),
              const _SectionHeader(title: 'Flash Sales', actionLabel: 'See All'),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  return _ProductCard(item: _products[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Location',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF90958C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF33A852),
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'New York,USA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2A1F),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF74806F),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5DD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: onLogout,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF5F8E37),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EBE0)),
            ),
            child: Row(
              children: const [
                Icon(Icons.search_rounded, color: Color(0xFF90A287)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search vegetables,Fruits,etc',
                    style: TextStyle(
                      color: Color(0xFF9FA39A),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF2FB344),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _OfferBanner extends StatelessWidget {
  const _OfferBanner({
    required this.controller,
    required this.activeIndex,
    required this.onChanged,
  });

  final PageController controller;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 142,
          child: PageView(
            controller: controller,
            onPageChanged: onChanged,
            children: const [
              _BannerCard(
                background: Color(0xFFE9F4C9),
                title: 'Up to 20% Offer sale',
                subtitle: 'Enjoy your shopping with our black friday offer',
                buttonLabel: 'Shop Now',
                icon: Icons.shopping_basket_rounded,
              ),
              _BannerCard(
                background: Color(0xFFFFE7C8),
                title: 'Fresh fruits deal',
                subtitle: 'Pick sweet seasonal fruits with instant savings',
                buttonLabel: 'Explore',
                icon: Icons.local_grocery_store_rounded,
              ),
              _BannerCard(
                background: Color(0xFFE1F3FF),
                title: 'Daily essentials',
                subtitle: 'Stock your kitchen with fast home delivery',
                buttonLabel: 'Order Now',
                icon: Icons.delivery_dining_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: index == activeIndex ? 10 : 7,
              height: index == activeIndex ? 10 : 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == activeIndex
                    ? const Color(0xFF6B7F1A)
                    : const Color(0xFFE0E1D8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.background,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
  });

  final Color background;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF29331F),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF4B5647),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF28A33E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(buttonLabel),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, size: 54, color: const Color(0xFFF08B1F)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF202A20),
          ),
        ),
        const Spacer(),
        Text(
          actionLabel,
          style: const TextStyle(
            color: Color(0xFF809431),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.item});

  final _CategoryItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.background,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: const Color(0xFF62863A), size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7068),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item});

  final _ProductItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: item.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  size: 62,
                  color: const Color(0xFFC77F2A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.category,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9A9E94),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF253024),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                item.price,
                style: const TextStyle(
                  color: Color(0xFF2EA645),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF2EA645),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem(this.label, this.icon, this.background);

  final String label;
  final IconData icon;
  final Color background;
}

class _ProductItem {
  const _ProductItem(
    this.category,
    this.name,
    this.price,
    this.icon,
    this.background,
  );

  final String category;
  final String name;
  final String price;
  final IconData icon;
  final Color background;
}
