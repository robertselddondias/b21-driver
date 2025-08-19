// lib/widget/ride_assignment_modal.dart
import 'dart:async';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/widget/location_view.dart';
import 'package:driver/widget/user_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  int _secondsRemaining = 15;

  @override
  void initState() {
    super.initState();

    // Configuração das animações
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 15),
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

    // Inicia countdown
    _startCountdown();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        widget.onReject();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

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
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: themeChange.getThem()
                        ? AppColors.darkContainerBackground
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header com timer
                      _buildHeader(themeChange),

                      const SizedBox(height: 20),

                      // Informações da corrida
                      _buildRideInfo(themeChange),

                      const SizedBox(height: 20),

                      // Informações do usuário
                      _buildUserInfo(),

                      const SizedBox(height: 20),

                      // Localizações
                      _buildLocationInfo(),

                      const SizedBox(height: 25),

                      // Botões de ação
                      _buildActionButtons(themeChange),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(DarkThemeProvider themeChange) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_taxi,
              color: AppColors.primary,
              size: 30,
            ),
            const SizedBox(width: 10),
            Text(
              'Nova Corrida!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: themeChange.getThem() ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // Barra de progresso circular
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: 1.0 - _progressController.value,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _secondsRemaining <= 5 ? Colors.red : AppColors.primary,
                    ),
                  );
                },
              ),
            ),
            Text(
              '$_secondsRemaining',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _secondsRemaining <= 5 ? Colors.red : AppColors.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          'Responda em $_secondsRemaining segundos',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey,
          ),
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
    return Column(
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
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: themeChange.getThem() ? Colors.white : Colors.black,
          ),
        ),
      ],
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
    return LocationView(
      sourceLocation: widget.orderModel.sourceLocationName ?? 'Local de origem',
      destinationLocation: widget.orderModel.destinationLocationName ?? 'Destino',
    );
  }

  Widget _buildActionButtons(DarkThemeProvider themeChange) {
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
              onPressed: widget.onReject,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rejeitar',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
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
          child: ButtonThem.buildButton(
            context,
            title: 'Aceitar',
            btnHeight: 50,
            onPress: widget.onAccept,
            btnWidthRatio: 1.0,
          ),
        ),
      ],
    );
  }

  String _calculateEstimatedTime() {
    // Cálculo simples baseado na distância
    // Assumindo velocidade média de 30 km/h no trânsito urbano
    try {
      double distance = double.parse(widget.orderModel.distance ?? '0');
      double estimatedMinutes = (distance / 30) * 60; // km/h para minutos
      return estimatedMinutes.round().toString();
    } catch (e) {
      return '15'; // Valor padrão
    }
  }
}