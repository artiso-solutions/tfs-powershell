# TFS Administration API Functions

<#
.SYNOPSIS
    Gets the Microsoft.TeamFoundation.Client.TfsConfigurationServer object for a TFS Server
.PARAMETER TFSUrl
    URL of the target TFS server
.PARAMETER GetFullURL
    Write full URL information to the pipeline. If not specified, only TPC display names will be used.
.LINK
    https://github.com/artiso-solutions/tfs-powershell  
#>

function Get-TFSConfigurationServer
     { 
        [CmdletBinding()]
        [OutputType([Microsoft.TeamFoundation.Client.TfsConfigurationServer])]
        param (
            [string] $TFSUrl
        )
        if (!($TFSUrl))
            {
               $TFSUrl = "http://localhost:8080/tfs" 
            }
        
        Write-Verbose ("Connecting to " + $TFSUrl)

        [Microsoft.TeamFoundation.Client.TfsConfigurationServer] $tfsConfigurationServer =
            [Microsoft.TeamFoundation.Client.TfsConfigurationServerFactory]::GetConfigurationServer($tfsURL)

        $tfsConfigurationServer.EnsureAuthenticated()

        if ($tfsConfigurationServer) 
            {
                Write-Verbose ("Connected to " + [string]$tfsConfigurationServer.Name + " as " + $tfsConfigurationServer.AuthorizedIdentity.DisplayName)
                Write-Output $tfsConfigurationServer
            }
        else
            {
                Write-Error ("Could not connect to " + $TFSUrl)
            }

    }

<#
.SYNOPSIS
    Gets a list of TFS Team Project Collection names or URLs from a TFS Server
.DESCRIPTION
    Gets the TFS Url from the pripeline and writes a list of Team Project Collections (names or URLs) to the pipeline
.PARAMETER TFSUrl
    URL of the target TFS server
.PARAMETER GetFullURL
    Write full URL information to the pipeline. If not specified, only TPC display names will be used.
.EXAMPLE
    "http://localhost:8080/tfs" | Get-TFSTeamProjectCollectionNames
.LINK
    https://github.com/artiso-solutions/tfs-powershell  
#>
function Get-TFSTeamProjectCollections
    { 
        [CmdletBinding()]
        [OutputType([string])]
        param   
            (
                [Parameter(ValueFromPipeline=$true)][string] $TFSUrl = "http://localhost:8080/tfs",
                [switch] $FullURL
            )
            
        begin 
            {
                Write-Debug("Get-TFSTeamProjectCollections() - Enter")  
            }

        process
            {

                [Microsoft.TeamFoundation.Client.TfsConfigurationServer]$tfsConfigurationServer = 
                    Get-TFSConfigurationServer -TFSUrl $TFSUrl

                $tfsConfigurationServer.EnsureAuthenticated()
                   
                [Microsoft.TeamFoundation.Framework.Client.CatalogNode]$catalogNode = 
                    $tfsConfigurationServer.CatalogNode 

                if (!$catalogNode)
                    {
                        Write-Error ("Could not connect to server " + $tfsConfigurationServer.Name)
                        return
                    }

                $tpcGUID = new-object System.Guid "26338d9e-d437-44aa-91f2-55880a328b54"
                $projectCollectionGUID = New-Object System.Collections.Generic.List[System.Guid] 
                $projectCollectionGUID.Add($tpcGUID)    

                $tpcNodes = $catalogNode.QueryChildren(
                    $projectCollectionGUID, 
                    $false, 
                    [Microsoft.TeamFoundation.Framework.Common.CatalogQueryOptions]::None)

                [int]$numberOfCollections =  $tpcNodes.Count
                
                if ($numberOfCollections -eq 0)
                    {
                        Write-Verbose  "No collections found."
                        return
                    }

                Write-Verbose ("Found " + [string]$numberOfCollections + " Team Project Collection(s):")

                foreach ($tpcNode in $tpcNodes)
                    {
                        Write-Verbose ("-" + $tpcNode.Resource.DisplayName)
                        if ($FullURL.IsPresent)
                            {      
                                Write-Output ($TFSUrl.TrimEnd("/") + "/" + $tpcNode.Resource.DisplayName)
                            }
                        else
                            {
                                Write-Output $tpcNode.Resource.DisplayName
                            }

                    }     
                }

            end
                {
                    Write-Debug("Get-TFSTeamProjectCollections() - Leave")  
                }

        }

<#
.SYNOPSIS
    Gets a list of TFS Team Project  names or URLs from a TFS Server
.DESCRIPTION
    Gets the TFS TPC Url from the pripeline and writes a list of Team Projects (names or URLs) to the pipeline
.PARAMETER TFSTpcUrl
    URL of the target TFS server
.PARAMETER GetFullURL
    Write full URL information to the pipeline. If not specified, only TPC names will be used.
.EXAMPLE
    "http://localhost:8080/tfs/DefaultCollection" | Get-TFSTeamProjectNames
.LINK
    https://github.com/artiso-solutions/tfs-powershell
  
