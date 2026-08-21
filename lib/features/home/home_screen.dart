import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/components/mascot/mascot_widget.dart';
import '../../core/components/mascot/mascot_assets.dart';
import '../class_mode/screens/class_mode_screen.dart';
import '../games/screens/games_menu_screen.dart';
import '../games/screens/cronometro_screen.dart';
import '../ai_planner/screens/ai_planner_screen.dart';
import '../students/screens/chamada_screen.dart';
import '../teacher_preparation/screens/teacher_preparation_screen.dart';
import 'admin_screen.dart';
import 'widgets/hero_action_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/screens/login_screen.dart';
import '../ai_planner/models/lesson_plan.dart';
import '../../core/db/database_helper.dart';
import '../../core/design_system/colors.dart';
import '../../core/design_system/typography.dart';
import '../../core/design_system/elevation.dart';
import '../../core/design_system/radius.dart';
import '../../core/design_system/spacing.dart';
import '../../core/components/image_helper.dart';
import '../../core/theme/app_colors.dart';

/// Tela Principal com Navegação Reativa e Dashboard Premium Fiel ao Estilo Apple
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _classModeRevision = 0;
  late Future<List<LessonPlan>> _lessonPlansFuture;

  @override
  void initState() {
    super.initState();
    _lessonPlansFuture = DatabaseHelper.instance.fetchAllLessonPlans();
  }

  void refreshLessonPlans() {
    setState(() {
      _lessonPlansFuture = DatabaseHelper.instance.fetchAllLessonPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DsColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardContent(
            lessonPlansFuture: _lessonPlansFuture,
            onRefresh: refreshLessonPlans,
            onSwitchTab: (index) {
              setState(() {
                _currentIndex = index;
                if (index == 1) {
                  _classModeRevision++;
                }
              });
            },
          ), // 0: Início
          ClassModeScreen(key: ValueKey(_classModeRevision)),           // 1: Aulas
          const GamesMenuScreen(),           // 2: Atividades / Jogos
          const AiPlannerScreen(),           // 3: Crianças / IA
          const AdminScreen(),               // 4: Configurações / Admin
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: DsColors.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60, // Ajustado de 56 para dar melhor conforto visual e área de toque
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home_rounded, label: 'Início', index: 0),
              _buildNavItem(icon: Icons.menu_book_rounded, label: 'Aulas', index: 1),
              _buildNavItem(icon: Icons.celebration_rounded, label: 'Atividades', index: 2),
              _buildNavItem(icon: Icons.auto_awesome_rounded, label: 'Planejar', index: 3),
              _buildNavItem(icon: Icons.settings_rounded, label: 'Ajustes', index: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = _currentIndex == index;
    final Color activeColor = DsColors.primaryBlue;
    final Color inactiveColor = DsColors.textDisabled;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              transform: Matrix4.identity()..scale(isActive ? 1.1 : 1.0),
              child: Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CONTEÚDO PRINCIPAL DA DASHBOARD (PREMIUM) ---
class DashboardContent extends StatefulWidget {
  final Future<List<LessonPlan>> lessonPlansFuture;
  final VoidCallback onRefresh;
  final ValueChanged<int> onSwitchTab;

  const DashboardContent({
    super.key,
    required this.lessonPlansFuture,
    required this.onRefresh,
    required this.onSwitchTab,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  Future<Map<String, dynamic>> _fetchMuraisData() async {
    final prefs = await SharedPreferences.getInstance();
    final prayers = prefs.getStringList('prayer_requests') ?? [];

    final students = await DatabaseHelper.instance.fetchAllStudents();
    final presentIds = prefs.getStringList('present_student_ids') ?? [];
    final allIds = students.map((e) => e.id.toString()).toSet();
    final actualPresentIds = presentIds.where((id) => allIds.contains(id)).toSet();

    // Absent students
    final absents = students.where((s) => !actualPresentIds.contains(s.id.toString())).toList();

    // Birthdays this week (or month)
    final now = DateTime.now();
    final currentMonthStr = now.month.toString().padLeft(2, '0');
    final birthdays = students.where((s) {
      if (s.birthDate == null || s.birthDate!.isEmpty) return false;
      final parts = s.birthDate!.split('/');
      if (parts.length >= 2) {
        return parts[1] == currentMonthStr;
      }
      return false;
    }).toList();

    return {
      'prayers': prayers,
      'absents': absents,
      'birthdays': birthdays,
    };
  }

  void _showAddPrayerDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Registrar Pedido de Oração 🙏', style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Digite o pedido de oração...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar', style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFF64748B))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isNotEmpty) {
                        final prefs = await SharedPreferences.getInstance();
                        final list = prefs.getStringList('prayer_requests') ?? [];
                        list.add(text);
                        await prefs.setStringList('prayer_requests', list);
                        if (mounted) setState(() {});
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulCeleste,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Registrar', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return _buildDashboardBody(context, 'Admin', '');
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        String name = 'Professor';
        String fotoUrl = '';
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['nome'] ?? 'Professor';
          fotoUrl = data['fotoUrl'] ?? '';
        }
        return _buildDashboardBody(context, name, fotoUrl);
      },
    );
  }

  Widget _buildDashboardBody(BuildContext context, String userName, String fotoUrl) {
    return Stack(
      children: [
        // 1. Formas Orgânicas Pastel de Fundo com Blur
        _buildPastelBackground(),

        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeArea(bottom: false, child: _buildHeader(context, userName, fotoUrl)),
              const SizedBox(height: 12),
              
              // Hero Card: Boas-Vindas + Mascot
              _buildWelcomeHeroCard(userName),
              const SizedBox(height: 16),

              // HeroActionCard Unificado (Hoje na Aula + Versículo + Ação)
              _buildHeroActionCard(context),
              const SizedBox(height: 16),

              // Grid de 2 Colunas: Turma de Hoje e Próxima Atividade
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildClassTodayCard(context)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildNextActivityCard(context)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Murais Auxiliares
              const Text(
                'Mural da Salinha 📌',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              FutureBuilder<Map<String, dynamic>>(
                future: _fetchMuraisData(),
                builder: (context, snapshot) {
                  final data = snapshot.data ?? {'prayers': <String>[], 'absents': [], 'birthdays': []};
                  final List<String> prayers = List<String>.from(data['prayers']);
                  final List absents = data['absents'];
                  final List birthdays = data['birthdays'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Mural de Aniversariantes
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: DsRadius.large,
                          border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
                          boxShadow: _floatingShadow(),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.cake_rounded, color: Colors.purpleAccent, size: 18),
                                SizedBox(width: 6),
                                Text('Aniversariantes', style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (birthdays.isEmpty)
                              Row(
                                children: const [
                                  Text('🎂', style: TextStyle(fontSize: 14)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Nenhum aniversariante esta semana 🎂',
                                      style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: birthdays.map((s) => Chip(
                                  label: Text('${s.name} (${s.birthDate?.substring(0, 5)})', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 11, color: Color(0xFF7E22CE))),
                                  backgroundColor: const Color(0xFFF3E8FF),
                                  side: BorderSide.none,
                                  padding: EdgeInsets.zero,
                                )).toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. Mural de Pedidos de Oração
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: DsRadius.large,
                          border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
                          boxShadow: _floatingShadow(),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
                                    SizedBox(width: 6),
                                    Text('Pedidos de Oração', style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  ],
                                ),
                                if (prayers.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.azulCeleste, size: 20),
                                    onPressed: () => _showAddPrayerDialog(context),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (prayers.isEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Nenhum pedido cadastrado', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showAddPrayerDialog(context),
                                      icon: const Icon(Icons.add_rounded, size: 16),
                                      label: const Text('Registrar Oração', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.azulCeleste,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: prayers.length,
                                itemBuilder: (context, i) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.lens, size: 6, color: Colors.redAccent),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            prayers[i],
                                            style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.grey),
                                          onPressed: () async {
                                            final prefs = await SharedPreferences.getInstance();
                                            prayers.removeAt(i);
                                            await prefs.setStringList('prayer_requests', prayers);
                                            setState(() {});
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Mural de Ausências
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: DsRadius.large,
                          border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
                          boxShadow: _floatingShadow(),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.flag_rounded, color: Colors.orangeAccent, size: 18),
                                SizedBox(width: 6),
                                Text('Ausências / Faltas', style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (absents.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: const [
                                    Text('🎉', style: TextStyle(fontSize: 14)),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Toda a turma presente! 🎉',
                                        style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: Color(0xFF047857), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${absents.length} alunos ausentes hoje:',
                                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: absents.map((s) => Chip(
                                      label: Text(s.name, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 11, color: Color(0xFFC2410C))),
                                      backgroundColor: const Color(0xFFFFE5D9),
                                      side: BorderSide.none,
                                      padding: EdgeInsets.zero,
                                    )).toList(),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // --- BACKGROUND COM MANCHAS PASTEL SUAVES ---
  Widget _buildPastelBackground() {
    return Stack(
      children: [
        Positioned(
          top: -40,
          left: -40,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF08A).withOpacity(0.18), // Suave
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 80,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE).withOpacity(0.22), // Suave
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -50,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFC7F4C2).withOpacity(0.15), // Suave
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: -20,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF).withOpacity(0.18), // Suave
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
      ],
    );
  }

  void _showProfileOptionsDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoController = TextEditingController();
    
    if (user != null) {
      FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get().then((doc) {
        if (doc.exists) {
          photoController.text = (doc.data() as Map<String, dynamic>)['fotoUrl'] ?? '';
        }
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setStateModal) {
                final previewUrl = photoController.text.trim();
                final hasValidPreview = previewUrl.isNotEmpty && previewUrl.startsWith('http');
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho
                    const Text(
                      'Opções de Perfil 👤',
                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Atualize sua foto de perfil ou gerencie sua conta.',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    
                    // Seção de Perfil
                    const Text(
                      'Perfil do Professor',
                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 10),
                    
                    // Box de Visualização
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(color: DsColors.primaryBlue.withOpacity(0.3), width: 2.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: hasValidPreview
                              ? Image.network(
                                  ImageHelper.getProxiedImageUrl(previewUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 32),
                                )
                              : const Icon(Icons.person_rounded, color: Colors.grey, size: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (user != null) ...[
                      TextField(
                        controller: photoController,
                        onChanged: (val) => setStateModal(() {}),
                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Link da Foto de Perfil',
                          labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                          hintText: 'Cole a URL da imagem aqui',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.link_rounded, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    const Divider(),
                    const SizedBox(height: 12),
                    
                    // Seção de Conta
                    const Text(
                      'Gerenciamento de Conta',
                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100.withOpacity(0.6)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Sair da Conta',
                              style: TextStyle(fontFamily: 'Fredoka', color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Spacer(),
                            Icon(Icons.chevron_right_rounded, color: Colors.redAccent, size: 18),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botões de Ação Horizontalmente Alinhados
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar', style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFF64748B))),
                        ),
                        const SizedBox(width: 8),
                        if (user != null)
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
                                'fotoUrl': photoController.text.trim(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DsColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Salvar Foto', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _getDirectImageUrl(String url) {
    return ImageHelper.getProxiedImageUrl(url);
  }

  // --- HEADER SUPERIOR ---
  Widget _buildHeader(BuildContext context, String userName, String fotoUrl) {
    final firstName = userName.split(' ').first;
    final directUrl = _getDirectImageUrl(fotoUrl);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _showProfileOptionsDialog(context),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: _softShadow(),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: directUrl.isNotEmpty
                      ? Image.network(
                          directUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.person_rounded,
                            color: Color(0xFF94A3B8),
                            size: 24,
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF94A3B8),
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Olá, professor(a)',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    firstName,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DsColors.primaryBlue.withOpacity(0.1), width: 1.5),
            boxShadow: _softShadow(),
          ),
          child: const Text(
            'CME Infantil 🇨🇭',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3B82F6),
            ),
          ),
        ),
      ],
    );
  }

  // --- CARD BOAS-VINDAS COM MASCOTE GIGANTE ---
  Widget _buildWelcomeHeroCard(String userName) {
    final firstName = userName.split(' ').first;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 130, 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: DsRadius.large,
            border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
            boxShadow: _floatingShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bom dia,\n$firstName!',
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 24,
                  height: 1.1,
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tudo pronto para a salinha hoje?',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 5,
          bottom: -8,
          child: const MascotWidget(
            pose: MascotPose.front,
            height: 155,
            width: 125,
          ),
        ),
      ],
    );
  }

  // --- HERO ACTION CARD UNIFICADO ---
  Widget _buildHeroActionCard(BuildContext context) {
    return FutureBuilder<List<LessonPlan>>(
      future: widget.lessonPlansFuture,
      builder: (context, snapshot) {
        final planList = snapshot.data;
        final hasPlan = planList != null && planList.isNotEmpty;
        final latestPlan = hasPlan ? planList.first : null;
        
        final title = latestPlan != null ? latestPlan.title : 'Nenhuma aula ativa';
        final verse = latestPlan != null ? latestPlan.keyVerse : 'Seja forte e corajoso! Não se apavore, nem desanime...';

        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, prefsSnapshot) {
            bool chamadaConcluida = false;
            if (prefsSnapshot.hasData && prefsSnapshot.data != null) {
              final presentIds = prefsSnapshot.data!.getStringList('present_student_ids') ?? [];
              chamadaConcluida = presentIds.isNotEmpty;
            }

            final badgeText = chamadaConcluida 
                ? 'Aula pronta para começar!' 
                : 'Aguardando chamada de hoje';
            final badgeColor = chamadaConcluida 
                ? const Color(0xFF10B981) 
                : const Color(0xFFF59E0B);
            final actionType = chamadaConcluida 
                ? HeroActionType.startClass 
                : HeroActionType.startAttendance;

            return HeroActionCard(
              title: title,
              verse: verse,
              badgeText: badgeText,
              badgeColor: badgeColor,
              actionType: actionType,
              onActionPressed: () {
                if (!chamadaConcluida) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChamadaScreen()),
                  );
                } else {
                  if (latestPlan != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherPreparationScreen(
                          plan: latestPlan,
                          onStartClass: () {
                            widget.onSwitchTab(1); // Mudar aba para Modo Aula (tab index 1)
                          },
                        ),
                      ),
                    );
                  } else {
                    widget.onSwitchTab(1);
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  // --- CARD TURMA DE HOJE ---
  Widget _buildClassTodayCard(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchClassTodayData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'teachers': 0, 'students': 0, 'present': 0};
        
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChamadaScreen())),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE2F7ED).withOpacity(0.95),
              borderRadius: DsRadius.large,
              border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
              boxShadow: _floatingShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.people_alt_rounded, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Turma de Hoje',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow('Professores', '${data['teachers']}'),
                    const SizedBox(height: 4),
                    _buildStatRow('Alunos', '${data['students']}'),
                    const SizedBox(height: 4),
                    _buildStatRow('Presentes', '${data['present']} de ${data['students']}'),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34D399), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: DsElevation.glow(const Color(0xFF10B981)),
                  ),
                  child: const Text(
                    'Abrir Chamada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 12,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<Map<String, int>> _fetchClassTodayData() async {
    int teachersCount = 0;
    try {
      final query = await FirebaseFirestore.instance.collection('usuarios').count().get();
      teachersCount = query.count ?? 0;
    } catch (_) {
      // Ignora erro se nÃ£o conseguir buscar (ex: offline)
    }

    int studentsCount = 0;
    int presentCount = 0;
    try {
      final students = await DatabaseHelper.instance.fetchAllStudents();
      studentsCount = students.length;

      final prefs = await SharedPreferences.getInstance();
      final presentIds = prefs.getStringList('present_student_ids') ?? [];
      
      // Conta apenas os presentes que ainda existem na lista de alunos (evita contar alunos excluÃ­dos)
      final allIds = students.map((e) => e.id.toString()).toSet();
      presentCount = presentIds.where((id) => allIds.contains(id)).length;
    } catch (_) {}

    return {
      'teachers': teachersCount,
      'students': studentsCount,
      'present': presentCount,
    };
  }

  // --- CARD PRÓXIMA ATIVIDADE ---
  Widget _buildNextActivityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE3CE).withOpacity(0.95),
        borderRadius: DsRadius.large,
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
        boxShadow: _floatingShadow(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Central de Jogos & Dinâmicas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _floatingShadow(),
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: Color(0xFFFF8C00),
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acesse a arena com quizzes, roleta, equipes e dinâmicas interativas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesMenuScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: DsColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              elevation: 0,
            ),
            child: const Text(
              'Abrir Central de Jogos',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }



  List<BoxShadow> _softShadow() => DsElevation.subtle;
  List<BoxShadow> _floatingShadow() => DsElevation.floatCard;
}
