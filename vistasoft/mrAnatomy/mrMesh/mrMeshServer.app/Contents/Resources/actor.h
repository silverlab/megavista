#ifndef _ACTOR_H_
#define _ACTOR_H_

#include "vector.h"
#include "matrix3x3.h"
#include "matrix4x4.h"
#include "commandhandler.h"
#include "color.h"

#include "polydatabuffer.h"

class CCamera;
struct SceneInfo
{
	CPolyDataBuffer	*pPolyBuffer;
	CCamera			*pCamera;
	int				nLights;

	bool			bTransparentMeshEnabled;
};

/**
	Base class for all scene objects
*/

class CActor : public CCommandHandler
{
public:
	CActor(const SceneInfo *pSI, int iActorID);
	virtual ~CActor();

	virtual void Render() = 0;
	virtual const char* GetClassName() = 0;
	int	GetID()
	{
		return iActorID;
	}

	/// "get" command handler. Derived classes overloading this function must call parent's GetProperties
	virtual bool GetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);
	/// "set" command handler. Derived classes overloading this function must call parent's SetProperties
	virtual bool SetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);

	/// Adds vDelta to vOrigin. May be redefined for special actors (2d etc.)
	/// @param vDelta Translation in world coordinates.
	virtual	void Move(CVector &vDelta)
	{
		vOrigin += vDelta;
	}

//protected:
public:

	CVector		vOrigin;
	CMatrix3x3	mRotation;

	//void		Show(bool bShow = true)	{bVisible = bShow;}
	//bool		IsVisible()	{return bVisible;}

	bool	IsAttachedToCameraSpace()	{return bInCameraSpace;}
	void	AttachToCameraSpace(bool bAttach)	{bInCameraSpace = bAttach;}

	CVector	GetCameraRelativeOrigin();

private:
	int		iActorID;	///< In-scene id
	bool	bVisible;	///< Not used yet
	bool	bInCameraSpace;	///< Parent coordinate system; if true, object is not transformed by camera matrix

protected:
	const SceneInfo	*pSceneInfo;
	

private:
//	DECLARE_COMMAND_HANDLER(CommandShow);

	DECLARE_HANDLER_TABLE()
};

#endif
