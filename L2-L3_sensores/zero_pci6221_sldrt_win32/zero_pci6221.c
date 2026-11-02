/*
 * zero_pci6221.c
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
#include "zero_pci6221_dt.h"

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
  0.001, 0.0,
};

/* list of Simulink Desktop Real-Time boards */
const int RTWinBoardCount = 1;
RTWINBOARD RTWinBoards[1] = {
  { "National_Instruments/PCI-6221", 4294967295U, 5, RTWinBoardOptions0 },
};

/* Block signals (auto storage) */
B_zero_pci6221_T zero_pci6221_B;

/* Continuous states */
X_zero_pci6221_T zero_pci6221_X;

/* Block states (auto storage) */
DW_zero_pci6221_T zero_pci6221_DW;

/* Real-time model */
RT_MODEL_zero_pci6221_T zero_pci6221_M_;
RT_MODEL_zero_pci6221_T *const zero_pci6221_M = &zero_pci6221_M_;

/*
 * This function updates continuous states using the ODE3 fixed-step
 * solver algorithm
 */
static void rt_ertODEUpdateContinuousStates(RTWSolverInfo *si )
{
  /* Solver Matrices */
  static const real_T rt_ODE3_A[3] = {
    1.0/2.0, 3.0/4.0, 1.0
  };

  static const real_T rt_ODE3_B[3][3] = {
    { 1.0/2.0, 0.0, 0.0 },

    { 0.0, 3.0/4.0, 0.0 },

    { 2.0/9.0, 1.0/3.0, 4.0/9.0 }
  };

  time_T t = rtsiGetT(si);
  time_T tnew = rtsiGetSolverStopTime(si);
  time_T h = rtsiGetStepSize(si);
  real_T *x = rtsiGetContStates(si);
  ODE3_IntgData *id = (ODE3_IntgData *)rtsiGetSolverData(si);
  real_T *y = id->y;
  real_T *f0 = id->f[0];
  real_T *f1 = id->f[1];
  real_T *f2 = id->f[2];
  real_T hB[3];
  int_T i;
  int_T nXc = 1;
  rtsiSetSimTimeStep(si,MINOR_TIME_STEP);

  /* Save the state values at time t in y, we'll use x as ynew. */
  (void) memcpy(y, x,
                (uint_T)nXc*sizeof(real_T));

  /* Assumes that rtsiSetT and ModelOutputs are up-to-date */
  /* f0 = f(t,y) */
  rtsiSetdX(si, f0);
  zero_pci6221_derivatives();

  /* f(:,2) = feval(odefile, t + hA(1), y + f*hB(:,1), args(:)(*)); */
  hB[0] = h * rt_ODE3_B[0][0];
  for (i = 0; i < nXc; i++) {
    x[i] = y[i] + (f0[i]*hB[0]);
  }

  rtsiSetT(si, t + h*rt_ODE3_A[0]);
  rtsiSetdX(si, f1);
  zero_pci6221_output();
  zero_pci6221_derivatives();

  /* f(:,3) = feval(odefile, t + hA(2), y + f*hB(:,2), args(:)(*)); */
  for (i = 0; i <= 1; i++) {
    hB[i] = h * rt_ODE3_B[1][i];
  }

  for (i = 0; i < nXc; i++) {
    x[i] = y[i] + (f0[i]*hB[0] + f1[i]*hB[1]);
  }

  rtsiSetT(si, t + h*rt_ODE3_A[1]);
  rtsiSetdX(si, f2);
  zero_pci6221_output();
  zero_pci6221_derivatives();

  /* tnew = t + hA(3);
     ynew = y + f*hB(:,3); */
  for (i = 0; i <= 2; i++) {
    hB[i] = h * rt_ODE3_B[2][i];
  }

  for (i = 0; i < nXc; i++) {
    x[i] = y[i] + (f0[i]*hB[0] + f1[i]*hB[1] + f2[i]*hB[2]);
  }

  rtsiSetT(si, tnew);
  rtsiSetSimTimeStep(si,MAJOR_TIME_STEP);
}

