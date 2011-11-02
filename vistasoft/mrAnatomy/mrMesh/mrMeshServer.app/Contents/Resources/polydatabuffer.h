#ifndef _POLYDATABUFFER_H_
#define _POLYDATABUFFER_H_

#include "vector.h"

// stl
#include "vector"

/**
	class that keeps transformed vertices and sorts triangles by depth
*/

class CMesh;
class CScene;
class CCamera;

class CPolyDataBuffer
{
public:
	CPolyDataBuffer(CScene *pScene);
	virtual ~CPolyDataBuffer();

	bool	RegisterObject(CMesh *pMesh);
	bool	UnregisterObject(CMesh *pMesh);

	void	SetupGLArrays();
	void	Render(bool bWithGLNames = false);

	void	UpdateTransform();
	void	UpdateMeshTransform(CMesh *pMesh);
	void	SortTriangles();

private:
	CScene	*pScene;

	struct PolyObject
	{
		CMesh	*pMesh;
		int		iFirstVertexIndex;	///< offset in pTransformedVertices
		int		iFirstTriangleIndex;	///< used to delete appropriate triangles from buffer

		PolyObject(CMesh *_pMesh, int _iFirstVertex, int _iFirstTriangle):
			pMesh(_pMesh), iFirstVertexIndex(_iFirstVertex), iFirstTriangleIndex(_iFirstTriangle){}
	};
	std::vector<PolyObject*> arrayObjects;

	struct	TransformedVertex
	{
		CVector	vCoord;
		CVector	vNormal;
	};
	/// transformed by object itselft and camera object's vertices
	TransformedVertex	*pVertices;
	/// number of transformed vertices
	int		nVertices;

	struct TriangleInfo
	{
//		int v[3];		///< indices in pTransformedVertices
		PolyObject	*pOwner;
		int			iTriangleIndex;	///< index in pOwner->pMesh->pTriangles
		float		fSumZ;	///< sum(pTransformedVertices[v[i]].z) = (average_Z)*3
	};
	/// triangles built up of transformed vertices
	TriangleInfo	*pTriangles;
	/// total number of triangles
	int		nTriangles;

	/// array containing indices of triangles sorted in z-order
	int		*pTriangleOrder;

	/// Adds nItemsToAdd to array. New items are uninitialized
	bool	GrowVertexBuffer(int nItemsToAdd);
	bool	DeleteFromVertexBuffer(int iStart, int nCount);

	/// Adds nItemsToAdd to arrays pTriangles and pTriangleOrder.
	/// New items are uninitialized, triangle order is undefined
	bool	GrowTriangleBuffer(int nItemsToAdd);
	/// @remark triangle order becomes undefined
	bool	DeleteFromTriangleBuffer(int iStart, int nCount);

	void	UpdateObjectTransform(PolyObject *pObject, CCamera *pCamera);

	/// Z-comparison callback proc
	static bool CompareTrianglesZ(int i1, int i2, void *pParam);
};

#endif //_POLYDATABUFFER_H_
