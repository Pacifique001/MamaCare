import 'package:flutter/foundation.dart';
import 'package:mama_care/domain/usecases/timeline_use_case.dart';
// Remove DatabaseHelper import - ViewModel shouldn't interact directly with it
// import 'package:mama_care/data/local/database_helper.dart';
import 'package:mama_care/domain/entities/pregnancy_details.dart';

class TimelineViewModel extends ChangeNotifier {
  final TimelineUseCase _timelineUseCase;
  // Remove DatabaseHelper dependency
  // final DatabaseHelper _databaseHelper;

  TimelineViewModel({
    required TimelineUseCase timelineUseCase,
    // Remove DatabaseHelper from constructor
    // required DatabaseHelper databaseHelper,
  }) : _timelineUseCase = timelineUseCase {
       // _databaseHelper = databaseHelper; // Remove assignment
    // initialize(); // Consider removing this - fetchPregnancyDetails is likely called from UI initState
    // If initialize is removed, ensure initial _calculateCurrentProgress runs with default due date
    _calculateCurrentProgress(); // Calculate initial state based on default _dueDate
  }

  // State Variables
  PregnancyDetails? _pregnancyDetails; // Store the fetched details
  bool _isLoading = false; // Default to false, set true during fetch
  String? _errorMessage;

  // Static pregnancy timeline data (remains the same)
   final List<List<String>> weeks = [
    [
      'Week 1',
      'Your body is preparing for ovulation. The menstrual cycle begins, counting towards your estimated due date.',
    ],
    [
      'Week 2',
      'Ovulation occurs, and conception may happen during this period.',
    ],
    [
      'Week 3',
      'The fertilized egg implants in the uterus, starting embryo development.',
    ],
    [
      'Week 4',
      'Your baby is now the size of a poppy seed, and their heart begins to form.',
    ],
    [
      'Week 5',
      'The neural tube starts developing into the brain and spinal cord.',
    ],
    [
      'Week 6',
      'Your baby\'s heart is beating, and tiny buds for arms and legs appear.',
    ],
    ['Week 7', 'Facial features like nostrils and eyes start forming.'],
    ['Week 8', 'Your baby\'s fingers and toes start to develop.'],
    [
      'Week 9',
      'Essential organs like the liver, brain, and heart continue growing.',
    ],
    ['Week 10', 'The baby is moving, but you can\'t feel it yet.'],
    ['Week 11', 'Your baby\'s bones are hardening, and tooth buds appear.'],
    ['Week 12', 'Your baby\'s intestines start moving into the abdomen.'],
    ['Week 13', 'Your baby now has fingerprints, and vocal cords are forming.'],
    [
      'Week 14',
      'Hair follicles start appearing, and your baby begins making facial expressions.',
    ],
    ['Week 15', 'Your baby\'s skeletal system is developing rapidly.'],
    [
      'Week 16',
      'Your baby\'s hearing is developing, and limb movements become more coordinated.',
    ],
    ['Week 17', 'Your baby is practicing swallowing and sucking reflexes.'],
    [
      'Week 18',
      'Your baby\'s ears are fully developed and can hear outside noises.',
    ],
    [
      'Week 19',
      'Your baby\'s skin starts forming vernix, a protective coating.',
    ],
    ['Week 20', 'Halfway there! Your baby is the size of a banana.'],
    [
      'Week 21',
      'Your baby is tasting amniotic fluid and developing taste buds.',
    ],
    [
      'Week 22',
      'Your baby\'s senses are refining, and fingerprints are forming.',
    ],
    ['Week 23', 'Your baby\'s lungs are developing to prepare for breathing.'],
    [
      'Week 24',
      'Your baby\'s face is fully formed, and they may respond to touch.',
    ],
    ['Week 25', 'Your baby is gaining fat, making skin less translucent.'],
    [
      'Week 26',
      'Your baby\'s eyes start opening, and they can distinguish light and dark.',
    ],
    ['Week 27', 'Your baby\'s brain activity increases significantly.'],
    ['Week 28', 'Your baby is now capable of dreaming.'],
    ['Week 29', 'Your baby\'s muscles and lungs continue developing.'],
    ['Week 30', 'Your baby is practicing breathing with amniotic fluid.'],
    [
      'Week 31',
      'Your baby starts storing essential minerals like iron and calcium.',
    ],
    ['Week 32', 'Your baby likely assumes a head-down position for birth.'],
    ['Week 33', 'Your baby\'s immune system is developing.'],
    ['Week 34', 'Your baby\'s nails and hair are fully formed.'],
    ['Week 35', 'Your baby\'s nervous system is nearly mature.'],
    ['Week 36', 'Your baby\'s head is likely engaged in the pelvis.'],
    ['Week 37', 'Your baby is considered full-term.'],
    ['Week 38', 'Your baby is developing final fat stores for warmth.'],
    ['Week 39', 'Your baby\'s brain continues to grow rapidly.'],
    ['Week 40', 'Your baby is ready for birth!'],
  ];
  // Current pregnancy state (calculated)
  // Initialize with a default value, will be updated by fetchPregnancyDetails
  DateTime _dueDate = DateTime.now().add(const Duration(days: 280));
  int _weeksPregnant = 0;
  int _daysPregnant = 0;
  // Remove babyHeight/Weight if not actively used/calculated in this VM
  // final double _babyHeight = 0.0;
  // final double _babyWeight = 0.0;

