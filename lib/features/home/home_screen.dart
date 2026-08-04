import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/components/mascot/mascot_widget.dart';
import '../../core/components/mascot/mascot_assets.dart';
import '../class_mode/screens/class_mode_screen.dart';
import '../games/screens/games_menu_screen.dart';
import '../games/screens/cronometro_screen.dart';
import '../ai_planner/screens/ai_planner_screen.dart';
import '../students/screens/chamada_screen.dart';
import 'admin_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/screens/login_screen.dart';
import '../ai_planner/models/lesson_plan.dart';
import '../../core/db/database_helper.dart';
import '../../core/services/aula_status_service.dart';
import '../../core/design_system/colors.dart';
import '../../core/design_system/typography.dart';
import '../../core/design_system/elevation.dart';
import '../../core/design_system/radius.dart';
import '../../core/design_system/spacing.dart';
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
      backgroundColor: DsColors.background,
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
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final PageController _carouselController = PageController();
  int _carouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _startCarouselTimer();
  }

  void _startCarouselTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      final next = (_carouselIndex + 1) % 3;
      _carouselController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      setState(() => _carouselIndex = next);
      _startCarouselTimer();
    });
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildDashboardBody(context, 'Professor', '');
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
        // 1. Formas Orgânicas Pastel de Fundo com Blur (Reduzido em opacidade de 0.55/0.7 para 0.2/0.25 para não brigar com conteúdo)
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

              // Card "Hoje na Aula" (Hero principal)
              _buildTodayClassCard(context),
              const SizedBox(height: 16),

              // Grid de 2 Colunas: Turma de Hoje e Card Contextual (Experimento 3)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildClassTodayCard(context)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildContextualCard(context)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildVerseCard(),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
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

  // --- CARD HOJE NA AULA ---
  // Combina o LessonPlan mais recente com o AulaStatus do dia, sem
  // duplicar dados: quem grava/lê o status é sempre o AulaStatusService.
  Future<({LessonPlan? plan, AulaStatusResult status})> _fetchTodayClassCardData() async {
    final planList = await DatabaseHelper.instance.fetchAllLessonPlans();
    final latestPlan = planList.isNotEmpty ? planList.first : null;
    final status = await AulaStatusService.getStatus(
      lessonId: latestPlan?.id,
      totalEtapas: 5, // Quebra-gelo, História, Quiz, Atividade, Oração
    );
    return (plan: latestPlan, status: status);
  }

  Widget _buildTodayClassCard(BuildContext context) {
    return FutureBuilder<({LessonPlan? plan, AulaStatusResult status})>(
      future: _fetchTodayClassCardData(),
      builder: (context, snapshot) {
        final latestPlan = snapshot.data?.plan;
        final aulaStatus = snapshot.data?.status.status ?? AulaStatus.semPlano;

        final title = latestPlan != null ? latestPlan.title : 'Nenhuma aula ativa';
        final subtitle = latestPlan != null ? 'Versículo: ${latestPlan.keyVerse}' : 'Abra uma aula para ver aqui';

        // Badge (canto superior direito) e CTA (rodapé do card) reagem
        // ao AulaStatus, sem alterar o layout/identidade visual do card.
        String badgeText;
        Color badgeColor;
        String ctaText;
        IconData ctaIcon;
        switch (aulaStatus) {
          case AulaStatus.semPlano:
            badgeText = 'Aguardando';
            badgeColor = const Color(0xFFF59E0B);
            ctaText = 'Planejar Aula';
            ctaIcon = Icons.auto_awesome_rounded;
            break;
          case AulaStatus.chamadaPendente:
            badgeText = 'Chamada pendente';
            badgeColor = const Color(0xFFF59E0B);
            ctaText = 'Fazer Chamada';
            ctaIcon = Icons.how_to_reg_rounded;
            break;
          case AulaStatus.aulaNaoIniciada:
            badgeText = 'Pronta pra começar';
            badgeColor = const Color(0xFF10B981);
            ctaText = 'Iniciar Aula';
            ctaIcon = Icons.play_arrow_rounded;
            break;
          case AulaStatus.aulaEmAndamento:
            final etapaAtual = (snapshot.data?.status.etapaAtual ?? 0) + 1;
            final totalEtapas = snapshot.data?.status.totalEtapas ?? 5;
            badgeText = 'Etapa $etapaAtual de $totalEtapas';
            badgeColor = const Color(0xFF10B981);
            ctaText = 'Continuar Aula';
            ctaIcon = Icons.arrow_forward_rounded;
            break;
          case AulaStatus.aulaConcluida:
            badgeText = 'Concluída';
            badgeColor = const Color(0xFF10B981);
            ctaText = 'Ver Relatório';
            ctaIcon = Icons.description_rounded;
            break;
        }

        final icon = latestPlan != null ? Icons.auto_awesome : Icons.event_busy_rounded;
        final iconColor = latestPlan != null ? DsColors.primaryBlue : DsColors.textDisabled;

        return GestureDetector(
          onTap: () async {
            if (aulaStatus == AulaStatus.chamadaPendente) {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ChamadaScreen()));
            } else if (aulaStatus == AulaStatus.semPlano) {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AiPlannerScreen()));
            } else {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassModeScreen()));
            }
            if (context.mounted) {
              setState(() {});
            }
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFD7E7FC).withOpacity(0.95),
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
                    const Text(
                      'Hoje na Aula',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: 26,
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
                          const SizedBox(height: 4),
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
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DsColors.primaryBlue, const Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: DsElevation.glow(DsColors.primaryBlue),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(ctaIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        ctaText,
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // --- CARD TURMA DE HOJE (PAINEL VIVO, SEM BOTÃO — Experimento 2) ---
  // A ação de "fazer chamada" já é coberta pelo Hero Card ("Hoje na Aula").
  // Este card passa a ser só informativo: mostra o retrato da turma agora.
  Widget _buildClassTodayCard(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchClassTodayData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'teachers': 0, 'students': 0, 'present': 0, 'initiated': 0};
        final bool isInitiated = data['initiated'] == 1;
        final int students = data['students'] ?? 0;
        final int present = data['present'] ?? 0;
        final int absent = (students - present).clamp(0, students);

        return GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const ChamadaScreen()));
            if (context.mounted) {
              setState(() {});
            }
          },
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
                const SizedBox(height: 10),
                if (!isInitiated)
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: Colors.grey.shade400, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Chamada ainda não feita hoje',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11.5,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow('Alunos', '$students'),
                      const SizedBox(height: 4),
                      _buildStatRow('Presentes', '$present'),
                      const SizedBox(height: 4),
                      _buildStatRow('Ausentes', '$absent'),
                    ],
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
    } catch (_) {}

    int studentsCount = 0;
    int presentCount = 0;
    bool hasInitiated = false;
    try {
      final students = await DatabaseHelper.instance.fetchAllStudents();
      studentsCount = students.length;

      final prefs = await SharedPreferences.getInstance();
      final todayDate = DateTime.now().toIso8601String().split('T')[0];
      final attendanceDate = prefs.getString('attendance_date') ?? '';
      hasInitiated = attendanceDate == todayDate;
      if (!hasInitiated) {
        hasInitiated = await DatabaseHelper.instance.hasAttendanceToday();
      }

      final presentIds = prefs.getStringList('present_student_ids') ?? [];
      final allIds = students.map((e) => e.id.toString()).toSet();
      presentCount = presentIds.where((id) => allIds.contains(id)).length;
    } catch (_) {}

    return {
      'teachers': teachersCount,
      'students': studentsCount,
      'present': presentCount,
      'initiated': hasInitiated ? 1 : 0,
    };
  }

  // --- CARD CARROSSEL ROTATIVO (3 SLIDES) ---
  Widget _buildContextualCard(BuildContext context) {
    return FutureBuilder<LessonPlan?>(
      future: DatabaseHelper.instance.fetchLessonOfTheWeek(),
      builder: (context, planSnapshot) {
        final plan = planSnapshot.data;
        return FutureBuilder<AulaStatusResult>(
          future: AulaStatusService.getStatus(lessonId: plan?.id),
          builder: (context, snapshot) {
            final status = snapshot.data?.status ?? AulaStatus.semPlano;
            final isConcluida = status == AulaStatus.aulaConcluida;

            final slides = [
              // Slide 1: Status da Aula
              _buildCarouselSlide(
                icon: isConcluida ? Icons.stars_rounded : Icons.bolt_rounded,
                color: isConcluida ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                bgColor: isConcluida ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                title: isConcluida ? 'Missão Cumprida!' : 'Apoio da Etapa',
                description: isConcluida
                    ? 'Relatório e presença salvos com sucesso. Parabéns!'
                    : 'Mantenha o foco na etapa atual e acompanhe a participação.',
              ),
              // Slide 2: Mural de Recados
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('mural').orderBy('criadoEm', descending: true).limit(1).snapshots(),
                builder: (ctx, muralSnap) {
                  final murals = muralSnap.data?.docs ?? [];
                  final mensagem = murals.isNotEmpty
                      ? (murals.first.data() as Map<String, dynamic>)['mensagem'] as String? ?? 'Fique atento aos avisos da semana!'
                      : 'Fique atento aos avisos da semana!';
                  return _buildCarouselSlide(
                    icon: Icons.campaign_rounded,
                    color: const Color(0xFF7C3AED),
                    bgColor: const Color(0xFFF3E8FF),
                    title: 'Mural da Salinha',
                    description: mensagem,
                  );
                },
              ),
              // Slide 3: Líderes do Mês
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('equipes').orderBy('pontuacao', descending: true).limit(1).snapshots(),
                builder: (ctx, teamSnap) {
                  final teams = teamSnap.data?.docs ?? [];
                  final teamData = teams.isNotEmpty ? (teams.first.data() as Map<String, dynamic>) : null;
                  final teamName = teamData?['nome'] as String? ?? 'Equipe Campeã';
                  final teamScore = teamData?['pontuacao']?.toString() ?? '--';
                  return _buildCarouselSlide(
                    icon: Icons.emoji_events_rounded,
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                    title: 'Líder do Mês',
                    description: '$teamName · $teamScore pts',
                  );
                },
              ),
            ];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 130,
                  child: PageView(
                    controller: _carouselController,
                    onPageChanged: (i) => setState(() => _carouselIndex = i),
                    children: slides,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _carouselIndex == i ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _carouselIndex == i ? DsColors.primaryBlue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCarouselSlide({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.95),
        borderRadius: DsRadius.large,
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
        boxShadow: _floatingShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 10.5, color: Color(0xFF475569), height: 1.3, fontWeight: FontWeight.w600),
          ),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: DsRadius.large,
            border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
            boxShadow: _floatingShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Versículo do Dia',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 15,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '📖 Leitura',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                verseText,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.5, // Conforto visual de line-height
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  verseReference,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 11,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  List<BoxShadow> _softShadow() => DsElevation.subtle;
  List<BoxShadow> _floatingShadow() => DsElevation.floatCard;
}
