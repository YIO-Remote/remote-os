#!/bin/bash -e
# Stripped down version from:
# https://github.com/gdbtek/linux-cookbooks/blob/master/libraries/util.bash
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Nam Nguyen
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


#######################
# DATE TIME UTILITIES #
#######################

function getISO8601DateTimeNow()
{
    date -u +'%Y-%m-%dT%H:%M:%SZ'
}

function getUTCNowInSeconds()
{
    date -u +'%s'
}

function secondsToReadableTime()
{
    local -r time="${1}"

    local -r day="$((time / 60 / 60 / 24))"
    local -r hour="$((time / 60 / 60 % 24))"
    local -r minute="$((time / 60 % 60))"
    local -r second="$((time % 60))"

    if [[ "${day}" = '0' ]]
    then
        printf '%02d:%02d:%02d' "${hour}" "${minute}" "${second}"
    elif [[ "${day}" = '1' ]]
    then
        printf '%d day and %02d:%02d:%02d' "${day}" "${hour}" "${minute}" "${second}"
    else
        printf '%d days and %02d:%02d:%02d' "${day}" "${hour}" "${minute}" "${second}"
    fi
}

########################
# FILE LOCAL UTILITIES #
########################

function checkExistFile()
{
    local -r file="${1}"
    local -r errorMessage="${2}"

    if [[ "${file}" = '' || ! -f "${file}" ]]
    then
        if [[ "$(isEmptyString "${errorMessage}")" = 'true' ]]
        then
            fatal "\nFATAL : file '${file}' not found"
        fi

        fatal "\nFATAL : ${errorMessage}"
    fi
}

function checkExistFolder()
{
    local -r folder="${1}"
    local -r errorMessage="${2}"

    if [[ "${folder}" = '' || ! -d "${folder}" ]]
    then
        if [[ "$(isEmptyString "${errorMessage}")" = 'true' ]]
        then
            fatal "\nFATAL : folder '${folder}' not found"
        fi

        fatal "\nFATAL : ${errorMessage}"
    fi
}

function emptyFolder()
{
    local -r folder="${1}"

    checkExistFolder "${folder}"

    find "${folder}" \
        -mindepth 1 \
        -delete
}

function getFileExtension()
{
    local -r string="${1}"

    local -r fullFileName="$(basename "${string}")"

    echo "${fullFileName##*.}"
}

function getFileName()
{
    local -r string="${1}"

    local -r fullFileName="$(basename "${string}")"

    echo "${fullFileName%.*}"
}

function getTemporaryFile()
{
    local extension="${1}"

    if [[ "$(isEmptyString "${extension}")" = 'false' && "$(grep -i -o "^." <<< "${extension}")" != '.' ]]
    then
        extension=".${extension}"
    fi

    mktemp "$(getTemporaryFolderRoot)/$(date +'%Y%m%d-%H%M%S')-XXXXXXXXXX${extension}"
}

function getTemporaryFolder()
{
    mktemp -d "$(getTemporaryFolderRoot)/$(date +'%Y%m%d-%H%M%S')-XXXXXXXXXX"
}

function getTemporaryFolderRoot()
{
    local temporaryFolder='/tmp'

    if [[ "$(isEmptyString "${TMPDIR}")" = 'false' ]]
    then
        temporaryFolder="$(formatPath "${TMPDIR}")"
    fi

    echo "${temporaryFolder}"
}

function redirectOutputToLogFile()
{
    local -r logFile="${1}"

    mkdir -p "$(dirname "${logFile}")"
    exec > >(tee -a "${logFile}") 2>&1
}

####################
# NUMBER UTILITIES #
####################

function checkNaturalNumber()
{
    local -r string="${1}"
    local -r errorMessage="${2}"

    if [[ "$(isNaturalNumber "${string}")" = 'false' ]]
    then
        if [[ "$(isEmptyString "${errorMessage}")" = 'true' ]]
        then
            fatal '\nFATAL : not natural number detected'
        fi

        fatal "\nFATAL : ${errorMessage}"
    fi
}

function checkPositiveInteger()
{
    local -r string="${1}"
    local -r errorMessage="${2}"

    if [[ "$(isPositiveInteger "${string}")" = 'false' ]]
    then
        if [[ "$(isEmptyString "${errorMessage}")" = 'true' ]]
        then
            fatal '\nFATAL : not positive number detected'
        fi

        fatal "\nFATAL : ${errorMessage}"
    fi
}

