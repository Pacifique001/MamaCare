class AssetsHelper {
  const AssetsHelper._();

  // Onboarding Images
  static const String onboardingImage1 = 'assets/svg/onboarding/screen1.svg';
  static const String onboardingImage2 = 'assets/svg/onboarding/screen2.svg';
  static const String onboardingImage3 = 'assets/svg/onboarding/screen3.svg';
  static const String onboardingImage4 = 'assets/svg/onboarding/screen4.svg';

  // Exercise Images - Trimester 1
  static const String walking = 'assets/images/exercise/walking.jpg';
  static const String swimming = 'assets/images/exercise/swimming.jpg';
  static const String yoga = 'assets/images/exercise/yoga.jpg';
  static const String strengthTraining =
      'assets/images/exercise/strength-training.jpg';
  static const String stretching = 'assets/images/exercise/stretching.jpg';
  static const String kegels = 'assets/images/exercise/kegels.jpg';

  // Exercise Images - Trimester 2
  static const String prenatalPilates =
      'assets/images/exercise/prenatal-pilates.jpg';
  static const String lowImpactAerobics =
      'assets/images/exercise/low-impact-aerobics.jpg';
  static const String stationaryCycling =
      'assets/images/exercise/stationary-cycling.jpg';
  static const String dancing = 'assets/images/exercise/dancing.jpg';
  static const String squats = 'assets/images/exercise/squats.jpg';
  static const String prenatalYoga = 'assets/images/exercise/prenatal-yoga.jpg';

  // Exercise Images - Trimester 3
  static const String modifiedPlanks =
      'assets/images/exercise/modified-planks.jpg';
  static const String wallPushUps = 'assets/images/exercise/wall-push-ups.jpg';
  static const String pelvicTilts = 'assets/images/exercise/pelvic-tilts.jpg';

  // Article Images
  static const String pregnantWoman =
      'assets/images/article/pregnant-woman.jpg';
  static const String prenatalYogaArticle =
      'assets/images/article/prenatal-yoga.jpg';
  static const String mentalHealthPregnancy =
      'assets/images/article/mental-health-pregnancy.png';
  static const String fourthTrimester =
      'assets/images/article/fourth-trimester.jpg';
  static const String preparingForLaborDelivery =
      'assets/images/article/preparing-for-labor-delivery.jpg';

  // Dashboard Images
  static const String maternalImage = 'assets/svg/dashboard/Maternal.svg';
  static const String timelineIndicator = 'assets/svg/timeline/timeline.svg';
  static const String seedSvg = 'assets/svg/suggested_food/seeds.svg';

  // Pregnancy Detail Images
  static const String babyWeight =
      'assets/images/pregnancy detail/pediatrics.png';
  static const String babyHeight = 'assets/images/pregnancy detail/height.png';
  static const String babyCalendar =
      'assets/images/pregnancy detail/calendar.png';

  // API URLs
  static const String place_api_base_url =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?';
  static const String placePhotoApiBaseUrl =
      'https://maps.googleapis.com/maps/api/place/photo?';
  static const String risk_detector_api_base_url =
      'https://your-api-url.com/risk-detector?';
  static const String placeApiKey = 'AIzaSyBf1L_eG08w2nOqRDgHmmbOsONvQJCmIQc';

  // Article Data
  static final List<Map<String, dynamic>> articleData = [
    {
      'id': 'ARTICLE_001', // Unique ID for each article
      'title': 'Maintaining a Healthy Pregnancy',
      'content': // Renamed from 'detail'
          'Nutrition Tips and Strategies for Expectant Mothers - This article provides an in-depth look at the importance of maintaining a healthy diet during pregnancy. It covers nutrients like folic acid and iron, managing pregnancy discomforts like morning sickness, and incorporating healthy foods. Includes recipes and meal plans designed specifically for pregnant women.',
      // Removed 'image' key, using 'imageUrl'
      'author': 'Dr. Evelyn Reed', // Added Author
      'imageUrl':
          'https://media.istockphoto.com/id/1003178120/photo/pregnant-woman-fitness-exercise.jpg?s=2048x2048&w=is&k=20&c=C1xb_lSXFNXrE6V53v6sz2Fxy4Y8bN0DU32XodZvLFU=', // Placeholder URL
      'publishDate':
          DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(), // Added Date
      'isBookmarked': false, // Added default bookmark
      'tags': ['Nutrition', 'Health', 'First Trimester', 'Diet'], // Added Tags
    },
    {
      'id': 'ARTICLE_002',
      'title': 'Prenatal Yoga: Gentle & Safe',
      'content':
          'An introduction to the benefits of practicing prenatal yoga. Covers physical and emotional benefits, modifications for a growing belly, and precautions. Includes a sequence of poses to help relieve common discomforts like back pain and improve well-being.',
      'author': 'MamaCare Wellness Team',
      'imageUrl':
          'https://media.istockphoto.com/id/686720486/photo/pregnant-woman-staying-in-shape-with-a-personal-trainer.jpg?s=2048x2048&w=is&k=20&c=L4m66fXimk2WN7hs34xU-Ru8-R-XiCf5Jwozu733rKA=',
      'publishDate':
          DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'isBookmarked': true, // Example bookmarked
      'tags': ['Exercise', 'Yoga', 'Wellness', 'Second Trimester'],
    },
    {
      'id': 'ARTICLE_003',
      'title': 'Preparing for Labor and Delivery',
      'content':
          'An overview of exercises and techniques for labor preparation. Covers kegel exercises, perineal massage, breathing and relaxation techniques for pain management. Includes advice on creating a birth plan and understanding labor stages.',
      'author': 'Community Midwives Collective',
      'imageUrl':
          'https://media.istockphoto.com/id/1299850715/photo/pregnant-woman-packing-bag-for-maternity-hospital-making-notes-checking-list-in-diary.jpg?s=2048x2048&w=is&k=20&c=YuoAGV-Xq5eXv3yUUp0Wtgp-iagtKCdsoQCJ5rQfEO0=',
      'publishDate':
          DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      'isBookmarked': false,
      'tags': [
        'Labor',
        'Delivery',
        'Preparation',
        'Third Trimester',
        'Exercise',
      ],
    },
    {
      'id': 'ARTICLE_004',
      'title': 'Mental Health and Pregnancy',
      'content':
          'Tips and strategies for managing stress and anxiety during pregnancy. Covers the link between stress and complications, self-care importance, mindfulness meditation, CBT techniques, and seeking professional help.',
      'author': 'Dr. Ben Carter, Psychologist',
      'imageUrl':
          'https://images.pexels.com/photos/4101143/pexels-photo-4101143.jpeg?auto=compress&cs=tinysrgb&w=600&h=400',
      'publishDate':
          DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      'isBookmarked': false,
      'tags': ['Mental Health', 'Wellness', 'Stress Management', 'Anxiety'],
    },
    {
      'id': 'ARTICLE_005',
      'title': 'The Fourth Trimester: Postpartum Care',
      'content':
          'An overview of the postpartum recovery period. Covers physical recovery, emotional challenges (like PPD/PPA), newborn adjustments, and essential self-care tips. Includes advice on seeking support from doulas or mental health professionals.',
      'author': 'Postpartum Support Int.',
      'imageUrl':
          'https://media.istockphoto.com/id/675059642/photo/happy-pregnant-woman-with-baby-clothes.jpg?s=2048x2048&w=is&k=20&c=smXKILV3JVCFLw-cHFz1J4q5yejCF-ccG-R90ooOo1c=',
      'publishDate':
          DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      'isBookmarked': false,
      'tags': [
        'Postpartum',
        'Recovery',
        'Newborn',
        'Self-care',
        'Mental Health',
      ],
    },
  ];

  // Food Data
  static final List<Map<String, dynamic>> foodData = [
    {
      // Renamed "Food Name" to "name" for consistency with FoodModel
      "name": "Salmon",
      "description":
          "Excellent source of high-quality protein and omega-3 fatty acids (DHA and EPA), crucial for baby's brain and eye development.",
      "category": "Seafood",
      // Added imageUrl
      "imageUrl":
          "https://images.pexels.com/photos/327158/pexels-photo-327158.jpeg?auto=compress&cs=tinysrgb&w=600", // Example image URL
      "benefits": [
        "Brain Development",
        "Eye Health",
        "Protein Source",
      ], // Example benefits
    },
    {
      "name": "Eggs",
      "description":
          "Great source of protein, vitamins (D, B12), and choline, which is vital for baby's brain development and preventing neural tube defects.",
      "category": "Dairy & Alternatives", // Broadened category
      "imageUrl":
          "https://images.pexels.com/photos/162712/egg-white-food-protein-162712.jpeg?auto=compress&cs=tinysrgb&w=600",
      "benefits": [
        "Brain Development",
        "Protein Source",
        "Choline",
        "Vitamin D",
      ],
    },
    {
      "name": "Sweet Potatoes",
      "description":
          "Rich in beta-carotene (converts to Vitamin A), essential for baby's cell growth, vision, skin, and immune system. Also provides fiber.",
      "category": "Vegetables",
      "imageUrl":
          "https://media.istockphoto.com/id/175235391/photo/sliced-yellow-and-white-fleshed-yams.jpg?s=2048x2048&w=is&k=20&c=OXgWy259CA93l0JGyxV4Q7EkR-pQ1Y-3q6Vvbx11EAc=",
      "benefits": ["Vitamin A", "Vision Health", "Immune Support", "Fiber"],
    },
    {
      "name": "Leafy Greens",
      "description":
          "Packed with vitamins (A, C, K), minerals (calcium, iron), and folate. Folate is crucial early on for preventing neural tube defects.",
      "category": "Vegetables",
      "imageUrl":
          "https://media.istockphoto.com/id/1163648688/photo/selection-of-healthy-green-food-fresh-vegetables-and-fruit-concept-of-green-color-clean.jpg?s=2048x2048&w=is&k=20&c=D4KNNCXwCNDalQ3318PQLiJlkrsIooyx839dMt_Nmmk=", // Spinach/Kale mix
      "benefits": ["Folate", "Iron", "Calcium", "Vitamin K", "Fiber"],
    },
    {
      "name": "Berries",
      "description":
          "High in antioxidants, vitamin C, water, and fiber. Help protect against cell damage and support immune health.",
      "category": "Fruits",
      "imageUrl":
          "https://images.pexels.com/photos/7082101/pexels-photo-7082101.jpeg?auto=compress&cs=tinysrgb&w=600", // Mixed berries
      "benefits": ["Antioxidants", "Vitamin C", "Immune Support", "Fiber"],
    },
    {
      "name": "Avocado",
      "description":
          "Rich in healthy monounsaturated fats, fiber, folate, potassium, and vitamin K. Supports baby's brain development and can help with leg cramps.",
      "category": "Fruits",
      "imageUrl":
          "https://images.pexels.com/photos/557659/pexels-photo-557659.jpeg?auto=compress&cs=tinysrgb&w=600",
      "benefits": [
        "Healthy Fats",
        "Folate",
        "Potassium",
        "Fiber",
        "Brain Development",
      ],
    },
    {
      "name": "Nuts & Seeds",
      "description":
          "Good source of healthy fats (including omega-3s in walnuts/flax/chia), protein, fiber, magnesium, and other minerals.",
      "category": "Nuts and Seeds",
      "imageUrl":
          "https://media.istockphoto.com/id/658447720/photo/assortment-of-nuts-on-rustic-wood-table.jpg?s=2048x2048&w=is&k=20&c=txFgP1VXO_Y3qNVB67-Lg7DWVplUXNsTD1vhhYiHjL8=", // Mixed nuts/seeds
      "benefits": [
        "Healthy Fats",
        "Protein Source",
        "Fiber",
        "Magnesium",
        "Omega-3 (some)",
      ],
    },
    {
      "name": "Lean Meats",
      "description":
          "Excellent source of high-quality protein and easily absorbed iron, vital for red blood cell production and preventing anemia.",
      "category": "Meats & Poultry",
      "imageUrl":
          "https://media.istockphoto.com/id/1407833173/photo/food-products-recommended-for-pregnancy-healthy-diet.jpg?s=2048x2048&w=is&k=20&c=MXisObKZyN5biMrtiYRP-VTiFU8pg13Y-TCznNy2DqU=", // Cooked chicken breast
      "benefits": ["Protein Source", "Iron", "Vitamin B12"],
    },
    {
      "name": "Greek Yogurt", // Specified Greek for higher protein
      "description":
          "Great source of calcium, protein, and probiotics (gut health). Choose plain varieties to avoid added sugars.",
      "category": "Dairy & Alternatives",
      "imageUrl":
          "https://media.istockphoto.com/id/1159838603/photo/strawberry-and-blueberry-perfect-against-a-white-wood-background.jpg?s=2048x2048&w=is&k=20&c=78TVP0d8jq3mG9soBy_v6ttSQ__ugSzogB34lxvbkA0=",
      "benefits": ["Calcium", "Protein Source", "Probiotics", "Bone Health"],
    },
    {
      "name": "Legumes",
      "description":
          "Includes beans, lentils, peas, chickpeas. Excellent source of plant-based protein, fiber, iron, folate, and calcium.",
      "category": "Beans & Legumes", // More specific category
      "imageUrl":
          "https://media.istockphoto.com/id/659524906/photo/composition-with-variety-of-vegetarian-food-ingredients.jpg?s=2048x2048&w=is&k=20&c=zCN_E6jtZLPcoJNYxao0zSbXseFoEtkWbVtxHsx3yCI=", // Mixed legumes
      "benefits": ["Protein Source", "Fiber", "Iron", "Folate", "Calcium"],
    },
    {
      "name": "Whole Grains",
      "description":
          "Provide complex carbohydrates for energy, fiber, B vitamins, and some minerals. Examples: oats, quinoa, brown rice, whole wheat bread.",
      "category": "Grains",
      "imageUrl":
          "https://media.istockphoto.com/id/953148202/photo/grains-of-whole-oats-in-a-wicker-box-and-ears-of-various-cereals-wheat-oats-rye-and-others-on.jpg?s=2048x2048&w=is&k=20&c=p0zOxGl7HiV02nr0ZeCeTja6OtiDF5tlX3Xz_IMmE80=", // Oats/Quinoa
      "benefits": ["Fiber", "Energy", "B Vitamins"],
    },
    {
      "name": "Broccoli", // Example specific leafy green
      "description":
          "A powerhouse of nutrients including vitamins C and K, fiber, calcium, folate, and antioxidants. Supports immune function and bone health.",
      "category": "Vegetables",
      "imageUrl":
          "https://images.pexels.com/photos/1435903/pexels-photo-1435903.jpeg?auto=compress&cs=tinysrgb&w=600",
      "benefits": [
        "Vitamin C",
        "Vitamin K",
        "Fiber",
        "Calcium",
        "Folate",
        "Antioxidants",
      ],
    },
    {
      "name": "Fortified Cereals",
      "description":
          "Can be a good source of added iron and folic acid, especially important during pregnancy. Check labels for fortification levels.",
      "category": "Grains",
      "imageUrl":
          "https://media.istockphoto.com/id/521982892/photo/corn-flakes-with-milk.jpg?s=2048x2048&w=is&k=20&c=WwENrGnSu6KGGK6UxBx9lkmcElRSxycz_DyKTDClCpg=", // Generic cereal
      "benefits": ["Iron (fortified)", "Folic Acid (fortified)"],
    },
    // Note: Removed "Cheese" and "Fatty Fish" as separate entries as they overlap with Dairy and Seafood.
    // You can add specific types if needed, e.g., "Low-Mercury Tuna".
  ];
  // Helper Methods
  static String getExerciseImage(String exerciseName) {
    switch (exerciseName.toLowerCase()) {
      case 'walking':
        return walking;
      case 'swimming':
        return swimming;
      case 'yoga':
        return yoga;
      case 'strength training':
        return strengthTraining;
      case 'stretching':
        return stretching;
      case 'kegels':
        return kegels;
      case 'prenatal pilates':
        return prenatalPilates;
      case 'low impact aerobics':
        return lowImpactAerobics;
      case 'stationary cycling':
        return stationaryCycling;
      case 'dancing':
        return dancing;
      case 'squats':
        return squats;
      case 'prenatal yoga':
        return prenatalYoga;
      case 'modified planks':
        return modifiedPlanks;
      case 'wall push ups':
        return wallPushUps;
      case 'pelvic tilts':
        return pelvicTilts;
      default:
        throw ArgumentError('Exercise image not found for: $exerciseName');
    }
  }

  static String getArticleImage(String articleTitle) {
    switch (articleTitle.toLowerCase()) {
      case 'maintaining a healthy pregnancy':
        return pregnantWoman;
      case 'prenatal yoga':
        return prenatalYogaArticle;
      case 'preparing for labor and delivery':
        return preparingForLaborDelivery;
      case 'mental health and pregnancy':
        return mentalHealthPregnancy;
      case 'the fourth trimester':
        return fourthTrimester;
      default:
        throw ArgumentError('Article image not found for: $articleTitle');
    }
  }

  // Add other asset paths as needed
  static const String baby_weight = 'assets/images/baby_weight.png';
  static const String baby_height = 'assets/images/baby_height.png';
  static const String strength_training = 'assets/images/strength_training.png';
  // Add other image paths
}
