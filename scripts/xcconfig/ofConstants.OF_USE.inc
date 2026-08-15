// Proposed snippet for libs/openFrameworks/utils/ofConstants.h
// Paste near the other feature gates. Default OFF — ofGL*Renderer stays default.
// Do not apply until metalangle / dawn libs exist in libs/.

#ifndef OF_USE_ANGLE
#define OF_USE_ANGLE 0
#endif

#ifndef OF_USE_DAWN
#define OF_USE_DAWN 0
#endif
