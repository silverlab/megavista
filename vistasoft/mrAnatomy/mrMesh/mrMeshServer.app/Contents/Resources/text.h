#ifndef _TEXT_H_
#define _TEXT_H_

#include "actor.h"

class CText : public CActor
{
public:
	CText(const SceneInfo *pSI, int iActorID);
	virtual ~CText();

	static const char *pszClassName;
	virtual const char* GetClassName() {return pszClassName;}

	virtual bool GetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);
	virtual bool SetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);

	virtual void	Render();
	/// Overloaded for 2d text
	virtual void	Move(CVector &vDelta);

private:
	static int		iTextActorsCounter;
	static GLuint	uFontTexture;
	static GLuint	uFontListsBase;

	bool	LoadFont();
	int		iGlyphSize;
	int		iCharSpacing;

	wxString	strText;
	CColor		cColor;
};

#endif //_TEXT_H_
