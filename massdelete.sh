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
Force="0"

###FUNCTIONS
function checkstatus
{
  if [ "$AutomaticMode" = "0" ]; then
  #prompt for user token
    echo "Hi there !"
    echo "This script will delete all the posts by the user your log in to Ghost. You may change this in the filters below."
    echo "You need to login for this to work. No data is stored."
    echo "WARNING : PLEASE MAKE A BACKUP OF YOUR DATA BEFORE USING THIS ! IT WILL DELETE YOUR POSTS. THERE IS NO MAGIC UNDO BUTTON."
    echo "Please type in your blog adress (http://blog.mysite.com)"
    read BlogAdress
    echo "Please type in your username"
    read GhostLogin
    echo "and now your password:"
    read GhostPassword
    echo "By default, the filter is set to delete all posts made by the logged in user."
    echo "If you want, you may specify override the filters here."
    echo "Write the filters in GQL. For example, the default filter used here is author_id:$Author"
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

  #Check if custom filters were set and use them if so to query the list of posts to delete
  if [ -z "$CustomFilters" ]
    then
      echo "Using default filters"
      declare -a PostsToDelete=`curl --header "Authorization: Bearer $BearerToken" $BlogAdress/ghost/api/v0.1/posts/?filter=\(author_id:$Author\) | jq '.posts[] | .id'`
    else
      echo "Using custom filters"
      declare -a PostsToDelete=`curl --header "Authorization: Bearer $BearerToken" $BlogAdress/ghost/api/v0.1/posts/?filter=\($CustomFilters\) | jq '.posts[] | .id'`
  fi
  echo "Posts to Delete ids: $PostsToDelete"

  if [ "$Force" = "0" ]; then
  #Sanity Check
    echo "This is your last chance to check your filters before deletion"
    echo "Post IDs are written above"
    echo "There is no magic undo button"
    echo "You should probably backup your blog first"
    echo "You may skip this screen by passing the argument -f on next usage"
    read -n1 -r -p "Press any key to confirm or CTRL-C to exit" key
    deleteall
  else
    echo "You know what you're doing..."
    deleteall
  fi
}

function deleteall
{
#Loop over the posts and delete them
for ThisPostId in $PostsToDelete
do
echo "Deleting $ThisPostId"
curl -X DELETE --header "Authorization: Bearer $BearerToken" $BlogAdress/ghost/api/v0.1/posts/$ThisPostId
done
echo "Deleted all the posts !"
}

function usage
{
    echo "usage: massdelete.sh [[-a (http://blog.mysite.eu ghostlogin ghostpassword customfilters)] [-f]] | [-h]]"
}


###ARGUMENTS
while [ "$1" != "" ]; do
    case $1 in
        -a | --automatic )      AutomaticMode=1
                                shift
                                BlogAdress=$1
                                GhostLogin=$2
                                GhostPassword=$3
                                ClientSecret=$4
                                checkstatus
                                ;;
        -f | --force )          Force=1
                                ;;                                
        -h | --help )           usage
                                exit
                                ;;
        * )                     exit 1
    esac
    shift
done

###MAIN
checkstatus