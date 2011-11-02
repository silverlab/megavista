#ifndef _IMAGEQUAD_H_
#define _IMAGEQUAD_H_

#include "actor.h"



/**

	Textured rectangle

*/



class CImageQuad : public CActor

{

public:

	CImageQuad(const SceneInfo *pSI, int iActorID);

	virtual ~CImageQuad();



	static const char *pszClassName;

	virtual const char* GetClassName() {return pszClassName;}



	virtual	void Render();

	virtual bool GetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);

	virtual bool SetProperties(CParametersMap &paramsIn, CParametersMap &paramsOut);



private:

	/// sets RGB texture

	void	SetTexture(int iWidth, int iHeight, int nColorComp, int iFormat, void *pImage);



private:

	/// OpenGL texture name

	GLuint	uTextureID;

	/// true if 4-th image data component (alpha) was supplied

	bool	bAlphaChannel;



	float	fWidth,		///< quad width

			fHeight;	///< quad height

};



#endif //_IMAGEQUAD_H_

