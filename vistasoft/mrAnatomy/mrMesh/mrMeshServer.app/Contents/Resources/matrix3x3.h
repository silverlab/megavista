#ifndef _MATRIX3X3_H_
#define _MATRIX3X3_H_

#include "helpers.h"
#include "vector.h"
#include "intel_mm.h"

/**
	Rotation matrix
*/

class CMatrix3x3
{
public:
	float	fElements[9];

public:
	CMatrix3x3()
	{
		Identity();
	}
	CMatrix3x3(
		float a0, float a1, float a2,
		float a3, float a4, float a5,
		float a6, float a7, float a8
	)
	{
		fElements[0] = a0; fElements[1] = a1; fElements[2] = a2;
		fElements[3] = a3; fElements[4] = a4; fElements[5] = a5;
		fElements[6] = a6; fElements[7] = a7; fElements[8] = a8;
	}
	CMatrix3x3(const CMatrix3x3& m)
	{
		memmove(fElements, m.fElements, 9*sizeof(float));
	}

	void	Zero()
	{
		memset(fElements, 0, 9*sizeof(float));
	}

	void	Identity()
	{
		memset(fElements, 0, 9*sizeof(float));
		fElements[0] = fElements[4] = fElements[8] = 1.0f;
	}

	CMatrix3x3 operator *(CMatrix3x3 &m)
	{
		CMatrix3x3 out;

#if _CPU == CPU_PENTIUM_II
		PII_Mult_3x3_3x3(fElements, m.fElements, out.fElements);
#elif _CPU == CPU_PENTIUM_III
		PIII_Mult00_3x3_3x3(fElements, m.fElements, out.fElements);
#else
		float *a = fElements;
		const float *b = m.fElements;

		float *c = out.fElements;

		int	iOut = 0;
		for (int i=0; i<3; i++)
		{
			for (int j=0; j<3; j++)
			{
				c[iOut] = 0;
				for (int k=0; k<3; k++)
					c[iOut] += a[i*3+k] * b[k*3+j];

				iOut++;
			}
		}
#endif	//_CPU
		return out;
	}
	CMatrix3x3 Inverse()
	{
		const float *m = fElements;
		float fDetInv = 1.0f /
			(m[0] * (m[4] * m[8] - m[5] * m[7])
			-m[1] * (m[3] * m[8] - m[5] * m[6])
			+m[2] * (m[3] * m[7] - m[4] * m[6]));

		return CMatrix3x3(
				fDetInv * (m[4]*m[8] - m[5]*m[7]),
				-fDetInv* (m[1]*m[8] - m[2]*m[7]),
				fDetInv * (m[1]*m[5] - m[2]*m[4]),

				-fDetInv* (m[3]*m[8] - m[5]*m[6]),
				fDetInv * (m[0]*m[8] - m[2]*m[6]),
				-fDetInv* (m[0]*m[5] - m[2]*m[3]),

				fDetInv * (m[3]*m[7] - m[4]*m[6]),
				-fDetInv* (m[0]*m[7] - m[1]*m[6]),
				fDetInv * (m[0]*m[4] - m[1]*m[3])
			);
	}

	static CMatrix3x3 RotationX(float fAngle)
	{
		float fSinA = sinf(fAngle);
		float fCosA = cosf(fAngle);

		return CMatrix3x3(
			1, 0, 0,
			0, fCosA, -fSinA,
			0, fSinA, fCosA);
	}

	static CMatrix3x3 RotationY(float fAngle)
	{
		float fSinA = sinf(fAngle);
		float fCosA = cosf(fAngle);

		return CMatrix3x3(
			fCosA, 0, -fSinA,
			0, 1, 0,
			fSinA, 0, fCosA);
	}

	static CMatrix3x3 RotationZ(float fAngle)
	{
		float fSinA = sinf(fAngle);
		float fCosA = cosf(fAngle);

		return CMatrix3x3(
			fCosA, -fSinA, 0,
			fSinA, fCosA, 0,
			0, 0, 1);
	}

	/// vAxis must be normalized
	static CMatrix3x3 Rotation(const CVector &vAxis, float fAngle)
	{
		float	fSinA = sinf(fAngle);
		float	fCosA = cosf(fAngle);

		const float	&x = vAxis.x;
		const float	&y = vAxis.y;
		const float	&z = vAxis.z;

		float	fX2 = x * x;
		float	fY2 = y * y;
		float	fZ2 = z * z;

		return CMatrix3x3(
				fX2 + fCosA * (1 - fX2),
				x * y * (1 - fCosA) + z * fSinA,
				x * z * (1 - fCosA) - y * fSinA,

				x * y * (1 - fCosA) - z * fSinA,
				fY2 + fCosA * (1 - fY2),
				y * z * (1 - fCosA) + x * fSinA,

				x * z * (1 - fCosA) + y * fSinA,
				y * z * (1 - fCosA) - x * fSinA,
				fZ2 + fCosA * (1 - fZ2)
			);
	}
};

inline CVector operator *(const CVector &v, const CMatrix3x3 &m)
{
	const float *pM = m.fElements;
	return CVector(
			v.x * pM[0] + v.y * pM[3] + v.z * pM[6],
			v.x * pM[1] + v.y * pM[4] + v.z * pM[7],
			v.x * pM[2] + v.y * pM[5] + v.z * pM[8]
		);
}

void MatrixAndVectorTo4x4(float *fMatrix4x4, const CMatrix3x3 &mRotation, const CVector &vOrigin);
void Transfom3x3AndVectorBy3x3(float *pOut4x4, const CMatrix3x3 &mSrc, const CVector &vSrc, const CMatrix3x3 &mRotation);


#endif //_MATRIX3X3_H_
