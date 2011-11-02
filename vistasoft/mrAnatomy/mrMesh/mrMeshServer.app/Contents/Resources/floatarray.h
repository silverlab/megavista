#ifndef _FLOATARRAY_H_
#define _FLOATARRAY_H_

/// Array used by CParametersMap

class CFloatArray
{
public:
	CFloatArray();
	virtual ~CFloatArray();

	bool	Create(int nDimensions, int iSizeX, int iSizeY=0, int iSizeZ=0);

	bool	GetValue(float *pValue, int x, int y=0, int z=0);
	bool	GetValueRounded(int *pValue, int x, int y=0, int z=0);
	bool	SetValue(float fValue, int x, int y=0, int z=0);

	bool	SetAtAbsoluteIndex(float fValue, int iIndex);
	bool	GetAtAbsoluteIndex(float *pValue, int iIndex);

	float	*GetPointer()
	{
		return fValues;
	}

	int		GetNumberOfItems()
	{
		return nTotalItems;
	}
	int		GetNumberOfDimensions()
	{
		return nDimensions;
	}
	const int *GetSizes()
	{
		return iSize;
	}

	/// checks if array has right dimensions
	bool	CheckSizes(int nDims, int iSizeX, int iSizeY = 0, int iSizeZ = 0);
private:
	int		nDimensions;
	int		iSize[3];
	int		nTotalItems;	///< count of fValues
	float	*fValues;

	void	Free();
};

#endif //_FLOATARRAY_H_
