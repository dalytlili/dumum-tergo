import 'package:flutter/material.dart';
import 'package:dumum_tergo/views/welcome_screen.dart';
import 'package:dumum_tergo/constants/colors.dart';

class OnboardingScreens extends StatefulWidget {
  const OnboardingScreens({super.key});

  @override
  _OnboardingScreensState createState() => _OnboardingScreensState();
}

class _OnboardingScreensState extends State<OnboardingScreens> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Découvrez le Camping en Tunisie',
      description:
          'En Tunisie, la culture du Camping-cars est quasiment inexistante par rapport à d\'autres pays occidentaux où ce mode de voyage est plus courant..',
      imagePath: 'assets/images/image1.png',
    ),
    OnboardingPageData(
      title: 'Dumum Tergo : Une Nouvelle Perspective',
      description:
          'D\'ou l\'importance de Dumum Tergo !\nNous vous offrons des expériences immersives combinant exploration des paysages et découvertes culturelles.',
      imagePath: 'assets/images/image1.png',
    ),
    OnboardingPageData(
      title: 'Voyagez Autrement',
      description:
          'Dumum Tergo vous invite à repenser votre façon de voyager.\nDécouvrez la liberté et l\'authenticité du voyage en camping-car.',
      imagePath: 'assets/images/image3.png',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
        appBar: AppBar(
    //backgroundColor: Colors.transparent,
    elevation: 0,
    toolbarHeight: 0, // Cache l'AppBar mais garde la barre de statut
  ),
      body: Stack(
        children: [
          // Page View with smooth swipe
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: _OnboardingPage(
                  data: _pages[index],
                  onNextPressed: _nextPage,
                  onBackPressed: _previousPage,
                  isLastPage: index == _pages.length - 1,
                  isFirstPage: index == 0,
                ),
              );
            },
          ),

          // Custom Page Indicator
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? AppColors.primary 
                        : AppColors.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          // Skip Button (only show if not last page)
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  );
                },
                child: Text(
                  'Passer',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final String imagePath;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  final VoidCallback onNextPressed;
  final VoidCallback onBackPressed;
  final bool isLastPage;
  final bool isFirstPage;

  const _OnboardingPage({
    required this.data,
    required this.onNextPressed,
    required this.onBackPressed,
    required this.isLastPage,
    required this.isFirstPage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Back Button with animation
          if (!isFirstPage)
            AnimatedOpacity(
              opacity: isFirstPage ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.topLeft,
              
              ),
            ),

          // Image with fade animation
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Hero(
                tag: 'onboarding-image-${data.imagePath}',
                child: Image.asset(
                  data.imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Content with slide animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Column(
              key: ValueKey(data.title),
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  data.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Next Button with scale animation
          AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: onNextPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
                shadowColor: AppColors.primary.withOpacity(0.3),
              ),
              child: Text(
                isLastPage ? 'Commencer l\'aventure' : 'Continuer',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}