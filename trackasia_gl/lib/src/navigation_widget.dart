part of '../trackasia_gl.dart';

/// A widget that provides navigation UI components
class NavigationWidget extends StatefulWidget {
  /// The map controller to use for navigation
  final TrackAsiaMapController mapController;
  
  /// The destination to navigate to
  final LatLng destination;
  
  /// Optional waypoints to navigate through
  final List<LatLng>? waypoints;
  
  /// Navigation options
  final NavigationOptions? options;
  
  /// Callback when navigation starts
  final VoidCallback? onNavigationStarted;
  
  /// Callback when navigation stops
  final VoidCallback? onNavigationStopped;
  
  /// Callback when navigation is paused
  final VoidCallback? onNavigationPaused;
  
  /// Callback when navigation is resumed
  final VoidCallback? onNavigationResumed;
  
  /// Callback for route progress updates
  final ValueChanged<RouteProgress>? onRouteProgress;
  
  /// Callback for voice instructions
  final ValueChanged<VoiceInstruction>? onVoiceInstruction;
  
  /// Callback for banner instructions
  final ValueChanged<BannerInstruction>? onBannerInstruction;
  
  /// Whether to show navigation controls
  final bool showControls;
  
  /// Whether to show voice instructions
  final bool showVoiceInstructions;
  
  /// Whether to show banner instructions
  final bool showBannerInstructions;
  
  const NavigationWidget({
    Key? key,
    required this.mapController,
    required this.destination,
    this.waypoints,
    this.options,
    this.onNavigationStarted,
    this.onNavigationStopped,
    this.onNavigationPaused,
    this.onNavigationResumed,
    this.onRouteProgress,
    this.onVoiceInstruction,
    this.onBannerInstruction,
    this.showControls = true,
    this.showVoiceInstructions = true,
    this.showBannerInstructions = true,
  }) : super(key: key);
  
  @override
  State<NavigationWidget> createState() => _NavigationWidgetState();
}

class _NavigationWidgetState extends State<NavigationWidget> {
  late StreamSubscription<NavigationEvent> _navigationEventSubscription;
  late StreamSubscription<RouteProgress> _routeProgressSubscription;
  late StreamSubscription<VoiceInstruction> _voiceInstructionSubscription;
  late StreamSubscription<BannerInstruction> _bannerInstructionSubscription;
  
  bool _isNavigating = false;
  bool _isPaused = false;
  RouteProgress? _currentProgress;
  VoiceInstruction? _currentVoiceInstruction;
  BannerInstruction? _currentBannerInstruction;
  
  @override
  void initState() {
    super.initState();
    _setupEventListeners();
  }
  
  @override
  void dispose() {
    _navigationEventSubscription.cancel();
    _routeProgressSubscription.cancel();
    _voiceInstructionSubscription.cancel();
    _bannerInstructionSubscription.cancel();
    super.dispose();
  }
  
  void _setupEventListeners() {
    final navigation = TrackAsiaNavigation.instance;
    
    _navigationEventSubscription = navigation.onNavigationEvent.listen((event) {
      setState(() {
        switch (event.type) {
          case NavigationEventType.navigationStarted:
            _isNavigating = true;
            _isPaused = false;
            widget.onNavigationStarted?.call();
          case NavigationEventType.navigationStopped:
            _isNavigating = false;
            _isPaused = false;
            widget.onNavigationStopped?.call();
          case NavigationEventType.navigationPaused:
            _isPaused = true;
            widget.onNavigationPaused?.call();
          case NavigationEventType.navigationResumed:
            _isPaused = false;
            widget.onNavigationResumed?.call();
          case NavigationEventType.routeProgress:
            // Handle route progress events if needed
            break;
          case NavigationEventType.routeRecalculation:
            // Handle route recalculation events if needed
            break;
          case NavigationEventType.arrival:
          // Handle arrival at destination
          break;
        case NavigationEventType.offRoute:
          // Handle off-route events
          break;
        case NavigationEventType.voiceInstruction:
          // Handle voice instruction events
          break;
        default:
          // Handle other navigation event types
          break;
      }
      });
    });
    
    _routeProgressSubscription = navigation.onRouteProgress.listen((progress) {
      setState(() {
        _currentProgress = progress;
      });
      widget.onRouteProgress?.call(progress);
    });
    
    _voiceInstructionSubscription = navigation.onVoiceInstruction.listen((instruction) {
      setState(() {
        _currentVoiceInstruction = instruction;
      });
      widget.onVoiceInstruction?.call(instruction);
    });
    
    _bannerInstructionSubscription = navigation.onBannerInstruction.listen((instruction) {
      setState(() {
        _currentBannerInstruction = instruction;
      });
      widget.onBannerInstruction?.call(instruction);
    });
  }
  
