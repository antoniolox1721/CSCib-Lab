/*
 * view_record_pci6221_20ms_data.c
 *
 * Code generation for model "view_record_pci6221_20ms".
 *
 * Model version              : 1.12
 * Simulink Coder version : 8.8 (R2015a) 09-Feb-2015
 * C source code generated on : Mon Sep 21 15:04:23 2026
 *
 * Target selection: rtwin.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: Specified
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "view_record_pci6221_20ms.h"
#include "view_record_pci6221_20ms_private.h"

/* Block parameters (auto storage) */
P_view_record_pci6221_20ms_T view_record_pci6221_20ms_P = {
  0.0,                                 /* Mask Parameter: TensaoMotor_FinalValue
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */
  0.0,                                 /* Mask Parameter: TensaoMotor_InitialValue
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */
  10.0,                                /* Mask Parameter: TensaoMotor_MaxMissedTicks
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */
  10.0,                                /* Mask Parameter: Analoginputs_MaxMissedTicks
                                        * Referenced by: '<Root>/Analog inputs'
                                        */
  0.0,                                 /* Mask Parameter: TensaoMotor_YieldWhenWaiting
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */
  0.0,                                 /* Mask Parameter: Analoginputs_YieldWhenWaiting
                                        * Referenced by: '<Root>/Analog inputs'
                                        */

  /*  Mask Parameter: RepeatingSequence_rep_seq_y
   * Referenced by: '<S3>/Look-Up Table1'
   */
  { 1.0, 1.0, 0.0, 0.0, -1.0, -1.0, 0.0, 0.0 },
  0,                                   /* Mask Parameter: TensaoMotor_Channels
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */

  /*  Mask Parameter: Analoginputs_Channels
   * Referenced by: '<Root>/Analog inputs'
   */
  { 0, 1, 2, 3 },
  0,                                   /* Mask Parameter: TensaoMotor_RangeMode
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */
  0,                                   /* Mask Parameter: Analoginputs_RangeMode
                                        * Referenced by: '<Root>/Analog inputs'
                                        */
  0,                                   /* Mask Parameter: TensaoMotor_VoltRange
                                        * Referenced by: '<Root>/Tensao Motor'
                                        */
  0,                                   /* Mask Parameter: Analoginputs_VoltRange
                                        * Referenced by: '<Root>/Analog inputs'
                                        */
  1.0,                                 /* Expression: 1
                                        * Referenced by: '<S1>/Step'
                                        */
  0.0,                                 /* Expression: 0
                                        * Referenced by: '<S1>/Step'
                                        */
  0.0,                                 /* Expression: 0
                                        * Referenced by: '<S1>/Step'
                                        */
  4.0,                                 /* Expression: period
                                        * Referenced by: '<S3>/Constant'
                                        */

  /*  Expression: rep_seq_t - min(rep_seq_t)
   * Referenced by: '<S3>/Look-Up Table1'
   */
  { 0.0, 0.9999, 1.0, 1.9999, 2.0, 2.9999, 3.0, 4.0 },
  0.0,                                 /* Expression: 0
                                        * Referenced by: '<S2>/StrainOffset'
                                        */
  1U                                   /* Computed Parameter: ManualSwitch_CurrentSetting
                                        * Referenced by: '<S1>/Manual Switch'
                                        */
};
