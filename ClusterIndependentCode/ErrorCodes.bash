#
#  Copyright (c) 2017,2020 Alessandro Sciarra
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

#NOTE: Here we do not include the definition of the variables in a function
#      as everywhere else. So we can use them just sourcing the file also in
#      the tests. It is fine because they are all just constants.

#Standard bash exit codes
readonly BHMAS_successExitCode=0
readonly BHMAS_failureExitCode=1

#Variables for exit codes (between 64 and 113 http://tldp.org/LDP/abs/html/exitcodes.html)
readonly BHMAS_fatalBuiltin=64
readonly BHMAS_fatalPathError=65
readonly BHMAS_fatalMissingFeature=66
readonly BHMAS_fatalFileNotFound=67
readonly BHMAS_fatalFileExists=68
readonly BHMAS_fatalWrongBetasFile=69
readonly BHMAS_fatalCommandLine=70
readonly BHMAS_fatalValueError=71
readonly BHMAS_fatalVariableUnset=109
readonly BHMAS_fatalRequirement=110
readonly BHMAS_fatalLogicError=111
readonly BHMAS_fatalGeneric=112
readonly BHMAS_internal=113
