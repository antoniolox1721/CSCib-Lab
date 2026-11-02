/*
 * view_record_pci6221_20ms.c
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
#include "view_record_pci6221_20ms_dt.h"

/* options for Simulink Desktop Real-Time board 0 */
static double RTWinBoardOptions0[] = {
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
};

/* list of Simulink Desktop Real-Time timers */
const int RTWinTimerCount = 1;
const double RTWinTimers[2] = {
  0.02, 0.0,
};

/* list of Simulink Desktop Real-Time boards */
const int RTWinBoardCount = 1;
RTWINBOARD RTWinBoards[1] = {
  { "National_Instruments/PCI-6221", 4294967295U, 5, RTWinBoardOptions0 },
};

/* Block signals (auto storage) */
B_view_record_pci6221_20ms_T view_record_pci6221_20ms_B;

/* Block states (auto storage) */
DW_view_record_pci6221_20ms_T view_record_pci6221_20ms_DW;

/* Real-time model */
RT_MODEL_view_record_pci6221_20ms_T view_record_pci6221_20ms_M_;
RT_MODEL_view_record_pci6221_20ms_T *const view_record_pci6221_20ms_M =
  &view_record_pci6221_20ms_M_;
real_T look1_binlxpw(real_T u0, const real_T bp0[], const real_T table[],
                     uint32_T maxIndex)
{
  real_T frac;
  uint32_T iRght;
  uint32_T iLeft;
  uint32_T bpIdx;

  /* Lookup 1-D
     Search method: 'binary'
     Use previous index: 'off'
     Interpolation method: 'Linear'
     Extrapolation method: 'Linear'
     Use last breakpoint for index at or above upper limit: 'off'
     Remove protection against out-of-range input in generated code: 'off'
   */
  /* Prelookup - Index and Fraction
     Index Search method: 'binary'
     Extrapolation method: 'Linear'
     Use previous index: 'off'
     Use last breakpoint for index at or above upper limit: 'off'
     Remove protection against out-of-range input in generated code: 'off'
   */
  if (u0 <= bp0[0U]) {
    iLeft = 0U;
    frac = (u0 - bp0[0U]) / (bp0[1U] - bp0[0U]);
  } else if (u0 < bp0[maxIndex]) {
    /* Binary Search */
    bpIdx = maxIndex >> 1U;
    iLeft = 0U;
    iRght = maxIndex;
    while (iRght - iLeft > 1U) {
      if (u0 < bp0[bpIdx]) {
        iRght = bpIdx;
      } else {
        iLeft = bpIdx;
      }

      bpIdx = (iRght + iLeft) >> 1U;
    }

    frac = (u0 - bp0[iLeft]) / (bp0[iLeft + 1U] - bp0[iLeft]);
  } else {
    iLeft = maxIndex - 1U;
    frac = (u0 - bp0[maxIndex - 1U]) / (bp0[maxIndex] - bp0[maxIndex - 1U]);
  }

  /* Interpolation 1-D
     Interpolation method: 'Linear'
     Use last breakpoint for index at or above upper limit: 'off'
     Overflow mode: 'portable wrapping'
   */
  return (table[iLeft + 1U] - table[iLeft]) * frac + table[iLeft];
}

real_T rt_roundd_snf(real_T u)
{
  real_T y;
  if (fabs(u) < 4.503599627370496E+15) {
    if (u >= 0.5) {
      y = floor(u + 0.5);
    } else if (u > -0.5) {
      y = u * 0.0;
    } else {
      y = ceil(u - 0.5);
    }
  } else {
    y = u;
  }

  return y;
}

