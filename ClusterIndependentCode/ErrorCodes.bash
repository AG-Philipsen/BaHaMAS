#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

#NOTE: Here we do not include the definition of the variables in a function
#      as everywhere else. So we can use them just sourcing the file also in
#      the tests. It is fine because they are all just constants.

#Variables for exit codes (between 64 and 113 http://tldp.org/LDP/abs/html/exitcodes.html)
readonly BHMAS_successExitCode=0
readonly BHMAS_fatalBuiltin=64
readonly BHMAS_fatalPathError=65
readonly BHMAS_fatalMissingFeature=66
readonly BHMAS_fatalFileNotFound=67
readonly BHMAS_fatalFileExists=68
readonly BHMAS_fatalWrongBetasFile=69
readonly BHMAS_fatalCommandLine=70
readonly BHMAS_fatalVariableUnset=109
readonly BHMAS_fatalRequirement=110
readonly BHMAS_fatalLogicError=111
readonly BHMAS_fatalGeneric=112
readonly BHMAS_internal=113