/* Model output function */
void zero_pci6221_output(void)
{
  real_T *lastU;
  real_T rtb_Sum1;
  real_T rtb_IdealDerivative;
  if (rtmIsMajorTimeStep(zero_pci6221_M)) {
    /* set solver stop time */
    if (!(zero_pci6221_M->Timing.clockTick0+1)) {
      rtsiSetSolverStopTime(&zero_pci6221_M->solverInfo,
                            ((zero_pci6221_M->Timing.clockTickH0 + 1) *
        zero_pci6221_M->Timing.stepSize0 * 4294967296.0));
    } else {
      rtsiSetSolverStopTime(&zero_pci6221_M->solverInfo,
                            ((zero_pci6221_M->Timing.clockTick0 + 1) *
        zero_pci6221_M->Timing.stepSize0 + zero_pci6221_M->Timing.clockTickH0 *
        zero_pci6221_M->Timing.stepSize0 * 4294967296.0));
    }
  }                                    /* end MajorTimeStep */

  /* Update absolute time of base rate at minor time step */
  if (rtmIsMinorTimeStep(zero_pci6221_M)) {
    zero_pci6221_M->Timing.t[0] = rtsiGetT(&zero_pci6221_M->solverInfo);
  }

  /* Step: '<Root>/pulse' */
  if (zero_pci6221_M->Timing.t[0] < zero_pci6221_P.pulse_Time) {
    zero_pci6221_B.pulse = zero_pci6221_P.pulse_Y0;
  } else {
    zero_pci6221_B.pulse = zero_pci6221_P.pulse_YFinal;
  }

  /* End of Step: '<Root>/pulse' */
  if (rtmIsMajorTimeStep(zero_pci6221_M)) {
    /* S-Function Block: <Root>/Potenciometro */
    {
      ANALOGIOPARM parm;
      parm.mode = (RANGEMODE) zero_pci6221_P.Potenciometro_RangeMode;
      parm.rangeidx = zero_pci6221_P.Potenciometro_VoltRange;
      RTBIO_DriverIO(0, ANALOGINPUT, IOREAD, 1,
                     &zero_pci6221_P.Potenciometro_Channels,
                     &zero_pci6221_B.Potenciometro, &parm);
    }

    /* S-Function Block: <Root>/Extensometro */
    {
      ANALOGIOPARM parm;
      parm.mode = (RANGEMODE) zero_pci6221_P.Extensometro_RangeMode;
      parm.rangeidx = zero_pci6221_P.Extensometro_VoltRange;
      RTBIO_DriverIO(0, ANALOGINPUT, IOREAD, 1,
                     &zero_pci6221_P.Extensometro_Channels,
                     &zero_pci6221_B.Extensometro, &parm);
    }

    /* Gain: '<Root>/Ganho Calib Pot' */
    zero_pci6221_B.GanhoCalibPot = zero_pci6221_P.GanhoCalibPot_Gain *
      zero_pci6221_B.Potenciometro;
  }

  /* Sum: '<Root>/Sum1' incorporates:
   *  Gain: '<Root>/Graus para Radianos'
   */
  rtb_Sum1 = zero_pci6221_P.GrausparaRadianos_Gain * zero_pci6221_B.pulse -
    zero_pci6221_B.GanhoCalibPot;

  /* Gain: '<S1>/Derivative Gain' */
  zero_pci6221_B.DerivativeGain = zero_pci6221_P.PIDController_D * rtb_Sum1;

  /* Derivative: '<S1>/Ideal Derivative' */
  if ((zero_pci6221_DW.TimeStampA >= zero_pci6221_M->Timing.t[0]) &&
      (zero_pci6221_DW.TimeStampB >= zero_pci6221_M->Timing.t[0])) {
    rtb_IdealDerivative = 0.0;
  } else {
    rtb_IdealDerivative = zero_pci6221_DW.TimeStampA;
    lastU = &zero_pci6221_DW.LastUAtTimeA;
    if (zero_pci6221_DW.TimeStampA < zero_pci6221_DW.TimeStampB) {
      if (zero_pci6221_DW.TimeStampB < zero_pci6221_M->Timing.t[0]) {
        rtb_IdealDerivative = zero_pci6221_DW.TimeStampB;
        lastU = &zero_pci6221_DW.LastUAtTimeB;
      }
    } else {
      if (zero_pci6221_DW.TimeStampA >= zero_pci6221_M->Timing.t[0]) {
        rtb_IdealDerivative = zero_pci6221_DW.TimeStampB;
        lastU = &zero_pci6221_DW.LastUAtTimeB;
      }
    }

    rtb_IdealDerivative = (zero_pci6221_B.DerivativeGain - *lastU) /
      (zero_pci6221_M->Timing.t[0] - rtb_IdealDerivative);
  }

  /* End of Derivative: '<S1>/Ideal Derivative' */

  /* Sum: '<S1>/Sum' incorporates:
   *  Gain: '<S1>/Proportional Gain'
   *  Integrator: '<S1>/Integrator'
   */
  rtb_IdealDerivative += zero_pci6221_P.PIDController_P * rtb_Sum1 +
    zero_pci6221_X.Integrator_CSTATE;

  /* Saturate: '<Root>/Saturation' */
  if (rtb_IdealDerivative > zero_pci6221_P.Saturation_UpperSat) {
    zero_pci6221_B.Saturation = zero_pci6221_P.Saturation_UpperSat;
  } else if (rtb_IdealDerivative < zero_pci6221_P.Saturation_LowerSat) {
    zero_pci6221_B.Saturation = zero_pci6221_P.Saturation_LowerSat;
  } else {
    zero_pci6221_B.Saturation = rtb_IdealDerivative;
  }

  /* End of Saturate: '<Root>/Saturation' */
  if (rtmIsMajorTimeStep(zero_pci6221_M)) {
    /* S-Function Block: <Root>/Tensao Motor */
    {
      {
        ANALOGIOPARM parm;
        parm.mode = (RANGEMODE) zero_pci6221_P.TensaoMotor_RangeMode;
        parm.rangeidx = zero_pci6221_P.TensaoMotor_VoltRange;
        RTBIO_DriverIO(0, ANALOGOUTPUT, IOWRITE, 1,
                       &zero_pci6221_P.TensaoMotor_Channels,
                       &zero_pci6221_B.Saturation, &parm);
      }
    }
  }

  /* Clock: '<S2>/Clock' */
  zero_pci6221_B.Clock = zero_pci6221_M->Timing.t[0];
  if (rtmIsMajorTimeStep(zero_pci6221_M)) {
    /* SignalConversion: '<S2>/TmpSignal ConversionAtTo WorkspaceInport1' */
    zero_pci6221_B.TmpSignalConversionAtToWorkspac[0] = zero_pci6221_B.Clock;
    zero_pci6221_B.TmpSignalConversionAtToWorkspac[1] = zero_pci6221_B.pulse;
    zero_pci6221_B.TmpSignalConversionAtToWorkspac[2] =
      zero_pci6221_B.Potenciometro;
    zero_pci6221_B.TmpSignalConversionAtToWorkspac[3] =
      zero_pci6221_B.Extensometro;
  }

  /* Gain: '<S1>/Integral Gain' */
  zero_pci6221_B.IntegralGain = zero_pci6221_P.PIDController_I * rtb_Sum1;
}

