![Version](https://img.shields.io/badge/Version-0.0.1-blue.svg)
![MinGhostVersion](https://img.shields.io/badge/Min%20Ghost%20v.-%3E%3D%200.8.x-red.svg)

#GhostScripts
Scripts cobbled together to do some recurring tasks on Ghost

==============

GhostScripts are shell scripts which I use to automate some tasks that I do recurringly on Ghost.
They may misbehave, not be portable, or otherwise un-perfect.
They do work well however ; should you want to use or modify them, please feel free to do so.

##General
For now, two (2) scripts are available:
- massdelete.sh
- masspublish.sh

Both are made to be executed from the command line, and can take several arguments.

##Massdelete.sh

By default, massdelete asks you for your blog URL, Login, Password, and optional filters.
If no custom filters are set, massdelete will delete ALL the posts made by the user you have logged in as via the script.
Please be aware the the ghost API is still under development, and that some filters which should be correct will not have the intended effect.

You should probably do a backup first. Really.

````sh
	massdelete.sh [[-a (http://blog.mysite.eu ghostlogin ghostpassword customfilters)] [-f]] | [-h]]
````


##Masspublish.sh

By default, Masspublish asks you for your blog URL, Login, Password, and optional filters.
If no custom filters are set, masspublish will publish ALL the posts currently in a draft state.
Please be aware the the ghost API is still under development, and that some filters which should be correct will not have the intended effect. For example, filtering by author to query which posts you will publish will not work as of Ghost version 0.9.0.

````sh
masspublish.sh [-a (http://blog.mysite.eu ghostlogin ghostpassword customfilters)] | [-h]]
````