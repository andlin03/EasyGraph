function Disconnect-EasyGraph {
<#
.SYNOPSIS
    Removes any existing connection to Microsoft Graph.

.DESCRIPTION
    Removes any existing connection to Microsoft Graph.

.EXAMPLE
    Disconnect-EasyGraph

.INPUTS
    None

.OUTPUTS
    None

.LINK
    Connect-EasyGraph
#>
param()
   $GraphConnection.Clear()
}