#>
function Get-TFSTeamProjects
    {
        [CmdletBinding()]
        [OutputType([string])]
        param ( 
            [Parameter(ValueFromPipeline=$true)][string] $TFSProjectCollectionUrl = "http://localhost:8080/tfs/DefaultCollection", 
            [switch] $FullURL
            )
            
            begin
            {
                Write-Debug("Get-TFSTeamProjects() - Enter")
            }

            process
            {
                
                $teamProjectCollection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($TFSProjectCollectionUrl)
                $ws = $teamProjectCollection.GetService([type]"Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore")

                Write-Verbose("Team Projects: ")
                foreach ($p in $ws.Projects)
                    {
                        $project = [Microsoft.TeamFoundation.WorkItemTracking.Client.Project]$p
                        Write-Verbose ("  " + $project.Name)
                        if ($FullURL.IsPresent)
                            {     
                                Write-Output($TFSProjectCollectionUrl.TrimEnd("/") + "/" + $project.Name)
                            }
                        else
                            {
                                Write-Output($project.Name)
                            }

                     }
            }

            end
            {
                Write-Debug("Get-TFSTeamProjects() - Enter")
            }

    }

function Get-TFSFieldDetails
    {
        [CmdletBinding()]
        [OutputType([PSObject])]
        param ( 
            [Parameter(ValueFromPipeline=$true)][string] $TFSProjectCollectionUrl = "http://localhost:8080/tfs/DefaultCollection" 
            )

        begin
        {
            Write-Verbose("Get-TFSFieldDetails() - Enter")
        }

        process
        {
                $teamProjectCollection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($TFSProjectCollectionUrl)
                $teamProjectCollection.EnsureAuthenticated()
         
                [Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore]$ws = $teamProjectCollection.GetService([type]"Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore")

                foreach ($currentField in $ws.FieldDefinitions)
                {
                    [Microsoft.TeamFoundation.WorkItemTracking.Client.FieldDefinition]$cf = $currentField
                    Write-Verbose ("Found field - " + $cf.Name)      
                    $fieldDefinitionObject = New-Object PSObject -Property @{ 
                        Name                   = $cf.Name    
                        ReferenceName          = $cf.ReferenceName    
                        Id                     = $cf.Id  
                        Usage                  = $cf.Usage 
                        IsIndexed              = $cf.IsIndexed 
                        IsCoreField            = $cf.IsCoreField 
                        IsEditable             = $cf.IsEditable 
                        IsComputed             = $cf.IsUserNameField 
                        IsUserNameField        = $cf.HelpText 
                        HelpText               = $cf.FieldType 
                        ReportingAttributeType = $cf.ReportingAttributes.Type #ReportingAttributes contains redundant Name and ReferenceName Information, we only want the Type
                        SystemType             = $cf.IsQueryable 
                        IsQueryable            = $cf.IsQueryable 
                        CanSortBy              = $cf.CanSortBy 
                        PsFieldType            = $cf.PsFieldType 
                        IsLongText             = $cf.IsLongText 
                        SupportsTextQuery      = $cf.SupportsTextQuery 
                        IsCloneable            = $cf.IsCloneable 
                        IsInternal             = $cf.IsInternal 
                        PsReportingType        = $cf.PsReportingType # Extended Compare
                        PsReportingFormula     = $cf.PsReportingFormula # Extended Compare
                        IsReportable           = $cf.IsReportable # Extended Compare
                        ReportingName          = $cf.ReportingName # Extended Compare
                        ReportingReferenceName = $cf.ReportingReferenceName # Extended Compare
                        AllowedValues          = $cf.AllowedValues 
                        ProhibitedValues       = $cf.ProhibitedValues 
                        IsUsedInWorkItemType   = $cf.IsUsedInWorkItemType 
                        IsUsedInGlobalWorkflow = $cf.IsUsedInGlobalWorkflow
                       #WorkItemStore          = $cf.WorkItemStore #Removed because it clutters up the output. Mught be required if access to the WorkItemStore is required
                    }
                    Write-Output($fieldDefinitionObject)
                    
                }

        }

        end
        {
            Write-Verbose("Get-TFSFieldDetails() - Leave")
        }

    } 

function Edit-TFSWorkitemFieldValue
    {
        [CmdletBinding()]
        [OutputType([string])]
        param   
            (
                [string] $TFSProjectCollectionUrl = "http://localhost:8080/tfs/DefaultCollection",
                [Parameter(ValueFromPipeline=$true)][string] $Project,
                [string] $WorkItemTypeName,
                [String] $FieldName,
                [string] $CurrentValue,
                [string] $NewValue
            )

        process
            {

                $teamProjectCollection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($TFSProjectCollectionUrl)
                $teamProjectCollection.EnsureAuthenticated()
         
                [Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore]$ws = $teamProjectCollection.GetService([type]"Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore")

                [Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemCollection] $queryResults = $ws.Query("Select [System.Title] From WorkItems Where [System.TeamProject] = """ + $Project + """ and [System.WorkitemType] = """ + $WorkItemTypeName + """")

                $unchangedRecords = 0
                $changedRecords = 0
                $errorRecords = 0 

                Write-Output ("Changing fields in project " + $Project + "...")
                
                foreach ($wi in $queryResults)
                {
                    $workitem = [Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItem]$wi
                    $workitem.Open()
                    if ($workitem.Fields[$FieldName].Value -eq $CurrentValue)
                          { 
                            try 
                                {
                                    $workitem.Fields[$FieldName].Value= $NewValue
                                    $workitem.Save() 
                                    $changedRecords++
                                }
                            catch
                                {
                                    write-output ("Error saving workitem ID " + $workitem.Id + " (""" + $workitem.Title + """)")
                                    $errorRecords++
                                }
                          }
                    else
                         {
                            $unchangedRecords++
                         }
                    $workItem.Close() 
                }
                   
                Write-Output ("Project " + $Project + ": Changed " + $changedRecords + " records, skipped " + $unchangedRecords + " records, " + $errorRecords + " error(s).")
               
            }
        }