function isNaturalNumber()
{
    local -r string="${1}"

    if [[ "${string}" =~ ^[0-9]+$ ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function isPositiveInteger()
{
    local -r string="${1}"

    if [[ "${string}" =~ ^[1-9][0-9]*$ ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

#####################
# SERVICE UTILITIES #
#####################

function disableService()
{
    local -r serviceName="${1}"

    checkNonEmptyString "${serviceName}" 'undefined service name'

    if [[ "$(existCommand 'systemctl')" = 'true' ]]
    then
        header "DISABLE SYSTEMD ${serviceName}"

        systemctl daemon-reload
        systemctl disable "${serviceName}"
        systemctl stop "${serviceName}" || true
    else
        header "DISABLE SERVICE ${serviceName}"

        chkconfig "${serviceName}" off
        service "${serviceName}" stop || true
    fi

    statusService "${serviceName}"
}

function enableService()
{
    local -r serviceName="${1}"

    checkNonEmptyString "${serviceName}" 'undefined service name'

    if [[ "$(existCommand 'systemctl')" = 'true' ]]
    then
        header "ENABLE SYSTEMD ${serviceName}"

        systemctl daemon-reload
        systemctl enable "${serviceName}" || true
    else
        header "ENABLE SERVICE ${serviceName}"

        chkconfig "${serviceName}" on
    fi

    statusService "${serviceName}"
}

function restartService()
{
    local -r serviceName="${1}"

    checkNonEmptyString "${serviceName}" 'undefined service name'

    stopService "${serviceName}"
    startService "${serviceName}"
}

function startService()
{
    local -r serviceName="${1}"

    checkNonEmptyString "${serviceName}" 'undefined service name'

    if [[ "$(existCommand 'systemctl')" = 'true' ]]
    then
        header "STARTING SYSTEMD ${serviceName}"

        systemctl daemon-reload
        systemctl enable "${serviceName}" || true
        systemctl start "${serviceName}"
    else
        header "STARTING SERVICE ${serviceName}"

        chkconfig "${serviceName}" on
        service "${serviceName}" start
    fi

    statusService "${serviceName}"
}

function statusService()
{
    local -r serviceName="${1}"

    checkNonEmptyString "${serviceName}" 'undefined service name'

    if [[ "$(existCommand 'systemctl')" = 'true' ]]
    then
        header "STATUS SYSTEMD ${serviceName}"

        systemctl status "${serviceName}" --full --no-pager || true
    else
        header "STATUS SERVICE ${serviceName}"

        service "${serviceName}" status || true
    fi
}

function stopService()
{
    local -r serviceName="${1}"

    checkNonEmptyString "${serviceName}" 'undefined service name'

    if [[ "$(existCommand 'systemctl')" = 'true' ]]
    then
        header "STOPPING SYSTEMD ${serviceName}"

        systemctl daemon-reload
        systemctl stop "${serviceName}" || true
    else
        header "STOPPING SERVICE ${serviceName}"

        service "${serviceName}" stop || true
    fi

    statusService "${serviceName}"
}

####################
# STRING UTILITIES #
####################

function checkNonEmptyString()
{
    local -r string="${1}"
    local -r errorMessage="${2}"

    if [[ "$(isEmptyString "${string}")" = 'true' ]]
    then
        if [[ "$(isEmptyString "${errorMessage}")" = 'true' ]]
        then
            fatal '\nFATAL : empty value detected'
        fi

        fatal "\nFATAL : ${errorMessage}"
    fi
}

function checkTrueFalseString()
{
    local -r string="${1}"
    local -r errorMessage="${2}"

    if [[ "${string}" != 'true' && "${string}" != 'false' ]]
    then
        if [[ "$(isEmptyString "${errorMessage}")" = 'true' ]]
        then
            fatal "\nFATAL : '${string}' is not 'true' or 'false'"
        fi

        fatal "\nFATAL : ${errorMessage}"
    fi
}

function debug()
{
    local -r message="${1}"

    if [[ "$(isEmptyString "${message}")" = 'false' ]]
    then
        echo -e "\033[1;34m${message}\033[0m" 2>&1
    fi
}

function deleteSpaces()
{
    local -r content="${1}"

    replaceString "${content}" ' ' ''
}

function encodeURL()
{
    local -r url="${1}"

    local i=0

    for ((i = 0; i < ${#url}; i++))
    do
        local walker=''
        walker="${url:i:1}"

        case "${walker}" in
            [a-zA-Z0-9.~_-])
                printf '%s' "${walker}"
                ;;
            ' ')
                printf +
                ;;
            *)
                printf '%%%X' "'${walker}"
                ;;
        esac
    done
}

function error()
{
    local -r message="${1}"

    if [[ "$(isEmptyString "${message}")" = 'false' ]]
    then
        echo -e "\033[1;31m${message}\033[0m" 1>&2
    fi
}

function escapeGrepSearchPattern()
{
    local -r searchPattern="${1}"

    sed 's/[]\.|$(){}?+*^]/\\&/g' <<< "${searchPattern}"
}

function escapeSearchPattern()
{
    local -r searchPattern="${1}"

    sed -e "s@\@@\\\\\\@@g" -e "s@\[@\\\\[@g" -e "s@\*@\\\\*@g" -e "s@\%@\\\\%@g" <<< "${searchPattern}"
}

function fatal()
{
    local -r message="${1}"

    error "${message}"
    exit 1
}

function formatPath()
{
    local path="${1}"

    while [[ "$(grep -F '//' <<< "${path}")" != '' ]]
    do
        path="$(sed -e 's/\/\/*/\//g' <<< "${path}")"
    done

    sed -e 's/\/$//g' <<< "${path}"
}

function header()
{
    local -r title="${1}"

    if [[ "$(isEmptyString "${title}")" = 'false' ]]
    then
        echo -e "\n\033[1;33m>>>>>>>>>> \033[1;4;35m${title}\033[0m \033[1;33m<<<<<<<<<<\033[0m\n"
    fi
}

function indentString()
{
    local -r indentString="$(escapeSearchPattern "${1}")"
    local -r string="$(escapeSearchPattern "${2}")"

    sed "s@^@${indentString}@g" <<< "${string}"
}

function info()
{
    local -r message="${1}"

    if [[ "$(isEmptyString "${message}")" = 'false' ]]
    then
        echo -e "\033[1;36m${message}\033[0m" 2>&1
    fi
}

function invertTrueFalseString()
{
    local -r string="${1}"

    checkTrueFalseString "${string}"

    if [[ "${string}" = 'true' ]]
    then
        echo 'false' && return 1
    fi

    echo 'true' && return 0
}

function isEmptyString()
{
    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function postUpMessage()
{
    echo -e "\n\033[1;32m¯\_(ツ)_/¯\033[0m"
}

function printTable()
{
    local -r delimiter="${1}"
    local -r tableData="$(removeEmptyLines "${2}")"
    local -r colorHeader="${3}"
    local -r displayTotalCount="${4}"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${tableData}")" = 'false' ]]
    then
        local -r numberOfLines="$(trimString "$(wc -l <<< "${tableData}")")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${tableData}")"

                local numberOfColumns=0
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                # Add Header Or Body

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#|  %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                local output=''
                output="$(echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1')"

                if [[ "${colorHeader}" = 'true' ]]
                then
                    echo -e "\033[1;32m$(head -n 3 <<< "${output}")\033[0m"
                    tail -n +4 <<< "${output}"
                else
                    echo "${output}"
                fi
            fi
        fi

        if [[ "${displayTotalCount}" = 'true' && "${numberOfLines}" -ge '0' ]]
        then
            echo -e "\n\033[1;36mTOTAL ROWS : $((numberOfLines - 1))\033[0m"
        fi
    fi
}

function removeEmptyLines()
{
    local -r content="${1}"

    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString()
{
    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "$(isPositiveInteger "${numberToRepeat}")" = 'true' ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function replaceString()
{
    local -r content="${1}"
    local -r oldValue="$(escapeSearchPattern "${2}")"
    local -r newValue="$(escapeSearchPattern "${3}")"

    sed "s@${oldValue}@${newValue}@g" <<< "${content}"
}

function stringToNumber()
{
    local -r string="${1}"

    checkNonEmptyString "${string}" 'undefined string'

    if [[ "$(existCommand 'md5')" = 'true' ]]
    then
        md5 <<< "${string}" | tr -cd '0-9'
    elif [[ "$(existCommand 'md5sum')" = 'true' ]]
    then
        md5sum <<< "${string}" | tr -cd '0-9'
    else
        fatal '\nFATAL : md5 or md5sum command not found'
    fi
}

function stringToSearchPattern()
{
    local -r string="$(trimString "${1}")"

    if [[ "$(isEmptyString "${string}")" = 'true' ]]
    then
        echo "${string}"
    else
        echo "^\s*$(sed -e 's/\s\+/\\s+/g' <<< "$(escapeSearchPattern "${string}")")\s*$"
    fi
}

function trimString()
{
    local -r string="${1}"

    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

function warn()
{
    local -r message="${1}"

    if [[ "$(isEmptyString "${message}")" = 'false' ]]
    then
        echo -e "\033[1;33m${message}\033[0m" 1>&2
    fi
}

####################
# SYSTEM UTILITIES #
####################

function checkExistCommand()
{
    local -r command="${1}"
    local -r errorMessage="${2}"

    if [[ "$(existCommand "${command}")" = 'false' ]]
    then
        if [[ "$(isEmptyString "${errorMessage}")" = 'true' ]]
        then
            fatal "\nFATAL : command '${command}' not found"
        fi

        fatal "\nFATAL : ${errorMessage}"
    fi
}

function existCommand()
{
    local -r command="${1}"

    if [[ "$(which "${command}" 2> '/dev/null')" = '' ]]
    then
        echo 'false' && return 1
    fi

    echo 'true' && return 0
}

function existDiskMount()
{
    local -r disk="$(escapeGrepSearchPattern "${1}")"
    local -r mountOn="$(escapeGrepSearchPattern "${2}")"

    local -r foundMount="$(df | grep -E "^${disk}\s+.*\s+${mountOn}$")"

    if [[ "$(isEmptyString "${foundMount}")" = 'true' ]]
    then
        echo 'false' && return 1
    fi

    echo 'true' && return 0
}

function existMount()
{
    local -r mountOn="$(escapeGrepSearchPattern "${1}")"

    local -r foundMount="$(df | grep -E ".*\s+${mountOn}$")"

    if [[ "$(isEmptyString "${foundMount}")" = 'true' ]]
    then
        echo 'false' && return 1
    fi

    echo 'true' && return 0
}