real_T rt_remd_snf(real_T u0, real_T u1)
{
  real_T y;
  real_T u1_0;
  if (!((!rtIsNaN(u0)) && (!rtIsInf(u0)) && ((!rtIsNaN(u1)) && (!rtIsInf(u1)))))
  {
    y = (rtNaN);
  } else {
    if (u1 < 0.0) {
      u1_0 = ceil(u1);
    } else {
      u1_0 = floor(u1);
    }

    if ((u1 != 0.0) && (u1 != u1_0)) {
      u1_0 = u0 / u1;
      if (fabs(u1_0 - rt_roundd_snf(u1_0)) <= DBL_EPSILON * fabs(u1_0)) {
        y = 0.0;
      } else {
        y = fmod(u0, u1);
      }
    } else {
      y = fmod(u0, u1);
    }
  }

  return y;
}

/* Model output function */
void view_record_pci6221_20ms_output(void)
{
  /* local block i/o variables */
  real_T rtb_LookUpTable1;
  real_T currentTime;

  /* Step: '<S1>/Step' */
  currentTime = view_record_pci6221_20ms_M->Timing.t[0];

  /* Clock: '<S3>/Clock' */
  rtb_LookUpTable1 = view_record_pci6221_20ms_M->Timing.t[0];

  /* Sum: '<S3>/Sum' incorporates:
   *  S-Function (sfun_tstart): '<S3>/startTime'
   */
  rtb_LookUpTable1 -= (0.0);

  /* Math: '<S3>/Math Function' incorporates:
   *  Constant: '<S3>/Constant'
   */
  rtb_LookUpTable1 = rt_remd_snf(rtb_LookUpTable1,
    view_record_pci6221_20ms_P.Constant_Value);

  /* Lookup_n-D: '<S3>/Look-Up Table1' */
  rtb_LookUpTable1 = look1_binlxpw(rtb_LookUpTable1,
    view_record_pci6221_20ms_P.LookUpTable1_bp01Data,
    view_record_pci6221_20ms_P.RepeatingSequence_rep_seq_y, 7U);

  /* ManualSwitch: '<S1>/Manual Switch' */
  if (view_record_pci6221_20ms_P.ManualSwitch_CurrentSetting == 1) {
    /* Step: '<S1>/Step' */
    if (currentTime < view_record_pci6221_20ms_P.Step_Time) {
      view_record_pci6221_20ms_B.ManualSwitch =
        view_record_pci6221_20ms_P.Step_Y0;
    } else {
      view_record_pci6221_20ms_B.ManualSwitch =
        view_record_pci6221_20ms_P.Step_YFinal;
    }
  } else {
    /* Step: '<S1>/Step' */
    view_record_pci6221_20ms_B.ManualSwitch = rtb_LookUpTable1;
  }

  /* End of ManualSwitch: '<S1>/Manual Switch' */
  /* S-Function Block: <Root>/Tensao Motor */
  {
    {
      ANALOGIOPARM parm;
      parm.mode = (RANGEMODE) view_record_pci6221_20ms_P.TensaoMotor_RangeMode;
      parm.rangeidx = view_record_pci6221_20ms_P.TensaoMotor_VoltRange;
      RTBIO_DriverIO(0, ANALOGOUTPUT, IOWRITE, 1,
                     &view_record_pci6221_20ms_P.TensaoMotor_Channels,
                     &view_record_pci6221_20ms_B.ManualSwitch, &parm);
    }
  }

  /* S-Function Block: <Root>/Analog inputs */
  {
    ANALOGIOPARM parm;
    parm.mode = (RANGEMODE) view_record_pci6221_20ms_P.Analoginputs_RangeMode;
    parm.rangeidx = view_record_pci6221_20ms_P.Analoginputs_VoltRange;
    RTBIO_DriverIO(0, ANALOGINPUT, IOREAD, 4,
                   view_record_pci6221_20ms_P.Analoginputs_Channels,
                   &view_record_pci6221_20ms_B.Analoginputs[0], &parm);
  }

  /* Sum: '<S2>/Sum' incorporates:
   *  Constant: '<S2>/StrainOffset'
   */
  view_record_pci6221_20ms_B.Sum = view_record_pci6221_20ms_B.Analoginputs[2] +
    view_record_pci6221_20ms_P.StrainOffset_Value;
}

