#!/usr/bin/env bash
##################################################################################
##################################################################################
###########																									          ############
###########									Ghost Generic API Request									############
###########							for the Ghost blogging platform		            ############
###########									v. 1 @ Geoffrey Bessereau									############
###########																					        				  ############
###########																           									############
##################################################################################
##################################################################################

#declare vars
BlogAdress=""
GhostLogin=""
GhostPassword=""
ClientSecret=""
BearerToken=""
RequestType=""
Endpoint=""
AdditionalInfo=""
AutomaticMode="0"
ManualMode="0"
ManualRequest=""

function sanitycheck
{
    if [ -z "$BlogAdress" ]
    then
     	echo 'BlogAdress is not set. Please set it in the script, this should normally not vary after first use. This should point to where dataloader-uber.jar is stored, in the format "/home/user/pathtojar"'
     	exit
    elif [ -z "$GhostPassword" ]
    then
      echo 'Ghost Login is not set or complete. Please set it in the script, this should normally not vary after first use. This should point to where the config files for the dataloader are stored, in the format "/home/user/pathtoconfig"'
      exit
    else
    apirequest
    fi
}


function apirequest
{
  if [ "$AutomaticMode" = "0" ]; then
  #prompt for user token
    echo "Hi there !"
    echo "This script is made to emit a request to the Ghost API endpoints."
    echo "You need to login for this to work. No data is stored."
    echo "Please type in your blog adress (http://blog.mysite.com)"
    read BlogAdress
    echo "Please type in your username"
    read GhostLogin
    echo "and now your password:"
    read GhostPassword
    echo "Choose your request type (GET, POST, PUT, DELETE)"
    read RequestType
    echo "Choose your Endpoint (posts, users, tags)"
    read Endpoint
    echo "Manually type any required additional statements. (include=tags, limit=2, filters, etc)"
    read AdditionalInfo
  else
    echo "AutomaticMode is on, assuming variables are already set..."
  fi

  #Login and get the BearerToken
    ClientSecret=`curl $BlogAdress/ghost/signin/ | grep -o -P '(?<=env-clientSecret" content=").*(?=" data-type="string)'`
    BearerToken=`curl --data grant_type=password --data username=$GhostLogin --data password=$GhostPassword --data client_id=ghost-admin --data client_secret=$ClientSecret $BlogAdress/ghost/api/v0.1/authentication/token | grep -o -P '(?<="access_token":").*(?=","refresh_token")'`


  if [ "$ManualMode" = "1" ]; then
    echo "BearerToken : $BearerToken"
  fi


  if [ "$ManualMode" = "0" ]; then
    #Make the request
      declare -a RequestResponse=`curl --trace-ascii trace.txt -X "$RequestType" --header "Authorization: Bearer $BearerToken" "$BlogAdress"/ghost/api/v0.1/"$Endpoint"/?"$AdditionalInfo" | jq '.$Endpoint[]'`
      for ThisPost in $RequestResponse
        do
        echo $ThisPost
        done
      echo "Response Printed !"
  else
     echo "Type in your request here. The script automatically preprends the authorisation headers and logs a trace in trace.txt."
      read ManualRequest
      declare -a RequestResponse=`curl trace-ascii trace.txt --header "Authorization: Bearer $BearerToken" "$ManualRequest"`
      for ThisPost in $RequestResponse
        do
        echo $ThisPost
        done
      echo "Response Printed !"
  fi


}
function usage
{
    echo "usage: APIrequest.sh [-a (http://blog.mysite.eu ghostlogin ghostpassword RequestType Endpoint AdditionalInfo)] | [-m (http://blog.mysite.eu ghostlogin ghostpassword cURLrequest)] | [-h]]"
}


###ARGUMENTS
while [ "$1" != "" ]; do
    case $1 in
        -a | --automatic )      shift
                                AutomaticMode=1
                                BlogAdress=$1
                                GhostLogin=$2
                                GhostPassword=$3
                                RequestType=$4
                                Endpoint=$5
                                AdditionalInfo=$6
                                apirequest
                                ;;
        -m | --manualmode )      shift
                                AutomaticMode=1
                                ManualMode=1
                                BlogAdress=$1
                                GhostLogin=$2
                                GhostPassword=$3
                                ManualRequest=$4
                                apirequest
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     exit 1
    esac
    shift
done

###MAIN
apirequest