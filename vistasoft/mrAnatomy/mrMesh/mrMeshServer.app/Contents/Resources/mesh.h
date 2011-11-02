#ifndef _MESH_H_
#define _MESH_H_

#include "actor.h"

class CMesh : public CActor
{
public:
	CMesh(const SceneInfo *pSI, int iActorID);
	virtual ~CMesh();

	static const char *pszClassName;
	virtual const char* GetClassName() {return pszClassName;}

	virtual void Render();
	virtual bool GetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);
	virtual bool SetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);

public:
	int	FindClosestVertex(const CVector &vCoord);

public:
	struct	Vertex
	{
		CVector	vCoord;
		CVector	vNormal;
		CColor	cColor;
	};
	struct	Triangle
	{
		int v[3];
	};

public:
	int	nVertices;
	int nTriangles;

	Vertex		*pVertices;
	Triangle	*pTriangles;

private:
	static	CColor	cDefaultColor;

	void	Destroy();

	/// Converts data of VTK mesh
	/// @params paramsOut required to report errors
	bool	CreateFromVtkPolyData(vtkPolyData *pPD, CParametersMap &paramsOut);
	
	/// Converts mesh to VTK structures
	vtkPolyData	*BuildVtkPolyDataTriangles();

	/// Helper function used in mesh painting.
	/// Finds array item that is close to given point
	/// @param pArray must be [3xN]
	/// @return index in array, or -1 if point was not found
	int		FindPointInArray(CFloatArray *pArray, float *pXYZ);
	void	ResetColor(CColor &cColor);

	/// Mix colors with specified ratio
	/// @param fMixFactor "weight" of source #1 colors [0..1]
	template<class T1, class T2, class T3>
		void	MixColors(T1 *pDst, const T2 *pSrc1, const T3 *pSrc2, float fMixFactor, int nComponents);

	bool	BuildNormalsViaVTK(CParametersMap &paramsOut);
	
	/// Function adapted from mrGray. Calculates curvature values for mesh.
	/// @return array, containing -1 for most concave point, +1 for most convex
	CFloatArray* GetMrGrayCurvature(vtkPolyData* p);

	/// @param fBounds {x_min, x_max, y_min, y_max, z_min, z_max}
	void	FindBounds(float fBounds[6]);

private:
	DECLARE_COMMAND_HANDLER(CommandCube);
	DECLARE_COMMAND_HANDLER(CommandTube);
	DECLARE_COMMAND_HANDLER(CommandGrid);
	DECLARE_COMMAND_HANDLER(CommandOpenGray);
	DECLARE_COMMAND_HANDLER(CommandOpenClass);
	DECLARE_COMMAND_HANDLER(CommandOpenMRM);
	DECLARE_COMMAND_HANDLER(CommandSaveMRM);

	DECLARE_COMMAND_HANDLER(CommandResetColor);
	DECLARE_COMMAND_HANDLER(CommandPaint);
	DECLARE_COMMAND_HANDLER(CommandApplyROI);
	DECLARE_COMMAND_HANDLER(CommandCurvatures);

	DECLARE_COMMAND_HANDLER(CommandDecimate);
	DECLARE_COMMAND_HANDLER(CommandSmooth);

	DECLARE_COMMAND_HANDLER(CommandModifyMesh);
	DECLARE_COMMAND_HANDLER(CommandSetMesh);
	DECLARE_COMMAND_HANDLER(CommandBuildMesh);

	DECLARE_HANDLER_TABLE()
};

#endif //_MESH_H_
