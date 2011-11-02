#ifndef _VECTOR_H_
#define _VECTOR_H_

//#include "FastMath.h"
#include "helpers.h"

class CVector
{
public:
	float	x, y, z;

public:
	CVector() {x = y = z = 0;}
	CVector(const CVector &v) {x = v.x; y = v.y; z = v.z;}
	CVector(float _x, float _y, float _z) {x = _x; y = _y; z = _z;}

	float operator *(const CVector &v) const
	{
		return x*v.x + y*v.y + z*v.z;
	}
	CVector operator ^(const CVector &v) const
	{
		return CVector(y*v.z - z*v.y, z*v.x - x*v.z, x*v.y - y*v.x);
	}
	CVector operator +(const CVector &v) const
	{
		return CVector(x+v.x, y+v.y, z+v.z);
	}
	CVector operator -(const CVector &v) const
	{
		return CVector(x-v.x, y-v.y, z-v.z);
	}
	CVector& operator +=(const CVector &v)
	{
		x += v.x;
		y += v.y;
		z += v.z;
		return *this;
	}
	CVector& operator -=(const CVector &v)
	{
		x -= v.x;
		y -= v.y;
		z -= v.z;
		return *this;
	}
	CVector operator *(float fScale)
	{
		return CVector(x*fScale, y*fScale, z*fScale);
	}
	CVector operator /(float fScale)
	{
		float fInvScale = 1.0f / fScale;
		return CVector(x * fInvScale, y * fInvScale, z * fInvScale);
	}
	CVector& operator *=(float fScale)
	{
		x *= fScale;
		y *= fScale;
		z *= fScale;
		return *this;
	}
	float GetMagnitude()
	{
		//return CFastMath::SqrtLt(x*x + y*y + z*z);
		return FastSqrtLt(x*x + y*y + z*z);
	}
	void Normalize()
	{
		float l = x*x + y*y + z*z;
		//l = CFastMath::InvSqrtLt(l);
		l = FastInvSqrtLt(l);
		x = x * l;
		y = y * l;
		z = z * l;
	}
	CVector operator -() const
	{
		return CVector(-x, -y, -z);
	}
	operator float*()
	{
		return &x;
	}
	operator const float*()
	{
		return &x;
	}
};

#endif	// _VECTOR_H_