  // --- Getters ---
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get weeksPregnant => _weeksPregnant;
  int get daysPregnant => _daysPregnant;
  DateTime get dueDate => _dueDate;
  // Expose the full details object if needed by the UI
  PregnancyDetails? get pregnancyDetails => _pregnancyDetails;

  // --- Initialization and Data Fetching ---

  // Call this from your View's initState or similar lifecycle method
  Future<void> fetchPregnancyDetails() async {
    // Prevent multiple simultaneous fetches
    if (_isLoading) return;

    debugPrint("[TimelineVM] Fetching pregnancy details...");
    _updateState(isLoading: true, errorMessage: null); // Set loading, clear previous error

    try {
      // UseCase now fetches from Repository (which handles Firestore/Cache logic)
      final details = await _timelineUseCase.getPregnancyDetails();

      if (details != null) {
        debugPrint("[TimelineVM] Details fetched successfully: Due Date ${details.dueDate}");
        _updateFromDetails(details);
        // REMOVED: Caching is handled by the Repository now
        // await _cacheLocally(details);
      } else {
        // Handle case where no details are found (neither Firestore nor cache)
        debugPrint("[TimelineVM] No pregnancy details found.");
        // Keep the default due date calculated initially, or set a specific message
        _errorMessage = "Pregnancy details not available. Please set them up in your profile.";
        // Ensure progress is calculated based on the default due date
        _calculateCurrentProgress();
        // We still notifyListeners via _updateState in finally block
      }
    } catch (e, stackTrace) {
      // Log the error from the use case/repository
      debugPrint("[TimelineVM] Error fetching pregnancy details: $e\n$stackTrace");
      _handleError('Failed to load pregnancy details. Please try again.');
    } finally {
      // Ensure loading state is always turned off
      _updateState(isLoading: false);
    }
  }

  // --- State Update Methods ---

  // Call this if the user can manually update the due date in the UI
  void updateDueDate(DateTime newDate) {
    // Add validation if needed (e.g., reasonable date range)
    if (newDate.isBefore(DateTime.now().subtract(const Duration(days: 300))) ||
        newDate.isAfter(DateTime.now().add(const Duration(days: 300)))) {
       debugPrint("[TimelineVM] Ignoring unreasonable due date update: $newDate");
       return; // Or show an error message
    }
    if (newDate.isAtSameMomentAs(_dueDate)) return; // No actual change

    debugPrint("[TimelineVM] Manually updating due date to: $newDate");
    _dueDate = newDate;
    _calculateCurrentProgress(); // Recalculate and notify listeners

    // Optional: Persist this manual change back to Firestore/Cache
    // This would require adding an update method to the UseCase/Repository
    // e.g., _timelineUseCase.updatePregnancyDueDate(newDate)
    //      .catchError((e) => _handleError("Failed to save updated due date"));
  }

