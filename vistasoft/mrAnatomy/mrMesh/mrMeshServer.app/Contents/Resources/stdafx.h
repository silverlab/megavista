#ifndef _STDAFX_H_
#define _STDAFX_H_
#ifdef _WINDOWS
	#include <windows.h>
	#pragma warning(disable: 4267)
#endif

#include <math.h>

#include "wx/wxprec.h"

#ifndef  WX_PRECOMP
  #include "wx/wx.h"
#endif //precompiled headers

#include <wx/socket.h>
#include <wx/grid.h>
#include <wx/hashmap.h>
#include <wx/glcanvas.h>
#include <wx/listbox.h>
#include <wx/listctrl.h>
#include <wx/image.h>

// OpenGL / Mesa

#include <GL/gl.h>
#include <GL/glu.h>

// VTK stuff// Shouldn't this be <Common/mumble>, <Graphics/mumble> and
// so forth?  Then we can just set the include directory
// to the one top level directory.

#include "vtkPolyDataMapper.h"
#include "vtkRenderWindow.h"
#include "vtkRenderWindowInteractor.h"
#include "vtkRenderer.h"
#include "vtkProperty.h"
#include "vtkPolyData.h"
#include "vtkPointData.h"
#include "vtkCellArray.h"
#include "vtkFloatArray.h"
#include "vtkStructuredPoints.h"
#include "vtkMarchingCubes.h"
#include "vtkUnsignedCharArray.h"

#include "vtkDecimatePro.h"
#include "vtkDecimate.h"
#include "vtkStripper.h"
#include "vtkSmoothPolyDataFilter.h"
// 2003.09.24 RFD: Added smoothing method option WindowedSinc (see vtkfilter.cpp)
#include "vtkWindowedSincPolyDataFilter.h"
#include "vtkPolyDataNormals.h"
#include "vtkMath.h"
#include "vtkTriangle.h"
#include "vtkCleanPolyData.h"
#include "vtkReverseSense.h"


#ifdef _WINDOWS
	// Microsoft VC++ code generation workaround
	#pragma pointers_to_members(full_generality, virtual_inheritance)
#endif

// Configuration

// Define this to disable realtime progress updates.
// Messaging system of wxWindows seems a bit unsafe, so this 
// may the point in stability question.
// Disabling gives stable results.

//#define _NO_PROGRESS_INDICATOR


// Set appropriate processor family to use in matrix computations.
// Note that code optimized for proper CPU works up to 10 times faster.

#define CPU_GENERIC		0
#define CPU_PENTIUM_II	1
#define CPU_PENTIUM_III	2

// CPU_PENTIUM_II code seems to be even faster than CPU_PENTIUM_III on Athlon
// and producing more accurate results.
//#define _CPU	CPU_PENTIUM_II

// wxWindows should define this on Intel platforms, but it doesn't.
// So define or undefine this manually.
//#define __INTEL__


// ------------- standard configurations -------

#ifdef _WINDOWS
	#define __INTEL__
	#define _CPU	CPU_PENTIUM_II
#else
	#define _NO_PROGRESS_INDICATOR
	#define _CPU	CPU_GENERIC
#endif //_WINDOWS

#endif //_STDAFX_H_
