#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description:
Describe 'autoinstall lib.sh'
  # Note shellspec runs from the git checkout dir
  Include modules/iso/lib.sh

  Describe 'sfdisk labels work?'
    It 'labels dos labels correctly'
      When call sfdisklabel dos 0 "" 100M 200M
      The output should eq 'label: dos

1: size=100M, start=1M, type=83, bootable
2: size=200M, type=fd
3: size=256GiB, type=83'
    End
    It 'labels gpt labels correctly index 0'
      When call sfdisklabel gpt 0 "" 100M 200M
      The output should eq 'label: gpt

1: size=100M, type= uefi, bootable
2: size=200M, type= 0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
3: size=256GiB, type= E6D6D379-F507-44C2-A23C-238F2A3DF928
4: type= 0FC63DAF-8483-4772-8E79-3D69D8477DE4'
    End
    It 'labels gpt labels correctly index 1'
      When call sfdisklabel gpt 1 "" 100M 200M
      The output should eq 'label: gpt

1: size=100M, type= uefi, bootable
2: size=200M, type= 0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
3: size=256GiB, type= E6D6D379-F507-44C2-A23C-238F2A3DF928
4: type= 0FC63DAF-8483-4772-8E79-3D69D8477DE4'
    End

    It 'labels gpt with dedicated boot true correctly and at index 0'
      When call sfdisklabel gpt 0 "anything" 100M 200M
      The output should eq 'label: gpt

1: type= uefi, bootable'
    End

  End
End
