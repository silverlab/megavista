#ifndef _MRM_IO_H_
#define _MRM_IO_H_

/// .mrm mesh vertex (28 bytes)
//typedef struct {
//	float p[3];	///< x,y,z of vertex
//	float n[3];	///< x,y,z of normal
//	unsigned char c[4]; ///< r,g,b,a
//} MrM_Vertex;

enum MrM_mesh_flags{
	/// Mesh data contains normals (MrVertex::n is valid)
	MRMESH_NORMALS_OK	= 0x01,
	/// MrVertex::c is valid
	MRMESH_COLOR_OK		= 0x02
};

enum MrM_file_offsets
{
	OFFSET_STRIPS	= 0,
	OFFSET_VERTICES	= 1,
	OFFSET_UNKNOWN	= 2
};

//#pragma pack(push)
//#pragma pack(1)

#pragma pack(push, 1)

struct MrM_Header
{
	char Signature[11];
	int  iFlags;
	int  nStrips;
	int  nTriangles;
	float Bounds[6];
	int   Offsets[3];
};

#pragma pack(pop)

#endif //_MRM_IO_H_
