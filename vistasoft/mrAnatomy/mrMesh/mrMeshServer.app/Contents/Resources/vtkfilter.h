#ifndef _VTKILTER_H_
#define _VTKILTER_H_

#include "parametersmap.h"

class CVTKFilter
{
public:
	static bool	DecimatePolyData(vtkPolyData* &pPD, CParametersMap &paramsIn);
	static bool	Strippify(vtkPolyData* &pPD, CParametersMap &paramsIn);
	static bool	Smooth(vtkPolyData* &pPD, CParametersMap &paramsIn);
	static bool	BuildNormals(vtkPolyData* &pPD, CParametersMap &paramsIn);
	static bool	CleanPolyData(vtkPolyData* &pPD, CParametersMap &paramsIn);
};

#endif //_VTKILTER_H_
