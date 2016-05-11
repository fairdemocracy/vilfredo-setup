MAIL PROBLEMS

If the mail do not arrive (or are always placed in spam) there can be several reasons. 

REVERSE DNS NOT SET UP: One of them is that the REVERSE DNS has not been set up. Each host will do this differently. On Digital Ocean the droplet must be called with the name of the url (vilfredo.org for the main site). This will set up the reverse dns, thus any machine asking what URL is connected to the IP address will get the correct address.

THE IP FROM WHICH THE EMAILS ARE SENT IS VARIABLE: Spam service tend to use variable IP to send their mails. As such having a variable IP can signal that the email is suspicious. Dreamhost use to have this problem. Unfortunately in that case the solution was to leave that host. Another possible solution could have been to use an external service.

THE MAILS ARE NOT SIGNED, OR THE SIGNATURE IS NOT RECOGNISED: To check that the emails are official, emails get signed by the server sending them. The process is called Domain Key Identified Domain (DKIM). To work it is necessary to give the necessary instructions, but also to change the TXT value for on the DNS.

In any case remember that in /var/log/mail.log there is a log of all the mail sent. And if a mail was not received it will say here why. "tail -n 100 mail.log" will show you the last 100 lines
