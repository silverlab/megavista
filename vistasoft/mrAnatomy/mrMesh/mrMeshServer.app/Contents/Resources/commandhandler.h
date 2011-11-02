#ifndef _COMMANDHANDLER_H_
#define _COMMANDHANDLER_H_

#include "parametersmap.h"

// command handlers table macros

#define DECLARE_HANDLER_TABLE() \
	private: \
		static const CommandTableEntry m_HandlersTable[]; \
	public: \
		virtual const CommandTableEntry *GetHandlersTable() const \
			{return m_HandlersTable;}

#define BEGIN_HANDLER_TABLE(Class) \
	const CCommandHandler::CommandTableEntry Class::m_HandlersTable[] = {

#define END_HANDLER_TABLE() \
		CommandTableEntry(NULL, NULL) \
	};

#define COMMAND_HANDLER(Command, Proc) CommandTableEntry(Command, (CCommandHandler::HandlerProc)&Proc),

#define DECLARE_COMMAND_HANDLER(Proc) bool Proc(CParametersMap &paramsIn, CParametersMap &paramsOut)

/// base class for all command handlers

class CCommandHandler
{
public:
	CCommandHandler();
	virtual ~CCommandHandler();

	typedef bool (CCommandHandler::*HandlerProc)(CParametersMap &paramsIn, CParametersMap &paramsOut);

	struct	CommandTableEntry
	{
		char		*pCommand;
		CCommandHandler::HandlerProc	procHandler;
		CommandTableEntry(char *pC, CCommandHandler::HandlerProc hp)
		{
			pCommand = pC;
			procHandler = hp;
		}
	};

	/// @return true if command handler was found and called
	virtual	bool ProcessCommand(char *pCommand, bool *pRes, CParametersMap &paramsIn, CParametersMap &paramsOut);

	bool	TestHandler(CParametersMap &paramsIn, CParametersMap &paramsOut)
	{
		//int x = paramsIn.GetInt("x", 0x17);
		//paramsOut.SetInt("test", 666);
		return true;
	}
	DECLARE_HANDLER_TABLE();
};

#endif //_COMMANDHANDLER_H_
