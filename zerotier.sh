#!/bin/bash
# tested on ubuntu 20.04
# purpose automate console monitoring through Zerotier API token and send out SMTP alert on system offline over 1 hour
# pre-requirements, will need the following packages: curl, jq and bc
# VALUE YOU NEED TO UPDATE:
#    YOUR_SMTP_OR_USE_MAIL.SMTOP2GO.COM
#    2525
#    AUTHORIZE_SENDER@DOMAIN.COM
#    YOUR_NOTIFICATIO_EMAIL@DOMAIN.COM
#    ZEROTIER_API_TOKEN
#    YOUR_ZEROTIER_NETWORK
#    NODE_ID1 ..... NODE_IDx

function checkStatus {
  read -u 3 sts line
  expect=250
  if [ $# -eq 1 ] ; then
    expect="${1}"
  fi
  if [ $sts -ne $expect ] ; then
    echo "Error: ${line}"
    exit
  fi
}

function send_mail {
    MailHost="YOUR_SMTP_OR_USE_MAIL.SMTOP2GO.COM"
    MailPort=2525
        FromAddr="AUTHORIZE_SENDER@DOMAIN.COM"
        ToAddr="YOUR_NOTIFICATIO_EMAIL@DOMAIN.COM"


        # Brilliant!!
        exec 3<>/dev/tcp/${MailHost}/${MailPort} ; checkStatus 220

        echo "HELO ${MyHost}" >&3 ; checkStatus
        echo "MAIL FROM: ${FromAddr}" >&3 ; checkStatus
        echo "RCPT TO: ${ToAddr}" >&3 ; checkStatus
        echo "DATA" >&3 ; checkStatus 354
        echo "Subject: ${Subject}" >&3

        # Insert one blank line here to let the relay know you are done sending headers
        # Otherwise a colon ":" in the message text will result in no text being sent.
        echo "" >&3

        # Send the message text and close
        echo "${Message}" >&3
        echo "." >&3 ; checkStatus
}

function checknode () {
        response=$(curl -s -H "Authorization: Bearer ZEROTIER_API_TOKEN" \
        -H "Content-Type: application/json" \
        https://my.zerotier.com/api/v1/network/YOUR_ZEROTIER_NETWORK/member/$1)
        time1=$(jq '.lastOnline' <<< "$response")
                name=$(jq '.name' <<< "$response")
                IP=$(jq '.physicalAddress' <<< "$response")
        time1=$(bc -l <<< "$time1/1000")
        time2=$(bc -l <<< "$EPOCHREALTIME")
        timediff=$(bc -l <<< "$time2 - $time1")
        timehours=$(bc <<< "$timediff/3600")
        if test $timehours -ge 1
        then
           ((send=send+1))
        fi
        echo $1, $name, $IP, $timehours
                Message="$Message $1 $name $IP $timehours\n"
}

send=0
Message="\n"
checknode "NODE_ID1"
checknode "NODE_ID2"
checknode "NODE_ID3"
checknode "NODE_ID4"
checknode "NODE_ID5"
checknode "NODE_ID6"
checknode "NODE_ID7"
checknode "NODE_ID8"
checknode "NODE_ID9"
checknode "NODE_ID10"
checknode "NODE_ID11"
checknode "NODE_ID12"
checknode "NODE_ID13"
checknode "NODE_ID14"
checknode "NODE_ID15"
checknode "NODE_ID16"

Message=$(echo -e $Message)
Subject="Zerotier Status Alert"

echo $(date +"%D%T"), $send > /root/zero.log
if test $send -ge 1
then
   send_mail
fi
