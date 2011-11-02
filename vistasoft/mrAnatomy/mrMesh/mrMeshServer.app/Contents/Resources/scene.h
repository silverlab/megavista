#ifndef _SCENE_H_
#define _SCENE_H_

#include "actor.h"
#include "camera.h"

class CScene : public CCommandHandler
{
public:
	CScene();
	virtual ~CScene();

	/// Renders scene actors
	/// @param bWithGLNames use OpenGL name stack to perform selection
	void	Render(bool bWithGLNames = false);

	/// Processes own command handlers map via CCommandHandler::ProcessCommand
	/// or, if 'actor' variable given, passes processing to corresponding actor
	virtual	bool ProcessCommand(char *pCommand, bool *pRes, CParametersMap &paramsIn, CParametersMap &paramsOut);

	/// Actor class factory
	/// @param strClassName actor class
	/// @param iActorID in-scene id to give
	CActor*	CreateActorInstance(const wxString &strClassName, int iActorID);

	/// "system" actors such as cursors and cameras
	enum predefined_actors
	{
		PA_CAMERA = 0,
		PA_CURSOR,
		PA_MANIP_X,
		PA_MANIP_Y,
		PA_MANIP_Z,
		
		PA_PREDEFINED_COUNT = 32
	};
	/// number of actors that are not selectable and are not rendereder in GL_SELECT mode
	static const int nAuxActorsCount;

	/// @return actor with given id, or NULL if no such actor exists
	CActor*	GetActor(int iActorID);

//private:
public:
	/// Data supplied to actors
	SceneInfo	siSceneInfo;

private:
	WX_DEFINE_ARRAY(CActor*, ActorsArray);	///< array to store and sort image quad
	ActorsArray	arrayImageQuads;
	static int CMPFUNC_CONV	ImageQuadCompare(CActor **pA1, CActor **pA2); ///< compare callback

private:
	WX_DECLARE_HASH_MAP(int, CActor*, wxIntegerHash, wxIntegerEqual, HashMapActors);
	/// hash map ID => Actor
	HashMapActors	mapActors;
	HashMapActors	map2DActors;
	/// actor ID values counter
	int				iActorCounter;

	bool			bEnableArrows;
	bool			bEnable3DCursor;

	DECLARE_COMMAND_HANDLER(CommandAddActor);
	DECLARE_COMMAND_HANDLER(CommandRemoveActor);
	DECLARE_COMMAND_HANDLER(CommandTransparency);
	DECLARE_COMMAND_HANDLER(CommandBackground);
	DECLARE_COMMAND_HANDLER(CommandEnableOriginArrows);
	DECLARE_COMMAND_HANDLER(CommandEnable3DCursor);
	DECLARE_COMMAND_HANDLER(CommandGetNumActors);
private:
	DECLARE_HANDLER_TABLE()
};

#endif //_SCENE_H_
