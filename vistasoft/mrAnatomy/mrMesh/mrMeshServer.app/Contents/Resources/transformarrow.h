#ifndef _TRANSFORMARROW_H_
#define _TRANSFORMARROW_H_

#include "actor.h"

class CTransformArrow : public CActor
{
public:
	CTransformArrow(const SceneInfo *pSI, int iActorID, const CVector &vArrow);
	virtual ~CTransformArrow();

	static const char *pszClassName;
	virtual const char* GetClassName() {return pszClassName;}

	virtual void Render();

public:
	void	Show(bool bShow = true);

public:
	/// modified in CCamera::UpdateProjection
//	static	float	fArrowLength;

private:
	CVector	vDirection;
	CColor	cColor;

	bool	bVisible;
};

#endif //_TRANSFORMARROW_H_
