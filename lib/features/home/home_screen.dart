import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/components/mascot/mascot_widget.dart';
import '../../core/components/mascot/mascot_assets.dart';
import '../class_mode/screens/class_mode_screen.dart';
import '../games/screens/games_menu_screen.dart';
import '../games/screens/cronometro_screen.dart';
import '../ai_planner/screens/ai_planner_screen.dart';
import 'admin_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/screens/login_screen.dart';
import '../ai_planner/models/lesson_plan.dart';
import '../../core/db/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/components/image_helper.dart';

/// Tela Principal com Navegação Reativa e Dashboard Premium Fiel ao Estilo Apple
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Telas vinculadas a cada uma das 5 abas
  final List<Widget> _screens = [
    const DashboardContent(),          // 0: Início
    const ClassModeScreen(),           // 1: Aulas
    const GamesMenuScreen(),           // 2: Atividades / Jogos
    const AiPlannerScreen(),           // 3: Crianças / IA
    const AdminScreen(),               // 4: Configurações / Admin
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- BARRA DE NAVEGAÇÃO INFERIOR ESTILO IMAGEM 2 ---
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
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
    final Color activeColor = const Color(0xFF3B82F6);
    final Color inactiveColor = const Color(0xFF94A3B8);

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
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CONTEÚDO PRINCIPAL DA DASHBOARD (PREMIUM) ---
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      // É o admin (login via admin/admin2026 manual)
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

        // 2. Conteúdo com Rolar
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, userName, fotoUrl),
                const SizedBox(height: 12),
                
                // Hero Card: Boas-Vindas + Mascot
                _buildWelcomeHeroCard(userName),
                const SizedBox(height: 12),

                // Card "Hoje na Aula"
                _buildTodayClassCard(context),
                const SizedBox(height: 12),

                // Grid de 2 Colunas: Cronômetro e Próxima Atividade
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTimerCard(context)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildNextActivityCard(context)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildVerseCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- BACKGROUND COM MANCHAS PASTEL (PREMIUM LIGHT LEAKS) ---
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
              color: const Color(0xFFFEF08A).withOpacity(0.55),
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
              color: const Color(0xFFE0F2FE).withOpacity(0.7),
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
              color: const Color(0xFFC7F4C2).withOpacity(0.5), // Verde pastel
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
              color: const Color(0xFFF3E8FF).withOpacity(0.6), // Roxo
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Opções de Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user != null) ...[
              const Text('Link da Foto de Perfil:'),
              const SizedBox(height: 8),
              TextField(
                controller: photoController,
                decoration: const InputDecoration(
                  hintText: 'https://exemplo.com/foto.jpg',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              const Text('Conectado como Administrador.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Sair da Conta', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              contentPadding: EdgeInsets.zero,
              onTap: () async {
                Navigator.pop(ctx); // fecha modal
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
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          if (user != null)
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
                  'fotoUrl': photoController.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Salvar Foto'),
            )
        ],
      )
    );
  }

  String _getDirectImageUrl(String url) {
    return ImageHelper.getProxiedImageUrl(url);
  }

  // --- HEADER SUPERIOR ---
  Widget _buildHeader(BuildContext context, String userName, String fotoUrl) {
    // Pegar o primeiro nome
    final firstName = userName.split(' ').first;
    final directUrl = _getDirectImageUrl(fotoUrl);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 48), // Espaçamento compensatório
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.15), width: 1.5),
            boxShadow: _softShadow(),
          ),
          child: const Text(
            'CME Infantil',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3B82F6),
            ),
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => _showProfileOptionsDialog(context),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: _softShadow(),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: directUrl.isNotEmpty
                          ? Image.network(
                              directUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Icon(
                                Icons.person,
                                color: Color(0xFF94A3B8),
                                size: 24,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Color(0xFF94A3B8),
                              size: 24,
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    firstName,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  )
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  // --- CARD BOAS-VINDAS COM MASCOTE GIGANTE ---
  Widget _buildWelcomeHeroCard(String userName) {
    final firstName = userName.split(' ').first;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Card de fundo compacto
        Container(
          width: double.infinity,
          height: 125, // Altura bem reduzida do card
          padding: const EdgeInsets.fromLTRB(20, 16, 130, 16), // Espaço reservado para a ovelha à direita
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
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
              const SizedBox(height: 4),
              const Text(
                'Bem-vindos CME Suíça',
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
        // Ovelha em cima saindo do card (Efeito Pop-out)
        Positioned(
          right: 5,
          bottom: -10, // Transborda ligeiramente para baixo para dar efeito premium
          child: Image.asset(
            'assets/mascot/poses/front.png',
            height: 165, // Mantém a ovelha grande como solicitado
            width: 130,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.pets_rounded,
              size: 50,
              color: Color(0xFF93C5FD),
            ),
          ),
        ),
      ],
    );
  }

  // --- CARD HOJE NA AULA ---
  Widget _buildTodayClassCard(BuildContext context) {
    return FutureBuilder<List<LessonPlan>>(
      future: DatabaseHelper.instance.fetchAllLessonPlans(),
      builder: (context, snapshot) {
        final planList = snapshot.data;
        final hasPlan = planList != null && planList.isNotEmpty;
        final latestPlan = hasPlan ? planList.first : null;
        
        final title = latestPlan != null ? latestPlan.title : 'Nenhuma aula ativa';
        final subtitle = latestPlan != null ? 'Versículo: ${latestPlan.keyVerse}' : 'Inicie uma aula para ver aqui';
        final status = latestPlan != null ? 'Ativa' : 'Aguardando';
        final statusColor = latestPlan != null ? AppColors.verdePasto : const Color(0xFF0F172A);
        final icon = latestPlan != null ? Icons.auto_awesome : Icons.event_busy_rounded;
        final iconColor = latestPlan != null ? AppColors.azulCeleste : const Color(0xFF94A3B8);

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassModeScreen())),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD7E7FC).withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
              boxShadow: _floatingShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hoje na Aula',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: 28,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 1,
                  color: const Color(0xFF94A3B8).withOpacity(0.15),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Status: ',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // --- CARD CRONÔMETRO ---
  Widget _buildTimerCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CronometroScreen())),
      child: Container(
      height: 190, // Reduzido de 230
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F7ED).withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
        boxShadow: _floatingShadow(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Alinhamento distribuído
        children: [
          const Text(
            'Cronômetro',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60, // Reduzido de 72
                child: CircularProgressIndicator(
                  value: 0.0,
                  strokeWidth: 5,
                  backgroundColor: Colors.white,
                  color: const Color(0xFF3B82F6),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    '00:00',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '--:--',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 9,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Text(
            'Nenhum tempo rodando',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32, // Reduzido de 36
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Container(
                width: 32,
                height: 32, // Reduzido de 36
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: _floatingShadow(),
                ),
                child: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8), size: 16),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  // --- CARD PRÓXIMA ATIVIDADE ---
  Widget _buildNextActivityCard(BuildContext context) {
    return Container(
      height: 190, // Reduzido de 230
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE3CE).withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
        boxShadow: _floatingShadow(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Alinhamento distribuído
        children: [
          const Text(
            'Próxima Atividade',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8), // Reduzido de 10
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(14),
              boxShadow: _floatingShadow(),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF8B5CF6),
              size: 24, // Reduzido de 28
            ),
          ),
          Column(
            children: const [
              Text(
                'Nenhuma Agendada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Para hoje',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesMenuScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B67F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 2,
              shadowColor: const Color(0xFF5B67F6).withOpacity(0.2),
            ),
            child: const Text(
              'Iniciar Atividade',
              style: TextStyle(
                fontFamily: 'Nunito',
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

  // --- CARD VERSÍCULO DO DIA PREMIUM ---
  Widget _buildVerseCard() {
    return FutureBuilder<List<LessonPlan>>(
      future: DatabaseHelper.instance.fetchAllLessonPlans(),
      builder: (context, snapshot) {
        final planList = snapshot.data;
        final hasPlan = planList != null && planList.isNotEmpty;
        final latestPlan = hasPlan ? planList.first : null;
        
        final verseText = latestPlan != null && latestPlan.keyVerse.isNotEmpty 
            ? latestPlan.keyVerse 
            : '"Seja forte e corajoso! Não se apavore, nem desanime..."';
        final verseReference = latestPlan != null && latestPlan.title.isNotEmpty 
            ? latestPlan.title 
            : 'Josué 1:9';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
            boxShadow: _floatingShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Versículo do Dia',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                verseText,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                verseReference,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  List<BoxShadow> _softShadow() {
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }

  List<BoxShadow> _multiLayeredShadow() {
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.02),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.04),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
  }

  List<BoxShadow> _floatingShadow() {
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.08),
        blurRadius: 32,
        spreadRadius: 1,
        offset: const Offset(0, 14),
      ),
    ];
  }
}
