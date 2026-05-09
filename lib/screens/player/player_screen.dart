import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../config/theme.dart';
import '../../models/anime.dart';
import '../../models/watch_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/source_provider.dart';

typedef _GetForegroundWindowC = ffi.IntPtr Function();
typedef _GetForegroundWindowDart = int Function();
typedef _GetSystemMetricsC = ffi.Int32 Function(ffi.Int32);
typedef _GetSystemMetricsDart = int Function(int);
typedef _SetWindowLongPtrWC = ffi.IntPtr Function(ffi.IntPtr, ffi.Int32, ffi.IntPtr);
typedef _SetWindowLongPtrWDart = int Function(int, int, int);
typedef _SetWindowPosC = ffi.Int32 Function(ffi.IntPtr, ffi.IntPtr, ffi.Int32, ffi.Int32, ffi.Int32, ffi.Int32, ffi.Uint32);
typedef _SetWindowPosDart = int Function(int, int, int, int, int, int, int);
typedef _GetWindowLongPtrWC = ffi.IntPtr Function(ffi.IntPtr, ffi.Int32);
typedef _GetWindowLongPtrWDart = int Function(int, int);

class PlayerScreen extends ConsumerStatefulWidget {
  final Anime anime;
  final Episode episode;
  const PlayerScreen({super.key, required this.anime, required this.episode});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final Player _player;
  late final VideoController _controller;

  bool _isLoading = true;
  bool _isBuffering = false;
  String? _error;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 100.0; // media_kit uses 0-100
  bool _isMuted = false;
  double _savedVolume = 100.0;
  double _playbackSpeed = 1.0;
  bool _isFullscreen = false;

  // Controls
  bool _showControls = true;
  Timer? _hideTimer;

  // Gesture
  bool _isDragging = false;
  double _dragSeekDelta = 0;
  bool _showSeekFeedback = false;
  Timer? _gestureFeedbackTimer;

  // Auto-save progress periodically
  Timer? _autoSaveTimer;

  // Episode
  late int _currentEpisodeIndex;

