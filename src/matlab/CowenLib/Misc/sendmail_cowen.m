function sendmail_cowen(subject)
% Does not work with yahoo or gmail see doc sendmail
address = 'scowen@email.arizona.edu';
setpref('Internet','SMTP_Server','smtpgate.email.arizona.edu');
setpref('Internet','E_mail',address);
sendmail(address,subject);
