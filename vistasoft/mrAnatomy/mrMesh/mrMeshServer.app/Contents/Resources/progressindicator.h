#ifndef _PROGRESSINDICATOR_H_
#define _PROGRESSINDICATOR_H_

class CProgressIndicator
{
public:
	CProgressIndicator();

	static CProgressIndicator *GetInstance();
	void*	StartNewTask(vtkProcessObject *pProcessor, const wxString &strAction);
	void	EndTask(void* pTaskID);

	enum	commands
	{
		PI_START,
		PI_END,
		PI_TICK
	};
	typedef	void (*SubscriberCallback)(int iID, int iCommand, const wxString *strOperation, int iProgress, long lParam);

	void	SetDisplayProgressCallback(SubscriberCallback proc, long lParam);
	void	SetProgressValue(void *pTaskID, int iProgress);

private:
	struct	Task
	{
		int			iID;
		wxString	strAction;
		vtkProcessObject	*pProcessor;
		long		lParam;
		SubscriberCallback	procCallback;
	};
	SubscriberCallback	procSubscriberCallback;
	long				lSubscriberParam;

	int	iTaskIDCounter;

	static	void ProgressCallback(void *pParam);
};

#endif //_PROGRESSINDICATOR_H_
