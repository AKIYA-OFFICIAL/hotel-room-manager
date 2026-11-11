import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const HotelHousekeepingApp());
}

class HotelHousekeepingApp extends StatelessWidget {
  const HotelHousekeepingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel Room Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
      ),
      home: const HomeScreen(),
    );
  }
}

class RoomModel {
  String id;
  String roomNumber;
  String guestStatus; // 'Vacant', 'Check-In', 'Check-Out'
  String checkInTime;
  String checkOutTime;
  String statusNote;
  Map<String, int> neededSupplies;
  Map<String, bool> cleaningTasks;
  bool isFinished;
  String finishNote;
  String finishedAt;

  RoomModel({
    required this.id,
    required this.roomNumber,
    this.guestStatus = 'Check-Out',
    this.checkInTime = '',
    this.checkOutTime = '',
    this.statusNote = '',
    required this.neededSupplies,
    required this.cleaningTasks,
    this.isFinished = false,
    this.finishNote = '',
    this.finishedAt = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomNumber': roomNumber,
        'guestStatus': guestStatus,
        'checkInTime': checkInTime,
        'checkOutTime': checkOutTime,
        'statusNote': statusNote,
        'neededSupplies': neededSupplies,
        'cleaningTasks': cleaningTasks,
        'isFinished': isFinished,
        'finishNote': finishNote,
        'finishedAt': finishedAt,
      };

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      guestStatus: json['guestStatus'] ?? 'Check-Out',
      checkInTime: json['checkInTime'] ?? '',
      checkOutTime: json['checkOutTime'] ?? '',
      statusNote: json['statusNote'] ?? '',
      neededSupplies: Map<String, int>.from(json['neededSupplies'] ?? {}),
      cleaningTasks: Map<String, bool>.from(json['cleaningTasks'] ?? {}),
      isFinished: json['isFinished'] ?? false,
      finishNote: json['finishNote'] ?? '',
      finishedAt: json['finishedAt'] ?? '',
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> supplyMasterList = [
    'Coffee Packet',
    'Tea Bag',
    'Sugar Packet',
    'Paper Serviette (පේපර් සවියට්)',
    'Toilet Paper',
    'Shampoo',
    'Soap (සබන්)',
    'Towel (තුවා)',
    'Bath Mat (පාපිසි)',
    'Pillows (කොට්ට)',
    'Bed Sheet (ඇඳ ෂීට්)',
    'Duvet Cover',
  ];

  List<String> taskMasterList = [
    'Room එක අතුගාන එක',
    'Room එක Mop කරන එක',
    'Bathroom Mop කරන එක',
  ];

  List<RoomModel> rooms = [];
  bool isTotalExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSupplies = prefs.getStringList('supplyMasterList');
    final savedTasks = prefs.getStringList('taskMasterList');
    final savedRooms = prefs.getString('roomsData');

    setState(() {
      if (savedSupplies != null && savedSupplies.isNotEmpty) {
        supplyMasterList = savedSupplies;
      }
      if (savedTasks != null && savedTasks.isNotEmpty) {
        taskMasterList = savedTasks;
      }
      if (savedRooms != null) {
        final List<dynamic> decoded = jsonDecode(savedRooms);
        rooms = decoded.map((e) => RoomModel.fromJson(e)).toList();
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('supplyMasterList', supplyMasterList);
    await prefs.setStringList('taskMasterList', taskMasterList);
    final encodedRooms = jsonEncode(rooms.map((e) => e.toJson()).toList());
    await prefs.setString('roomsData', encodedRooms);
  }

  String _formatNow() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final min = now.minute.toString().padLeft(2, '0');
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} $hour:$min $amPm';
  }

  Map<String, int> _calculateGrandTotals() {
    final Map<String, int> totals = {};
    for (var item in supplyMasterList) {
      totals[item] = 0;
    }
    for (var room in rooms) {
      if (!room.isFinished) {
        room.neededSupplies.forEach((key, qty) {
          if (qty > 0) {
            totals[key] = (totals[key] ?? 0) + qty;
          }
        });
      }
    }
    return totals;
  }

  void _addNewRoomDialog() {
    final roomController = TextEditingController();
    final noteController = TextEditingController();
    String selectedStatus = 'Check-Out';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('අලුත් Room එකක් එකතු කරන්න'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(
                    labelText: 'Room අංකය / නම (උදා: 101, Deluxe 2)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Room Status එක',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Check-Out', child: Text('Check-Out (හදන්න තියෙන)')),
                    DropdownMenuItem(value: 'Check-In', child: Text('Check-In (Guest ඉන්නවා)')),
                    DropdownMenuItem(value: 'Vacant', child: Text('Vacant (හිස් කාමරයක්)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Check-in / Check-out Note එකක් (අවශ්‍ය නම්)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (roomController.text.trim().isEmpty) return;
                final newRoom = RoomModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  roomNumber: roomController.text.trim(),
                  guestStatus: selectedStatus,
                  checkInTime: selectedStatus == 'Check-In' ? _formatNow() : '',
                  checkOutTime: selectedStatus == 'Check-Out' ? _formatNow() : '',
                  statusNote: noteController.text.trim(),
                  neededSupplies: {for (var item in supplyMasterList) item: 0},
                  cleaningTasks: {for (var task in taskMasterList) task: false},
                );
                setState(() {
                  rooms.insert(0, newRoom);
                });
                _saveData();
                Navigator.pop(context);
                _openRoomDetails(newRoom);
              },
              child: const Text('Add & Open Checklist'),
            ),
          ],
        ),
      ),
    );
  }

  void _addCustomMasterItemDialog() {
    final itemController = TextEditingController();
    bool isSupplyItem = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('අලුත් අඩුපාඩුවක් / වැඩක් ලැයිස්තුවට දාන්න'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemController,
                decoration: const InputDecoration(
                  labelText: 'නම (උදා: Water Bottle / ජනෙල් පිහදාන්න)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              RadioListTile<bool>(
                title: const Text('බඩුවක් (ගණන් කරන - Supply)'),
                value: true,
                groupValue: isSupplyItem,
                onChanged: (v) => setDialogState(() => isSupplyItem = v!),
              ),
              RadioListTile<bool>(
                title: const Text('පිරිසිදු කිරීමේ වැඩක් (Tick කරන - Task)'),
                value: false,
                groupValue: isSupplyItem,
                onChanged: (v) => setDialogState(() => isSupplyItem = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = itemController.text.trim();
                if (text.isEmpty) return;
                setState(() {
                  if (isSupplyItem) {
                    if (!supplyMasterList.contains(text)) {
                      supplyMasterList.add(text);
                      for (var r in rooms) {
                        r.neededSupplies[text] = 0;
                      }
                    }
                  } else {
                    if (!taskMasterList.contains(text)) {
                      taskMasterList.add(text);
                      for (var r in rooms) {
                        r.cleaningTasks[text] = false;
                      }
                    }
                  }
                });
                _saveData();
                Navigator.pop(context);
              },
              child: const Text('එකතු කරන්න'),
            ),
          ],
        ),
      ),
    );
  }

  void _openRoomDetails(RoomModel room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailScreen(
          room: room,
          supplyMasterList: supplyMasterList,
          taskMasterList: taskMasterList,
          onUpdate: () {
            setState(() {});
            _saveData();
          },
          onAddCustomItem: _addCustomMasterItemDialog,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grandTotals = _calculateGrandTotals();
    final activeTotals = grandTotals.entries.where((e) => e.value > 0).toList();
    final pendingRoomsCount = rooms.where((r) => !r.isFinished).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hotel Room & Stock Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F766E),
        actions: [
          IconButton(
            tooltip: 'අලුත් බඩුවක්/වැඩක් ලැයිස්තුවට දාන්න',
            icon: const Icon(Icons.playlist_add),
            onPressed: _addCustomMasterItemDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewRoomDialog,
        backgroundColor: const Color(0xFF14B8A6),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Room', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: rooms.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'තවම Rooms ඇතුළත් කරලා නැහැ.\nපහළ තියෙන "Add Room" බටන් එක ඔබලා පටන් ගන්න.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 85),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final neededCount = room.neededSupplies.values
                          .fold<int>(0, (sum, item) => sum + item);
                      final completedTasks = room.cleaningTasks.values
                          .where((done) => done)
                          .length;
                      final totalTasks = room.cleaningTasks.length;

                      Color badgeColor = Colors.orange;
                      if (room.guestStatus == 'Check-In') badgeColor = Colors.blue;
                      if (room.guestStatus == 'Vacant') badgeColor = Colors.grey;
                      if (room.isFinished) badgeColor = Colors.green;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: room.isFinished
                            ? const Color(0xFF142E28)
                            : const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: room.isFinished
                                ? Colors.green.withOpacity(0.5)
                                : Colors.white12,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openRoomDetails(room),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          room.isFinished
                                              ? Icons.check_circle
                                              : Icons.meeting_room,
                                          color: room.isFinished
                                              ? Colors.greenAccent
                                              : Colors.tealAccent,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Room ${room.roomNumber}',
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: badgeColor),
                                      ),
                                      child: Text(
                                        room.isFinished
                                            ? 'FINISHED ✓'
                                            : room.guestStatus,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: badgeColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      'අඩුපාඩු බඩු: $neededCount',
                                      style: const TextStyle(
                                          color: Colors.amberAccent,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Cleaning: $completedTasks/$totalTasks',
                                      style: const TextStyle(color: Colors.cyanAccent),
                                    ),
                                  ],
                                ),
                                if (room.checkInTime.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('Check-In: ${room.checkInTime}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.white70)),
                                  ),
                                if (room.checkOutTime.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text('Check-Out: ${room.checkOutTime}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.white70)),
                                  ),
                                if (room.statusNote.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('Note: ${room.statusNote}',
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.orangeAccent)),
                                  ),
                                if (room.isFinished && room.finishNote.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Finish Note (${room.finishedAt}): ${room.finishNote}',
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.greenAccent),
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          rooms.removeAt(index);
                                        });
                                        _saveData();
                                      },
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18, color: Colors.redAccent),
                                      label: const Text('Delete',
                                          style: TextStyle(color: Colors.redAccent)),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.tonalIcon(
                                      onPressed: () => _openRoomDetails(room),
                                      icon: const Icon(Icons.edit_note, size: 18),
                                      label: const Text('අඩුපාඩු / විස්තර'),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Bottom Grand Total Bar
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF091E1C),
              border: Border(top: BorderSide(color: Color(0xFF14B8A6), width: 2)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => setState(() => isTotalExpanded = !isTotalExpanded),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ගන්න තියෙන මුළු බඩු එකතුව (Pending Rooms: $pendingRoomsCount)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.tealAccent,
                        ),
                      ),
                      Icon(
                        isTotalExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: Colors.tealAccent,
                      ),
                    ],
                  ),
                ),
                if (isTotalExpanded) ...[
                  const SizedBox(height: 8),
                  activeTotals.isEmpty
                      ? const Text(
                          'දැනට කිසිම Room එකක අඩුපාඩු බඩු සටහන් කරලා නැහැ.',
                          style: TextStyle(fontSize: 13, color: Colors.white60),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: activeTotals.map((entry) {
                            return Chip(
                              backgroundColor: const Color(0xFF134E4A),
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                '${entry.key}: ${entry.value}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoomDetailScreen extends StatefulWidget {
  final RoomModel room;
  final List<String> supplyMasterList;
  final List<String> taskMasterList;
  final VoidCallback onUpdate;
  final VoidCallback onAddCustomItem;

  const RoomDetailScreen({
    super.key,
    required this.room,
    required this.supplyMasterList,
    required this.taskMasterList,
    required this.onUpdate,
    required this.onAddCustomItem,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late TextEditingController statusNoteController;
  late TextEditingController finishNoteController;

  @override
  void initState() {
    super.initState();
    statusNoteController = TextEditingController(text: widget.room.statusNote);
    finishNoteController = TextEditingController(text: widget.room.finishNote);
  }

  String _formatNow() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final min = now.minute.toString().padLeft(2, '0');
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} $hour:$min $amPm';
  }

  void _markFinishedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Room ${widget.room.roomNumber} වැඩේ ඉවරද?'),
        content: TextField(
          controller: finishNoteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Final Note (අවශ්‍ය නම් විතරක් ලියන්න)',
            hintText: 'උදා: බඩු ඔක්කොම දැම්මා, AC එක හොඳට වැඩ...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check_circle),
            onPressed: () {
              setState(() {
                widget.room.isFinished = true;
                widget.room.finishNote = finishNoteController.text.trim();
                widget.room.finishedAt = _formatNow();
              });
              widget.onUpdate();
              Navigator.pop(context);
            },
            label: const Text('ඔව්, Finish කරන්න'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;

    return Scaffold(
      appBar: AppBar(
        title: Text('Room ${room.roomNumber} විස්තර'),
        backgroundColor: const Color(0xFF0F766E),
        actions: [
          TextButton.icon(
            onPressed: () {
              widget.onAddCustomItem();
              setState(() {});
            },
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: const Text('අලුත් Item', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Check-in / Check-out Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Check-In / Check-Out සහ Notes',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.tealAccent),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              room.guestStatus = 'Check-In';
                              room.checkInTime = _formatNow();
                            });
                            widget.onUpdate();
                          },
                          icon: const Icon(Icons.login, color: Colors.lightBlueAccent),
                          label: const Text('Mark Check-In'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              room.guestStatus = 'Check-Out';
                              room.checkOutTime = _formatNow();
                              room.isFinished = false;
                            });
                            widget.onUpdate();
                          },
                          icon: const Icon(Icons.logout, color: Colors.orangeAccent),
                          label: const Text('Mark Check-Out'),
                        ),
                      ),
                    ],
                  ),
                  if (room.checkInTime.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Check-In වෙලාව: ${room.checkInTime}',
                          style: const TextStyle(color: Colors.lightBlueAccent)),
                    ),
                  if (room.checkOutTime.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Check-Out වෙලාව: ${room.checkOutTime}',
                          style: const TextStyle(color: Colors.orangeAccent)),
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: statusNoteController,
                    decoration: const InputDecoration(
                      labelText: 'Room Note (Check-in/out හෝ වෙනත් විස්තර)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      room.statusNote = val;
                      widget.onUpdate();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cleaning Tasks Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'පිරිසිදු කිරීමේ වැඩ (Cleaning Checklist)',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent),
                  ),
                  const SizedBox(height: 6),
                  ...widget.taskMasterList.map((task) {
                    final isDone = room.cleaningTasks[task] ?? false;
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        task,
                        style: TextStyle(
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Colors.greenAccent : Colors.white,
                        ),
                      ),
                      value: isDone,
                      onChanged: (val) {
                        setState(() {
                          room.cleaningTasks[task] = val ?? false;
                        });
                        widget.onUpdate();
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Supplies Checklist Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'අඩුපාඩු බඩු ලැයිස්තුව (ඕන ගාණ + කරන්න)',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent),
                  ),
                  const SizedBox(height: 8),
                  ...widget.supplyMasterList.map((supply) {
                    final count = room.neededSupplies[supply] ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: count > 0
                            ? const Color(0xFF134E4A)
                            : Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              supply,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: count > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: count > 0
                                    ? () {
                                        setState(() {
                                          room.neededSupplies[supply] = count - 1;
                                        });
                                        widget.onUpdate();
                                      }
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '$count',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    room.neededSupplies[supply] = count + 1;
                                  });
                                  widget.onUpdate();
                                },
                                icon: const Icon(Icons.add_circle,
                                    color: Colors.tealAccent),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Finish or Reopen Room Button
          if (!room.isFinished)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _markFinishedDialog,
              icon: const Icon(Icons.done_all),
              label: const Text(
                'Room එක හදලා ඉවරයි (Finish & Note)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          else
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✓ Completed at ${room.finishedAt}',
                        style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold),
                      ),
                      if (room.finishNote.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Note: ${room.finishNote}'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      room.isFinished = false;
                    });
                    widget.onUpdate();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('ආපහු Pending කරන්න (Re-open Room)'),
                ),
              ],
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
