#!/bin/sh

# Copyright LEVAI Daniel <leva@ecentrum.hu>
# Distributed under the 2-clause BSD license (see LICENSE file)

# See XXX-Zsh markings, if you use Zsh!


# Zsh doesn't like zero as an index number in arrays...
typeset -i i=1
typeset -i nword=0

# XXX This is needed to use *() globbing in Zsh
if [ -n "$ZSH_VERSION" ];then
	set -o kshglob
fi

URL_PATTERN='https*://[[:alnum:]\.-]+(:[0-9]+)*(/~*[[:alnum:]#$%&*+,./:;=?@{}|~^_-]+)*'
url_prev=''
for word in $(tr '\n' '' |sed -r -e 's/\s*|"//g');do
	nword=$(( nword + 1 ))

	[ $(( $nword % 50 )) -eq 0 ]  &&  printf "$0: $nword ...\r"

	while [[ "${word}" = *http*(s)://* ]];do
		url=$( echo ${word} |sed -r -e "s,^(.*)(${URL_PATTERN})(.*)$,\2," )

		# Do not include the same url successively
		[ "${url}" = "${url_prev}" ]  &&  break

		# Fail-safe, to exclude garbage
		# XXX this slows us down a bit
		if [[ "${url}" != http*(s)://* ]];then
			word=$( echo ${word} |sed -r -e "s,^(.*)(${url})(.*)$,\1\3," )
			continue
		fi

		word=$( echo ${word} |sed -r -e "s,^(.*)(${URL_PATTERN})(.*)$,\1\3," )

		URLS[$i]=${url}
		url_prev=$url

		i=$(( i + 1 ))
	done
done
unset nword
unset word
unset url


printf "== URL viewer: $0 ==\n\n"
printf "BROWSER is '${BROWSER:-<empty>}'\n\n"

if [ ${#URLS[@]} -eq 0 ];then
	echo "No URLs found."
	exit 0;
fi

exec <&-
exec 0</dev/tty


typeset QUIT=0
FILTER_PATTERN=''

PS3="[<index>,x,b,f,s,?] #? "

while [ ${QUIT} -le 0 ];do
	[ -n "${FILTER_PATTERN}" ]  &&  echo "Filter is: ${FILTER_PATTERN}"

	select url in $(echo ${URLS[@]} |tr ' ' '\n' |egrep -E -e "${FILTER_PATTERN}");do
		case "${REPLY}" in
			X|x|Q|q)
				QUIT=1
				break;
			;;
			B|b)
				echo -n 'Enter new BROWSER value: '; read BROWSER
			;;
			F|f)
				echo -n 'Enter a filter pattern <empty to reset>: '; read -r FILTER_PATTERN
				# escape '$' characters:
				#FILTER_PATTERN=$( echo "${FILTER_PATTERN}" |sed -r -e 's,([$]),\\\1,g')

				if ! echo ${URLS[@]} |egrep -q -E -e "${FILTER_PATTERN}";then
					# XXX
					# This is needed with at least Bash 4.2.45,
					# because when select .. in .. {} encounters an
					# empty list, it enters an infinite loop...
					#
					# Ksh doesn't have this bug, neither Zsh,
					# but the latter would display the empty list element
					# if I were to put an empty element like
					# `select url in "" $( ... )' in the select statement.
					#
					# So, here is a workaround:
					echo -n "No matches for filter; I must reset it. (press <Enter>)"; read
					FILTER_PATTERN=''
				fi
				break;
			;;
			S|s)
				# Sort the array of URLs
				i=0
				for url in $(echo ${URLS[@]} |tr ' ' '\n' |sort |uniq);do
					i=$(( i + 1 ))
					URLS[$i]=${url}
				done
				# Erase the leftover items from the previous, unsorted array
				while [ ${#URLS[@]} -gt $i ];do
					unset URLS[$(( ${#URLS[@]} ))]
					# XXX-Zsh If you use Zsh, comment the previous line,
					#     and uncomment the next one.
					#URLS[$(( ${#URLS[@]} ))]=()
				done
				break;
			;;
			\?|help|h)
				echo "x,X,q,Q: Exit"
				echo "B,b: Enter a new executable name for the BROWSER variable."
				echo "F,f: Enter a filter pattern for filtering the URL list."
				echo "S,s: Sort the URL list and delete duplicate entries."
			;;
			*)
				[ -n "${url}" ]  ||  continue;

				if [ -z "${BROWSER}" ];then
					echo -n 'Wrong or empty BROWSER value! Enter a browser: '; read BROWSER
				fi

				if [ -z "${BROWSER}" ];then
					echo "Wrong or empty BROWSER value: '${BROWSER}'"
				else
					echo "Executing: ${BROWSER} ${url}"
					${BROWSER} "${url}"
				fi
			;;
		esac

		[ -n "${FILTER_PATTERN}" ]  &&  echo "Filter is: ${FILTER_PATTERN}"

		printf "\nPress <Enter> to redisplay list\n"
	done
done
