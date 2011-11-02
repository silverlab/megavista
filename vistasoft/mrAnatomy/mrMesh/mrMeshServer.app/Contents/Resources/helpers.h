#ifndef _HELPERS_H_
#define _HELPERS_H_

/// Changes byte-order in the array
void SwizzleInts(int *list, int n);

void CalculateNormal(const float *p1, const float *p2, const float *p3, float *n, float *pTriangleArea=NULL);
void NormalizeVector(float *pVector3);

#ifdef WORDS_BIGENDIAN
	#define SWAP_BYTES_IN_ARRAY_ON_BE(list, n) SwizzleInts(list, n)
	#define SWAP_BYTES_IN_ARRAY_ON_LE(list, n) {}
#else
	#define SWAP_BYTES_IN_ARRAY_ON_LE(list, n) SwizzleInts(list, n)
	#define SWAP_BYTES_IN_ARRAY_ON_BE(list, n) {}
#endif

#ifndef M_PI
#define M_PI 3.141593f
#endif

//#ifdef _WINDOWS
// should check for x86 instead
#ifdef __INTEL__	//should be defined by wxWindows
//#if 1
	float __fastcall FastX86InvSqrt(float x);
	float __fastcall FastX86Sqrt(float x);
	float __fastcall FastX86InvSqrtLt(float x);
	float __fastcall FastX86SqrtLt(float x);

	#define FastInvSqrt(x)		FastX86InvSqrt(x)
	#define FastSqrt(x)			FastX86Sqrt(x)
	#define FastInvSqrtLt(x)	FastX86InvSqrtLt(x)
	#define FastSqrtLt(x)		FastX86SqrtLt(x)

#else

	#define FastInvSqrt(x)	(1.0f/sqrtf(x))
	#define FastSqrt(x)		sqrtf(x)
	#define FastInvSqrtLt(x) (1.0f/sqrtf(x))
	#define FastSqrtLt(x)	sqrtf(x)

#endif	//__INTEL__

typedef bool (*SortCallback)(int item1, int item2, void *pParam);
template<class T> void ShellSort(T a[], long size);
void ShellSortInt(int a[], long size, SortCallback compare_proc, void *pParam);

template<class T> void Clamp(T &x, T min, T max)
{
	if (x < min)
		x = min;
	else if (x > max)
		x = max;
}

void Dump(const char *pszPrefix, void *pData, int iLen);

bool SendInParts(wxSocketBase *sock, char *pData, int iLen, int iPacketSize = 1024*1024);
bool ReceiveInParts(wxSocketBase *sock, char *pBuf, int iLen, int iPacketSize = 1024*1024);
#endif //_HELPERS_H_
