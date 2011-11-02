#ifndef _PARAMETERSMAP_H_
#define _PARAMETERSMAP_H_

#include "floatarray.h"

class CParametersMap
{
public:
	CParametersMap();
	virtual ~CParametersMap();

	int		GetInt(const wxString &strName, int iDefaultValue);
	float	GetFloat(const wxString &strName, float fDefaultValue);
	wxString GetString(const wxString &strName, const wxString &strDefault);
	CFloatArray *GetArray(const wxString &strName);

	/// @return false if no variable with name strName found
	/// @remarks if string contains floating-point value, this value is rounded to nearest int
	bool	GetInt(const wxString &strName, int *pValue);
	/// @return false if no variable with name strName found
	bool	GetFloat(const wxString &strName, float *pValue);
	/// @return false if no variable with name strName found
	bool	GetString(const wxString &strName, wxString *pstrValue);

	/// @param iLen size of buffer
	/// @return length of data in buffer; 0 on error
//	int	GetBinary(const wxString &strName, char *pBuf, int iLen);

	/// @remarks if string contains floating-point value, this value is rounded to nearest int
	void	SetInt(const wxString &strName, int iValue);
	void	SetFloat(const wxString &strName, float fValue);
	void	SetArray(const wxString &strName, CFloatArray *pArray);
	void	SetString(const wxString &strName, const wxString &strValue);
	/// if value with name == strName exists, append it with comma and strValue
	void	AppendString(const wxString &strName, const wxString &strValue);
//	void	SetBinary(const wxString &strName, char *pBuf, int iLen);

	/// @param pBuf - 0-terminated string
	bool	CreateFromString(char *pBuf, int iBufLen);
	/// @param pLen - on success, contains resulting string length, including 
	/// terminating 0
	char	*FormatString(int *pLen);

private:
	struct	BinaryData
	{
		int	len;
		char data[1];
	};

	/// inner parser states
	enum states
	{
		S_SKIP_TO_NAME,
		S_NAME,
		S_SKIP_TO_DATA,
		S_SKIP_TO_STRING,
		S_STRING,
		S_QUOTED_STRING,
		S_BINARY_LEN,
		S_BINARY,
		S_ARRAY_SIZES,
		S_SKIP_TO_ARRAY,
		S_SKIP_TO_BINARY_ARRAY,
		S_ARRAY_ITEMS,
		S_ARRAY_BINARY_ITEMS,
		S_FINISH,
		S_ERROR
	};


	WX_DECLARE_STRING_HASH_MAP(wxString, HashMapStringParams);
	WX_DECLARE_STRING_HASH_MAP(BinaryData*, HashMapBinaryParams);
	WX_DECLARE_STRING_HASH_MAP(CFloatArray*, HashMapArrayParams);

	HashMapStringParams	mapStrings;
	HashMapBinaryParams	mapBinary;
	HashMapArrayParams	mapArrays;

	void	CleanupBinaryParams();
	void	CleanupStringParams();
	void	CleanupArrayParams();

	void	FormatStringsMap(wxString &strResult);
	void	FormatArraysMap(wxString &strResult);
	void	FormatArraysMapBinary(char **pResult, int *pLength);

	static inline bool	IsCharNumeric(char c);
	static const char* pszFloatFormat;
};

#endif //_PARAMETERSMAP_H_
