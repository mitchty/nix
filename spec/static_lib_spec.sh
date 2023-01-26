#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: unit test lib.sh functionality

# shellspec thinks these are unreachable and thats true but they get used at
# shellspec eval time. Just ignore it for the entire file.
#shellcheck disable=SC2317
Describe 'lib.sh'
  # Note shellspec runs from the git checkout dir
  Include static/src/lib.sh

  # need to reset these before each test that abuses them
  sed_inplace_before() {
    _sed_inplace_once_memo=false
    unset SED_NEEDS_WHITESPACE
  }

  # These tests are to encompass the nonsense arg parsing differences between
  # bsd sed and gnu/busybox sed when you want to edit a file in place.
  #
  # If you do sed -e ... -i'' file on bsd sed, that fails
  #
  Describe 'sed_inplace bsd sed'
    Before 'sed_inplace_before'

    # How bsd sed behaves with -i'' (errors all over)
    sed() {
        printf "sed: -I or -i may not be used with stdin\n" >&2
        return 1
    }
    It "detects bsd style sed correctly and outputs -i ''"
      When call _sut_sed_inplace
      The output should eq "-i ''"
    End
  End

  Describe 'sed_inplace busybox sed'
    Before 'sed_inplace_before'

    # How busybox sed behaves with -i'' (its fine with it)
    sed() {
      return 0
    }

    It "detects busybox style sed correctly and outputs -i''"
      When call _sut_sed_inplace
      The output should eq "-i''"
    End
  End

  Describe 'sed_inplace gnu sed'
    Before 'sed_inplace_before'

    # How gnu sed behaves with -i'' (its fine with it)
    sed() {
      return 0
    }

    It "detects gnu style sed correctly and outputs -i''"
      When call _sut_sed_inplace
      The output should eq "-i''"
    End
  End
End