  Future<void> _startNavigation() async {
    try {
      final waypoints = widget.waypoints ?? [widget.destination];
      final success = await widget.mapController.navigateToWaypoints(
        waypoints,
        options: widget.options,
      );
      
      if (!success) {
        _showError('Failed to start navigation');
      }
    } catch (e) {
      _showError('Error starting navigation: $e');
    }
  }
  
  Future<void> _stopNavigation() async {
    try {
      await TrackAsiaNavigation.instance.stopNavigation();
    } catch (e) {
      _showError('Error stopping navigation: $e');
    }
  }
  
  Future<void> _pauseNavigation() async {
    try {
      await TrackAsiaNavigation.instance.pauseNavigation();
    } catch (e) {
      _showError('Error pausing navigation: $e');
    }
  }
  
  Future<void> _resumeNavigation() async {
    try {
      await TrackAsiaNavigation.instance.resumeNavigation();
    } catch (e) {
      _showError('Error resuming navigation: $e');
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner instructions
        if (widget.showBannerInstructions && _currentBannerInstruction != null)
          _buildBannerInstruction(),
        
        // Navigation controls
        if (widget.showControls)
          _buildNavigationControls(),
        
        // Route progress
        if (_currentProgress != null)
          _buildRouteProgress(),
        
        // Voice instructions
        if (widget.showVoiceInstructions && _currentVoiceInstruction != null)
          _buildVoiceInstruction(),
      ],
    );
  }
  
  Widget _buildBannerInstruction() {
    final instruction = _currentBannerInstruction!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            instruction.primaryText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (instruction.secondaryText != null)
            Text(
              instruction.secondaryText!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildNavigationControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!_isNavigating)
            ElevatedButton.icon(
              onPressed: _startNavigation,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
            )
          else ...[
            if (!_isPaused)
              ElevatedButton.icon(
                onPressed: _pauseNavigation,
                icon: const Icon(Icons.pause),
                label: const Text('Pause'),
              )
            else
              ElevatedButton.icon(
                onPressed: _resumeNavigation,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Resume'),
              ),
            ElevatedButton.icon(
              onPressed: _stopNavigation,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ]
        ],
      ),
    );
  }
  
  Widget _buildRouteProgress() {
    final progress = _currentProgress!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress.fractionTraveled,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distance: ${progress.distanceRemaining.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Time: ${progress.durationRemaining.inMinutes} min',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildVoiceInstruction() {
    final instruction = _currentVoiceInstruction!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        border: Border(
          top: BorderSide(color: Colors.green.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.volume_up,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instruction.announcement,
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple navigation button widget
class NavigationButton extends StatelessWidget {
  /// The map controller to use for navigation
  final TrackAsiaMapController mapController;
  
  /// The destination to navigate to
  final LatLng destination;
  
  /// Navigation options
  final NavigationOptions? options;
  
  /// Button text
  final String? text;
  
  /// Button icon
  final IconData? icon;
  
  /// Callback when navigation starts
  final VoidCallback? onNavigationStarted;
  
  const NavigationButton({
    Key? key,
    required this.mapController,
    required this.destination,
    this.options,
    this.text,
    this.icon,
    this.onNavigationStarted,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          final success = await mapController.navigateTo(
            destination,
            options: options,
          );
          
          if (success) {
            onNavigationStarted?.call();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to start navigation'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      icon: Icon(icon ?? Icons.navigation),
      label: Text(text ?? 'Navigate'),
    );
  }
}
