import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';

class WaterSettingsPage extends StatelessWidget {
  const WaterSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _TimerState(),
      builder: (context, child) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TimerWidget(),
                const Text("Time Until Water"),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed:
                          Provider.of<_TimerState>(context, listen: false)
                              .resetTimer,
                      child: const Text("Reset"),
                    ),
                    (Provider.of<_TimerState>(context, listen: true)
                            .isTimerRunning)
                        ? TextButton(
                            onPressed: Provider.of<_TimerState>(context,
                                    listen: false)
                                .stopTimer,
                            child: const Text("Stop"),
                          )
                        : TextButton(
                            onPressed: () => Provider.of<_TimerState>(context,
                                    listen: false)
                                .startTimer(context),
                            child: const Text("Start"),
                          ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TimerWidget extends StatefulWidget {
  const TimerWidget({
    super.key,
  });

  @override
  State<TimerWidget> createState() => _TimerTextfieldState();
}

class _TimerTextfieldState extends State<TimerWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => _handleInput());
  }

  void _handleInput() {
    var timerState = Provider.of<_TimerState>(context, listen: false);
    if (timerState.isTimerRunning) return;
    final RegExp nonNumbers = RegExp(r"([^\d])");
    final RegExp sixToNine = RegExp(r"([6-9])");
    String text = _controller.text.replaceAll(nonNumbers, "");
    if (text.length > 4) text = text.substring(0, 4);
    var minutes = text.length > 2 ? text.substring(0, 2) : text;
    var seconds = text.length > 2 ? text.substring(2) : "";
    if (seconds.length == 1) {
      seconds = seconds.replaceAll(sixToNine, "");
    }
    seconds = (seconds == "") ? "" : ":$seconds";
    text = "$minutes$seconds";
    _controller.value = _controller.value.copyWith(
      text: text,
      selection:
          TextSelection(baseOffset: text.length, extentOffset: text.length),
      composing: TextRange.empty,
    );
  }

  void _handleSubmit(BuildContext context) {
    String value = _controller.text;
    var timerState = Provider.of<_TimerState>(context, listen: false);
    if (timerState.isTimerRunning) return;
    // includes the ":"
    if (value.length == 5) {
      var timerState = Provider.of<_TimerState>(context, listen: false);
      timerState.mins = int.tryParse(value.substring(0, 2))!;
      timerState.secs = int.tryParse(value.substring(3, 5))!;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Invalid Time Dumbass"),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var timerState = context.watch<_TimerState>();
    _controller.text =
        "${timerState.mins.toString().padLeft(2, '0')}:${timerState.secs.toString().padLeft(2, '0')}";
    return SizedBox(
      width: 50,
      child: TextField(
        controller: _controller,
        onSubmitted: (value) => _handleSubmit(context),
        onTapOutside: (value) {
          _handleSubmit(context);
          FocusManager.instance.primaryFocus?.unfocus();
        },
        readOnly: timerState.isTimerRunning ? true : false,
      ),
    );
  }
}

class _TimerState extends ChangeNotifier {
  int _mins = 0, _secs = 0;
  int _currMins = 0, _currSecs = 0;
  bool get isTimerRunning =>
      (_updateTimer == null) ? false : _updateTimer!.isActive;
  int get mins => _currMins;
  int get secs => _currSecs;

  set mins(int mins) {
    _mins = mins;
    _currMins = _mins;
    notifyListeners();
  }

  set secs(int secs) {
    _secs = secs;
    _currSecs = _secs;
    notifyListeners();
  }

  Timer? _updateTimer;

  void startTimer(BuildContext context) async {
    _currMins = _mins;
    _currSecs = _secs;
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (var timer) async {
      if (_currMins == 0 && _currSecs == 0) {
        stopTimer();
        final player = AudioPlayer();
        player.setVolume(1);
        await player.play(AssetSource('sounds/vine-boom-spam.mp3'));
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("go drink water"),
        ));
        return;
      }
      if (_currSecs == 0) {
        _currMins--;
        _currSecs = 59;
      } else {
        _currSecs--;
      }

      notifyListeners();
    });

    notifyListeners();
  }

  void resetTimer() {
    stopTimer();
    _currMins = _mins;
    _currSecs = _secs;
    notifyListeners();
  }

  void stopTimer() {
    if (_updateTimer != null) {
      _updateTimer!.cancel();
    }
    notifyListeners();
  }
}
