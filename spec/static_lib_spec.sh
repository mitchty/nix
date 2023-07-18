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

  # TODO: more _s function unit tests...

  # Helper for doing evil things with ssh passing in options you never really
  # should if you care about security.
  Describe '_yolo() without SSHOPTS'
    Before 'setup'
    setup() {
      unset SSHOPTS
    }

    It "_yolo dumps default options when nothing set"
      When call _yolo
      The output should eq "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
    End
  End

  Describe '_yolo() with SSHOPTS set'
    Before 'setup'
    After 'teardown'

    setup() {
      export SSHOPTS='-o somekey=someval'
    }

    teardown() {
      unset SSHOPTS
    }

    It "_yolo wraps stuff when set"
      When call _yolo
      The output should eq "${SSHOPTS} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
    End
  End

  # Helper stuff for the _s ssh/scp using sshpass wrapper, note the ssh/scp is
  # stripped at this point.
  Describe '_s_host parsing'
    Parameters
      "user@host" host
      "user@host uptime" host
      "user@host:/dest" host
      "host" host
      "host uptime" host
      "foo.bar user@host:/tmp/blah" host
      "foo.bar host:/tmp/blah" host
      "host:/tmp/blah" host
    End
    It "parses arg strings appropriately to the hostname host"
      When call _s_host "$1"
      The output should eq "$2"
    End
  End

  # Test out the ~/.ssh/file parsing wrapping via ssh
  # Describe '_s_args parsing'
  #   It "blah"
  #     When call _s_args ssh hostname /some/file
  #     The output should eq "ssh hostname -F /some/file -G"
  #   End
  # End

  Context 'bw cli functions'
    Describe 'one bitwarden cli match'
      bw_items() {
        %text
        #|---
        #|{
        #|  "object": "item",
        #|  "id": "some-uuid",
        #|  "organizationId": null,
        #|  "folderId": "some-other-uuid",
        #|  "type": 2,
        #|  "reprompt": 0,
        #|  "name": "somename",
        #|  "notes": "",
        #|  "favorite": false,
        #|  "secureNote": {
        #|    "type": 0
        #|  },
        #|  "collectionIds": [],
        #|  "revisionDate": "2022-03-17T15:28:28.798Z",
        #|  "deletedDate": null
        #|}
      }
    End
  End
End
