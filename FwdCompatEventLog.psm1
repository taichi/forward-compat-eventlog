# Copyright 2022 taichi
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Function New-EventLog {
  [CmdletBinding(SupportsShouldProcess = $True)]
  param(
    [Parameter(Mandatory = $true, Position = 1)][Alias("LN")][string] $LogName,
    [Parameter(Mandatory = $true, Position = 2)][Alias("SRC")][string[]] $Source,
    [Parameter(Position = 3)][Alias("CN")][string[]] $ComputerName = @("."),
    [Alias("CRF")][string] $CategoryResourceFile,
    [Alias("MRF")][string] $MessageResourceFile,
    [Alias("PRF")][string] $ParameterResourceFile
  )
  process {
    Foreach ($item in $Source) {
      $data = New-Object -TypeName System.Diagnostics.EventSourceCreationData -ArgumentList $item, $LogName
      $data.MachineName = $ComputerName
      $data.CategoryResourceFile = $CategoryResourceFile
      $data.MessageResourceFile = $MessageResourceFile
      $data.ParameterResourceFile = $ParameterResourceFile

      if ($PSCmdlet.ShouldProcess($item, "CreateEventSource")) {
        [System.Diagnostics.EventLog]::CreateEventSource($data)
      }
    }
  }
}

Function Remove-EventLog {
  [CmdletBinding(SupportsShouldProcess = $True)]
  param(
    [Parameter(Position = 1)][Alias("CN")][string[]] $ComputerName = @(),
    [Parameter(Mandatory = $true, ParameterSetName = "Log", Position = 0)][Alias("LN")][string] $LogName,
    [Parameter(Mandatory = $true, ParameterSetName = "Source")][Alias("SRC")][string[]] $Source
  )
  process {
    switch ($PSCmdlet.ParameterSetName) {
      'Log' {
        if (0 -lt $ComputerName.Count) {
          foreach ($item in $ComputerName) {
            if ($PSCmdlet.ShouldProcess($item, "Delete")) {
              [System.Diagnostics.EventLog]::Delete($LogName, $item)
            }
          }
        }
        else {
          if ($PSCmdlet.ShouldProcess($item, "Delete")) {
            [System.Diagnostics.EventLog]::Delete($LogName)
          }
        }
      }
      'Source' {
        if (0 -lt $ComputerName.Count) {
          foreach ($citem in $ComputerName) {
            foreach ($sitem in $Source) {
              if ($PSCmdlet.ShouldProcess($sitem, "DeleteEventSource")) {
                [System.Diagnostics.EventLog]::DeleteEventSource($sitem, $citem)
              }
            }
          }
        }
        else {
          foreach ($sitem in $Source) {
            if ($PSCmdlet.ShouldProcess($sitem, "DeleteEventSource")) {
              [System.Diagnostics.EventLog]::DeleteEventSource($sitem)
            }
          }
        }
      }
    }
  }
}

Function Limit-EventLog {
  [CmdletBinding(SupportsShouldProcess = $True)]
  param(
    [Parameter(Mandatory = $true, Position = 0)][Alias("LN")][string[]] $LogName,
    [Alias("CN")][string[]] $ComputerName = @(),
    [Alias("MRD")][Int32] $RetentionDays = 0,
    [Alias("OFA")][System.Diagnostics.OverflowAction] $OverflowAction,
    [Int64] $MaximumSize = 0)
  process {
    if (0 -lt $ComputerName.Count) {
      foreach ($item in $ComputerName) {
        foreach ($litem in $LogName) {
          if ([System.Diagnostics.EventLog]::Exists($litem, $item)) {
            $log = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList $litem, $item

            if (0 -lt $RetentionDays) {
              if ($PSCmdlet.ShouldProcess($litem, "ModifyOverflowPolicy")) {
                $log.ModifyOverflowPolicy($OverflowAction, $RetentionDays)
              }
            }

            if (0 -lt $MaximumSize) {
              if ($PSCmdlet.ShouldProcess($litem, "ModifyMaximumKilobytes")) {
                $log.MaximumKilobytes = $MaximumSize
              }
            }
          }
        }
      }
    }
    else {
      foreach ($litem in $LogName) {
        if ([System.Diagnostics.EventLog]::Exists($litem)) {
          $log = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList $litem

          if (0 -lt $RetentionDays) {
            if ($PSCmdlet.ShouldProcess($litem, "ModifyOverflowPolicy")) {
              $log.ModifyOverflowPolicy($OverflowAction, $RetentionDays)
            }
          }

          if (0 -lt $MaximumSize) {
            if ($PSCmdlet.ShouldProcess($litem, "ModifyMaximumKilobytes")) {
              $log.MaximumKilobytes = $MaximumSize
            }
          }
        }
      }
    }
  }
}

Function Write-EventLog {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0)][Alias("LN")][string] $LogName,
    [Parameter(Mandatory = $true, Position = 1)][Alias("SRC")][string[]] $Source,
    [Parameter(Position = 3)][Alias("ET")][System.Diagnostics.EventLogEntryType] $EntryType = [System.Diagnostics.EventLogEntryType]::Information,
    [Int16] $Category,
    [Parameter(Position = 2)][Alias("ID", "EID")][Int32] $EventId = 0,
    [Parameter(Mandatory = $true, Position = 4)][Alias("MSG")][string] $Message,
    [Alias("RD")][Byte[]] $RawData,
    [Alias("CN")][string] $ComputerName 
  )
  process {
    $log = New-Object -TypeName System.Diagnostics.EventLog
    $log.Log = $LogName
    $log.Source = $Source
    if ($ComputerName) {
      $log.MachineName = $ComputerName
    }
    $log.WriteEntry($Message, $EntryType, $EventId, $Category, $RawData)
  }
}

# Function Get-EventLog {}
# Use Get-WinEvent instead

Function Show-EventLog {
  [OutputType([System.Diagnostics.EventLog[]])]
  param(
    [Alias("CN")][string] $ComputerName
  )
  process {
    if ($ComputerName) {
      return [System.Diagnostics.EventLog]::GetEventLogs($ComputerName)
    }
    else {
      return [System.Diagnostics.EventLog]::GetEventLogs()
    }
  }
}

Function Clear-EventLog {
  [CmdletBinding(SupportsShouldProcess = $True)]
  param(
    [Parameter(Mandatory = $true, Position = 0)][Alias("LN")][string[]] $LogName,
    [Alias("CN")][string[]] $ComputerName = @()
  )
  process {
    if (0 -lt $ComputerName.Count) {
      foreach ($item in $ComputerName) {
        foreach ($litem in $LogName) {
          if ($PSCmdlet.ShouldProcess($litem, "Clear")) {
            $log = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList $litem, $item
            $log.Clear()
          }
        }
      }
    }
    else {
      foreach ($litem in $LogName) {
        if ($PSCmdlet.ShouldProcess($litem, "Clear")) {
          $log = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList $litem
          $log.Clear()
        }
      }
    }
  }
}
