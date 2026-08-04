import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/design_system/colors.dart';
import '../../../core/design_system/typography.dart';
import '../../../core/design_system/radius.dart';
import '../../../core/design_system/elevation.dart';
import '../../../core/design_system/spacing.dart';
import '../../../core/design_system/illustrations.dart';
import '../../../core/components/mascot/mascot_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isRegistering = false;
  bool _keepLoggedIn = true;

  List<Map<String, dynamic>> _teachersList = [
    {'id': 'admin', 'nome': 'Administrador', 'email': 'admin'}
  ];
  Map<String, dynamic>? _selectedTeacher;
  bool _loadingTeachers = false;

  @override
  void initState() {
    super.initState();
    _selectedTeacher = _teachersList.first;
    _checkAutoLogin();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    setState(() => _loadingTeachers = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('ativo', isEqualTo: true)
          .get();
          
      final teachers = snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nome': data['nome'] ?? 'Sem nome',
          'email': data['email'] ?? '',
        };
      }).toList();

      setState(() {
        _teachersList = [
          {'id': 'admin', 'nome': 'Administrador', 'email': 'admin'},
          ...teachers,
        ];
        // Mantém a seleção pelo ID, mas sempre aponta para o OBJETO da
        // lista nova (o DropdownButtonFormField compara por identidade
        // de referência, então reaproveitar o Map antigo quebra o combo).
        _selectedTeacher = _teachersList.firstWhere(
          (t) => t['id'] == _selectedTeacher?['id'],
          orElse: () => _teachersList.first,
        );
      });
    } catch (e) {
      // Fallback
    } finally {
      setState(() => _loadingTeachers = false);
    }
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final keep = prefs.getBool('keep_logged_in') ?? false;
    final role = prefs.getString('user_role') ?? '';
    
    if (keep) {
      if (role == 'admin') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else if (role == 'teacher' && FirebaseAuth.instance.currentUser != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    }
  }

  Future<void> _submit() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (_isRegistering) {
        final email = _emailController.text.trim();
        final name = _nameController.text.trim();
        if (email.isEmpty || name.isEmpty) throw Exception('Por favor, informe seu nome e e-mail.');
        
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (cred.user != null) {
          await FirebaseFirestore.instance.collection('usuarios').doc(cred.user!.uid).set({
            'nome': name,
            'email': email,
            'ativo': false, // Inativo por padrão, aguardando admin
            'criadoEm': FieldValue.serverTimestamp(),
          });
          
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Conta criada! Aguarde o administrador ativar seu acesso.')),
            );
            setState(() {
              _isRegistering = false;
              _fetchTeachers();
            });
          }
        }
      } else {
        if (_selectedTeacher == null) {
          throw Exception('Por favor, selecione seu nome da lista.');
        }

        final selectedId = _selectedTeacher!['id'] as String;
        final selectedName = _selectedTeacher!['nome'] as String? ?? 'Professor';
        final email = _selectedTeacher!['email'] as String;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_teacher_id', selectedId);
        await prefs.setString('current_teacher_name', selectedName);

        if (selectedId == 'admin') {
          if (password == 'admin2026') {
            if (_keepLoggedIn) {
              await prefs.setBool('keep_logged_in', true);
              await prefs.setString('user_role', 'admin');
            }
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
            return;
          } else {
            throw Exception('Senha do Administrador inválida.');
          }
        }

        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (cred.user != null) {
          final doc = await FirebaseFirestore.instance.collection('usuarios').doc(cred.user!.uid).get();
          
          if (!doc.exists) {
            await FirebaseAuth.instance.signOut();
            throw Exception('Usuário não encontrado no banco de dados.');
          }
          
          final data = doc.data()!;
          if (data['ativo'] == true) {
            if (_keepLoggedIn) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('keep_logged_in', true);
              await prefs.setString('user_role', 'teacher');
            }
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          } else {
            await FirebaseAuth.instance.signOut();
            throw Exception('Sua conta está aguardando ativação pelo Administrador.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: DsColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0F2FE), // Azul bem clarinho (céu)
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Elementos Lúdicos do Fundo (Nuvens/Brilhos)
            Positioned(
              top: size.height * 0.1,
              left: 20,
              child: const Icon(Icons.cloud, color: Colors.white, size: 60),
            ),
            Positioned(
              top: size.height * 0.2,
              right: 30,
              child: const Icon(Icons.cloud, color: Colors.white, size: 80),
            ),
            Positioned(
              top: size.height * 0.4,
              left: 40,
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
            ),
            Positioned(
              top: size.height * 0.5,
              right: 50,
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: DsSpacing.s24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cabeçalho
                      Text(
                        'Seja bem-vindo ao',
                        style: DsTypography.bodyLarge.copyWith(color: DsColors.textMediumEmphasis),
                      ),
                      const SizedBox(height: DsSpacing.s4),
                      Text(
                        'CME Infantil',
                        style: DsTypography.heading1.copyWith(
                          color: const Color(0xFF4EA4FF), // Azul Institucional
                          fontSize: 36,
                        ),
                      ),
                      
                      const SizedBox(height: DsSpacing.s16),

                      // Professor / Personagem Principal de Boas-vindas (40% da tela)
                      SizedBox(
                        height: size.height * 0.40,
                        child: Image.asset(
                          DsIllustrations.avatarTeacherMale,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: DsSpacing.s24),

                      // Cartão de Login
                      Container(
                        padding: const EdgeInsets.all(DsSpacing.s24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: DsRadius.large,
                          boxShadow: DsElevation.floatCard,
                        ),
                        child: Column(
                          children: [
                            Text(
                              _isRegistering ? 'Criar Conta' : 'Login do Professor',
                              style: DsTypography.heading3,
                            ),
                            const SizedBox(height: DsSpacing.s24),
                            
                            if (_isRegistering) ...[
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Nome Completo',
                                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF4EA4FF)),
                                  border: OutlineInputBorder(
                                    borderRadius: DsRadius.medium,
                                    borderSide: const BorderSide(color: DsColors.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: DsRadius.medium,
                                    borderSide: const BorderSide(color: DsColors.borderColor),
                                  ),
                                ),
                              ),
                              const SizedBox(height: DsSpacing.s16),
                            ],
                            
                            if (_isRegistering) ...[
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'E-mail',
                                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF4EA4FF)),
                                  border: OutlineInputBorder(
                                    borderRadius: DsRadius.medium,
                                    borderSide: const BorderSide(color: DsColors.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: DsRadius.medium,
                                    borderSide: const BorderSide(color: DsColors.borderColor),
                                  ),
                                ),
                              ),
                            ] else ...[
                              DropdownButtonFormField<Map<String, dynamic>>(
                                value: _selectedTeacher,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.person_pin_rounded, color: Color(0xFF4EA4FF)),
                                  border: OutlineInputBorder(
                                    borderRadius: DsRadius.medium,
                                    borderSide: const BorderSide(color: DsColors.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: DsRadius.medium,
                                    borderSide: const BorderSide(color: DsColors.borderColor),
                                  ),
                                ),
                                items: _teachersList.map((t) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: t,
                                    child: Text(t['nome'] as String),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedTeacher = val;
                                  });
                                },
                              ),
                            ],
                            const SizedBox(height: DsSpacing.s16),
                            
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4EA4FF)),
                                border: OutlineInputBorder(
                                  borderRadius: DsRadius.medium,
                                  borderSide: const BorderSide(color: DsColors.borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: DsRadius.medium,
                                  borderSide: const BorderSide(color: DsColors.borderColor),
                                ),
                              ),
                            ),
                             if (!_isRegistering) ...[
                               Row(
                                 children: [
                                   Checkbox(
                                     value: _keepLoggedIn,
                                     onChanged: (val) {
                                       setState(() => _keepLoggedIn = val ?? true);
                                     },
                                     activeColor: const Color(0xFF4EA4FF),
                                   ),
                                   const Text(
                                     'Manter conectado',
                                     style: TextStyle(
                                       fontFamily: 'Nunito',
                                       fontSize: 14,
                                       color: Color(0xFF64748B),
                                       fontWeight: FontWeight.w600,
                                     ),
                                   ),
                                 ],
                               ),
                               const SizedBox(height: DsSpacing.s8),
                             ],
                             const SizedBox(height: DsSpacing.s16),
                            
                            // Botão Entrar
                            _isLoading
                                ? const CircularProgressIndicator(color: Color(0xFF4EA4FF))
                                : SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4EA4FF),
                                        foregroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: DsRadius.medium,
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        _isRegistering ? 'Registrar' : 'Entrar',
                                        style: DsTypography.buttonText,
                                      ),
                                    ),
                                  ),
                                  
                            const SizedBox(height: DsSpacing.s16),
                            
                            TextButton(
                              onPressed: () => setState(() => _isRegistering = !_isRegistering),
                              child: Text(
                                _isRegistering ? 'Já tenho conta. Fazer Login' : 'Não tem conta? Cadastre-se',
                                style: DsTypography.bodyMedium.copyWith(
                                  color: const Color(0xFF4EA4FF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DsSpacing.s24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
