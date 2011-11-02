#ifndef _CURSOR_H_
#define _CURSOR_H_

#include "actor.h"

/// Simple 3-axial cursor

class CCursor : public CActor
{
public:
	CCursor(const SceneInfo *pSI, int iActorID);
	virtual ~CCursor();

	static const char *pszClassName;
	virtual const char* GetClassName() {return pszClassName;}

	void	DrawArrows();
	void 	Render();

	void	OnSelectActor(CActor *pActor);

private:
	GLuint	uDisplayList;

	void	CompileList();

	int	iSelectedActor;
	int	iSelectedVertex;

private:
	DECLARE_COMMAND_HANDLER(CommandGetSelection);
	DECLARE_COMMAND_HANDLER(CommandSetSelection);
	DECLARE_HANDLER_TABLE()
};

#endif //_CURSOR_H_