  // Helper to get description for a specific week number (1-based index)
  String getWeekDescription(int weekNumber) {
    if (weekNumber < 1 || weekNumber > weeks.length) {
      return 'Information not available for this week.'; // Handle out-of-bounds
    }
    // Assumes weeks list is 0-indexed, so subtract 1
    return weeks[weekNumber - 1][1];
  }

  // --- Core Calculation Logic ---
  void _calculateCurrentProgress() {
    final now = DateTime.now();
    // Calculate estimated Last Menstrual Period (LMP) based on the current _dueDate
    // Standard calculation: Due Date = LMP + 280 days
    final estimatedLmpDate = _dueDate.subtract(const Duration(days: 280));

    // Calculate the duration since the estimated LMP
    final pregnancyDuration = now.difference(estimatedLmpDate);

    int calculatedWeeks = 0;
    int calculatedDays = 0;

    // Handle cases where the due date might be in the past relative to 'now'
    if (pregnancyDuration.isNegative) {
      // This means the due date has passed
      calculatedWeeks = weeks.length + (pregnancyDuration.inDays.abs() ~/ 7); // Show as 40+ weeks past due
      calculatedDays = pregnancyDuration.inDays.abs() % 7;
      debugPrint("[TimelineVM] Due date has passed. Calculated as Week $calculatedWeeks, Day $calculatedDays past due.");
      // Clamp to a maximum displayable week if needed, or handle "past due" state explicitly
       _weeksPregnant = weeks.length; // Clamp at max week defined
       _daysPregnant = 0; // Reset days for simplicity when past due, or show days past due

    } else {
      // Standard calculation: Week number is integer division + 1
      // (e.g., 0-6 days = week 1, 7-13 days = week 2)
      calculatedWeeks = (pregnancyDuration.inDays ~/ 7) + 1;
      // Days into the current week
      calculatedDays = pregnancyDuration.inDays % 7;

       // Clamp values to the defined range of weeks
      _weeksPregnant = calculatedWeeks.clamp(1, weeks.length); // Ensure it's at least 1 and max defined week
      _daysPregnant = calculatedDays.clamp(0, 6);
    }

    debugPrint("[TimelineVM] Calculated Progress: Week $_weeksPregnant, Day $_daysPregnant (Due: $_dueDate, LMP Est: $estimatedLmpDate)");

    // Notify listeners AFTER calculations are complete
    // Avoid calling notifyListeners within _updateState if it's called from here,
    // but since _calculateCurrentProgress calls it directly, it's fine.
    notifyListeners();
  }

  // --- Private Helper Methods ---

  // Called internally when fresh details are successfully fetched
  void _updateFromDetails(PregnancyDetails details) {
    _pregnancyDetails = details; // Store the details object
    _dueDate = details.dueDate;  // Update the due date state
    _calculateCurrentProgress(); // Recalculate progress based on the new due date
                                 // This method already calls notifyListeners()
  }

  // Centralized state update and notification
  void _updateState({bool? isLoading, String? errorMessage}) {
    bool needsNotify = false;

    // Update loading state if changed
    if (isLoading != null && _isLoading != isLoading) {
      _isLoading = isLoading;
      // Clear error when starting to load
      if (_isLoading) {
        _errorMessage = null;
      }
      needsNotify = true;
    }

    // Update error message state if changed
    // Allow setting null error message
    if (errorMessage != _errorMessage) {
        _errorMessage = errorMessage;
        needsNotify = true;
    }

    // If finishing loading successfully (isLoading=false, errorMessage=null)
    // and there was a previous error message, clear it.
     if (isLoading == false && errorMessage == null && _errorMessage != null) {
        _errorMessage = null;
        needsNotify = true;
     }


    if (needsNotify) {
      notifyListeners();
    }
  }

  // Handle errors and update state
  void _handleError(String message) {
    _errorMessage = message;
    // Ensure loading is turned off when an error occurs during fetch
    if (_isLoading) {
      _isLoading = false;
    }
    notifyListeners(); // Notify about error and loading state change
    // Debug print remains useful
    debugPrint("[TimelineVM] Error handled: $message");
  }


}