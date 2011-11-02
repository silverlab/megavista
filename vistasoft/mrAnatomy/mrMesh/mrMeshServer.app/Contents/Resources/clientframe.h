#ifndef _CLIENTFRAME_H_
#define _CLIENTFRAME_H_

#include "3dview.h"

class CClientFrame : public wxFrame
{
public:
	CClientFrame(wxFrame *pConsole, int iClientID, const wxString& title, const wxPoint& pos = wxDefaultPosition, const wxSize& size = wxDefaultSize);
	virtual ~CClientFrame();

	C3DView *Get3DView()
	{
		return m_p3DView;
	}

private:
	void OnSize(wxSizeEvent& event);
	void OnClose(wxCloseEvent& event);

private:
	/// CServerConsole to report about close event
	wxFrame	*m_pConsole;
	/// ID of client this frame belongs to
	int		m_iClientID;

	/// working window
	C3DView	*m_p3DView;

//	DECLARE_DYNAMIC_CLASS(CClientFrame)
	DECLARE_EVENT_TABLE()
};

#endif //_CLIENTFRAME_H_
