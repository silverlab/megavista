#ifndef _POLYLINE_H_
#define _POLYLINE_H_

#include "actor.h"

class CPolyLine : public CActor
{
public:
	CPolyLine(const SceneInfo *pSI, int iActorID);
	virtual ~CPolyLine();

	static const char *pszClassName;
	virtual const char* GetClassName() {return pszClassName;}

	virtual void Render();

	virtual bool SetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);
	virtual bool GetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);

private:
	int		nPoints;
	CVector	*pPoints;
	CColor	cColor;

	float	fLineWidth;

	void Destroy();
};

#endif //_POLYLINE_H_
