#ifndef _CAMERA_H_
#define _CAMERA_H_

#include "actor.h"

/**
	orthogonal camera defined by 6 clip planes
*/
class CCamera : public CActor
{
public:
	CCamera(const SceneInfo *pSI, int iActorID);
	virtual ~CCamera();

	static const char *pszClassName;
	virtual const char* GetClassName() {return pszClassName;}

	virtual void Render()
	{
		// don't render
		return;
	}

	virtual bool GetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);
	virtual bool SetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);

	/// Zoom in/out
	void	Zoom(float fZoomFactor);
	/// Move camera in XY plane. Use it instead of modifying vOrigin to translate
	/// camera in units corresponding to zoom level.
	/// fX add fY are measured in view area units, where 1 is viewport size (width or height)
	void	Move(float fX, float fY);

	///
	void	SetFrustum(float fWidth, float fHeight, float fNearClip, float fFarClip);
	void	GetFrustum(float *pWidth, float *pHeight, float *pNearClip, float *pFarClip);

	/// Method exporting camera view dimesions to keep size ratio for some actors
	float	GetFrustumHeight() {return fFrustumHeight;}
	/// Method exporting camera view dimesions to keep size ratio for some actors
	float	GetViewportHeight() {return fViewportHeight;}

	void	SetViewport(int x, int y, int w, int h);

	/// call after position/zoom changes
	void UpdateProjection();

private:
	GLdouble	fFrustumWidth,	///< distance between right and left clipping planes
				fFrustumHeight;	///< distance between top and bottom clipping planes
	GLdouble	fNearClip,	///< near clip plane
				fFarClip;	///< far clip plane
	
	/// values saved on SetViewport calls to preserve aspect ration on Zoom
	float		fViewportWidth,
				fViewportHeight;
};

#endif // _CAMERA_H_
