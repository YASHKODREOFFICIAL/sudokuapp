import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(SudokuApp());
}

class SudokuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku Game',
      theme: ThemeData.dark(),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    HomeScreen(),
    DailyGameScreen(),
    StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: 'Daily Game'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  void navigateToPuzzle(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SudokuPuzzleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Text(
              'Sudoku',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.grey[900],
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed: () => navigateToPuzzle(context),
                    child: Text('Daily Challenge', style: TextStyle(fontSize: 18)),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => navigateToPuzzle(context),
                    child: Text('New Game', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DailyGameScreen extends StatefulWidget {
  @override
  _DailyGameScreenState createState() => _DailyGameScreenState();
}

class _DailyGameScreenState extends State<DailyGameScreen> {
  DateTime _selectedDay = DateTime.now();
  List<SudokuPuzzle> allPuzzles = [];

  @override
  void initState() {
    super.initState();
    loadPuzzles().then((puzzles) {
      setState(() {
        allPuzzles = puzzles;
      });
    });
  }

  Future<List<SudokuPuzzle>> loadPuzzles() async {
    final String jsonString = await rootBundle.loadString('assets/puzzles.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((e) => SudokuPuzzle.fromJson(e)).toList();
  }

  void navigateToDailyPuzzle(DateTime date) {
    if (allPuzzles.isEmpty) return;
    int index = date.day % allPuzzles.length;
    final puzzle = allPuzzles[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SudokuPuzzleScreen(
          dailyPuzzle: puzzle,
          dailyDate: date,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 65),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
              navigateToDailyPuzzle(selectedDay);
            },
          ),
        ],
      ),
    );
  }
}

class SudokuPuzzleScreen extends StatefulWidget {
  final SudokuPuzzle? dailyPuzzle;
  final DateTime? dailyDate;

  SudokuPuzzleScreen({this.dailyPuzzle, this.dailyDate});

  @override
  _SudokuPuzzleScreenState createState() => _SudokuPuzzleScreenState();
}

class _SudokuPuzzleScreenState extends State<SudokuPuzzleScreen> {
  List<List<int?>> puzzle = List.generate(9, (_) => List.filled(9, null));
  List<List<int>> solution = List.generate(9, (_) => List.filled(9, 0));
  List<List<int?>> defaultPuzzle = List.generate(9, (_) => List.filled(9, null));
  int? selectedRow;
  int? selectedCol;
  int? highlightedNumber;
  Set<String> incorrectCells = {};
  List<SudokuPuzzle> allPuzzles = [];
  bool _completed = false;
  bool _winRecorded = false;
  int _failedAttempts = 0;
  bool _failed = false;
  bool _failRecorded = false;

  @override
  void initState() {
    super.initState();
    loadPuzzles().then((loadedPuzzles) {
      setState(() {
        allPuzzles = loadedPuzzles;
        if (widget.dailyPuzzle != null) {
          setPuzzle(widget.dailyPuzzle!);
        } else {
          _startNewGame();
        }
      });
    });
  }

  Future<List<SudokuPuzzle>> loadPuzzles() async {
    final String jsonString = await rootBundle.loadString('assets/puzzles.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((e) => SudokuPuzzle.fromJson(e)).toList();
  }

  void setPuzzle(SudokuPuzzle puzzleData) {
    if (!_validatePuzzle(puzzleData)) {
      throw Exception("Invalid puzzle JSON: must be 9x9 grid");
    }
    setState(() {
      puzzle = puzzleData.puzzle.map((row) => row.toList()).toList();
      defaultPuzzle = puzzleData.puzzle.map((row) => row.toList()).toList();
      solution = puzzleData.solution.map((row) => row.toList()).toList();
      incorrectCells.clear();
      selectedRow = null;
      selectedCol = null;
      highlightedNumber = null;
      _completed = false;
      _winRecorded = false;
      _failedAttempts = 0;
      _failed = false;
      _failRecorded = false;
    });
  }

  bool _validatePuzzle(SudokuPuzzle puzzleData) {
    if (puzzleData.puzzle.length != 9 || puzzleData.solution.length != 9) return false;
    for (var row in puzzleData.puzzle) {
      if (row.length != 9) return false;
    }
    for (var row in puzzleData.solution) {
      if (row.length != 9) return false;
    }
    return true;
  }

  void _startNewGame() {
    if (allPuzzles.isEmpty) return;
    final randomPuzzle = allPuzzles[Random().nextInt(allPuzzles.length)];
    setPuzzle(randomPuzzle);
  }

  void selectCell(int row, int col) {
    if (row < 0 || row > 8 || col < 0 || col > 8) return;
    if (_completed || _failed) return;
    setState(() {
      selectedRow = row;
      selectedCol = col;
      int? value = puzzle[row][col];
      highlightedNumber = (value != null && value == solution[row][col]) ? value : null;
    });
  }

  void enterNumber(int number) {
    if (selectedRow == null || selectedCol == null) return;
    if (_completed || _failed) return;
    int row = selectedRow!;
    int col = selectedCol!;
    if (!_isValidCell(row, col)) return;
    if (puzzle[row][col] != null && puzzle[row][col] == solution[row][col]) return;

    setState(() {
      puzzle[row][col] = number;
      String key = '$row-$col';
      if (solution[row][col] != number) {
        incorrectCells.add(key);
        _failedAttempts += 1;
        if (_failedAttempts >= 10) {
          _handlePuzzleFailure();
        }
      } else {
        incorrectCells.remove(key);
      }
      highlightedNumber = null;
      _checkForCompletion();
    });
  }

  void eraseNumber() {
    if (selectedRow == null || selectedCol == null) return;
    if (_completed || _failed) return;
    int row = selectedRow!;
    int col = selectedCol!;
    if (!_isValidCell(row, col)) return;
    if (puzzle[row][col] != null && puzzle[row][col] == solution[row][col]) return;

    setState(() {
      puzzle[row][col] = null;
      highlightedNumber = null;
      incorrectCells.remove('$row-$col');
    });
  }

  void resetPuzzle() {
    setState(() {
      puzzle = defaultPuzzle.map((row) => row.toList()).toList();
      incorrectCells.clear();
      selectedRow = null;
      selectedCol = null;
      highlightedNumber = null;
      _completed = false;
      _winRecorded = false;
      _failedAttempts = 0;
      _failed = false;
      _failRecorded = false;
    });
  }

  bool _isValidCell(int row, int col) {
    return row >= 0 && row < 9 && col >= 0 && col < 9;
  }

  Future<void> _checkForCompletion() async {
    if (_failed) return;
    bool complete = true;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (puzzle[i][j] != solution[i][j]) {
          complete = false;
          break;
        }
      }
      if (!complete) break;
    }

