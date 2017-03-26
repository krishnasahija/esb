#!/bin/bash

IFS=:
# find . -maxdepth 1  -type f | cut -d'/' -f2- > file_set.txt
find . -mindepth 1 -maxdepth 1  | cut -d'/' -f2- | grep -vE '^[0-9]{4}[s]?$' > file_set.txt
cat file_set.txt

function file_to_folder(){
	[ -z $1 ] && return
	[ ! -d $2 ] && mkdir -p $2 
	mv -- $1 $2/$1
}

while read line; do 
	# case $line
		[[ $line =~ 19[0-5][0-9] ]] && echo "${line} is <1950's file " && file_to_folder ${line} "1950s" && continue
		[[ $line =~ 196[0-9] ]] && echo "${line} is 1960's file " && file_to_folder ${line} "1960s" && continue
		[[ $line =~ 197[0-9] ]] && echo "${line} is 1970's file " && file_to_folder ${line} "1970s" && continue
		[[ $line =~ 198[0-9] ]] && echo "${line} is 1980's file " && file_to_folder ${line} "1980s" && continue
		[[ $line =~ 199[0-9] ]] && echo "${line} is 1990's file " && file_to_folder ${line} "1990s" && continue
		[[ $line =~ 2000 ]] && echo "${line} is 2000 file " && file_to_folder ${line} 2000 && continue
		[[ $line =~ 2001 ]] && echo "${line} is 2001 file " && file_to_folder ${line} 2001 && continue
		[[ $line =~ 2002 ]] && echo "${line} is 2002 file " && file_to_folder ${line} 2002 && continue
		[[ $line =~ 2003 ]] && echo "${line} is 2003 file " && file_to_folder ${line} 2003 && continue
		[[ $line =~ 2004 ]] && echo "${line} is 2004 file " && file_to_folder ${line} 2004 && continue
		[[ $line =~ 2005 ]] && echo "${line} is 2005 file " && file_to_folder ${line} 2005 && continue
		[[ $line =~ 2006 ]] && echo "${line} is 2006 file " && file_to_folder ${line} 2006 && continue
		[[ $line =~ 2007 ]] && echo "${line} is 2007 file " && file_to_folder ${line} 2007 && continue
		[[ $line =~ 2008 ]] && echo "${line} is 2008 file " && file_to_folder ${line} 2008 && continue
		[[ $line =~ 2009 ]] && echo "${line} is 2009 file " && file_to_folder ${line} 2009 && continue
		[[ $line =~ 2010 ]] && echo "${line} is 2010 file " && file_to_folder ${line} 2010 && continue
		[[ $line =~ 2011 ]] && echo "${line} is 2011 file " && file_to_folder ${line} 2011 && continue
		[[ $line =~ 2012 ]] && echo "${line} is 2012 file " && file_to_folder ${line} 2012 && continue
		[[ $line =~ 2013 ]] && echo "${line} is 2013 file " && file_to_folder ${line} 2013 && continue
		[[ $line =~ 2014 ]] && echo "${line} is 2014 file " && file_to_folder ${line} 2014 && continue
		[[ $line =~ 2015 ]] && echo "${line} is 2015 file " && file_to_folder ${line} 2015 && continue
		[[ $line =~ 2016 ]] && echo "${line} is 2016 file " && file_to_folder ${line} 2016 && continue
		[[ $line =~ 2017 ]] && echo "${line} is 2017 file " && file_to_folder ${line} 2017 && continue
	# esac
done < file_set.txt

rm file_set.txt
unset IFS
chmod -R 775 *
chmod -R 775 ~/movies/*