/* Model update function */
void view_record_pci6221_20ms_update(void)
{
  /* Update absolute time for base rate */
  /* The "clockTick0" counts the number of times the code of this task has
   * been executed. The absolute time is the multiplication of "clockTick0"
   * and "Timing.stepSize0". Size of "clockTick0" ensures timer will not
   * overflow during the application lifespan selected.
   * Timer of this task consists of two 32 bit unsigned integers.
   * The two integers represent the low bits Timing.clockTick0 and the high bits
   * Timing.clockTickH0. When the low bit overflows to 0, the high bits increment.
   */
  if (!(++view_record_pci6221_20ms_M->Timing.clockTick0)) {
    ++view_record_pci6221_20ms_M->Timing.clockTickH0;
  }

  view_record_pci6221_20ms_M->Timing.t[0] =
    view_record_pci6221_20ms_M->Timing.clockTick0 *
    view_record_pci6221_20ms_M->Timing.stepSize0 +
    view_record_pci6221_20ms_M->Timing.clockTickH0 *
    view_record_pci6221_20ms_M->Timing.stepSize0 * 4294967296.0;

  {
    /* Update absolute timer for sample time: [0.02s, 0.0s] */
    /* The "clockTick1" counts the number of times the code of this task has
     * been executed. The absolute time is the multiplication of "clockTick1"
     * and "Timing.stepSize1". Size of "clockTick1" ensures timer will not
     * overflow during the application lifespan selected.
     * Timer of this task consists of two 32 bit unsigned integers.
     * The two integers represent the low bits Timing.clockTick1 and the high bits
     * Timing.clockTickH1. When the low bit overflows to 0, the high bits increment.
     */
    if (!(++view_record_pci6221_20ms_M->Timing.clockTick1)) {
      ++view_record_pci6221_20ms_M->Timing.clockTickH1;
    }

    view_record_pci6221_20ms_M->Timing.t[1] =
      view_record_pci6221_20ms_M->Timing.clockTick1 *
      view_record_pci6221_20ms_M->Timing.stepSize1 +
      view_record_pci6221_20ms_M->Timing.clockTickH1 *
      view_record_pci6221_20ms_M->Timing.stepSize1 * 4294967296.0;
  }
}

/* Model initialize function */
void view_record_pci6221_20ms_initialize(void)
{
  /* S-Function Block: <Root>/Tensao Motor */
  {
    {
      ANALOGIOPARM parm;
      parm.mode = (RANGEMODE) view_record_pci6221_20ms_P.TensaoMotor_RangeMode;
      parm.rangeidx = view_record_pci6221_20ms_P.TensaoMotor_VoltRange;
      RTBIO_DriverIO(0, ANALOGOUTPUT, IOWRITE, 1,
                     &view_record_pci6221_20ms_P.TensaoMotor_Channels,
                     &view_record_pci6221_20ms_P.TensaoMotor_InitialValue, &parm);
    }
  }
}

/* Model terminate function */
void view_record_pci6221_20ms_terminate(void)
{
  /* S-Function Block: <Root>/Tensao Motor */
  {
    {
      ANALOGIOPARM parm;
      parm.mode = (RANGEMODE) view_record_pci6221_20ms_P.TensaoMotor_RangeMode;
      parm.rangeidx = view_record_pci6221_20ms_P.TensaoMotor_VoltRange;
      RTBIO_DriverIO(0, ANALOGOUTPUT, IOWRITE, 1,
                     &view_record_pci6221_20ms_P.TensaoMotor_Channels,
                     &view_record_pci6221_20ms_P.TensaoMotor_FinalValue, &parm);
    }
  }
}

/*========================================================================*
 * Start of Classic call interface                                        *
 *========================================================================*/
void MdlOutputs(int_T tid)
{
  view_record_pci6221_20ms_output();
  UNUSED_PARAMETER(tid);
}

void MdlUpdate(int_T tid)
{
  view_record_pci6221_20ms_update();
  UNUSED_PARAMETER(tid);
}

