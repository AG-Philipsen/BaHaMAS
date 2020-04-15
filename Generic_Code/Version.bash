#
#  Copyright (c) 2020 Alessandro Sciarra
#
#  This file is part of BaHaMAS.
#
#  BaHaMAS is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  BaHaMAS is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with BaHaMAS. If not, see <http://www.gnu.org/licenses/>.
#

function PrintCodeVersion(){
    local gitTagShort gitTagLong tagDate
    if ! gitTagLong=$(git -C "${BHMAS_repositoryTopLevelPath}" describe --tags 2>/dev/null); then
        Fatal "It was not possible to obtain the version in use!\n"\
              "This probably (but not necessarily) means that\n"\
              "you are behind any release in the BaHaMAS history."
    fi
    if ! gitTagShort=$(git -C "${BHMAS_repositoryTopLevelPath}" describe --tags --abbr=0 2>/dev/null); then
        Internal "Unexpected error in \"${FUNCNAME}\" trying to obtain the closest git tag."
    fi
    tagDate=$(date -d "$(git -C "${BHMAS_repositoryTopLevelPath}" tag -l "${gitTagShort}" --format='%(creatordate:short)')" +'%d %B %Y')
    if [[ "${gitTagShort}" != "${gitTagLong}" ]]; then
        gitTagLong=$(git -C "${BHMAS_repositoryTopLevelPath}" describe --tags --dirty --broken 2>/dev/null)
        Warning "You are not using an official release of the BaHaMAS.\n"\
                "Unless you have a reason not to do so, it would be better\n"\
                "to checkout a stable release. The last stable release behind\n"\
                "the commit you are using is " lc "${gitTagShort} (${tagDate})" y ".\n\n"\
                lo "The repository state is " emph "${gitTagLong}"\
                "\n(see git-describe documentation for more information)."
    else
        cecho bb "This is " emph "${gitTagShort}" " released on " emph "${tagDate}"
    fi
}
