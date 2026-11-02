/*
 * zero_pci6221_data.c
 *
 * Code generation for model "zero_pci6221".
 *
 * Model version              : 1.40
 * Simulink Coder version : 8.8 (R2015a) 09-Feb-2015
 * C source code generated on : Mon Sep 21 13:48:07 2026
 *
 * Target selection: rtwin.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: 32-bit Real-Time Windows Target
 * Emulation hardware selection:
 *    Differs from embedded hardware (32-bit Generic)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "zero_pci6221.h"
#include "zero_pci6221_private.h"

/* Block parameters (auto storage) */
P_zero_pci6221_T zero_pci6221_P = {
  0.0,                                 /* Mask Parameter: PIDController_D
                                        * Referenced by: '<S1>/Derivative Gain'
                                        */
  0.0,                                 /* Mask Parameter: TensaoMotor_FinalValue
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */
  1.0,                                 /* Mask Parameter: PIDController_I
                                        * Referenced by: '<S1>/Integral Gain'
                                        */
  0.0,                                 /* Mask Parameter: TensaoMotor_InitialValue
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */
  10.0,                                /* Mask Parameter: Potenciometro_MaxMissedTicks
                                        * Referenced by: '<Root>/Potenciometro'
                                        */
  10.0,                                /* Mask Parameter: Extensometro_MaxMissedTicks
                                        * Referenced by: '<Root>/Extensometro'
                                        */
  10.0,                                /* Mask Parameter: TensaoMotor_MaxMissedTicks
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */
  2.2,                                 /* Mask Parameter: PIDController_P
                                        * Referenced by: '<S1>/Proportional Gain'
                                        */
  0.0,                                 /* Mask Parameter: Potenciometro_YieldWhenWaiting
                                        * Referenced by: '<Root>/Potenciometro'
                                        */
  0.0,                                 /* Mask Parameter: Extensometro_YieldWhenWaiting
                                        * Referenced by: '<Root>/Extensometro'
                                        */
  0.0,                                 /* Mask Parameter: TensaoMotor_YieldWhenWaiting
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */
  0,                                   /* Mask Parameter: Potenciometro_Channels
                                        * Referenced by: '<Root>/Potenciometro'
                                        */
  1,                                   /* Mask Parameter: Extensometro_Channels
                                        * Referenced by: '<Root>/Extensometro'
                                        */
  0,                                   /* Mask Parameter: TensaoMotor_Channels
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */
  0,                                   /* Mask Parameter: Potenciometro_RangeMode
                                        * Referenced by: '<Root>/Potenciometro'
                                        */
  0,                                   /* Mask Parameter: Extensometro_RangeMode
                                        * Referenced by: '<Root>/Extensometro'
                                        */
  0,                                   /* Mask Parameter: TensaoMotor_RangeMode
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */
  0,                                   /* Mask Parameter: Potenciometro_VoltRange
                                        * Referenced by: '<Root>/Potenciometro'
                                        */
  0,                                   /* Mask Parameter: Extensometro_VoltRange
                                        * Referenced by: '<Root>/Extensometro'
                                        */
  0,                                   /* Mask Parameter: TensaoMotor_VoltRange
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */
  3.0,                                 /* Expression: 3
                                        * Referenced by: '<Root>/pulse'
                                        */
  20.0,                                /* Expression: 20
                                        * Referenced by: '<Root>/pulse'
                                        */
  0.0,                                 /* Expression: 0
                                        * Referenced by: '<Root>/pulse'
                                        */
  0.017453292519943295,                /* Expression: pi/180
                                        * Referenced by: '<Root>/Graus para Radianos'
                                        */
  0.6144,                              /* Expression: 0.6144
                                        * Referenced by: '<Root>/Ganho Calib Pot'
                                        */
  0.0,                                 /* Expression: 0
                                        * Referenced by: '<S1>/Integrator'
                                        */
  1.0,                                 /* Expression: 1
                                        * Referenced by: '<Root>/Saturation'
                                        */
  -1.0                                 /* Expression: -1
                                        * Referenced by: '<Root>/Saturation'
                                        */
};