  // Animation
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();
    _player = Player();
    _controller = VideoController(_player);

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0, // Start visible
    );

    _findCurrentEpisodeIndex();
    _setupListeners();
    _initPlayer();
  }

  void _findCurrentEpisodeIndex() {
    final episodes = widget.anime.episodes ?? [];
    _currentEpisodeIndex = episodes.indexWhere(
      (e) => e.url == widget.episode.url && e.title == widget.episode.title,
    );
    if (_currentEpisodeIndex < 0) _currentEpisodeIndex = 0;
  }

  void _setupListeners() {
    _player.stream.playing.listen((v) {
      if (!mounted) return;
      setState(() => _isPlaying = v);
      if (v) {
        _startHideTimer();
        _startAutoSave();
      } else {
        _hideTimer?.cancel();
        _autoSaveTimer?.cancel();
        _saveProgress();
        _showControls = true;
        _animCtrl.forward();
      }
    });
    _player.stream.position.listen((v) {
      if (mounted && !_isDragging) setState(() => _position = v);
    });
    _player.stream.duration.listen((v) {
      if (mounted) setState(() => _duration = v);
    });
    _player.stream.volume.listen((v) {});
    _player.stream.completed.listen((v) {
      if (v && mounted) {
        setState(() => _isPlaying = false);
        _hideTimer?.cancel();
        _autoSaveTimer?.cancel();
        _saveProgress(); // Save on completion
        _showControls = true;
        _animCtrl.forward();
      }
    });
    _player.stream.buffering.listen((v) {
      if (mounted) setState(() => _isBuffering = v);
    });
  }

  String _getReferer() {
    final apiUrl = ref.read(activeApiUrlProvider);
    if (apiUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(apiUrl);
        return '${uri.scheme}://${uri.host}/';
      } catch (_) {}
    }
    return 'https://www.yhdm365.com/';
  }

  Map<String, String> _videoHeaders() => {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Referer': _getReferer(),
  };

  Future<void> _initPlayer() async {
    try {
      final url = widget.episode.url;
      if (url.isEmpty) {
        if (mounted) setState(() { _error = '没有可播放的视频源'; _isLoading = false; });
        return;
      }
      await _player.open(Media(url, httpHeaders: _videoHeaders()));
      await _player.setVolume(100.0);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() { _error = '播放失败: $e'; _isLoading = false; });
    }
  }

  // Win32 cached bindings (lazy, Windows-only)
  static ffi.DynamicLibrary? _user32Lib;
  static ffi.DynamicLibrary get _user32 {
    if (_user32Lib == null) {
      if (!Platform.isWindows) throw UnsupportedError('Win32 APIs are only available on Windows');
      _user32Lib = ffi.DynamicLibrary.open('user32.dll');
    }
    return _user32Lib!;
  }

  static _GetForegroundWindowDart? _getForegroundWindowFn;
  static _GetForegroundWindowDart get _getForegroundWindow =>
      _getForegroundWindowFn ??= _user32.lookupFunction<_GetForegroundWindowC, _GetForegroundWindowDart>('GetForegroundWindow');

  static _GetSystemMetricsDart? _getSystemMetricsFn;
  static _GetSystemMetricsDart get _getSystemMetrics =>
      _getSystemMetricsFn ??= _user32.lookupFunction<_GetSystemMetricsC, _GetSystemMetricsDart>('GetSystemMetrics');

  static _GetWindowLongPtrWDart? _getWindowLongPtrWFn;
  static _GetWindowLongPtrWDart get _getWindowLongPtrW =>
      _getWindowLongPtrWFn ??= _user32.lookupFunction<_GetWindowLongPtrWC, _GetWindowLongPtrWDart>('GetWindowLongPtrW');

  static _SetWindowLongPtrWDart? _setWindowLongPtrWFn;
  static _SetWindowLongPtrWDart get _setWindowLongPtrW =>
      _setWindowLongPtrWFn ??= _user32.lookupFunction<_SetWindowLongPtrWC, _SetWindowLongPtrWDart>('SetWindowLongPtrW');

  static _SetWindowPosDart? _setWindowPosFn;
  static _SetWindowPosDart get _setWindowPos =>
      _setWindowPosFn ??= _user32.lookupFunction<_SetWindowPosC, _SetWindowPosDart>('SetWindowPos');

  static const _gwlStyle = -16;
  static const _gwlExStyle = -20;
  static const _wsBorder = 0x00800000;
  static const _wsCaption = 0x00C00000;
  static const _wsThickframe = 0x00040000;
  static const _swpFrameChanged = 0x0020;
  static const _swpNoZOrder = 0x0004;
  static const _hwndTop = 0;
  static const _smCxScreen = 0;
  static const _smCyScreen = 1;

  int? _savedStyle;
  int? _savedExStyle;

  void _toggleFullscreen() {
    if (!Platform.isWindows) {
      // Mobile: use SystemChrome
      setState(() => _isFullscreen = !_isFullscreen);
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([]);
      }
      return;
    }

    // Windows: Win32 API
    final hwnd = _getForegroundWindow();
    if (hwnd == 0) return;

    setState(() => _isFullscreen = !_isFullscreen);

    if (_isFullscreen) {
      // Save current styles
      _savedStyle = _getWindowLongPtrW(hwnd, _gwlStyle);
      _savedExStyle = _getWindowLongPtrW(hwnd, _gwlExStyle);

      // Remove border/title
      final newStyle = _savedStyle! & ~(_wsCaption | _wsBorder | _wsThickframe);
      _setWindowLongPtrW(hwnd, _gwlStyle, newStyle);
      _setWindowLongPtrW(hwnd, _gwlExStyle, 0);

      // Resize to full screen
      final cx = _getSystemMetrics(_smCxScreen);
      final cy = _getSystemMetrics(_smCyScreen);
      _setWindowPos(hwnd, _hwndTop, 0, 0, cx, cy, _swpFrameChanged | _swpNoZOrder);
    } else {
      // Restore styles
      if (_savedStyle != null) {
        _setWindowLongPtrW(hwnd, _gwlStyle, _savedStyle!);
        _setWindowLongPtrW(hwnd, _gwlExStyle, _savedExStyle ?? 0);
      }
      // Restore to a reasonable window size
      _setWindowPos(hwnd, _hwndTop, 100, 100, 1280, 720, _swpFrameChanged | _swpNoZOrder);
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isPlaying && !_isDragging) {
        _showControls = false;
        _animCtrl.reverse();
      }
    });
  }

  void _toggleControls() {
    if (_showControls) {
      _showControls = false;
      _animCtrl.reverse();
      _hideTimer?.cancel();
    } else {
      _showControls = true;
      _animCtrl.forward();
      if (_isPlaying) _startHideTimer();
    }
    setState(() {});
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isPlaying && _position.inSeconds > 0) {
        _saveProgress();
      }
    });
  }

  Future<void> _saveProgress() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final email = user['email'] ?? '';
      if (email.isEmpty) return;
      final pos = _position.inSeconds;
      if (pos <= 0) return;
      final record = WatchRecord(
        animeId: widget.anime.id,
        animeTitle: widget.anime.title,
        animeCover: widget.anime.cover,
        episodeTitle: widget.episode.title,
        episodeUrl: widget.episode.url,
        progress: pos,
        duration: _duration.inSeconds,
        watchedAt: DateTime.now(),
      );
      await ref.read(storageServiceProvider).saveWatchRecord(email, record);
    } catch (e) {
      // ignore save errors
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _autoSaveTimer?.cancel();
    _gestureFeedbackTimer?.cancel();
    _animCtrl.dispose();
    _player.dispose();
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _setVolume(double v) {
    _player.setVolume(v);
    if (mounted) setState(() => _volume = v);
  }

  void _seekRelative(int sec) {
    final pos = _position + Duration(seconds: sec);
    _player.seek(pos.isNegative ? Duration.zero : (pos > _duration ? _duration : pos));
  }

  void _playEpisodeAt(int index) {
    final eps = widget.anime.episodes ?? [];
    if (index < 0 || index >= eps.length) return;
    setState(() { _currentEpisodeIndex = index; _isLoading = true; _error = null; });
    _player.open(Media(eps[index].url, httpHeaders: _videoHeaders()));
    _player.setVolume(_isMuted ? 0.0 : _volume);
  }

  // === Build ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3))
          : _error != null
              ? _buildError()
              : _buildPlayer(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.accentColor, size: 56),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () { setState(() { _isLoading = true; _error = null; }); _initPlayer(); },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    final eps = widget.anime.episodes ?? [];
    final hasNext = _currentEpisodeIndex < eps.length - 1;
    final hasPrev = _currentEpisodeIndex > 0;
    final epTitle = eps.isNotEmpty ? eps[_currentEpisodeIndex].title : widget.episode.title;

    return Stack(
      children: [
        // Layer 1: Video
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleControls,
            child: Video(
              controller: _controller,
              controls: NoVideoControls,
            ),
          ),
        ),

        // Layer 2: Gesture overlay for seek drag (only when controls hidden)
        if (!_showControls)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleControls,
              onPanStart: (_) { _isDragging = true; _dragSeekDelta = 0; },
              onPanUpdate: (d) {
                if (d.delta.dx.abs() > d.delta.dy.abs()) {
                  _dragSeekDelta += d.delta.dx * 0.5;
                  setState(() => _showSeekFeedback = true);
                }
              },
              onPanEnd: (_) {
                if (_dragSeekDelta.abs() > 1) _seekRelative(_dragSeekDelta.toInt());
                setState(() { _isDragging = false; _showSeekFeedback = false; });
                _startHideTimer();
              },
              child: const SizedBox.expand(),
            ),
          ),

        // Layer 3: Buffering
        if (_isBuffering)
          const IgnorePointer(
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3),
            ),
          ),

        // Layer 4: Seek drag feedback
        if (_showSeekFeedback)
          IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${_dragSeekDelta >= 0 ? '+' : ''}${_dragSeekDelta.toInt()}s',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

        // Layer 5: Controls (always on top, IgnorePointer when hidden)
        IgnorePointer(
          ignoring: !_showControls,
          child: FadeTransition(
            opacity: _animCtrl,
            child: Stack(
              children: [
                // Top bar
                _buildTopBar(epTitle),
                // Center: prev/next episode quick buttons
                _buildCenterButtons(hasPrev, hasNext),
                // Bottom bar
                _buildBottomBar(hasNext, hasPrev, epTitle),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // === Top bar ===
  Widget _buildTopBar(String epTitle) {
    final padTop = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(top: padTop + 4, left: 12, right: 12, bottom: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC000000), Color(0x00000000)],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.anime.title,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(epTitle,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (_playbackSpeed != 1.0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(4)),
                child: Text('${_playbackSpeed}x', style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  // === Center prev/next buttons ===
  Widget _buildCenterButtons(bool hasPrev, bool hasNext) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (hasPrev)
              _circleButton(Icons.skip_previous_rounded, () => _playEpisodeAt(_currentEpisodeIndex - 1))
            else
              const SizedBox.shrink(),
            if (hasNext)
              _circleButton(Icons.skip_next_rounded, () => _playEpisodeAt(_currentEpisodeIndex + 1))
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(icon, color: Colors.white, size: 36),
        ),
      ),
    );
  }

  // === Bottom bar ===
  Widget _buildBottomBar(bool hasNext, bool hasPrev, String epTitle) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 24, 12, safeBottom + 4),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xDD000000), Color(0x00000000)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress
            _buildProgressBar(),
            const SizedBox(height: 4),
            // Main controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _iconBtn(Icons.skip_previous_rounded, 30, hasPrev, hasPrev ? () => _playEpisodeAt(_currentEpisodeIndex - 1) : null),
                _iconBtn(Icons.replay_10_rounded, 34, true, () => _seekRelative(-10)),
                _playPauseBtn(),
                _iconBtn(Icons.forward_10_rounded, 34, true, () => _seekRelative(10)),
                _iconBtn(Icons.skip_next_rounded, 30, hasNext, hasNext ? () => _playEpisodeAt(_currentEpisodeIndex + 1) : null),
              ],
            ),
            // Extra controls
            Row(
              children: [
                _muteBtn(),
                SizedBox(
                  width: 90,
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.white60,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    ),
                    child: Slider(
                      value: _volume, min: 0, max: 100,
                      onChanged: (v) {
                        _setVolume(v);
                        if (v > 0 && _isMuted) setState(() => _isMuted = false);
                      },
                    ),
                  ),
                ),
                const Spacer(),
                _speedBtn(),
                const SizedBox(width: 8),
                _epListBtn(),
                const SizedBox(width: 8),
                _fullscreenBtn(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: AppTheme.primaryColor,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        overlayColor: AppTheme.primaryColor.withOpacity(0.2),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      ),
      child: Slider(
        value: _duration.inMilliseconds > 0
            ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0,
        onChanged: (v) => _player.seek(Duration(milliseconds: (v * _duration.inMilliseconds).toInt())),
        onChangeStart: (_) { _isDragging = true; _hideTimer?.cancel(); },
        onChangeEnd: (_) { _isDragging = false; _startHideTimer(); },
      ),
    );
  }

  // === Buttons ===

  Widget _playPauseBtn() {
    return GestureDetector(
      onTap: () { _player.playOrPause(); _startHideTimer(); },
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)],
        ),
        child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _iconBtn(IconData icon, double size, bool enabled, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: enabled ? Colors.white : Colors.white24, size: size),
      ),
    );
  }

  Widget _muteBtn() {
    return GestureDetector(
      onTap: () {
        if (_isMuted) {
          final restore = _savedVolume > 1 ? _savedVolume : 50.0;
          _setVolume(restore);
          setState(() => _isMuted = false);
        } else {
          _savedVolume = _volume;
          _setVolume(0);
          setState(() => _isMuted = true);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          _isMuted ? Icons.volume_off_rounded : _volume > 50 ? Icons.volume_up_rounded : Icons.volume_down_rounded,
          color: Colors.white70, size: 20,
        ),
      ),
    );
  }

  Widget _speedBtn() {
    return PopupMenuButton<double>(
      onSelected: (s) { _player.setRate(s); setState(() => _playbackSpeed = s); },
      itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) =>
        PopupMenuItem(value: s, child: Row(children: [
          if (s == _playbackSpeed) Icon(Icons.check, size: 16, color: AppTheme.primaryColor) else const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text('${s}x', style: TextStyle(color: s == _playbackSpeed ? AppTheme.primaryColor : AppTheme.textPrimary, fontWeight: s == _playbackSpeed ? FontWeight.bold : FontWeight.normal)),
        ]))
      ).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.speed_rounded, color: Colors.white70, size: 16),
          const SizedBox(width: 4),
          Text('${_playbackSpeed}x', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _epListBtn() {
    return GestureDetector(
      onTap: _showEpisodeSheet,
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.list_rounded, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _fullscreenBtn() {
    return GestureDetector(
      onTap: _toggleFullscreen,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
          color: Colors.white70, size: 22,
        ),
      ),
    );
  }

  // === Episode sheet ===
  void _showEpisodeSheet() {
    final eps = widget.anime.episodes ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5, maxChildSize: 0.8, minChildSize: 0.3, expand: false,
        builder: (ctx, ctrl) => Column(children: [
          Container(margin: const EdgeInsets.only(top: 8), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Text('选集', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(width: 8),
              Text('共${eps.length}集', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ]),
          ),
          Expanded(
            child: GridView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.2),
              itemCount: eps.length,
              itemBuilder: (_, i) {
                final cur = i == _currentEpisodeIndex;
                return GestureDetector(
                  onTap: () { Navigator.pop(ctx); _playEpisodeAt(i); },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cur ? AppTheme.primaryColor : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(eps[i].title, style: TextStyle(fontSize: 13, color: cur ? Colors.white : AppTheme.textPrimary, fontWeight: cur ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