    if (complete && !_winRecorded) {
      setState(() {
        _completed = true;
        _winRecorded = true;
      });

      final recordDate = widget.dailyDate ?? DateTime.now();
      try {
        await StatisticsManager.recordWin(recordDate);
      } catch (e) {
        print("Error recording win: $e");
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Puzzle Solved!'),
            content: Text('Congratulations! You completed the puzzle.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handlePuzzleFailure() async {
    if (_failRecorded) return;
    setState(() {
      _failed = true;
      _failRecorded = true;
    });

    final recordDate = widget.dailyDate ?? DateTime.now();
    try {
      await StatisticsManager.recordFailure(recordDate);
    } catch (e) {
      print("Error recording failure: $e");
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Puzzle Failed'),
          content: Text('You have reached 10 failed attempts. The puzzle is marked as failed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget buildCell(int row, int col) {
    if (!_isValidCell(row, col)) return SizedBox.shrink();
    bool isSelected = selectedRow == row && selectedCol == col;
    int? value = puzzle[row][col];
    bool isPrefilled = value != null && value == solution[row][col];
    bool isIncorrect = incorrectCells.contains('$row-$col');
    bool isHighlighted = highlightedNumber != null && value == highlightedNumber;

    double left = (col % 3 == 0) ? 2 : 0.5;
    double top = (row % 3 == 0) ? 2 : 0.5;
    double right = (col == 8) ? 2 : 0.5;
    double bottom = (row == 8) ? 2 : 0.5;

    Color bgColor;
    if (isIncorrect)
      bgColor = Colors.red;
    else if (isSelected)
      bgColor = Colors.blueAccent;
    else if (isHighlighted)
      bgColor = Colors.orange.withOpacity(0.5);
    else if (isPrefilled)
      bgColor = Colors.grey[700]!;
    else
      bgColor = Colors.black87;

    return GestureDetector(
      onTap: () => selectCell(row, col),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.grey, width: left),
            top: BorderSide(color: Colors.grey, width: top),
            right: BorderSide(color: Colors.grey, width: right),
            bottom: BorderSide(color: Colors.grey, width: bottom),
          ),
          color: bgColor,
        ),
        child: Center(
          child: Text(
            value?.toString() ?? '',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget buildKeyboard() {
    List<Widget> numberKeys = List.generate(9, (index) {
      int number = index + 1;
      return Expanded(
        child: GestureDetector(
          onTap: (_completed || _failed) ? null : () => enterNumber(number),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
        ),
      );
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Failed attempts: $_failedAttempts', style: TextStyle(color: Colors.white)),
              if (_failed) Text('Puzzle failed', style: TextStyle(color: Colors.red)),
              if (_completed) Text('Puzzle completed', style: TextStyle(color: Colors.green)),
            ],
          ),
        ),
        Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: numberKeys),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: (_completed || _failed) ? null : eraseNumber,
                child: Container(
                  height: 50,
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.backspace, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Erase", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: resetPuzzle,
                child: Container(
                  height: 50,
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text("Reset", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _startNewGame,
                child: Container(
                  height: 50,
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text("New Game", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sudoku Puzzle"),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: 81,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9, crossAxisSpacing: 2, mainAxisSpacing: 2),
                itemBuilder: (context, index) {
                  int row = index ~/ 9;
                  int col = index % 9;
                  return buildCell(row, col);
                },
              ),
            ),
          ),
          buildKeyboard(),
        ],
      ),
    );
  }
}

class StatisticsScreen extends StatefulWidget {
  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<DateTime, Map<String, int>> dailyResults = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    StatisticsManager.notifier.addListener(_loadStatistics);
  }

  @override
  void dispose() {
    StatisticsManager.notifier.removeListener(_loadStatistics);
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    final results = await StatisticsManager.getDailyResults();
    setState(() {
      dailyResults = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Statistics")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text("Daily Results", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : dailyResults.isEmpty
                      ? Center(child: Text("No results recorded yet", style: TextStyle(color: Colors.white)))
                      : ListView(
                          children: dailyResults.entries.map((entry) {
                            final date = entry.key;
                            final wins = entry.value['wins'] ?? 0;
                            final fails = entry.value['fails'] ?? 0;
                            return ListTile(
                              title: Text(
                                '${date.day}-${date.month}-${date.year}',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text('Wins: $wins   Fails: $fails', style: TextStyle(color: Colors.white70)),
                              trailing: Text('${wins}w / ${fails}f', style: TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class SudokuPuzzle {
  final List<List<int?>> puzzle;
  final List<List<int>> solution;

  SudokuPuzzle({required this.puzzle, required this.solution});

  factory SudokuPuzzle.fromJson(Map<String, dynamic> json) {
    List<List<int?>> puzzleData = (json['default'] as List)
        .map((row) => (row as List).map((e) => e == null ? null : e as int).toList())
        .toList();

    List<List<int>> solutionData = (json['solution'] as List)
        .map((row) => (row as List).map((e) => e as int).toList())
        .toList();

    return SudokuPuzzle(puzzle: puzzleData, solution: solutionData);
  }
}

class StatisticsManager {
  static const _fileName = 'daily_results.json';
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  static Future<Map<String, dynamic>> _readAllResults() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return {};
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return {};
      final Map<String, dynamic> jsonData = json.decode(contents);
      return jsonData;
    } catch (e) {
      return {};
    }
  }

  static Future<void> _writeAllResults(Map<String, dynamic> data) async {
    try {
      final file = await _localFile;
      await file.writeAsString(json.encode(data));
    } catch (e) {
      print("Error writing statistics: $e");
    }
  }

  static Future<Map<DateTime, Map<String, int>>> getDailyResults() async {
    try {
      final jsonData = await _readAllResults();
      Map<DateTime, Map<String, int>> results = {};
      jsonData.forEach((key, value) {
        try {
          final date = DateTime.parse(key);
          int wins = 0;
          int fails = 0;
          if (value is Map) {
            wins = (value['wins'] ?? 0) is num ? (value['wins'] ?? 0).toInt() : 0;
            fails = (value['fails'] ?? 0) is num ? (value['fails'] ?? 0).toInt() : 0;
          }
          results[DateTime(date.year, date.month, date.day)] = {'wins': wins, 'fails': fails};
        } catch (e) {}
      });
      return results;
    } catch (e) {
      return {};
    }
  }

  static Future<void> recordWin(DateTime date) async {
    try {
      final jsonData = await _readAllResults();
      final normalizedDate = DateTime(date.year, date.month, date.day).toIso8601String();
      Map<String, dynamic> entry = {};
      if (jsonData.containsKey(normalizedDate) && jsonData[normalizedDate] is Map) {
        entry = Map<String, dynamic>.from(jsonData[normalizedDate]);
      }
      int currentWins = (entry['wins'] ?? 0) is num ? (entry['wins'] ?? 0) as int : 0;
      entry['wins'] = currentWins + 1;
      entry['fails'] = (entry['fails'] ?? 0) is num ? (entry['fails'] ?? 0) as int : 0;
      jsonData[normalizedDate] = entry;
      await _writeAllResults(jsonData);
      notifier.value++;
    } catch (e) {
      print("Error recording win: $e");
    }
  }

  static Future<void> recordFailure(DateTime date) async {
    try {
      final jsonData = await _readAllResults();
      final normalizedDate = DateTime(date.year, date.month, date.day).toIso8601String();
      Map<String, dynamic> entry = {};
      if (jsonData.containsKey(normalizedDate) && jsonData[normalizedDate] is Map) {
        entry = Map<String, dynamic>.from(jsonData[normalizedDate]);
      }
      int currentFails = (entry['fails'] ?? 0) is num ? (entry['fails'] ?? 0) as int : 0;
      entry['fails'] = currentFails + 1;
      entry['wins'] = (entry['wins'] ?? 0) is num ? (entry['wins'] ?? 0) as int : 0;
      jsonData[normalizedDate] = entry;
      await _writeAllResults(jsonData);
      notifier.value++;
    } catch (e) {
      print("Error recording failure: $e");
    }
  }
}
