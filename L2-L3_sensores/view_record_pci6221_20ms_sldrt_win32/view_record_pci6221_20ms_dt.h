/*
 * view_record_pci6221_20ms_dt.h
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

#include "ext_types.h"

/* data type size table */
static uint_T rtDataTypeSizes[] = {
  sizeof(real_T),
  sizeof(real32_T),
  sizeof(int8_T),
  sizeof(uint8_T),
  sizeof(int16_T),
  sizeof(uint16_T),
  sizeof(int32_T),
  sizeof(uint32_T),
  sizeof(boolean_T),
  sizeof(fcn_call_T),
  sizeof(int_T),
  sizeof(pointer_T),
  sizeof(action_T),
  2*sizeof(uint32_T)
};

/* data type name table */
static const char_T * rtDataTypeNames[] = {
  "real_T",
  "real32_T",
  "int8_T",
  "uint8_T",
  "int16_T",
  "uint16_T",
  "int32_T",
  "uint32_T",
  "boolean_T",
  "fcn_call_T",
  "int_T",
  "pointer_T",
  "action_T",
  "timer_uint32_pair_T"
};

/* data type transitions for block I/O structure */
static DataTypeTransition rtBTransitions[] = {
  { (char_T *)(&view_record_pci6221_20ms_B.ManualSwitch), 0, 0, 6 }
  ,

  { (char_T *)(&view_record_pci6221_20ms_DW.TensaoMotor_PWORK), 11, 0, 3 }
};

/* data type transition table for block I/O structure */
static DataTypeTransitionTable rtBTransTable = {
  2U,
  rtBTransitions
};

/* data type transitions for Parameters structure */
static DataTypeTransition rtPTransitions[] = {
  { (char_T *)(&view_record_pci6221_20ms_P.TensaoMotor_FinalValue), 0, 0, 14 },

  { (char_T *)(&view_record_pci6221_20ms_P.TensaoMotor_Channels), 6, 0, 9 },

  { (char_T *)(&view_record_pci6221_20ms_P.Step_Time), 0, 0, 13 },

  { (char_T *)(&view_record_pci6221_20ms_P.ManualSwitch_CurrentSetting), 3, 0, 1
  }
};

/* data type transition table for Parameters structure */
static DataTypeTransitionTable rtPTransTable = {
  4U,
  rtPTransitions
};

/* [EOF] view_record_pci6221_20ms_dt.h */