void MdlInitializeSizes(void)
{
}

void MdlInitializeSampleTimes(void)
{
}

void MdlInitialize(void)
{
}

void MdlStart(void)
{
  view_record_pci6221_20ms_initialize();
}

void MdlTerminate(void)
{
  view_record_pci6221_20ms_terminate();
}

/* Registration function */
RT_MODEL_view_record_pci6221_20ms_T *view_record_pci6221_20ms(void)
{
  /* Registration code */

  /* initialize non-finites */
  rt_InitInfAndNaN(sizeof(real_T));

  /* initialize real-time model */
  (void) memset((void *)view_record_pci6221_20ms_M, 0,
                sizeof(RT_MODEL_view_record_pci6221_20ms_T));

  {
    /* Setup solver object */
    rtsiSetSimTimeStepPtr(&view_record_pci6221_20ms_M->solverInfo,
                          &view_record_pci6221_20ms_M->Timing.simTimeStep);
    rtsiSetTPtr(&view_record_pci6221_20ms_M->solverInfo, &rtmGetTPtr
                (view_record_pci6221_20ms_M));
    rtsiSetStepSizePtr(&view_record_pci6221_20ms_M->solverInfo,
                       &view_record_pci6221_20ms_M->Timing.stepSize0);
    rtsiSetErrorStatusPtr(&view_record_pci6221_20ms_M->solverInfo,
                          (&rtmGetErrorStatus(view_record_pci6221_20ms_M)));
    rtsiSetRTModelPtr(&view_record_pci6221_20ms_M->solverInfo,
                      view_record_pci6221_20ms_M);
  }

  rtsiSetSimTimeStep(&view_record_pci6221_20ms_M->solverInfo, MAJOR_TIME_STEP);
  rtsiSetSolverName(&view_record_pci6221_20ms_M->solverInfo,"FixedStepDiscrete");

  /* Initialize timing info */
  {
    int_T *mdlTsMap = view_record_pci6221_20ms_M->Timing.sampleTimeTaskIDArray;
    mdlTsMap[0] = 0;
    mdlTsMap[1] = 1;
    view_record_pci6221_20ms_M->Timing.sampleTimeTaskIDPtr = (&mdlTsMap[0]);
    view_record_pci6221_20ms_M->Timing.sampleTimes =
      (&view_record_pci6221_20ms_M->Timing.sampleTimesArray[0]);
    view_record_pci6221_20ms_M->Timing.offsetTimes =
      (&view_record_pci6221_20ms_M->Timing.offsetTimesArray[0]);

    /* task periods */
    view_record_pci6221_20ms_M->Timing.sampleTimes[0] = (0.0);
    view_record_pci6221_20ms_M->Timing.sampleTimes[1] = (0.02);

    /* task offsets */
    view_record_pci6221_20ms_M->Timing.offsetTimes[0] = (0.0);
    view_record_pci6221_20ms_M->Timing.offsetTimes[1] = (0.0);
  }

  rtmSetTPtr(view_record_pci6221_20ms_M,
             &view_record_pci6221_20ms_M->Timing.tArray[0]);

  {
    int_T *mdlSampleHits = view_record_pci6221_20ms_M->Timing.sampleHitArray;
    mdlSampleHits[0] = 1;
    mdlSampleHits[1] = 1;
    view_record_pci6221_20ms_M->Timing.sampleHits = (&mdlSampleHits[0]);
  }

  rtmSetTFinal(view_record_pci6221_20ms_M, 5.0);
  view_record_pci6221_20ms_M->Timing.stepSize0 = 0.02;
  view_record_pci6221_20ms_M->Timing.stepSize1 = 0.02;

  /* External mode info */
  view_record_pci6221_20ms_M->Sizes.checksums[0] = (2322687128U);
  view_record_pci6221_20ms_M->Sizes.checksums[1] = (1499828904U);
  view_record_pci6221_20ms_M->Sizes.checksums[2] = (3646830092U);
  view_record_pci6221_20ms_M->Sizes.checksums[3] = (331724829U);

  {
    static const sysRanDType rtAlwaysEnabled = SUBSYS_RAN_BC_ENABLE;
    static RTWExtModeInfo rt_ExtModeInfo;
    static const sysRanDType *systemRan[1];
    view_record_pci6221_20ms_M->extModeInfo = (&rt_ExtModeInfo);
    rteiSetSubSystemActiveVectorAddresses(&rt_ExtModeInfo, systemRan);
    systemRan[0] = &rtAlwaysEnabled;
    rteiSetModelMappingInfoPtr(view_record_pci6221_20ms_M->extModeInfo,
      &view_record_pci6221_20ms_M->SpecialInfo.mappingInfo);
    rteiSetChecksumsPtr(view_record_pci6221_20ms_M->extModeInfo,
                        view_record_pci6221_20ms_M->Sizes.checksums);
    rteiSetTPtr(view_record_pci6221_20ms_M->extModeInfo, rtmGetTPtr
                (view_record_pci6221_20ms_M));
  }

  view_record_pci6221_20ms_M->solverInfoPtr =
    (&view_record_pci6221_20ms_M->solverInfo);
  view_record_pci6221_20ms_M->Timing.stepSize = (0.02);
  rtsiSetFixedStepSize(&view_record_pci6221_20ms_M->solverInfo, 0.02);
  rtsiSetSolverMode(&view_record_pci6221_20ms_M->solverInfo,
                    SOLVER_MODE_SINGLETASKING);

  /* block I/O */
  view_record_pci6221_20ms_M->ModelData.blockIO = ((void *)
    &view_record_pci6221_20ms_B);
  (void) memset(((void *) &view_record_pci6221_20ms_B), 0,
                sizeof(B_view_record_pci6221_20ms_T));

  /* parameters */
  view_record_pci6221_20ms_M->ModelData.defaultParam = ((real_T *)
    &view_record_pci6221_20ms_P);

  /* states (dwork) */
  view_record_pci6221_20ms_M->ModelData.dwork = ((void *)
    &view_record_pci6221_20ms_DW);
  (void) memset((void *)&view_record_pci6221_20ms_DW, 0,
                sizeof(DW_view_record_pci6221_20ms_T));

  /* data type transition information */
  {
    static DataTypeTransInfo dtInfo;
    (void) memset((char_T *) &dtInfo, 0,
                  sizeof(dtInfo));
    view_record_pci6221_20ms_M->SpecialInfo.mappingInfo = (&dtInfo);
    dtInfo.numDataTypes = 14;
    dtInfo.dataTypeSizes = &rtDataTypeSizes[0];
    dtInfo.dataTypeNames = &rtDataTypeNames[0];

    /* Block I/O transition table */
    dtInfo.B = &rtBTransTable;

    /* Parameters transition table */
    dtInfo.P = &rtPTransTable;
  }

  /* Initialize Sizes */
  view_record_pci6221_20ms_M->Sizes.numContStates = (0);/* Number of continuous states */
  view_record_pci6221_20ms_M->Sizes.numY = (0);/* Number of model outputs */
  view_record_pci6221_20ms_M->Sizes.numU = (0);/* Number of model inputs */
  view_record_pci6221_20ms_M->Sizes.sysDirFeedThru = (0);/* The model is not direct feedthrough */
  view_record_pci6221_20ms_M->Sizes.numSampTimes = (2);/* Number of sample times */
  view_record_pci6221_20ms_M->Sizes.numBlocks = (13);/* Number of blocks */
  view_record_pci6221_20ms_M->Sizes.numBlockIO = (3);/* Number of block outputs */
  view_record_pci6221_20ms_M->Sizes.numBlockPrms = (37);/* Sum of parameter "widths" */
  return view_record_pci6221_20ms_M;
}

/*========================================================================*
 * End of Classic call interface                                          *
 *========================================================================*/
