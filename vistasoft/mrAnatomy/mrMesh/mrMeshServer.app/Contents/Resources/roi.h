#ifndef _ROI_H_
#define _ROI_H_

class CROI
{
public:
	CROI();
	~CROI();

	bool	Load(const wxString &strFilename);
	void	Free();

	bool	PointInROI(float x, float y, float z);
	const unsigned char *GetColor(){return color;};
private:
	struct	Voxel
	{
		int	x, y, z;
		int	who_knows;
	};

	unsigned char	color[3];

	/// xmin xmax ymin ymax zmin zmax
	int		bounds[6];
	/// (xmax - xmin), (ymax-ymin), (zmax-zmin)
	int		size[3];
	
	/// array of size =  size[0]*size[1]*size[2].
	/// 1 - contains ROI, 0 - empty volume
	unsigned char	*pClassification;

	int	nItems;

	bool	bLoaded;

	/// @return Index in pClassification array for point {x,y,z}
	inline	int ClassIndex(int x, int y, int z)
	{
		wxASSERT(pClassification);
		return	(z - bounds[4])*size[0]*size[1] +
				(y - bounds[2])*size[0] +
				(x - bounds[0]);
	}
};

#endif //_ROI_H_
