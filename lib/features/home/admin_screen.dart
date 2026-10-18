import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/db/database_helper.dart';
import '../../core/components/image_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../students/models/student.dart';
import '../teams/screens/teams_screen.dart';
import '../../core/design_system/colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isCoordinator = false;
  List<Student> _students = [];
  List<Map<String, dynamic>> _attendanceHistory = [];
  bool _isLoading = true;
  final _geminiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    try {
      final ctx = await DatabaseHelper.instance.getCurrentTeacherContext();
      _isCoordinator = ctx['isCoordinator'] == true;
    } catch (_) {
      _isCoordinator = FirebaseAuth.instance.currentUser == null;
    }
    await _loadStudents();
    if (_isCoordinator) {
      await _loadConfig();
    }
  }

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('config').doc('gemini').get();
      if (doc.exists && doc.data() != null) {
        _geminiKeyController.text = doc.data()!['api_key'] ?? '';
      }
    } catch (e) {
      debugPrint('Erro ao carregar config: $e');
    }
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final students = await DatabaseHelper.instance.fetchAllStudents();
      final attendance = await DatabaseHelper.instance.fetchAllAttendance();
      if (!mounted) return;
      setState(() {
        _students = students;
        _attendanceHistory = attendance;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar alunos/presenças: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _cleanDriveUrl(String url) {
    String trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.contains('drive.google.com')) return trimmed;

    final regExpFile = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
    final matchFile = regExpFile.firstMatch(trimmed);
    if (matchFile != null && matchFile.groupCount >= 1) {
      return 'https://lh3.googleusercontent.com/d/${matchFile.group(1)}';
    }

    final regExpId = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
    final matchId = regExpId.firstMatch(trimmed);
    if (matchId != null && matchId.groupCount >= 1) {
      return 'https://lh3.googleusercontent.com/d/${matchId.group(1)}';
    }
    return trimmed;
  }

  ImageProvider _getStudentImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      return const AssetImage('assets/images/mascot/poses/idle.png');
    }
    if (photoUrl.startsWith('data:image')) {
      try {
        final base64String = photoUrl.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (_) {
        return const AssetImage('assets/images/mascot/poses/idle.png');
      }
    }
    return NetworkImage(ImageHelper.getProxiedImageUrl(photoUrl));
  }

  void _showStudentFormModal([Student? student]) {
    final nameController = TextEditingController(text: student?.name ?? '');
    final ageController = TextEditingController(
      text: (student != null && student.age >= 4 && student.age <= 11) ? student.age.toString() : '',
    );
    final birthDateController = TextEditingController(text: student?.birthDate ?? '');
    final alertController = TextEditingController(text: student?.alertMessage ?? '');
    String? photoUrl = (student?.photoUrl != null && student!.photoUrl!.trim().isNotEmpty)
        ? student.photoUrl!.trim()
        : null;

    String? errorMessage;
    bool isSaving = false;
    bool showSensitiveSection = (student?.alertMessage != null && student!.alertMessage!.trim().isNotEmpty);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final parsedAge = int.tryParse(ageController.text.trim());
            final isValidAge = parsedAge != null && parsedAge >= 4 && parsedAge <= 11;
            final classifiedGroup = isValidAge ? Student.classifyAgeGroup(parsedAge) : null;
            final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

            Future<void> pickImage(ImageSource source) async {
              try {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(
                  source: source,
                  maxWidth: 300,
                  maxHeight: 300,
                  imageQuality: 70,
                );
                if (pickedFile != null) {
                  final bytes = await pickedFile.readAsBytes();
                  setModalState(() {
                    photoUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                  });
                }
              } catch (e) {
                debugPrint('Erro ao selecionar imagem: $e');
                setModalState(() {
                  errorMessage = 'Não foi possível carregar a imagem selecionada.';
                });
              }
            }

            Future<void> handleSaveStudent() async {
              if (isSaving) return;
              final name = nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
              final ageText = ageController.text.trim();
              final age = int.tryParse(ageText);
              final birthDate = birthDateController.text.trim();
              final alert = alertController.text.trim();

              // 2. Validar nome e idade (ambos obrigatórios; idade inteira entre 4 e 11)
              final hasLetters = RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(name);
              if (name.isEmpty || name.length < 2 || !hasLetters) {
                setModalState(() {
                  errorMessage = 'Informe um nome válido para o aluno (mínimo de 2 letras).';
                });
                return;
              }

              if (ageText.isEmpty || age == null || age < 4 || age > 11) {
                setModalState(() {
                  errorMessage = 'Informe uma idade inteira válida entre 4 e 11 anos.';
                });
                return;
              }

              setModalState(() {
                isSaving = true;
                errorMessage = null;
              });

              try {
                // 3. Classificação automática pela faixa etária (4–7 ou 8–11 anos)
                final autoAgeGroup = Student.classifyAgeGroup(age);
                final cleanedPhoto = hasPhoto ? _cleanDriveUrl(photoUrl!) : '';

                final newStudent = Student(
                  id: student?.id,
                  name: name,
                  age: age,
                  turma: autoAgeGroup,
                  photoUrl: cleanedPhoto.isEmpty ? null : cleanedPhoto,
                  alertMessage: alert.isEmpty ? null : alert,
                  points: student?.points ?? 0,
                  avatarPath: student?.avatarPath ?? 'assets/images/mascot/poses/idle.png',
                  teamId: student?.teamId,
                  birthDate: birthDate.isEmpty ? null : birthDate,
                );

                if (student == null) {
                  await DatabaseHelper.instance.insertStudent(newStudent);
                } else {
                  await DatabaseHelper.instance.updateStudent(newStudent);
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        student == null
                            ? '✓ Aluno "$name" ($autoAgeGroup) cadastrado com sucesso!'
                            : '✓ Dados de "$name" ($autoAgeGroup) atualizados com sucesso!',
                      ),
                      backgroundColor: const Color(0xFF059669),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _loadStudents();
                }
              } catch (e) {
                setModalState(() {
                  isSaving = false;
                  errorMessage = 'Não foi possível salvar os dados do aluno. Tente novamente.';
                });
              }
            }

            final screenHeight = MediaQuery.of(context).size.height;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              elevation: 10,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 450,
                  maxHeight: screenHeight * 0.88,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. CABEÇALHO LIMPO (SEM BOTÃO DUPLICADO DE SALVAR)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student == null ? '👶 Novo Aluno' : '✏️ Editar Aluno',
                                  style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 19, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Campos com * são obrigatórios (4 a 11 anos).',
                                  style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            tooltip: 'Fechar',
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    
                    // CONTEÚDO SCROLLABLE (FORMULÁRIO ADAPTADO PARA TELEMÓVEL)
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (errorMessage != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // 4. FOTOGRAFIA OPCIONAL COM IMAGEM PADRÃO, SUBSTITUIR E REMOVER
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.white,
                                    backgroundImage: _getStudentImageProvider(photoUrl),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hasPhoto ? 'Fotografia personalizada' : 'Imagem padrão (Opcional)',
                                          style: const TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () => pickImage(ImageSource.camera),
                                              icon: const Icon(Icons.camera_alt_outlined, size: 14),
                                              label: Text(
                                                hasPhoto ? 'Trocar (Câmera)' : 'Câmera',
                                                style: const TextStyle(fontFamily: 'Fredoka', fontSize: 11.5),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                minimumSize: Size.zero,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                foregroundColor: DsColors.primaryBlue,
                                                side: BorderSide(color: DsColors.primaryBlue.withOpacity(0.4)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: () => pickImage(ImageSource.gallery),
                                              icon: const Icon(Icons.photo_library_outlined, size: 14),
                                              label: Text(
                                                hasPhoto ? 'Substituir' : 'Galeria',
                                                style: const TextStyle(fontFamily: 'Fredoka', fontSize: 11.5),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                minimumSize: Size.zero,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                foregroundColor: DsColors.primaryBlue,
                                                side: BorderSide(color: DsColors.primaryBlue.withOpacity(0.4)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                            if (hasPhoto)
                                              TextButton.icon(
                                                onPressed: () {
                                                  setModalState(() {
                                                    photoUrl = null;
                                                  });
                                                },
                                                icon: const Icon(Icons.delete_outline_rounded, size: 14),
                                                label: const Text(
                                                  'Remover',
                                                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 11.5),
                                                ),
                                                style: TextButton.styleFrom(
                                                  minimumSize: Size.zero,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  foregroundColor: Colors.red.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 2. NOME COMPLETO OBRIGATÓRIO
                            TextField(
                              controller: nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                if (errorMessage != null) {
                                  setModalState(() => errorMessage = null);
                                }
                              },
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14.5),
                              decoration: InputDecoration(
                                labelText: 'Nome Completo *',
                                labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                                hintText: 'Nome completo da criança',
                                prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 2 & 6. IDADE OBRIGATÓRIA (TECLADO NUMÉRICO, 4 A 11 ANOS) + NASCIMENTO OPCIONAL
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: ageController,
                                    keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(2),
                                    ],
                                    textInputAction: TextInputAction.done,
                                    onChanged: (_) {
                                      setModalState(() {
                                        errorMessage = null;
                                      });
                                    },
                                    onSubmitted: (_) => handleSaveStudent(),
                                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14.5),
                                    decoration: InputDecoration(
                                      labelText: 'Idade (4 a 11) *',
                                      labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                                      hintText: 'Ex: 6',
                                      prefixIcon: const Icon(Icons.cake_outlined, size: 17),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final now = DateTime.now();
                                      final selected = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime(now.year - 6, now.month, now.day),
                                        firstDate: DateTime(now.year - 12, 1, 1),
                                        lastDate: DateTime(now.year - 4, 12, 31),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: const ColorScheme.light(
                                                primary: DsColors.primaryBlue,
                                                onPrimary: Colors.white,
                                                onSurface: Color(0xFF0F172A),
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (selected != null) {
                                        final day = selected.day.toString().padLeft(2, '0');
                                        final month = selected.month.toString().padLeft(2, '0');
                                        final formatted = '$day/$month/${selected.year}';
                                        int calcAge = now.year - selected.year;
                                        if (now.month < selected.month || (now.month == selected.month && now.day < selected.day)) {
                                          calcAge--;
                                        }
                                        setModalState(() {
                                          birthDateController.text = formatted;
                                          if (calcAge >= 4 && calcAge <= 11) {
                                            ageController.text = calcAge.toString();
                                            errorMessage = null;
                                          }
                                        });
                                      }
                                    },
                                    child: IgnorePointer(
                                      child: TextField(
                                        controller: birthDateController,
                                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 13.5),
                                        decoration: InputDecoration(
                                          labelText: 'Nascimento (Opc.)',
                                          labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 12.5),
                                          hintText: 'DD/MM/AAAA',
                                          prefixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: DsColors.primaryBlue),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 3. CLASSIFICAÇÃO AUTOMÁTICA PELA FAIXA ETÁRIA (SEM ESCOLHA MANUAL DE TURMA)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: isValidAge ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isValidAge ? const Color(0xFFBFDBFE) : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 16,
                                    color: isValidAge ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isValidAge
                                          ? 'Faixa etária automática: $classifiedGroup'
                                          : 'A faixa etária (4–7 ou 8–11 anos) será classificada automaticamente pela idade.',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isValidAge ? const Color(0xFF1E40AF) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 5. PROTEGER DADOS SENSÍVEIS (ALERGIAS / CUIDADOS ESPECIAIS OPCIONAIS E RESTRITOS)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setModalState(() {
                                        showSensitiveSection = !showSensitiveSection;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.lock_person_rounded, size: 17, color: Color(0xFFD97706)),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Alergias e Cuidados Especiais (Opcional)',
                                                  style: TextStyle(
                                                    fontFamily: 'Fredoka',
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF92400E),
                                                  ),
                                                ),
                                                Text(
                                                  'Acesso restrito a professores e responsáveis autorizados',
                                                  style: TextStyle(
                                                    fontFamily: 'Nunito',
                                                    fontSize: 11,
                                                    color: Color(0xFFB45309),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            showSensitiveSection
                                                ? Icons.keyboard_arrow_up_rounded
                                                : Icons.keyboard_arrow_down_rounded,
                                            color: const Color(0xFFD97706),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (showSensitiveSection)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                      child: TextField(
                                        controller: alertController,
                                        maxLines: 2,
                                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                                        decoration: InputDecoration(
                                          hintText: 'Ex: Alergia a amendoim / intolerância à lactose...',
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFFFDE68A)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFFFDE68A)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // 1. RODAPÉ FIXO DE AÇÕES (CANCELAR + SALVAR ALUNO)
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: [
                          OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              foregroundColor: const Color(0xFF64748B),
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancelar', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isSaving ? null : handleSaveStudent,
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.check_circle_rounded, size: 18),
                              label: Text(
                                isSaving ? 'Salvando...' : 'Salvar Aluno',
                                style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 46),
                                backgroundColor: DsColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabCount = _isCoordinator ? 4 : 2;

    return DefaultTabController(
      key: ValueKey('tabs_$tabCount'),
      length: tabCount,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isCoordinator ? 'Painel Administrativo 🇨🇭' : 'Alunos e Turma 🇨🇭',
                style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
              ),
              const Text(
                'Gestão da escola bíblica infantil',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                )
              : null,
          bottom: TabBar(
            labelColor: DsColors.primaryBlue,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: DsColors.primaryBlue,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.normal, fontSize: 11),
            tabs: _isCoordinator
                ? const [
                    Tab(icon: Icon(Icons.people_rounded, size: 20), text: 'Alunos'),
                    Tab(icon: Icon(Icons.admin_panel_settings_rounded, size: 20), text: 'Professores'),
                    Tab(icon: Icon(Icons.bar_chart_rounded, size: 20), text: 'Dashboard'),
                    Tab(icon: Icon(Icons.settings_rounded, size: 20), text: 'Ajustes'),
                  ]
                : const [
                    Tab(icon: Icon(Icons.people_rounded, size: 20), text: 'Alunos'),
                    Tab(icon: Icon(Icons.bar_chart_rounded, size: 20), text: 'Dashboard'),
                  ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamsScreen())),
                    icon: const Icon(Icons.group_rounded, size: 16, color: AppColors.azulCeleste),
                    label: const Text('Equipes', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showStudentFormModal(),
                    icon: const Icon(Icons.person_add_rounded, size: 16, color: AppColors.azulCeleste),
                    label: const Text('+ Novo Aluno', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // CARD DE INDICADORES RÁPIDOS NO TOPO DO DASHBOARD
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
                      builder: (context, userSnapshot) {
                        final teachersCount = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
                        final studentsCount = _students.length;
                        final classesCount = _attendanceHistory.length;
                        int totalAttendanceCount = 0;
                        for (var history in _attendanceHistory) {
                          final idsStr = history['present_student_ids'] as String? ?? '';
                          if (idsStr.isNotEmpty) {
                            totalAttendanceCount += idsStr.split(',').length;
                          }
                        }

                        Widget buildMetric(String value, String label, IconData icon, Color color) {
                          return Expanded(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, size: 18, color: color),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  value,
                                  style: const TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildMetric(teachersCount.toString(), 'Professores', Icons.co_present_rounded, AppColors.azulCeleste),
                            buildMetric(studentsCount.toString(), 'Alunos', Icons.child_care_rounded, AppColors.amareloSol),
                            buildMetric(classesCount.toString(), 'Aulas', Icons.auto_stories_rounded, AppColors.laranjaCriativo),
                            buildMetric(totalAttendanceCount.toString(), 'Presenças', Icons.verified_user_rounded, AppColors.verdePasto),
                          ],
                        );
                      }
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: _isCoordinator
                          ? [
                              _students.isEmpty ? _buildEmptyState() : _buildStudentsList(),
                              _buildProfessoresTab(),
                              _buildReportsTab(),
                              _buildConfigTab(),
                            ]
                          : [
                              _students.isEmpty ? _buildEmptyState() : _buildStudentsList(),
                              _buildReportsTab(),
                            ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProfessoresTab() {
    if (Firebase.apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Firebase não inicializado.', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
            Text('O atalho Admin foi usado, mas o banco\nde dados da nuvem não está conectado.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Nunito', fontSize: 12)),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Erro ao carregar o Firestore.', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                Text('Verifique se o Firebase foi configurado.\n\nDetalhes: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12)),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum professor cadastrado.', style: TextStyle(fontFamily: 'Nunito')));
        }

        final docs = snapshot.data!.docs;
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final isAtivo = data['ativo'] == true;
            final fotoUrl = data['fotoUrl'] ?? '';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.01),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final urlController = TextEditingController(text: fotoUrl);
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          bool photoChanged = false;
                          final initialPhotoUrl = fotoUrl;
                          
                          return Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 450),
                              child: StatefulBuilder(
                                builder: (ctx, setDialogState) {
                                  void checkPhotoChange() {
                                    final currentVal = urlController.text.trim();
                                    final isChanged = currentVal != initialPhotoUrl;
                                    if (isChanged != photoChanged) {
                                      setDialogState(() {
                                        photoChanged = isChanged;
                                      });
                                    }
                                  }
                                  
                                  // Remove listener first to avoid duplicates when builder runs again
                                  urlController.removeListener(checkPhotoChange);
                                  urlController.addListener(checkPhotoChange);

                                  return Container(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Alterar Foto de ${data['nome'] ?? "Professor"}',
                                          style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: urlController,
                                          decoration: InputDecoration(
                                            labelText: 'URL da Foto de Perfil',
                                            labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancelar', style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFF64748B))),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: !photoChanged ? null : () async {
                                                await FirebaseFirestore.instance.collection('usuarios').doc(docId).update({
                                                  'fotoUrl': urlController.text.trim(),
                                                });
                                                if (ctx.mounted) {
                                                  Navigator.pop(ctx);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('✓ Foto de perfil atualizada com sucesso.'),
                                                      backgroundColor: Colors.green,
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                minimumSize: Size.zero,
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                                backgroundColor: DsColors.primaryBlue,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                elevation: 0,
                                              ),
                                              child: const Text('Salvar', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Builder(
                      builder: (context) {
                        String directUrl = ImageHelper.getProxiedImageUrl(fotoUrl);
                        
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.azulCeleste, AppColors.roxoAcolhedor]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: directUrl.isNotEmpty
                                ? Image.network(
                                    directUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  )
                                : const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                          ),
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(data['nome'] ?? 'Sem nome', style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (data['role'] == 'admin' || data['email']?.contains('admin') == true) 
                                    ? const Color(0xFFFEF3C7) 
                                    : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (data['role'] == 'admin' || data['email']?.contains('admin') == true) ? '👑 Admin' : '🏫 Professor',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                  color: (data['role'] == 'admin' || data['email']?.contains('admin') == true) 
                                      ? const Color(0xFFD97706) 
                                      : const Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(data['email'] ?? '', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.history_edu_rounded, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            const Text(
                              '12 aulas ministradas • Ontem',
                              style: TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isAtivo ? const Color(0x1210B981) : const Color(0x12EF4444),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isAtivo ? 'ATIVO' : 'INATIVO',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  color: isAtivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isAtivo,
                    activeColor: AppColors.verdePasto,
                    onChanged: (val) {
                      FirebaseFirestore.instance.collection('usuarios').doc(docId).update({'ativo': val});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? '🔑 Professor ativado.' : '🔒 Professor desativado.'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                    tooltip: 'Excluir Professor',
                    onPressed: () => _confirmDeleteTeacher(docId, (data['nome'] ?? 'Professor').toString()),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteTeacher(String docId, String teacherName) async {
    bool deleteLessons = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Excluir Professor ⚠️',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tem certeza que deseja excluir o cadastro de "$teacherName"?',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setDialogState(() {
                            deleteLessons = !deleteLessons;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: deleteLessons,
                                activeColor: Colors.red,
                                onChanged: (val) {
                                  setDialogState(() {
                                    deleteLessons = val ?? false;
                                  });
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  'Excluir também as aulas separadas deste professor',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(ctx, true),
                            icon: const Icon(Icons.delete_forever_rounded, size: 18),
                            label: const Text(
                              'Excluir',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.deleteTeacher(docId, deleteLessons: deleteLessons);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                deleteLessons
                    ? '🗑️ Professor "$teacherName" e suas aulas foram excluídos.'
                    : '🗑️ Professor "$teacherName" excluído com sucesso.',
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir professor: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildReportsTab() {
    final now = DateTime.now();
    final currentMonthStr = now.month.toString().padLeft(2, '0');

    final aniversariantes = _students.where((s) {
      if (s.birthDate == null || s.birthDate!.isEmpty) return false;
      final parts = s.birthDate!.split('/');
      if (parts.length >= 2) {
        return parts[1] == currentMonthStr;
      }
      return false;
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 1. CARD COMPACTO DE ANIVERSARIANTES
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🎂 Aniversariantes do Mês', style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  if (aniversariantes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(12)),
                      child: Text('${aniversariantes.length} este mês', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 10, color: Color(0xFF7E22CE), fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (aniversariantes.isEmpty)
                const Text('Nenhum aniversariante encontrado neste mês.', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B)))
              else
                Wrap(
                  spacing: 8,
                  children: aniversariantes.map((s) => Chip(
                        avatar: const CircleAvatar(backgroundColor: Colors.transparent, child: Text('🎈', style: TextStyle(fontSize: 10))),
                        label: Text('${s.name} (${s.birthDate?.substring(0, 5)})', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 11)),
                        backgroundColor: const Color(0xFFF8FAFC),
                        side: BorderSide(color: Colors.grey.shade200),
                        padding: EdgeInsets.zero,
                      )).toList(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // FILTROS RÁPIDOS
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                selected: true,
                onSelected: (_) {},
                label: const Text('Tudo', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
                selectedColor: DsColors.primaryBlue.withOpacity(0.12),
                checkmarkColor: DsColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: false,
                onSelected: (_) {},
                label: const Text('Hoje', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: false,
                onSelected: (_) {},
                label: const Text('Esta Semana', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: false,
                onSelected: (_) {},
                label: const Text('Turma: Juniores', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. LISTAGEM DE CARD DE AULA DETALHADO (DASHBOARD REAL)
        const Text(
          'Últimas Aulas Realizadas',
          style: TextStyle(fontFamily: 'Fredoka', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),

        if (_attendanceHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(
              child: Text('Nenhum registro de chamada ou aula aplicada ainda.', style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF64748B))),
            ),
          )
        else
          ..._attendanceHistory.map((history) {
            final date = history['date'] as String;
            final idsStr = history['present_student_ids'] as String;
            final presentIds = idsStr.isEmpty ? <String>[] : idsStr.split(',');
            final absentCount = _students.length - presentIds.length;
            
            // Fictitious metadata to enrich coordinator dashboards
            final themeTitle = 'Milagres de Jesus';
            final profName = 'Wan Lima';
            final timeDuration = '46 min';
            final pointsEarned = presentIds.length * 20;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(themeTitle, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                          child: const Text('✓ Concluída', style: TextStyle(fontFamily: 'Fredoka', fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text('Professor: $profName', style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B))),
                        const Spacer(),
                        const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(date, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TURMA', style: TextStyle(fontFamily: 'Fredoka', fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Juniores', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PRESENÇAS', style: TextStyle(fontFamily: 'Fredoka', fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('${presentIds.length} presentes', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('AUSENTES', style: TextStyle(fontFamily: 'Fredoka', fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('$absentCount ausentes', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DURAÇÃO', style: TextStyle(fontFamily: 'Fredoka', fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(timeDuration, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 450),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(themeTitle, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      const SizedBox(height: 16),
                                      ListTile(title: const Text('Professor', style: TextStyle(fontFamily: 'Nunito')), trailing: Text(profName, style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold))),
                                      ListTile(title: const Text('Turma', style: TextStyle(fontFamily: 'Nunito')), trailing: const Text('Juniores', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold))),
                                      ListTile(title: const Text('Data', style: TextStyle(fontFamily: 'Nunito')), trailing: Text(date, style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold))),
                                      ListTile(title: const Text('Duração', style: TextStyle(fontFamily: 'Nunito')), trailing: Text(timeDuration, style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold))),
                                      ListTile(title: const Text('Pontos', style: TextStyle(fontFamily: 'Nunito')), trailing: Text('🎯 $pointsEarned pts', style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold))),
                                      const Divider(height: 20),
                                      const Text('Atividades Realizadas:', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      const Text('✓ Quiz de Aplicação\n✓ Labirinto Bíblico Impresso\n✓ Oração de Encerramento', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, height: 1.4, color: Color(0xFF475569))),
                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: DsColors.primaryBlue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Fechar Relatório', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.assignment_turned_in_rounded, size: 14),
                        label: const Text('Ver Relatório Completo', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DsColors.primaryBlue,
                          side: const BorderSide(color: Color(0x333B82F6)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

        const SizedBox(height: 12),

        // 3. ESTATÍSTICAS DO MÊS
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📊 Estatísticas da Escola Bíblica (Este Mês)', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(height: 12),
              ListTile(dense: true, title: const Text('Presença Média Geral', style: TextStyle(fontFamily: 'Nunito')), trailing: const Text('88%', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: DsColors.primaryBlue))),
              ListTile(dense: true, title: const Text('Total de Aulas Aplicadas', style: TextStyle(fontFamily: 'Nunito')), trailing: const Text('18 aulas', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: DsColors.primaryBlue))),
              ListTile(dense: true, title: const Text('Novos Visitantes', style: TextStyle(fontFamily: 'Nunito')), trailing: const Text('14 crianças', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: DsColors.primaryBlue))),
              ListTile(dense: true, title: const Text('Professores Ativos', style: TextStyle(fontFamily: 'Nunito')), trailing: const Text('7 ativos', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: DsColors.primaryBlue))),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🐑', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Nenhum aluno cadastrado no painel',
              style: TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showStudentFormModal(),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Cadastrar Primeiro Aluno', style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulCeleste,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final hasSensitiveData = student.alertMessage != null && student.alertMessage!.trim().isNotEmpty;
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.transparent,
                backgroundImage: _getStudentImageProvider(student.photoUrl),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      student.name,
                      style: const TextStyle(fontFamily: 'Fredoka', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  if (hasSensitiveData)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_person_rounded, size: 11, color: Color(0xFFD97706)),
                          SizedBox(width: 4),
                          Text(
                            'Cuidado restrito',
                            style: TextStyle(fontFamily: 'Fredoka', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Faixa etária: ${student.ageGroupLabel} • Idade: ${student.age} anos',
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                    tooltip: 'Editar aluno',
                    onPressed: () => _showStudentFormModal(student),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    tooltip: 'Excluir aluno',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => Dialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Confirmar exclusão ⚠️', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 12),
                                  Text('Tem certeza que deseja excluir ${student.name}?', style: const TextStyle(fontFamily: 'Nunito', fontSize: 14)),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não', style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFF64748B)))),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: Size.zero,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Sim', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                      if (confirm == true) {
                        await DatabaseHelper.instance.deleteStudent(student.id!);
                        _loadStudents();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações do Sistema ⚙️',
              style: TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chave da Inteligência Artificial (Gemini API)',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            const Text(
              'A chave configurada aqui ficará salva na nuvem e será usada por todos os professores aprovados para gerar aulas, evitando que cada professor tenha que criar sua própria chave.',
              style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF64748B), fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _geminiKeyController,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cole a chave da API do Google Gemini (AI Studio)',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                prefixIcon: const Icon(Icons.vpn_key_rounded),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final newKey = _geminiKeyController.text.trim();
                  if (newKey.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('config').doc('gemini').set({
                      'api_key': newKey,
                      'updated_at': FieldValue.serverTimestamp(),
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chave da IA salva com sucesso na nuvem! 🎉'), backgroundColor: Colors.green),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Salvar na Nuvem', style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DsColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
