#ifndef _COLOR_H_
#define _COLOR_H_

#include "floatarray.h"

class CColor
{
public:
	union{
		unsigned char	m_ucColor[4];
		struct
		{
			unsigned char	r, g, b, a;
		};
	};

	CColor()
	{
		r = g = b = 255;
		a = 255;
	}

	CColor(CColor &c)
	{
		*this = c;
	}

	CColor(unsigned char _r, unsigned char _g, unsigned char _b, unsigned char _a = 255)
		:r(_r), g(_g), b(_b), a(_a)
	{
	}

	operator unsigned char *()
	{
		return m_ucColor;
	}

	bool	FromArray(CFloatArray *pArray)
	{
		if (!pArray)
		{
			wxASSERT(0);
			return false;
		}
		int iSize = pArray->GetNumberOfItems();
		if ((iSize != 3) && (iSize != 4))
			return false;

		float *pData = pArray->GetPointer();
		for (int i=0; i<iSize; i++)
			m_ucColor[i] = (unsigned char)pData[i];
		if (iSize != 4)
			a = 255;
		return true;
	}
	CFloatArray* ToArray()
	{
		CFloatArray *pArray = new CFloatArray;
		if (!pArray)
			return NULL;

		//bool		bGotColors = false;

		if (!pArray->Create(1, 4))
		{
			delete pArray;
			return NULL;
		}
		for (int iComp = 0; iComp < 4; iComp++)
			pArray->SetAtAbsoluteIndex(float(m_ucColor[iComp]), iComp);
		
		return pArray;
	}
};

#endif //_COLOR_H_
