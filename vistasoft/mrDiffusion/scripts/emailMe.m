function emailMe(subject, emailTo, emailFrom, message)
% function emailMe([subject], emailTo, [emailFrom], [message])
%
% email a message. it is useful to call this function immediatley
% after
% starting a long process in order to know when it is done. The message
% will show up as the subject title
%
% Example:
% status=['Preprocessed this subject successfully'];
% emailMe(status,'jennifer.yoon@stanford.edu');
%
% 7/2008 JW
% 11/2008 DY: modified default input arguments

if notDefined('subject')
    subject = 'matlab has sent you an email!';
end

if notDefined('emailTo')
    error('You need to specify an @stanford.edu address to send the email to');
end

if notDefined('emailFrom')
    emailFrom = emailTo;
end

if notDefined('message')
    message = subject;
end

setpref('Internet','SMTP_Server','smtp.stanford.edu');
setpref('Internet','E_mail',emailFrom);
sendmail(emailTo, subject, message);