/* Model update function */
void zero_pci6221_update(void)
{
  real_T *lastU;

  /* Update for Derivative: '<S1>/Ideal Derivative' */
  if (zero_pci6221_DW.TimeStampA == (rtInf)) {
    zero_pci6221_DW.TimeStampA = zero_pci6221_M->Timing.t[0];
    lastU = &zero_pci6221_DW.LastUAtTimeA;
  } else if (zero_pci6221_DW.TimeStampB == (rtInf)) {
    zero_pci6221_DW.TimeStampB = zero_pci6221_M->Timing.t[0];
    lastU = &zero_pci6221_DW.LastUAtTimeB;
  } else if (zero_pci6221_DW.TimeStampA < zero_pci6221_DW.TimeStampB) {
    zero_pci6221_DW.TimeStampA = zero_pci6221_M->Timing.t[0];
    lastU = &zero_pci6221_DW.LastUAtTimeA;
  } else {
    zero_pci6221_DW.TimeStampB = zero_pci6221_M->Timing.t[0];
    lastU = &zero_pci6221_DW.LastUAtTimeB;
  }

  *lastU = zero_pci6221_B.DerivativeGain;

  /* End of Update for Derivative: '<S1>/Ideal Derivative' */
  if (rtmIsMajorTimeStep(zero_pci6221_M)) {
    rt_ertODEUpdateContinuousStates(&zero_pci6221_M->solverInfo);
  }

  /* Update absolute time for base rate */
  /* The "clockTick0" counts the number of times the code of this task has
   * been executed. The absolute time is the multiplication of "clockTick0"
   * and "Timing.stepSize0". Size of "clockTick0" ensures timer will not
   * overflow during the application lifespan selected.
   * Timer of this task consists of two 32 bit unsigned integers.
   * The two integers represent the low bits Timing.clockTick0 and the high bits
   * Timing.clockTickH0. When the low bit overflows to 0, the high bits increment.
   */
  if (!(++zero_pci6221_M->Timing.clockTick0)) {
    ++zero_pci6221_M->Timing.clockTickH0;
  }

  zero_pci6221_M->Timing.t[0] = rtsiGetSolverStopTime
    (&zero_pci6221_M->solverInfo);

  {
    /* Update absolute timer for sample time: [0.001s, 0.0s] */
    /* The "clockTick1" counts the number of times the code of this task has
     * been executed. The absolute time is the multiplication of "clockTick1"
     * and "Timing.stepSize1". Size of "clockTick1" ensures timer will not
     * overflow during the application lifespan selected.
     * Timer of this task consists of two 32 bit unsigned integers.
     * The two integers represent the low bits Timing.clockTick1 and the high bits
     * Timing.clockTickH1. When the low bit overflows to 0, the high bits increment.
     */
    if (!(++zero_pci6221_M->Timing.clockTick1)) {
      ++zero_pci6221_M->Timing.clockTickH1;
    }

    zero_pci6221_M->Timing.t[1] = zero_pci6221_M->Timing.clockTick1 *
      zero_pci6221_M->Timing.stepSize1 + zero_pci6221_M->Timing.clockTickH1 *
      zero_pci6221_M->Timing.stepSize1 * 4294967296.0;
  }
}

