#ifndef _LIGHT_H_
#define _LIGHT_H_

#include "actor.h"

class CLight : public CActor
{
public:
	CLight(const SceneInfo *pSI, int iActorID);
	virtual ~CLight();

	static const char *pszClassName;
	virtual const char* GetClassName() {return pszClassName;}

	virtual bool GetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);
	virtual bool SetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);

	virtual void	Render();

	void	Enable(bool bEnable = true);
	bool	IsEnabled() {return bEnabled;};

private:
	bool	bEnabled;

	enum	types
	{
		LT_OMNI,
		LT_DIRECTED,
	}iType;

	static	GLUquadricObj *quadObjSphere;

	/// static counter for creating/destorying light bulb polygon model
	static	int iGLLightsCounter;
	/// OpenGL light source id
	int		iGLLightID;

	float	m_fCutoff;
	float	m_Diffuse[4];
	float	m_Specular[4];
	float	m_Ambient[4];
};

#endif //_LIGHT_H_
