# Special Functions

function Get-TFSQueryDefinitions
    {
        [CmdletBinding()]
        [OutputType([string])]
        param ( 
            [Parameter(ValueFromPipeline=$true)][string] $TFSProjectCollectionUrl = "http://localhost:8080/tfs/DefaultCollection", 
            [switch] $GetFullURL
            )

        begin
        {
            Write-Verbose("Get-TFSQueryDefinitions() - Enter")
        }

        process
        {
                $teamProjectCollection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($TFSProjectCollectionUrl)
                $teamProjectCollection.EnsureAuthenticated()
         
                [Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore]$ws = $teamProjectCollection.GetService([type]"Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore")

                foreach ($currentProject in $ws.Projects)
                {
                    [Microsoft.TeamFoundation.WorkItemTracking.Client.Project]$pj = $currentProject
                    
                    foreach ($currentQuery in $pj.StoredQueries)
                        {
                               [Microsoft.TeamFoundation.WorkItemTracking.Client.StoredQuery]$sq = $currentQuery
                               Write-Verbose ($sq.Name)
                               Write-Output($sq)
                        }

                }

        }

        end
        {
            Write-Verbose("Get-TFSQueryDefinitions() - Leave")
        }   
    }

    function Compare-TFSFieldLists
    {
        param
        (
        [Parameter(ValueFromPipeline=$false, Mandatory=$true)][string]$SourceListFile,
        [Parameter(ValueFromPipeline=$false, Mandatory=$true)][string]$TargetListFile,
        [switch] $DifferentFieldsOnly,
        [switch] $Strict
        )

        $SourceList = Import-Clixml -Path $SourceListFile
        $TargetList = Import-Clixml -Path $TargetListFile

        $masterList = @{}

        foreach ($currentSourceField in $SourceList)
            {
                # Field is present in source list
                $no = New-Object PSObject -Property @{ 
                    ReferenceName = $currentSourceField.ReferenceName    
                    TargetName    = $null
                    SourceName    = $currentSourceField.Name}
                   
                $masterList.Add($currentSourceField.ReferenceName, $no)
            }

        foreach ($currentTargetField in $TargetList)
            {
                if ($masterList.ContainsKey($currentTargetField.ReferenceName))
                    {
                        # Field is present in both lists
                        $masterList.Item($currentTargetField.ReferenceName).TargetName = $currentTargetField.Name
                    }
                else
                    {
                        # Field is present in target list but not in source list
                        $no = New-Object PSObject -Property @{ 
                            ReferenceName = $currentTargetField.ReferenceName    
                            TargetName    = $currentTargetField.Name
                            SourceName    = $null}

                        $masterList.Add($currentTargetField.ReferenceName, $no)
                    }
            }

        foreach ($li in $masterList.Values)
            {
                if ($DifferentFieldsOnly.IsPresent)
                {
                    if ($li.TargetName -ne $li.SourceName)
                        {
                            Write-Output ($li)
                        }    
                }
                else
                {
                    Write-Output ($li)
                }

            }

    }