/* Derivatives for root system: '<Root>' */
void zero_pci6221_derivatives(void)
{
  XDot_zero_pci6221_T *_rtXdot;
  _rtXdot = ((XDot_zero_pci6221_T *) zero_pci6221_M->ModelData.derivs);

  /* Derivatives for Integrator: '<S1>/Integrator' */
  _rtXdot->Integrator_CSTATE = zero_pci6221_B.IntegralGain;
}

/* Model initialize function */
void zero_pci6221_initialize(void)
{
  /* S-Function Block: <Root>/Tensao Motor */
  {
    {
      ANALOGIOPARM parm;
      parm.mode = (RANGEMODE) zero_pci6221_P.TensaoMotor_RangeMode;
      parm.rangeidx = zero_pci6221_P.TensaoMotor_VoltRange;
      RTBIO_DriverIO(0, ANALOGOUTPUT, IOWRITE, 1,
                     &zero_pci6221_P.TensaoMotor_Channels,
                     &zero_pci6221_P.TensaoMotor_InitialValue, &parm);
    }
  }

  /* InitializeConditions for Integrator: '<S1>/Integrator' */
  zero_pci6221_X.Integrator_CSTATE = zero_pci6221_P.Integrator_IC;

  /* InitializeConditions for Derivative: '<S1>/Ideal Derivative' */
  zero_pci6221_DW.TimeStampA = (rtInf);
  zero_pci6221_DW.TimeStampB = (rtInf);
}

/* Model terminate function */
void zero_pci6221_terminate(void)
{
  /* S-Function Block: <Root>/Tensao Motor */
  {
    {
      ANALOGIOPARM parm;
      parm.mode = (RANGEMODE) zero_pci6221_P.TensaoMotor_RangeMode;
      parm.rangeidx = zero_pci6221_P.TensaoMotor_VoltRange;
      RTBIO_DriverIO(0, ANALOGOUTPUT, IOWRITE, 1,
                     &zero_pci6221_P.TensaoMotor_Channels,
                     &zero_pci6221_P.TensaoMotor_FinalValue, &parm);
    }
  }
}

/*========================================================================*
 * Start of Classic call interface                                        *
 *========================================================================*/

/* Solver interface called by GRT_Main */
#ifndef USE_GENERATED_SOLVER

void rt_ODECreateIntegrationData(RTWSolverInfo *si)
{
  UNUSED_PARAMETER(si);
  return;
}                                      /* do nothing */

void rt_ODEDestroyIntegrationData(RTWSolverInfo *si)
{
  UNUSED_PARAMETER(si);
  return;
}                                      /* do nothing */

void rt_ODEUpdateContinuousStates(RTWSolverInfo *si)
{
  UNUSED_PARAMETER(si);
  return;
}                                      /* do nothing */

#endif

void MdlOutputs(int_T tid)
{
  zero_pci6221_output();
  UNUSED_PARAMETER(tid);
}

void MdlUpdate(int_T tid)
{
  zero_pci6221_update();
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
  zero_pci6221_initialize();
}

void MdlTerminate(void)
{
  zero_pci6221_terminate();
}

