import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/zwilling_logo.dart';

/// Register page: assign card to user.
/// First input: User ID (username). Second: Card No (filled by scan, disabled until User ID is set).
/// After card scan fills Card No, POST /api/userCards/assign is called.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _cardNoController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isAssigning = false;
  String? _message;

  // HID RFID scan buffer
  String _currentBuffer = '';
  DateTime? _lastInputTime;
  static const Duration _debounceDuration = Duration(milliseconds: 100);
  static const int _maxUidLength = 20;

  @override
  void initState() {
    super.initState();
    _userIdController.addListener(_onFieldChanged);
    _cardNoController.addListener(_onFieldChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _onFieldChanged() {
    setState(() {});
  }

  bool get _hasUserId {
    final t = _userIdController.text.trim();
    if (t.isEmpty) return false;
    return int.tryParse(t) != null;
  }

  int? get _userId {
    final t = _userIdController.text.trim();
    return int.tryParse(t);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || !_hasUserId || _isAssigning) return;

    final now = DateTime.now();

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_currentBuffer.isNotEmpty) {
        final uid = _currentBuffer.trim();
        _currentBuffer = '';
        _lastInputTime = null;
        _cardNoController.text = uid;
        _callAssignApi(uid);
      }
      return;
    }

    final character = _getCharacterFromKeyEvent(event);
    if (character != null) {
      if (_lastInputTime != null &&
          now.difference(_lastInputTime!) > _debounceDuration) {
        _currentBuffer = '';
      }
      if (_currentBuffer.length < _maxUidLength) {
        _currentBuffer += character;
        _lastInputTime = now;
      } else {
        _currentBuffer = character;
        _lastInputTime = now;
      }
      setState(() {});
    }
  }

  String? _getCharacterFromKeyEvent(KeyEvent event) {
    if (event.logicalKey.keyId >= LogicalKeyboardKey.digit0.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
      return (event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId).toString();
    }
    if (event.logicalKey.keyId >= LogicalKeyboardKey.numpad0.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.numpad9.keyId) {
      return (event.logicalKey.keyId - LogicalKeyboardKey.numpad0.keyId).toString();
    }
    if (event.logicalKey.keyId >= LogicalKeyboardKey.keyA.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.keyZ.keyId) {
      final index = event.logicalKey.keyId - LogicalKeyboardKey.keyA.keyId;
      final shift = HardwareKeyboard.instance.isShiftPressed;
      return String.fromCharCode(shift ? 65 : 97 + index);
    }
    return null;
  }

  Future<void> _callAssignApi(String cardUid) async {
    final userId = _userId;
    if (userId == null) return;

    setState(() {
      _isAssigning = true;
      _message = null;
    });

    try {
      final result = await ApiService.assignUserCard(userId, cardUid);
      if (!mounted) return;
      if (result != null && result['success'] == true) {
        setState(() {
          _message = result['message'] as String? ?? 'Card assigned successfully';
          _cardNoController.clear();
          _currentBuffer = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_message!),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _message = 'Failed to assign card';
          _isAssigning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to assign card'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error: $e';
          _isAssigning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  @override
  void dispose() {
    _userIdController.removeListener(_onFieldChanged);
    _cardNoController.removeListener(_onFieldChanged);
    _userIdController.dispose();
    _cardNoController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardNoEnabled = _hasUserId && !_isAssigning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back to Login',
        ),
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Zwilling logo at top
              Center(child: ZwillingLogo(height: 56)),
              const SizedBox(height: 24),
              TextField(
                controller: _userIdController,
                decoration: InputDecoration(
                  labelText: 'Username (User ID)',
                  hintText: 'Enter user ID (number)',
                  border: const OutlineInputBorder(),
                  suffixIcon: _userIdController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _userIdController.clear();
                            setState(() {});
                          },
                          tooltip: 'Clear',
                        )
                      : null,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: false,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _cardNoController,
                decoration: InputDecoration(
                  labelText: 'Card No',
                  hintText: cardNoEnabled ? 'Scan card to fill' : 'Enter User ID first',
                  border: const OutlineInputBorder(),
                  suffixIcon: _cardNoController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _cardNoController.clear();
                            _currentBuffer = '';
                            setState(() {});
                          },
                          tooltip: 'Clear',
                        )
                      : null,
                ),
                readOnly: true,
                enabled: cardNoEnabled,
                onChanged: (_) => setState(() {}),
              ),
              if (!_hasUserId)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Card No is disabled until User ID is entered.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ),
              if (_hasUserId && !_isAssigning)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Scan the card now. Card No will fill and assign automatically.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                        ),
                  ),
                ),
              const SizedBox(height: 24),
              if (_isAssigning)
                const Center(child: CircularProgressIndicator()),
              if (_message != null && !_isAssigning)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _message!,
                    style: const TextStyle(color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
