import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> with TickerProviderStateMixin {
  List<NewsArticle> articles = [];
  bool isLoading = true;
  String selectedCategory = 'nepal';
  late TabController _tabController;
  String? nextPage;
  bool isRefresh = false;

  // Your API key
  static const String API_KEY = 'pub_d3ffe5fa45b5428499d5ec36903ad81f';

  final List<CategoryItem> categories = [
    CategoryItem(key: 'nepal', label: 'Nepal News', icon: Icons.flag, query: 'Nepal'),
    CategoryItem(key: 'politics', label: 'Politics', icon: Icons.account_balance, query: 'Nepal politics'),
    CategoryItem(key: 'business', label: 'Business', icon: Icons.business, query: 'Nepal business'),
    CategoryItem(key: 'technology', label: 'Technology', icon: Icons.computer, query: 'Nepal technology'),
    CategoryItem(key: 'sports', label: 'Sports', icon: Icons.sports_soccer, query: 'Nepal sports'),
    CategoryItem(key: 'entertainment', label: 'Entertainment', icon: Icons.movie, query: 'Nepal entertainment'),
    CategoryItem(key: 'health', label: 'Health', icon: Icons.health_and_safety, query: 'Nepal health'),
    CategoryItem(key: 'education', label: 'Education', icon: Icons.school, query: 'Nepal education'),
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _initializeAnimations();
    _fetchNews();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        isLoading = true;
        articles.clear();
        nextPage = null;
      });
    } else {
      setState(() => isLoading = true);
    }

    try {
      await _fetchFromNewsDataIO();
      _fadeController.forward();
    } catch (e) {
      print('Error fetching news: $e');
      _showErrorSnackBar('Unable to fetch latest news. Showing offline content.');
      // Load mock data as fallback
      await _loadMockData();
      _fadeController.forward();
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchFromNewsDataIO() async {
    try {
      // Use the /latest endpoint with minimal parameters
      String url = 'https://newsdata.io/api/1/latest?apikey=$API_KEY';

      // Get the current category
      final currentCategory = categories.firstWhere(
            (cat) => cat.key == selectedCategory,
        orElse: () => categories.first,
      );

      // Add simplified query parameter
      url += '&q=${Uri.encodeComponent(currentCategory.query)}';

      // Add language parameter
      url += '&language=en';

      // Remove size parameter to avoid 422 error on free tier
      // If you have a paid plan, you can uncomment and adjust:
      // url += '&size=10';

      // Add next page token if available
      if (nextPage != null) {
        url += '&page=$nextPage';
      }

      print('Fetching from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'FixTheCity/1.0',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response status: ${data['status']}');

        if (data['status'] == 'success') {
          final List<dynamic> newsData = data['results'] ?? [];
          nextPage = data['nextPage'];

          print('Found ${newsData.length} articles');

          if (newsData.isEmpty) {
            print('No articles found, loading mock data');
            await _loadMockData();
            return;
          }

          final newArticles = newsData.map((article) {
            return NewsArticle(
              title: article['title'] ?? 'No Title',
              summary: article['description'] ?? article['content'] ?? 'No description available',
              imageUrl: article['image_url'] ?? '',
              sourceUrl: article['link'] ?? '',
              source: article['source_id'] ?? 'Unknown Source',
              publishedAt: DateTime.tryParse(article['pubDate'] ?? '') ?? DateTime.now(),
              category: selectedCategory,
              creator: (article['creator'] is List && (article['creator'] as List).isNotEmpty)
                  ? article['creator'][0]
                  : null,
              keywords: article['keywords'] is List
                  ? List<String>.from(article['keywords'])
                  : [],
              country: article['country']?.isNotEmpty == true ? article['country'].first : null,
            );
          }).toList();

          setState(() {
            if (isRefresh || nextPage == null) {
              articles = newArticles;
            } else {
              articles.addAll(newArticles);
            }
          });
        } else {
          throw Exception(data['message'] ?? 'API Error');
        }
      } else if (response.statusCode == 422) {
        final errorData = json.decode(response.body);
        print('API Error Response: ${response.body}');

        // Handle specific error cases - try with even simpler parameters
        if (errorData['results']?['code'] == 'UnsupportedFilter') {
          print('Unsupported filter detected, trying basic request');
          await _fetchWithBasicParameters();
        } else {
          throw Exception('API Error: ${errorData['results']?['message'] ?? 'Invalid request parameters'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in _fetchFromNewsDataIO: $e');
      rethrow;
    }
  }

  // Fallback method with minimal parameters
  Future<void> _fetchWithBasicParameters() async {
    try {
      // Use only essential parameters
      String url = 'https://newsdata.io/api/1/latest?apikey=$API_KEY';

      // Add only basic query based on category
      String simpleQuery = selectedCategory == 'nepal' ? 'Nepal' : 'Nepal ${selectedCategory}';
      url += '&q=${Uri.encodeComponent(simpleQuery)}';

      print('Fetching with basic parameters: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'FixTheCity/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final List<dynamic> newsData = data['results'] ?? [];

          if (newsData.isEmpty) {
            await _loadMockData();
            return;
          }

          final newArticles = newsData.map((article) {
            return NewsArticle(
              title: article['title'] ?? 'No Title',
              summary: article['description'] ?? article['content'] ?? 'No description available',
              imageUrl: article['image_url'] ?? '',
              sourceUrl: article['link'] ?? '',
              source: article['source_id'] ?? 'Unknown Source',
              publishedAt: DateTime.tryParse(article['pubDate'] ?? '') ?? DateTime.now(),
              category: selectedCategory,
              creator: (article['creator'] is List && (article['creator'] as List).isNotEmpty)
                  ? article['creator'][0]
                  : null,
              keywords: article['keywords'] is List
                  ? List<String>.from(article['keywords'])
                  : [],
              country: article['country']?.isNotEmpty == true ? article['country'].first : null,
            );
          }).toList();

          setState(() {
            articles = newArticles;
          });
        } else {
          throw Exception(data['message'] ?? 'API Error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in _fetchWithBasicParameters: $e');
      // Ultimate fallback to mock data
      await _loadMockData();
    }
  }

  Future<void> _loadMockData() async {
    print('Loading mock Nepal news data');

    final mockArticles = [
      NewsArticle(
        title: 'काठमाडौं उपत्यकामा नयाँ मेट्रो रेल परियोजना',
        summary: 'काठमाडौं उपत्यकामा यातायात समस्या समाधानका लागि मेट्रो रेल परियोजना सुरु गर्ने तयारी भएको छ। यो परियोजनाले उपत्यकाका मुख्य क्षेत्रहरूलाई जोड्नेछ।',
        imageUrl: 'https://picsum.photos/400/200?random=1',
        sourceUrl: 'https://example.com/metro-rail-project',
        source: 'Kantipur Daily',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        category: 'infrastructure',
        creator: 'Rajesh Sharma',
        keywords: ['metro rail', 'transportation', 'kathmandu'],
      ),
      NewsArticle(
        title: 'Nepal\'s GDP Growth Rate Shows Improvement',
        summary: 'Nepal\'s economy has shown signs of recovery with a projected GDP growth of 4.5% this fiscal year, driven by increased tourism and agricultural productivity.',
        imageUrl: 'https://picsum.photos/400/200?random=2',
        sourceUrl: 'https://example.com/gdp-growth',
        source: 'The Himalayan Times',
        publishedAt: DateTime.now().subtract(const Duration(hours: 4)),
        category: 'business',
        creator: 'Economic Correspondent',
        keywords: ['GDP', 'economy', 'growth'],
      ),
      NewsArticle(
        title: 'नेपाली राष्ट्रिय फुटबल टिमको प्रशिक्षण सुरु',
        summary: 'आगामी अन्तर्राष्ट्रिय प्रतियोगिताका लागि नेपाली राष्ट्रिय फुटबल टिमले गहन प्रशिक्षण सुरु गरेको छ। नयाँ प्रशिक्षकको नेतृत्वमा टिम तयार भइरहेको छ।',
        imageUrl: 'https://picsum.photos/400/200?random=3',
        sourceUrl: 'https://example.com/football-training',
        source: 'Online Khabar',
        publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
        category: 'sports',
        creator: 'Sports Reporter',
        keywords: ['football', 'national team', 'training'],
      ),
      NewsArticle(
        title: 'Digital Nepal Initiative Launches New Tech Hub',
        summary: 'The Digital Nepal initiative has launched a new technology hub in Kathmandu to promote innovation and startup culture among young entrepreneurs.',
        imageUrl: 'https://picsum.photos/400/200?random=4',
        sourceUrl: 'https://example.com/tech-hub',
        source: 'Tech Khabar',
        publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
        category: 'technology',
        creator: 'Tech Reporter',
        keywords: ['technology', 'startups', 'innovation'],
      ),
      NewsArticle(
        title: 'नेपालमा पर्यटन क्षेत्रको पुनरुत्थान',
        summary: 'कोभिड-१९ पछि नेपालको पर्यटन क्षेत्रमा सुधार देखिएको छ। विदेशी पर्यटकको संख्या बढ्दै गइरहेको पर्यटन बोर्डले जनाएको छ।',
        imageUrl: 'https://picsum.photos/400/200?random=5',
        sourceUrl: 'https://example.com/tourism-recovery',
        source: 'Himalayan News',
        publishedAt: DateTime.now().subtract(const Duration(hours: 10)),
        category: 'tourism',
        creator: 'Tourism Correspondent',
        keywords: ['tourism', 'recovery', 'visitors'],
      ),
      NewsArticle(
        title: 'Nepal Implements New Education Policy',
        summary: 'The government has implemented a new education policy focusing on digital literacy and practical skills development in schools and colleges.',
        imageUrl: 'https://picsum.photos/400/200?random=6',
        sourceUrl: 'https://example.com/education-policy',
        source: 'Education Today',
        publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
        category: 'education',
        creator: 'Education Reporter',
        keywords: ['education', 'policy', 'digital literacy'],
      ),
      NewsArticle(
        title: 'हिमालमा जलवायु परिवर्तनको प्रभाव',
        summary: 'जलवायु परिवर्तनका कारण हिमालका हिमनदीहरू तीव्र गतिमा पग्लिरहेका छन्। यसले नेपालका नदी प्रणालीमा दीर्घकालीन प्रभाव पार्न सक्छ।',
        imageUrl: 'https://picsum.photos/400/200?random=7',
        sourceUrl: 'https://example.com/climate-change',
        source: 'Environment Nepal',
        publishedAt: DateTime.now().subtract(const Duration(hours: 14)),
        category: 'environment',
        creator: 'Environment Reporter',
        keywords: ['climate change', 'himalayas', 'glaciers'],
      ),
      NewsArticle(
        title: 'Nepal\'s Renewable Energy Capacity Increases',
        summary: 'Nepal has significantly increased its renewable energy capacity with new hydroelectric and solar projects coming online this year.',
        imageUrl: 'https://picsum.photos/400/200?random=8',
        sourceUrl: 'https://example.com/renewable-energy',
        source: 'Energy Today',
        publishedAt: DateTime.now().subtract(const Duration(hours: 16)),
        category: 'energy',
        creator: 'Energy Correspondent',
        keywords: ['renewable energy', 'hydroelectric', 'solar'],
      ),
    ];

    setState(() {
      articles = mockArticles;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openArticle(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Cannot open article');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening article: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child: isLoading && articles.isEmpty
                ? _buildLoadingIndicator()
                : _buildNewsList(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.newspaper, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nepal News',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Latest Updates',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.deepPurple,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () => _fetchNews(isRefresh: true),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.deepPurple,
        labelColor: Colors.deepPurple,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        onTap: (index) {
          setState(() {
            selectedCategory = categories[index].key;
            articles.clear();
            nextPage = null;
          });
          _fetchNews(isRefresh: true);
        },
        tabs: categories.map((category) {
          return Tab(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(category.icon, size: 16),
                  const SizedBox(width: 6),
                  Text(category.label),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading latest Nepal news...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList() {
    if (articles.isEmpty && !isLoading) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: () => _fetchNews(isRefresh: true),
        color: Colors.deepPurple,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            return _buildNewsCard(articles[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.newspaper_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No News Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull to refresh or try a different category',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openArticle(article.sourceUrl),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNewsImage(article),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNewsHeader(article),
                    const SizedBox(height: 12),
                    _buildNewsTitle(article),
                    const SizedBox(height: 8),
                    _buildNewsSummary(article),
                    if (article.keywords.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildKeywords(article),
                    ],
                    const SizedBox(height: 12),
                    _buildNewsFooter(article),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsImage(NewsArticle article) {
    if (article.imageUrl.isEmpty) {
      return _buildPlaceholderImage();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: CachedNetworkImage(
        imageUrl: article.imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.withOpacity(0.1),
            Colors.deepPurple.withOpacity(0.3),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.newspaper,
              size: 50,
              color: Colors.deepPurple.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'News Article',
              style: TextStyle(
                color: Colors.deepPurple.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsHeader(NewsArticle article) {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              article.category.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (article.country != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                article.country!.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            article.source,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNewsTitle(NewsArticle article) {
    return Text(
      article.title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildNewsSummary(NewsArticle article) {
    return Text(
      article.summary,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildKeywords(NewsArticle article) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: article.keywords.take(3).map((keyword) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            keyword,
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNewsFooter(NewsArticle article) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 4),
        Text(
          _getTimeAgo(article.publishedAt),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        if (article.creator != null) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.person,
            size: 14,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              article.creator!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const SizedBox(width: 4),
        Icon(
          Icons.arrow_forward,
          size: 16,
          color: Colors.deepPurple,
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class NewsArticle {
  final String title;
  final String summary;
  final String imageUrl;
  final String sourceUrl;
  final String source;
  final DateTime publishedAt;
  final String category;
  final String? creator;
  final List<String> keywords;
  final String? country;

  NewsArticle({
    required this.title,
    required this.summary,
    required this.imageUrl,
    required this.sourceUrl,
    required this.source,
    required this.publishedAt,
    required this.category,
    this.creator,
    this.keywords = const [],
    this.country,
  });
}

class CategoryItem {
  final String key;
  final String label;
  final IconData icon;
  final String query;

  CategoryItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.query,
  });
}