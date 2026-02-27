import 'package:flutter/material.dart';
import 'package:forsee_demo_one/model/student_model.dart';
import 'package:forsee_demo_one/pages/teacher/create_marks_entry_page.dart';
import 'package:forsee_demo_one/pages/student/student_profile.dart';

class ClassroomPage extends StatefulWidget {
  final String classTitle;
  final String subject;
  final String semester;
  final String std;
  final int participants;

  const ClassroomPage({
    super.key,
    this.classTitle = 'Class 12-B',
    this.subject = 'Science',
    this.semester = 'Semester II',
    this.std = 'STD 12th',
    this.participants = 24,
  });

  @override
  State<ClassroomPage> createState() => _ClassroomPageState();
}

class _ClassroomPageState extends State<ClassroomPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _attendanceUploaded = false;

  // ── STUDENT DATA ───────────────────────────────────────────────────────────
  // In a real app you'd fetch this list from Firebase using the classTitle.
  // Each student carries their own name, ID, standard, phone, and risk level.
  late final List<Map<String, dynamic>> _allStudents = [
    {
      'student': StudentModel(
        name: 'Dhruv Rathee',
        studentId: '#01245',
        standard: widget.std,
        phone: '91+ 9375459378',
        className: widget.classTitle,
        subject: widget.subject,
        riskLevel: RiskLevel.high,
      ),
      'color': Colors.red,
      'present': false,
    },
    {
      'student': StudentModel(
        name: 'Sourav Joshi',
        studentId: '#01246',
        standard: widget.std,
        phone: '91+ 9812345678',
        className: widget.classTitle,
        subject: widget.subject,
        riskLevel: RiskLevel.high,
      ),
      'color': Colors.red,
      'present': false,
    },
    {
      'student': StudentModel(
        name: 'Dhinchak Pooja',
        studentId: '#01247',
        standard: widget.std,
        phone: '91+ 9988776655',
        className: widget.classTitle,
        subject: widget.subject,
        riskLevel: RiskLevel.medium,
      ),
      'color': Colors.orange,
      'present': null,
    },
    {
      'student': StudentModel(
        name: 'Nishchay Malhan',
        studentId: '#01248',
        standard: widget.std,
        phone: '91+ 9123456789',
        className: widget.classTitle,
        subject: widget.subject,
        riskLevel: RiskLevel.none,
      ),
      'color': Colors.green,
      'present': true,
    },
    {
      'student': StudentModel(
        name: 'Ashish Chanchlani',
        studentId: '#01249',
        standard: widget.std,
        phone: '91+ 9234567890',
        className: widget.classTitle,
        subject: widget.subject,
        riskLevel: RiskLevel.none,
      ),
      'color': Colors.green,
      'present': true,
    },
    {
      'student': StudentModel(
        name: 'CarryMinati',
        studentId: '#01250',
        standard: widget.std,
        phone: '91+ 9345678901',
        className: widget.classTitle,
        subject: widget.subject,
        riskLevel: RiskLevel.medium,
      ),
      'color': Colors.orange,
      'present': null,
    },
    {
      'student': StudentModel(
        name: 'Triggered Insaan',
        studentId: '#01251',
        standard: widget.std,
        phone: '91+ 9456789012',
        className: widget.classTitle,
        subject: widget.subject,
        riskLevel: RiskLevel.none,
      ),
      'color': Colors.green,
      'present': true,
    },
    {
      'student': StudentModel(
        name: 'Tanmay Bhat',
        studentId: '#01252',
        standard: widget.std,
        phone: '91+ 9567890123',
        className: widget.classTitle,
        subject: widget.subject,
        riskLevel: RiskLevel.high,
      ),
      'color': Colors.red,
      'present': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return _allStudents;
    return _allStudents.where((s) {
      final student = s['student'] as StudentModel;
      return student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.studentId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── ATTENDANCE ─────────────────────────────────────────────────────────────

  void _showAttendanceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF3B2028),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Attendance',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Pridi'),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.classTitle}  •  ${widget.subject}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _attendanceOption(icon: Icons.camera_alt, label: 'Scan via Camera', subtitle: 'Use camera to auto-detect attendance', onTap: () { Navigator.pop(context); _confirmAttendanceUpload('Camera'); }),
            const SizedBox(height: 12),
            _attendanceOption(icon: Icons.upload_file, label: 'Upload CSV File', subtitle: 'Import attendance from a .csv file', onTap: () { Navigator.pop(context); _confirmAttendanceUpload('CSV'); }),
            const SizedBox(height: 12),
            _attendanceOption(icon: Icons.edit_note, label: 'Mark Manually', subtitle: 'Tap each student to mark present / absent', onTap: () { Navigator.pop(context); _showManualAttendance(); }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _attendanceOption({required IconData icon, required String label, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF4A3439), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: const Color(0xFFE9C2D7), radius: 20, child: Icon(icon, color: const Color(0xFF512D38), size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'Pridi', fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ])),
            const Icon(Icons.chevron_right, color: Colors.white30),
          ],
        ),
      ),
    );
  }

  void _confirmAttendanceUpload(String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$method attendance uploaded for ${widget.classTitle}!', style: const TextStyle(fontFamily: 'Pridi')),
        backgroundColor: const Color(0xFF512D38),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    setState(() => _attendanceUploaded = true);
  }

  void _showManualAttendance() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.5,
            builder: (_, scrollController) {
              return Container(
                decoration: const BoxDecoration(color: Color(0xFF3B2028), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Align(alignment: Alignment.centerLeft, child: Text('Mark Attendance', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Pridi')))),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _allStudents.length,
                        itemBuilder: (_, i) {
                          final student = _allStudents[i]['student'] as StudentModel;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: const Color(0xFF4A3439), borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: const Color(0xFFE9C2D7), child: Text(student.initial, style: const TextStyle(color: Color(0xFF512D38), fontWeight: FontWeight.bold))),
                              title: Text(student.name, style: const TextStyle(color: Colors.white, fontFamily: 'Pridi', fontSize: 14)),
                              subtitle: Text(student.studentId, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _attendancePill('P', Colors.green, _allStudents[i]['present'] == true, () { setState(() => _allStudents[i]['present'] = true); setSheetState(() {}); }),
                                  const SizedBox(width: 6),
                                  _attendancePill('A', Colors.red, _allStudents[i]['present'] == false, () { setState(() => _allStudents[i]['present'] = false); setSheetState(() {}); }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: GestureDetector(
                        onTap: () { Navigator.pop(context); _confirmAttendanceUpload('Manual'); },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(color: const Color(0xFFE9C2D7), borderRadius: BorderRadius.circular(28)),
                          child: const Center(child: Text('Submit Attendance', style: TextStyle(fontFamily: 'Pridi', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF512D38)))),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  Widget _attendancePill(String label, Color color, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 28,
        decoration: BoxDecoration(color: selected ? color : color.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color, width: 1)),
        child: Center(child: Text(label, style: TextStyle(color: selected ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.bold))),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final filtered = _filteredStudents;

    return Scaffold(
      backgroundColor: const Color(0xFF3B2F2F),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── HEADER ────────────────────────────────────────────────────
            Stack(
              children: [
                Image.asset('assets/imagesfor4see/Ellipse 17.png', width: screenWidth, fit: BoxFit.fill),
                Positioned(
                  top: 40, left: 10,
                  child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22), onPressed: () => Navigator.pop(context)),
                ),
                Positioned(
                  top: 48, left: 50, right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(widget.subject, style: const TextStyle(fontSize: 48, color: Colors.white, fontFamily: 'Pridi')),
                          const Spacer(),
                          Text(widget.std, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(widget.semester, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                      const SizedBox(height: 10),
                      RichText(text: TextSpan(style: const TextStyle(color: Color(0xFF3B2F2F), fontSize: 17), children: [
                        const TextSpan(text: 'No . of Participants '),
                        TextSpan(text: '${widget.participants}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
                      ])),
                    ],
                  ),
                ),
                if (_attendanceUploaded)
                  Positioned(
                    top: 44, right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle, size: 14, color: Color(0xFF1B5E20)),
                        SizedBox(width: 4),
                        Text('Attendance Done', style: TextStyle(fontSize: 11, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
              ],
            ),

            // ── ACTIONS ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _actionButton('Upload Attendance'),
                  const SizedBox(height: 10),
                  _searchBar(),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── STUDENT LIST ──────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No students found', style: TextStyle(color: Colors.white54, fontSize: 15)))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final student = filtered[index]['student'] as StudentModel;
                  final statusColor = filtered[index]['color'] as Color;
                  return GestureDetector(
                    onTap: () {
                      // ✅ Pass the full StudentModel — no more hardcoded names
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentProfilePage(student: student),
                        ),
                      );
                    },
                    child: StudentListItem(name: student.name, statusColor: statusColor),
                  );
                },
              ),
            ),

            // ── BOTTOM BUTTON ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: _actionButton('Upload Marks'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(color: const Color(0xFFF4D2DE), borderRadius: BorderRadius.circular(28)),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search Student',
          hintStyle: const TextStyle(color: Colors.black45),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(onTap: () { _searchController.clear(); setState(() => _searchQuery = ''); }, child: const Icon(Icons.close, color: Colors.black45, size: 18))
              : Padding(padding: const EdgeInsets.all(12), child: Image.asset('assets/imagesfor4see/Trailing-Elements.png')),
        ),
      ),
    );
  }

  Widget _actionButton(String title) {
    return GestureDetector(
      onTap: () {
        if (title == 'Upload Marks') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateMarksEntryPage()));
        } else if (title == 'Upload Attendance') {
          _showAttendanceOptions();
        }
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: const Color(0xFFF4BFDB), borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: [
            if (title == 'Upload Marks') ...[const Icon(Icons.add, color: Color(0xFF3B2F2F), size: 22), const SizedBox(width: 8)],
            Text(title, style: const TextStyle(fontSize: 18, fontFamily: 'Pridi')),
            const Spacer(),
            _icon('assets/imagesfor4see/mingcute_camera-fill.png', true),
            const SizedBox(width: 10),
            _icon('assets/imagesfor4see/bi_filetype-csv.png', false),
          ],
        ),
      ),
    );
  }

  Widget _icon(String asset, bool isWhite) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: const BoxDecoration(color: Color(0xFF512D38), shape: BoxShape.circle),
      child: Image.asset(asset, height: 20, color: isWhite ? Colors.white : null),
    );
  }
}

// ── STUDENT LIST ITEM ──────────────────────────────────────────────────────

class StudentListItem extends StatelessWidget {
  final String name;
  final Color statusColor;

  const StudentListItem({super.key, required this.name, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: const Color(0xFFF4BFDB), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD4AF37), width: 1)),
      child: Column(
        children: [
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Image.asset('assets/imagesfor4see/account_circle.png', height: 22),
            title: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            trailing: Image.asset('assets/imagesfor4see/Arrow right.png', height: 16),
          ),
          Container(height: 6, margin: const EdgeInsets.fromLTRB(14, 0, 14, 10), decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8))),
        ],
      ),
    );
  }
}