#ifndef _SERVERCONSOLE_H_

#define _SERVERCONSOLE_H_

#include "parametersmap.h"
#include "clientframe.h"
#include "commandhandler.h"


#define DECLARE_HANDLER(func) 	static bool func(ClientIDData *pClient, CParametersMap &paramsIn, CParametersMap &paramsOut, CServerConsole *pThis)



class CServerConsole : public wxFrame
{
public:

	CServerConsole(const wxString& title, const wxPoint& pos, const wxSize& size);

	virtual ~CServerConsole();


	/// Called by CClientFrame

	void	OnClientFrameClosed(int iClientID);



private:

	enum{

		ID_SERVER_EVENT,

		ID_SOCKET_EVENT

	};

	void OnServerEvent(wxSocketEvent& event);

	void OnSocketEvent(wxSocketEvent& event);


	struct	ClientHandshake

	{

        char hello[32];		///< not used yet

        char reserved[32];

        int  id;			///< client id, -1, to request new

	};

	struct	ServerReply

	{

		int id;		///< client id

		int status;	///< Status: <0 on error

		char reserved[24];

	};

	struct	ClientHeader

	{

		int	command_length;	///< Length of command sent after ClientHeader

		int	params_length;	///< Length of parameters string

		char reserved[24];

	};

	struct	ServerHeader

	{

		int status;			///< Status. On error: status<0, data contains error descripton

		int data_length;	///< Length of data sent after ServerHeader

	};



private:

	/// necessary info to keep

	struct ClientIDData

	{

		CClientFrame	*pWindow;

	};

	WX_DECLARE_HASH_MAP(int, ClientIDData, wxIntegerHash, wxIntegerEqual, HashMapClients);

	/// Clients list

	HashMapClients	mapClients;



	typedef bool (*ClientCommandProc)(ClientIDData *pClient, CParametersMap &paramsIn, CParametersMap &paramsOut, CServerConsole *pThis);



	WX_DECLARE_STRING_HASH_MAP(ClientCommandProc, HashMapCommandHandlers);

	/// Command handler functions list

	HashMapCommandHandlers	mapClientCommandHandlers;



	/// Fills mapClientCommandHandlers with handler function pointers

	void SetupCommandHandlers();



	/// Creates new client window and adds client to mapClients

	int	CreateNewClient(int iRequestedID = -1);

	/// Closes client frame window. Objects are deleted on OnClientFrameClosed confirmation

	void CloseClient(int iID);

	/// Calls command handler for pCommand

	bool ProcessClientCommand(ClientIDData *pClient, char *pCommand, CParametersMap &paramsIn, CParametersMap &paramsOut);

	/// Receives client command, calls CParamsParser, executes ProcessClientCommand and send result

	bool ReceiveClientCommand(int iID, wxSocketBase *sock);

	/// Checks if mapClients contains given iID

	bool IsClientIDValid(int iID);



private:

	void OnSize(wxSizeEvent& event);

	void OnClose(wxCloseEvent& event);



	void	Log(const char *strText)

	{

		m_pText->AppendText(strText);

		m_pText->AppendText("\n");

	}



private:

	//@{

	/** Client command handlers */

	DECLARE_HANDLER(CommandHelp);

	DECLARE_HANDLER(CommandMessage);

	DECLARE_HANDLER(CommandClose);

	DECLARE_HANDLER(CommandGetViewParameters);

	DECLARE_HANDLER(CommandSetViewParameters);

	DECLARE_HANDLER(CommandGetNumWindows);

	//@}

	struct	CommandHandlersArrayItem

	{

		char				*pCommand;

		ClientCommandProc	proc;

	};

	static	CommandHandlersArrayItem	m_CommandHandlersArray[];



private:

	/// Log window

	wxTextCtrl		*m_pText;

	/// Connected clients list

	wxListBox		*m_pListClients;

	/// Listbox with tasks progress info

	wxListCtrl		*m_pListTasks;

	/// Server socker

	wxSocketServer	*m_pServer;



	/// Used in CreateNewClient

	int	iClientIDCounter;



	static void ProgressCallback(int iID, int iCommand, const wxString *strOperation, int iProgress, long lParam);



	DECLARE_EVENT_TABLE()

};



#endif //_SERVERCONSOLE_H_

