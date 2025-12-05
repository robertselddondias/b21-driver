import 'dart:async';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
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
                  margin: EdgeInsets.all(Responsive.width(5, context)),
                  padding: EdgeInsets.all(Responsive.width(5, context)),
                  decoration: BoxDecoration(
                    color: themeChange.getThem()
                        ? AppColors.darkContainerBackground
                        : AppColors.containerBackground,
                    borderRadius: BorderRadius.circular(Responsive.width(5, context)),
                    border: Border.all(
                      color: themeChange.getThem()
                          ? AppColors.darkContainerBorder
                          : AppColors.containerBorder,
                      width: Responsive.width(0.5, context),
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

                        SizedBox(height: Responsive.height(2, context)),

                        // Countdown Timer SEM REBUILD
                        _buildCountdownTimerFixed(themeChange, context),

                        SizedBox(height: Responsive.height(2, context)),

                        // Ride Info (Otimizada para responsividade horizontal)
                        _buildRideInfo(themeChange, context),

                        SizedBox(height: Responsive.height(1.5, context)),

                        // User Info
                        _buildUserInfo(),

                        SizedBox(height: Responsive.height(1.5, context)),

                        // Location Info
                        _buildLocationInfo(),

                        SizedBox(height: Responsive.height(2.5, context)),

                        // Action Buttons
                        _buildActionButtons(themeChange, context),
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
  Widget _buildCountdownTimerFixed(DarkThemeProvider themeChange, BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: Responsive.width(20, context),
              height: Responsive.width(20, context),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _isUrgentNotifier,
                    builder: (context, isUrgent, child) {
                      return CircularProgressIndicator(
                        value: 1.0 - _progressController.value,
                        strokeWidth: Responsive.width(1.5, context),
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
                        fontSize: Responsive.width(6, context),
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

        SizedBox(height: Responsive.height(1, context)),

        // Texto do countdown
        ValueListenableBuilder<int>(
          valueListenable: _secondsNotifier,
          builder: (context, seconds, child) {
            return Text(
              'Responda em $seconds segundos',
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(3.5, context),
                color: Colors.grey,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRideInfo(DarkThemeProvider themeChange, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.width(4, context)),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Responsive.width(3, context)),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: Responsive.width(0.3, context),
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
            context,
          ),
          Container(
            width: Responsive.width(0.3, context),
            height: Responsive.height(5, context),
            color: Colors.grey.withOpacity(0.3),
          ),
          _buildInfoItem(
            'Valor',
            Constant.amountShow(amount: widget.orderModel.offerRate ?? '0'),
            Icons.monetization_on,
            themeChange,
            context,
          ),
          Container(
            width: Responsive.width(0.3, context),
            height: Responsive.height(5, context),
            color: Colors.grey.withOpacity(0.3),
          ),
          _buildInfoItem(
            'Duração',
            '~${_calculateEstimatedTime()} min',
            Icons.access_time,
            themeChange,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, DarkThemeProvider themeChange, BuildContext context) {
    // RESPONSIVIDADE HORIZONTAL: Flexible para dividir o espaço da Row
    return Flexible(
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: Responsive.width(5, context),
          ),
          SizedBox(height: Responsive.height(0.5, context)),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(3, context),
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
                fontSize: Responsive.width(3.5, context),
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

  Widget _buildActionButtons(DarkThemeProvider themeChange, BuildContext context) {
    // Os botões já estão responsivos horizontalmente graças aos Expanded
    return Row(
      children: [
        // Botão Rejeitar
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Responsive.width(3, context)),
              border: Border.all(
                color: Colors.red.withOpacity(0.5),
                width: Responsive.width(0.5, context),
              ),
            ),
            child: TextButton(
              onPressed: _hasResponded ? null : _handleReject,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: Responsive.height(1.8, context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.width(3, context)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.close,
                    color: _hasResponded ? Colors.grey : Colors.red,
                    size: Responsive.width(5, context),
                  ),
                  SizedBox(width: Responsive.width(2, context)),
                  Text(
                    'Rejeitar',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.width(4, context),
                      fontWeight: FontWeight.w600,
                      color: _hasResponded ? Colors.grey : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(width: Responsive.width(4, context)),

        // Botão Aceitar
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Responsive.width(3, context)),
              color: Colors.green,
            ),
            child: TextButton(
              onPressed: _hasResponded ? null : _handleAccept,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: Responsive.height(1.8, context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.width(3, context)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check,
                    color: Colors.white,
                    size: Responsive.width(5, context),
                  ),
                  SizedBox(width: Responsive.width(2, context)),
                  Text(
                    'Aceitar',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.width(4, context),
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