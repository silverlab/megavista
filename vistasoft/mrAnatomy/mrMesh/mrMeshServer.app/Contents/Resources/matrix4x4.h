#ifndef _MATRIX4X4_H_
#define _MATRIX4X4_H_

#include "intel_mm.h"

class CMatrix4x4
{
public:
	float	fElements[16];

public:
	CMatrix4x4()
	{
		Identity();
	}
	CMatrix4x4(const CMatrix4x4 &m)
	{
		memmove(fElements, m.fElements, 16*sizeof(float));
	}
	CMatrix4x4(
		float a0, float a1, float a2, float a3,
		float a4, float a5, float a6, float a7,
		float a8, float a9, float a10, float a11,
		float a12, float a13, float a14, float a15
	)
	{
		fElements[0] = a0; fElements[1] = a1; fElements[2] = a2; fElements[3] = a3; 
		fElements[4] = a4; fElements[5] = a5; fElements[6] = a6; fElements[7] = a7;
		fElements[8] = a8; fElements[9] = a9; fElements[10] = a10; fElements[11] = a11;
		fElements[12] = a12; fElements[13] = a13; fElements[14] = a14; fElements[15] = a15;
	}
	CMatrix4x4(const float *fData)
	{
		memmove(fElements, fData, 16*sizeof(float));
	}

public:
	void Zero()
	{
		memset(fElements, 0, 16*sizeof(float));
	}
	void Identity()
	{
		memset(fElements, 0, 16*sizeof(float));
		fElements[0] = fElements[5] = fElements[10] = fElements[15] = 1.0f;
	}

	CMatrix4x4 operator *(CMatrix4x4 &m)
	{
		CMatrix4x4 out;

#if _CPU == CPU_PENTIUM_II
		PII_Mult00_4x4_4x4(fElements, m.fElements, out.fElements);
#elif _CPU == CPU_PENTIUM_III
//		PIII_Mult00_4x4_4x4(fElements, m.fElements, out.fElements);
		//^ trows exception for some reason
		PII_Mult00_4x4_4x4(fElements, m.fElements, out.fElements);
#else
		float *a = fElements;
		const float *b = m.fElements;

		float *c = out.fElements;

		int	iOut = 0;
		for (int i=0; i<4; i++)
		{
			for (int j=0; j<4; j++)
			{
				c[iOut] = 0;
				for (int k=0; k<4; k++)
					c[iOut] += a[i*4+k] * b[k*4+j];

				iOut++;
			}
		}
#endif
		return out;
	}

	static CMatrix4x4 RotationX(float fAngle)
	{
		float fSinA = sinf(fAngle);
		float fCosA = cosf(fAngle);

		return CMatrix4x4(
			1, 0, 0, 0,
			0, fCosA, -fSinA, 0,
			0, fSinA, fCosA, 0,
			0, 0, 0, 1);
	}

	static CMatrix4x4 RotationY(float fAngle)
	{
		float fSinA = sinf(fAngle);
		float fCosA = cosf(fAngle);

		return CMatrix4x4(
			fCosA, 0, -fSinA, 0, 
			0, 1, 0, 0,
			fSinA, 0, fCosA, 0,
			0, 0, 0, 1);
	}

	static CMatrix4x4 RotationZ(float fAngle)
	{
		float fSinA = sinf(fAngle);
		float fCosA = cosf(fAngle);

		return CMatrix4x4(
			fCosA, -fSinA, 0, 0,
			fSinA, fCosA, 0, 0, 
			0, 0, 1, 0,
			0, 0, 0, 1);
	}

	void	Translate(float fX, float fY, float fZ)
	{
		fElements[12] += fX;
		fElements[13] += fY;
		fElements[14] += fZ;
	}
};

#endif //_MATRIX4X4_H_
