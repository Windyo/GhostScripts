#!/usr/bin/env bash
#declare vars
BlogAdress=""
GhostLogin=""
GhostPassword=""
ClientSecret=""
BearerToken=""
Author=""
CustomFilters=""
AutomaticMode="0"


###FUNCTIONS
function masspublish
{
  if [ "$AutomaticMode" = "0" ]; then
  #prompt for user token
    echo "Hi there !"
    echo "This script will publish all the drafts corresponding to the filter in Ghost."
    echo "You need to login for this to work. No data is stored."
    echo "Please type in your blog adress (http://blog.mysite.com)"
    read BlogAdress
    echo "Please type in your username"
    read GhostLogin
    echo "and now your password:"
    read GhostPassword
    echo "By default, the filter is set to publish all posts made by the logged in user, in status Draft."
    echo "If you want, you may specify override the filters here."
    echo "Write the filters in GQL. For example, the default filter used here is status:draft"
    echo "More information is available on https://api.ghost.org/docs/filter"
    read CustomFilters
  else
    echo "AutomaticMode is on, assuming variables are already set..."
  fi

  #Login and get the BearerToken
    ClientSecret=`curl $BlogAdress/ghost/signin/ | grep -o -P '(?<=env-clientSecret" content=").*(?=" data-type="string)'`
    BearerToken=`curl --data grant_type=password --data username=$GhostLogin --data password=$GhostPassword --data client_id=ghost-admin --data client_secret=$ClientSecret $BlogAdress/ghost/api/v0.1/authentication/token | grep -o -P '(?<="access_token":").*(?=","refresh_token")'`
    Author=`curl --header "Authorization: Bearer $BearerToken" $BlogAdress/ghost/api/v0.1/users/me/ | grep -o -P '(?<="id":).*(?=,"uuid")'`
  # read -n1 -r -p "Logged in, got the bearer token ! Your Author id is $Author" key

  #Check if custom filters were set and use them if so to query the list of posts to publish
    if [ -z "$CustomFilters" ]
    then
      echo "Using default filters"
      declare -a PostsToPublish=`curl --header "Authorization: Bearer $BearerToken" $BlogAdress/ghost/api/v0.1/posts/?filter=\(status:draft\) | jq '.posts[] | .id'`
    else
      echo "Using custom filters"
      declare -a PostsToPublish=`curl --header "Authorization: Bearer $BearerToken" $BlogAdress/ghost/api/v0.1/posts/?filter=\($CustomFilters\) | jq '.posts[] | .id'`
    fi
    echo "Posts to Publish ids: $PostsToPublish"

  #Loop over the posts and publish them
    for ThisPostId in $PostsToPublish
      do
      curl --header "Authorization: Bearer $BearerToken" -H "Content-Type: application/json" -X PUT -d '{"posts":[{"status":"published"}]}' $BlogAdress/ghost/api/v0.1/posts/$ThisPostId
    done
    echo "Published all drafts !"
}

function usage
{
    echo "usage: masspublish.sh [-a (http://blog.mysite.eu ghostlogin ghostpassword customfilters)] | [-h]]"
}


###ARGUMENTS
while [ "$1" != "" ]; do
    case $1 in
        -a | --automatic )      shift
                                AutomaticMode=1
                                BlogAdress=$1
                                GhostLogin=$2
                                GhostPassword=$3
                                CustomFilters=$4
                                masspublish
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     exit 1
    esac
    shift
done

###MAIN
masspublish