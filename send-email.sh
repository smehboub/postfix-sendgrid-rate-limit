#!/bin/bash

read -p "Enter Recipient's Mail Server: " server
read -p "Enter SMTP Port: " port
read -p "Enter Your Email Address: " from
read -p "Enter Recipient's Email Address: " to

# create message
function mail_input {
echo "ehlo $(hostname -f)"
echo "MAIL FROM: <$from>"
echo "RCPT TO: <$to>"
echo "DATA"
echo "From: <$from>"
echo "To: <$to>"
echo "Subject: Testing SMTP Mail"
echo "This is only a test. Please do not panic. If this works, then all is well, else all is not well."
echo "."
echo "quit"
}

mail_input | netcat $server $port
