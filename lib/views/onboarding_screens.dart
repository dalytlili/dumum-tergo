import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  double _currentScrollValue = 0.0;
  SystemUiOverlayStyle _systemUiOverlayStyle = SystemUiOverlayStyle.light;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentScrollValue = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUIOverlayStyle();
  }

  void _updateSystemUIOverlayStyle() {
    final brightness = Theme.of(context).brightness;
    final newStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness == Brightness.dark 
          ? Brightness.light 
          : Brightness.dark,
      systemNavigationBarColor: brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      systemNavigationBarIconBrightness: brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    );
    
    if (_systemUiOverlayStyle != newStyle) {
      setState(() {
        _systemUiOverlayStyle = newStyle;
      });
      SystemChrome.setSystemUIOverlayStyle(newStyle);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Découvrez le Camping en Tunisie',
      description: 'En Tunisie, la culture du Camping-cars est quasiment inexistante par rapport à d\'autres pays occidentaux où ce mode de voyage est plus courant.',
      imagePath: 'assets/images/image1.png',
      bgColor: const Color(0xFFF5F5F5),
      textColor: Colors.black87,
    ),
    OnboardingPageData(
      title: 'Dumum Tergo : Une Nouvelle Perspective',
      description: 'D\'ou l\'importance de Dumum Tergo !\nNous vous offrons des expériences immersives combinant exploration des paysages et découvertes culturelles.',
      imagePath: 'assets/images/image2.png',
      bgColor: const Color(0xFFEDF7FF),
      textColor: Colors.black87,
    ),
    OnboardingPageData(
      title: 'Voyagez Autrement',
      description: 'Dumum Tergo vous invite à repenser votre façon de voyager.\nDécouvrez la liberté et l\'authenticité du voyage en camping-car.',
      imagePath: 'assets/images/image3.png',
      bgColor: const Color(0xFFFFF8E1),
      textColor: Colors.black87,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutQuint,
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
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutQuint,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUiOverlayStyle,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor:isDarkMode ? Colors.transparent : Colors.white,
          elevation: 0,
          toolbarHeight: 60,
          leading: _currentPage > 0 
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios, 
                      color: isDarkMode ? Colors.white : Colors.black),
                  onPressed: _previousPage,
                )
              : const SizedBox(),
          actions: [
            if (_currentPage < _pages.length - 1)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  );
                },
                child: Text(
                  'Passer',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          color: isDarkMode ? Colors.black : _pages[_currentPage].bgColor,
          child: Stack(
            children: [
              // Background elements with parallax effect
              ..._buildParallaxBackground(isDarkMode),

              // Page View
              PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  final delta = index - _currentScrollValue;
                  final parallaxOffset = delta * 100;

                  return _OnboardingPage(
                    data: page,
                    parallaxOffset: parallaxOffset,
                    isLastPage: index == _pages.length - 1,
                    isDarkMode: isDarkMode,
                  );
                },
              ),

              // Animated Dots Indicator
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: _buildAnimatedDots(isDarkMode),
              ),

              // Next Button
              Positioned(
                bottom: 10,
                left: 24,
                right: 24,
                child: _buildAnimatedButton(isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildParallaxBackground(bool isDarkMode) {
    return List.generate(5, (index) {
      final double offset = _currentScrollValue * (index + 1) * 0.5;
      return Positioned(
        top: 100 + offset * 20,
        left: -50 + offset * 10,
        child: Opacity(
          opacity: 0.1,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDarkMode ? Colors.white : AppColors.primary).withOpacity(0.3),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAnimatedDots(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final double scale = 1.0 - (0.2 * (_currentScrollValue - index).abs().clamp(0.0, 1.0));
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 8 * scale,
          height: 8 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? isDarkMode ? Colors.white : AppColors.primary
                : (isDarkMode ? Colors.grey : AppColors.primary.withOpacity(0.3)),
          ),
        );
      }),
    );
  }

  Widget _buildAnimatedButton(bool isDarkMode) {
    final isLastPage = _currentPage == _pages.length - 1;
    final buttonText = isLastPage ? 'Commencer' : 'Continuer';

    return AnimatedScale(
      scale: 1.0 - (0.1 * (_currentScrollValue - _currentPage).abs().clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? Colors.white : AppColors.primary,
          foregroundColor: isDarkMode ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          shadowColor: (isDarkMode ? Colors.white : AppColors.primary).withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              buttonText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isLastPage) 
              const SizedBox(width: 2),
            if (!isLastPage)
              const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final String imagePath;
  final Color bgColor;
  final Color textColor;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.bgColor,
    required this.textColor,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  final double parallaxOffset;
  final bool isLastPage;
  final bool isDarkMode;

  const _OnboardingPage({
    required this.data,
    required this.parallaxOffset,
    required this.isLastPage,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : data.textColor;
    final descriptionColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, parallaxOffset * 0.5),
            child: Hero(
              tag: 'onboarding-image-${data.imagePath}',
              child: Image.asset(
                data.imagePath,
                height: MediaQuery.of(context).size.height * 0.4,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Transform.translate(
            offset: Offset(parallaxOffset * 0.3, 0),
            child: Text(
              data.title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),

          Transform.translate(
            offset: Offset(parallaxOffset * 0.2, 0),
            child: Text(
              data.description,
              style: TextStyle(
                fontSize: 16,
                color: descriptionColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}