/* Registration function */
RT_MODEL_zero_pci6221_T *zero_pci6221(void)
{
  /* Registration code */

  /* initialize non-finites */
  rt_InitInfAndNaN(sizeof(real_T));

  /* initialize real-time model */
  (void) memset((void *)zero_pci6221_M, 0,
                sizeof(RT_MODEL_zero_pci6221_T));

  {
    /* Setup solver object */
    rtsiSetSimTimeStepPtr(&zero_pci6221_M->solverInfo,
                          &zero_pci6221_M->Timing.simTimeStep);
    rtsiSetTPtr(&zero_pci6221_M->solverInfo, &rtmGetTPtr(zero_pci6221_M));
    rtsiSetStepSizePtr(&zero_pci6221_M->solverInfo,
                       &zero_pci6221_M->Timing.stepSize0);
    rtsiSetdXPtr(&zero_pci6221_M->solverInfo, &zero_pci6221_M->ModelData.derivs);
    rtsiSetContStatesPtr(&zero_pci6221_M->solverInfo, (real_T **)
                         &zero_pci6221_M->ModelData.contStates);
    rtsiSetNumContStatesPtr(&zero_pci6221_M->solverInfo,
      &zero_pci6221_M->Sizes.numContStates);
    rtsiSetErrorStatusPtr(&zero_pci6221_M->solverInfo, (&rtmGetErrorStatus
      (zero_pci6221_M)));
    rtsiSetRTModelPtr(&zero_pci6221_M->solverInfo, zero_pci6221_M);
  }

  rtsiSetSimTimeStep(&zero_pci6221_M->solverInfo, MAJOR_TIME_STEP);
  zero_pci6221_M->ModelData.intgData.y = zero_pci6221_M->ModelData.odeY;
  zero_pci6221_M->ModelData.intgData.f[0] = zero_pci6221_M->ModelData.odeF[0];
  zero_pci6221_M->ModelData.intgData.f[1] = zero_pci6221_M->ModelData.odeF[1];
  zero_pci6221_M->ModelData.intgData.f[2] = zero_pci6221_M->ModelData.odeF[2];
  zero_pci6221_M->ModelData.contStates = ((real_T *) &zero_pci6221_X);
  rtsiSetSolverData(&zero_pci6221_M->solverInfo, (void *)
                    &zero_pci6221_M->ModelData.intgData);
  rtsiSetSolverName(&zero_pci6221_M->solverInfo,"ode3");

  /* Initialize timing info */
  {
    int_T *mdlTsMap = zero_pci6221_M->Timing.sampleTimeTaskIDArray;
    mdlTsMap[0] = 0;
    mdlTsMap[1] = 1;
    zero_pci6221_M->Timing.sampleTimeTaskIDPtr = (&mdlTsMap[0]);
    zero_pci6221_M->Timing.sampleTimes =
      (&zero_pci6221_M->Timing.sampleTimesArray[0]);
    zero_pci6221_M->Timing.offsetTimes =
      (&zero_pci6221_M->Timing.offsetTimesArray[0]);

    /* task periods */
    zero_pci6221_M->Timing.sampleTimes[0] = (0.0);
    zero_pci6221_M->Timing.sampleTimes[1] = (0.001);

    /* task offsets */
    zero_pci6221_M->Timing.offsetTimes[0] = (0.0);
    zero_pci6221_M->Timing.offsetTimes[1] = (0.0);
  }

  rtmSetTPtr(zero_pci6221_M, &zero_pci6221_M->Timing.tArray[0]);

  {
    int_T *mdlSampleHits = zero_pci6221_M->Timing.sampleHitArray;
    mdlSampleHits[0] = 1;
    mdlSampleHits[1] = 1;
    zero_pci6221_M->Timing.sampleHits = (&mdlSampleHits[0]);
  }

  rtmSetTFinal(zero_pci6221_M, 20.0);
  zero_pci6221_M->Timing.stepSize0 = 0.001;
  zero_pci6221_M->Timing.stepSize1 = 0.001;

  /* External mode info */
  zero_pci6221_M->Sizes.checksums[0] = (1978484324U);
  zero_pci6221_M->Sizes.checksums[1] = (2017936269U);
  zero_pci6221_M->Sizes.checksums[2] = (2125807735U);
  zero_pci6221_M->Sizes.checksums[3] = (3870627461U);

  {
    static const sysRanDType rtAlwaysEnabled = SUBSYS_RAN_BC_ENABLE;
    static RTWExtModeInfo rt_ExtModeInfo;
    static const sysRanDType *systemRan[1];
    zero_pci6221_M->extModeInfo = (&rt_ExtModeInfo);
    rteiSetSubSystemActiveVectorAddresses(&rt_ExtModeInfo, systemRan);
    systemRan[0] = &rtAlwaysEnabled;
    rteiSetModelMappingInfoPtr(zero_pci6221_M->extModeInfo,
      &zero_pci6221_M->SpecialInfo.mappingInfo);
    rteiSetChecksumsPtr(zero_pci6221_M->extModeInfo,
                        zero_pci6221_M->Sizes.checksums);
    rteiSetTPtr(zero_pci6221_M->extModeInfo, rtmGetTPtr(zero_pci6221_M));
  }

  zero_pci6221_M->solverInfoPtr = (&zero_pci6221_M->solverInfo);
  zero_pci6221_M->Timing.stepSize = (0.001);
  rtsiSetFixedStepSize(&zero_pci6221_M->solverInfo, 0.001);
  rtsiSetSolverMode(&zero_pci6221_M->solverInfo, SOLVER_MODE_SINGLETASKING);

  /* block I/O */
  zero_pci6221_M->ModelData.blockIO = ((void *) &zero_pci6221_B);

  {
    zero_pci6221_B.pulse = 0.0;
    zero_pci6221_B.Potenciometro = 0.0;
    zero_pci6221_B.Extensometro = 0.0;
    zero_pci6221_B.GanhoCalibPot = 0.0;
    zero_pci6221_B.DerivativeGain = 0.0;
    zero_pci6221_B.Saturation = 0.0;
    zero_pci6221_B.Clock = 0.0;
    zero_pci6221_B.TmpSignalConversionAtToWorkspac[0] = 0.0;
    zero_pci6221_B.TmpSignalConversionAtToWorkspac[1] = 0.0;
    zero_pci6221_B.TmpSignalConversionAtToWorkspac[2] = 0.0;
    zero_pci6221_B.TmpSignalConversionAtToWorkspac[3] = 0.0;
    zero_pci6221_B.IntegralGain = 0.0;
  }

  /* parameters */
  zero_pci6221_M->ModelData.defaultParam = ((real_T *)&zero_pci6221_P);

  /* states (continuous) */
  {
    real_T *x = (real_T *) &zero_pci6221_X;
    zero_pci6221_M->ModelData.contStates = (x);
    (void) memset((void *)&zero_pci6221_X, 0,
                  sizeof(X_zero_pci6221_T));
  }

  /* states (dwork) */
  zero_pci6221_M->ModelData.dwork = ((void *) &zero_pci6221_DW);
  (void) memset((void *)&zero_pci6221_DW, 0,
                sizeof(DW_zero_pci6221_T));
  zero_pci6221_DW.TimeStampA = 0.0;
  zero_pci6221_DW.LastUAtTimeA = 0.0;
  zero_pci6221_DW.TimeStampB = 0.0;
  zero_pci6221_DW.LastUAtTimeB = 0.0;

  /* data type transition information */
  {
    static DataTypeTransInfo dtInfo;
    (void) memset((char_T *) &dtInfo, 0,
                  sizeof(dtInfo));
    zero_pci6221_M->SpecialInfo.mappingInfo = (&dtInfo);
    dtInfo.numDataTypes = 14;
    dtInfo.dataTypeSizes = &rtDataTypeSizes[0];
    dtInfo.dataTypeNames = &rtDataTypeNames[0];

    /* Block I/O transition table */
    dtInfo.B = &rtBTransTable;

    /* Parameters transition table */
    dtInfo.P = &rtPTransTable;
  }

  /* Initialize Sizes */
  zero_pci6221_M->Sizes.numContStates = (1);/* Number of continuous states */
  zero_pci6221_M->Sizes.numPeriodicContStates = (0);/* Number of periodic continuous states */
  zero_pci6221_M->Sizes.numY = (0);    /* Number of model outputs */
  zero_pci6221_M->Sizes.numU = (0);    /* Number of model inputs */
  zero_pci6221_M->Sizes.sysDirFeedThru = (0);/* The model is not direct feedthrough */
  zero_pci6221_M->Sizes.numSampTimes = (2);/* Number of sample times */
  zero_pci6221_M->Sizes.numBlocks = (18);/* Number of blocks */
  zero_pci6221_M->Sizes.numBlockIO = (9);/* Number of block outputs */
  zero_pci6221_M->Sizes.numBlockPrms = (28);/* Sum of parameter "widths" */
  return zero_pci6221_M;
}

/*========================================================================*
 * End of Classic call interface                                          *
 *========================================================================*/
