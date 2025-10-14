import 'package:flutter/material.dart';

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardingPagePresenter(  
        pages: [
          OnboardingPageModel(
            title: 'Find Your Route Easily',
            description:
                'Just enter your current and destination locations to see the right jeepney codes instantly.',
            image: const Image(image: AssetImage('assets/tutorial_icons/route.png')),
            bgColor: const Color.fromARGB(255, 240, 93, 82),
          ),
          OnboardingPageModel(
            title: 'Navigate with Ease',
            description: 'Get reliable jeepney codes wherever you are in the city.',
            image: const Image(image: AssetImage('assets/tutorial_icons/route.png')),
            // imageUrl: 'https://i.ibb.co/LvmZypG/storefront-illustration-2.png',
            bgColor: const Color.fromARGB(255, 240, 93, 82),
          ),
          OnboardingPageModel(
            title: 'Save Time',
            description:
                'Plan your commute smartly and avoid taking the wrong route.',
            image: const Image(image: AssetImage('assets/tutorial_icons/route.png')),
            // imageUrl: 'https://i.ibb.co/420D7VP/building.png',
            bgColor: const Color.fromARGB(255, 240, 93, 82),
          ),
          OnboardingPageModel(
            title: 'Discover Local Routes',
            description: 'Explore and learn the jeepney codes that connect Cebu and Mandaue City.',
            image: const Image(image: AssetImage('assets/tutorial_icons/route.png')),
            // imageUrl: 'https://i.ibb.co/cJqsPSB/scooter.png',
            bgColor: const Color.fromARGB(255, 240, 93, 82),
          ),
        ],
        onSkip: (){
          Navigator.pushNamed(context, '/homepage');
        },
        onFinish: (){
          Navigator.pushNamed(context, '/homepage');
        },
      ),
    );
  }
}

class OnboardingPagePresenter extends StatefulWidget {
  final List<OnboardingPageModel> pages;
  final VoidCallback? onSkip;
  final VoidCallback? onFinish;

  const OnboardingPagePresenter({
    super.key,
    required this.pages,
    this.onSkip,
    this.onFinish,
  });

  @override
  State<OnboardingPagePresenter> createState() => _OnboardingPageState(); //state -> how it shud behave/change
}

class _OnboardingPageState extends State<OnboardingPagePresenter> {
  // Store the currently visible page
  int _currentPage = 0;
  // Define a controller for the pageview
  final PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: widget.pages[_currentPage].bgColor,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                // Pageview to render each page
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.pages.length,
                  onPageChanged: (idx) {
                    // Change current page when pageview changes
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemBuilder: (context, idx) {
                    final item = widget.pages[idx];
                    return Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: item.image,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  item.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: item.textColor,
                                      ),
                                ),
                              ),
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 280,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  item.description,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: item.textColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Current page indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.pages
                    .map(
                      (item) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: _currentPage == widget.pages.indexOf(item)
                            ? 30
                            : 8,
                        height: 8,
                        margin: const EdgeInsets.all(2.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    )
                    .toList(),
              ),

              // Bottom buttons
              SizedBox(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.comfortable,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        widget.onSkip?.call();
                      },
                      child: const Text("Skip"),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.comfortable,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        if (_currentPage == widget.pages.length - 1) {
                          widget.onFinish?.call();
                        } else {
                          _pageController.animateToPage(
                            _currentPage + 1,
                            curve: Curves.easeInOutCubic,
                            duration: const Duration(milliseconds: 250),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            _currentPage == widget.pages.length - 1
                                ? "Finish"
                                : "Next",
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == widget.pages.length - 1
                                ? Icons.done
                                : Icons.arrow_forward,
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
    );
  }
}

class OnboardingPageModel {
  final String title;
  final String description;
  final Image image;
  final Color bgColor;
  final Color textColor;

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.image,
    this.bgColor = Colors.blue,
    this.textColor = Colors.white,
  });
}
