import 'dart:async';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/widget/location_view.dart';
import 'package:driver/widget/user_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RideAssignmentModal extends StatefulWidget {
  final OrderModel orderModel;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RideAssignmentModal({
    super.key,
    required this.orderModel,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<RideAssignmentModal> createState() => _RideAssignmentModalState();
}

class _RideAssignmentModalState extends State<RideAssignmentModal>
    with TickerProviderStateMixin {

  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _countdownTimer;
  bool _hasResponded = false;

  late ValueNotifier<int> _secondsNotifier;
  late ValueNotifier<bool> _isUrgentNotifier;

  @override
  void initState() {
    super.initState();
    print('📱 Inicializando RideAssignmentModal para corrida ${widget.orderModel.id}');

    // Inicializa notifiers
    _secondsNotifier = ValueNotifier<int>(60);
    _isUrgentNotifier = ValueNotifier<bool>(false);

    // Configuração das animações
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Inicia animações
    _animationController.forward();
    _progressController.forward();

    // Inicia countdown SEM setState
    _startCountdownWithoutRebuild();
  }

  @override
  void dispose() {
    print('📱 Descartando RideAssignmentModal para corrida ${widget.orderModel.id}');

    // Dispose dos notifiers
    _secondsNotifier.dispose();
    _isUrgentNotifier.dispose();

    _animationController.dispose();
    _progressController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// MÉTODO: Countdown que NÃO causa rebuild
  void _startCountdownWithoutRebuild() {
    int secondsRemaining = 60;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_hasResponded) {
        timer.cancel();
        return;
      }

      if (secondsRemaining > 0) {
        secondsRemaining--;

        _secondsNotifier.value = secondsRemaining;
        _isUrgentNotifier.value = secondsRemaining <= 5;

      } else {
        timer.cancel();
        if (!_hasResponded && mounted) {
          _handleReject();
        }
      }
    });
  }

  void _handleAccept() {
    if (_hasResponded) return;

    _hasResponded = true;
    print('✅ Usuário aceitou corrida ${widget.orderModel.id}');

    // Cancela timer e animações
    _countdownTimer?.cancel();
    _animationController.stop();
    _progressController.stop();

    widget.onAccept();
  }

  void _handleReject() {
    if (_hasResponded) return;

    _hasResponded = true;
    print('❌ Usuário rejeitou corrida ${widget.orderModel.id}');

    // Cancela timer e animações
    _countdownTimer?.cancel();
    _animationController.stop();
    _progressController.stop();

    widget.onReject();
  }

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO: listen: false para evitar rebuilds desnecessários
    final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Center(
                child: Container(
                  // RESPONSIVIDADE: Largura máxima para telas grandes e 90% para celulares
                  width: screenWidth > 500 ? 500 : screenWidth * 0.9,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: themeChange.getThem()
                        ? AppColors.darkContainerBackground
                        : AppColors.containerBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: themeChange.getThem()
                          ? AppColors.darkContainerBorder
                          : AppColors.containerBorder,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),

                  // CORREÇÃO DE OVERFLOW: Permite rolagem em telas pequenas
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        const SizedBox(height: 20),

                        // Countdown Timer SEM REBUILD
                        _buildCountdownTimerFixed(themeChange),

                        const SizedBox(height: 20),

                        // Ride Info (Otimizada para responsividade horizontal)
                        _buildRideInfo(themeChange),

                        const SizedBox(height: 15),

                        // User Info
                        _buildUserInfo(),

                        const SizedBox(height: 15),

                        // Location Info
                        _buildLocationInfo(),

                        const SizedBox(height: 25),

                        // Action Buttons
                        _buildActionButtons(themeChange),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// WIDGET: Timer que NÃO causa rebuild do widget pai
  Widget _buildCountdownTimerFixed(DarkThemeProvider themeChange) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _isUrgentNotifier,
                    builder: (context, isUrgent, child) {
                      return CircularProgressIndicator(
                        value: 1.0 - _progressController.value,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUrgent ? Colors.red : AppColors.primary,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // ValueListenableBuilder evita rebuild do widget inteiro
            ValueListenableBuilder<int>(
              valueListenable: _secondsNotifier,
              builder: (context, seconds, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _isUrgentNotifier,
                  builder: (context, isUrgent, child) {
                    return Text(
                      '$seconds',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isUrgent ? Colors.red : AppColors.primary,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Texto do countdown
        ValueListenableBuilder<int>(
          valueListenable: _secondsNotifier,
          builder: (context, seconds, child) {
            return Text(
              'Responda em $seconds segundos',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRideInfo(DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      // Mantenho a Row e uso Flexible nos itens para dividir o espaço
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            'Distância',
            '${widget.orderModel.distance ?? '0'} ${widget.orderModel.distanceType ?? 'km'}',
            Icons.straighten,
            themeChange,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withOpacity(0.3),
          ),
          _buildInfoItem(
            'Valor',
            Constant.amountShow(amount: widget.orderModel.offerRate ?? '0'),
            Icons.monetization_on,
            themeChange,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withOpacity(0.3),
          ),
          _buildInfoItem(
            'Duração',
            '~${_calculateEstimatedTime()} min',
            Icons.access_time,
            themeChange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, DarkThemeProvider themeChange) {
    // RESPONSIVIDADE HORIZONTAL: Flexible para dividir o espaço da Row
    return Flexible(
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          // RESPONSIVIDADE: FittedBox garante que o texto não cause overflow horizontal
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center, // Centraliza o texto
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: themeChange.getThem() ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return UserView(
      userId: widget.orderModel.userId,
      amount: widget.orderModel.offerRate,
      distance: widget.orderModel.distance,
      distanceType: widget.orderModel.distanceType,
    );
  }

  Widget _buildLocationInfo() {
    // Certifique-se de que LocationView é responsivo internamente (usa Flexible/Expanded em textos)
    return LocationView(
      sourceLocation: widget.orderModel.sourceLocationName ?? 'Local de origem',
      destinationLocation: widget.orderModel.destinationLocationName ?? 'Destino',
    );
  }

  Widget _buildActionButtons(DarkThemeProvider themeChange) {
    // Os botões já estão responsivos horizontalmente graças aos Expanded
    return Row(
      children: [
        // Botão Rejeitar
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: TextButton(
              onPressed: _hasResponded ? null : _handleReject,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.close,
                    color: _hasResponded ? Colors.grey : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rejeitar',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _hasResponded ? Colors.grey : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 15),

        // Botão Aceitar
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.green,
            ),
            child: TextButton(
              onPressed: _hasResponded ? null : _handleAccept,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Aceitar',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _calculateEstimatedTime() {
    try {
      double distance = double.parse(widget.orderModel.distance ?? '0');
      // Cálculo: 2 minutos por km (incluindo trânsito/paradas)
      return (distance * 2).round();
    } catch (e) {
      return 60; // Valor padrão
    }
  }
}