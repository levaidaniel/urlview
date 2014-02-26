#!/bin/sh

# Copyright LEVAI Daniel <leva@ecentrum.hu>
# Distributed under the 2-clause BSD license (see LICENSE file)

# See XXX-Zsh markings, if you use Zsh!


# If you don't want to weed out duplicate URLs in the resulting list,
# set this to 0.
typeset -i SORTING=1


# Zsh doesn't like zero as an index number in arrays...
typeset -i i=1
typeset -i nword=0

# XXX This is needed to use *() globbing in Zsh
if [ -n "$ZSH_VERSION" ];then
	set -o kshglob
fi

URL_PATTERN='https*://[[:alnum:]:./?=&_-]+'
for word in $(tr '\n' ' ');do
	nword=$(( nword + 1 ))

	[ $(( $nword % 50 )) -eq 0 ]  &&  printf "$0: $nword ...\r"

	while [[ "${word}" = *http*(s)://* ]];do
		url=$( echo ${word} |sed -r -e "s,(.*)(${URL_PATTERN})(.*),\2," )
		word=$( echo ${word} |sed -r -e "s,(.*)(${URL_PATTERN})(.*),\1\3," )

		URLS[$i]=${url}
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


if [ ${SORTING} -gt 0 ];then
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
fi
unset i


typeset QUIT=0
FILTER_PATTERN=''

PS3="[<index>,x,b,f] #? "

while [ ${QUIT} -le 0 ];do
	[ -n "${FILTER_PATTERN}" ]  &&  echo "Filter is: ${FILTER_PATTERN}"

	select url in $(echo ${URLS[@]} |tr ' ' '\n' |fgrep -e "${FILTER_PATTERN}");do
		case "${REPLY}" in
			X|x|Q|q)
				QUIT=1
				break;
			;;
			B|b)
				echo -n 'Enter new BROWSER value: '; read BROWSER
			;;
			F|f)
				echo -n 'Enter a filter pattern <empty to reset>: '; read FILTER_PATTERN
				FILTER_PATTERN=$( echo "${FILTER_PATTERN}" |sed -r -e 's,([$]),\\\1,g')

				if ! echo ${URLS[@]} |tr ' ' '\n' |fgrep -q -e "${FILTER_PATTERN}";then
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
			*)
				[ -n "${url}" ]  ||  continue;

				if [ -z "${BROWSER}" ]  ||  [ ! -x "${BROWSER}" ];then
					echo -n 'Wrong or empty BROWSER value! Enter a browser: '; read BROWSER
				fi

				if [ -z "${BROWSER}" ]  ||  [ ! -x "${BROWSER}" ];then
					echo "Wrong or empty BROWSER value: '${BROWSER}'"
				else
					echo "Executing: ${BROWSER} ${url}"
					( ${BROWSER} "${url}" )
				fi
			;;
		esac

		echo ''

		[ -n "${FILTER_PATTERN}" ]  &&  echo "Filter is: ${FILTER_PATTERN}"
	done
done
