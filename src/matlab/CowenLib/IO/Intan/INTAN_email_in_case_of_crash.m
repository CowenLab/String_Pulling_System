function INTAN_email_in_case_of_crash(email_address,file_name, server_name)
if nargin == 0
    email_address = 'scowen@email.arizona.edu';
end
if nargin < 1
    file_name = '*.dat';
end
if nargin < 2
    server_name = 'smtpgate.email.arizona.edu';
end
% d = dir(file_name);
keep_going = true;
setpref('Internet','E_mail',email_address);
setpref('Internet','SMTP_Server',server_name);
% sendmail('cowenowner@yahoo.com','Hello From MATLAB!');
% sendmail('cowenowner@gmail.com','Hello From MATLAB!');
last_size = -1;
while (keep_going)
    d = dir(file_name);
    if d(1).bytes == last_size;
        sendmail(email_address,'INTAN CRASHED!!!!');
        msgbox('INTAN CRASHED')
        keep_going = false;
    end
    last_size = d(1).bytes;
    pause(10); % wait 10 seconds.
end
