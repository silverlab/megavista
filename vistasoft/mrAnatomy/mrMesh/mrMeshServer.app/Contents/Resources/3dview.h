#ifndef _3DVIEW_H_
#define _3DVIEW_H_
#include "scene.h"
#include "commandhandler.h"
#include "transformarrow.h"
class C3DView : public wxGLCanvas, CCommandHandler
{
public:
	C3DView(wxWindow* parent, const wxPoint& pos, const wxSize& size);
	virtual ~C3DView();

private:
	/// Scene rendering
	void OnPaint(wxPaintEvent& event);
	/// Updates viewport size
	void OnSize(wxSizeEvent& event);
	/// Does nothing. Useful on Windows.
	void OnEraseBackground(wxEraseEvent& event);
	/// Rotate & move around actors and camera
	void OnMouseMove(wxMouseEvent& event);
	/// Select actor
	void OnMouseDown(wxMouseEvent& event);
	/// End of rotating and moving
	void OnMouseUp(wxMouseEvent& event);
	/// Selects point on mesh surface (moves PA_CURSOR to clicked point)
	void OnLeftDoubleClick(wxMouseEvent& event);
	/// Resets camera position
	void OnRightDoubleClick(wxMouseEvent& event);
	/// Zoom
	void OnMouseWheel(wxMouseEvent& event);

private:
	/// Initial setup
	void InitGL();
	/// Retrieve next numeric filename for screen shot (like shot0012.bmp)
	void GetNextImageFileName(wxString &strFileName);

	/// Sets GL material properties
	void SetupMaterial();

	/// Find point in 3d-space by x,y coords of viewport
	bool UnProject(int vx, int vy, GLdouble *pX, GLdouble *pY, GLdouble *pZ);

	/// Returns selected scene actor
	CActor*	FindClickedActor(int iMouseX, int iMouseY);

	/// Changes pActiveActor and shows/hides manipulation arrows
	void	OnActorSelectionChange(CActor *pNewClickedActor);

private:
	/// true if InitGL was called for this view
	bool	bInitialized;

	/// point at screen - used to calculate rotations angles and movement distance
	wxPoint		m_ClickPos;
	/// point at which mouse move was started - used to perform selection
	//wxPoint		m_StartingMousePos;

	/// Max depth of OpenGL select buffer
	int		iGLNameStackSize;

	/// GL_SELECT rendering mode info
	GLuint	*pSelectBuffer;

	/// Screenshot counter to prevent unnecessary opening of files
	int	iNextScreenShotNumber;
	
private:
	CScene	m_Scene;
	
	/// Actor clicked with mouse that user is operating on
	CActor	*pActiveActor;

	/// keep track of mouse operation
	enum	transform_axis
	{
		TA_NONE,
		TA_X,
		TA_Y,
		TA_Z
	}taAxis;

private:
	//@{
	/// Called by OnMouseMove.
	/// @return true if object position was changed
	bool OnMouseMoveTransformActor(wxMouseEvent& event);
	bool OnMouseMoveTransformArrow(wxMouseEvent& event);
	bool OnMouseMoveTransformCamera(wxMouseEvent& event);
	//@}
	void MoveArrowToActiveActorOrigin();

public:
	/// Processes command or redirects for processing to CScene and its actors
	virtual	bool ProcessCommand(char *pCommand, bool *pRes, CParametersMap &paramsIn, CParametersMap &paramsOut);

private:
	DECLARE_COMMAND_HANDLER(CommandScreenShot);
	DECLARE_COMMAND_HANDLER(CommandEnableLighting);
	DECLARE_COMMAND_HANDLER(CommandRefresh);
	DECLARE_COMMAND_HANDLER(CommandSetSize);
	DECLARE_COMMAND_HANDLER(CommandSetWindowTitle);

private:
	DECLARE_EVENT_TABLE()
	DECLARE_HANDLER_TABLE()
};

#endif //_3DVIEW_H_
