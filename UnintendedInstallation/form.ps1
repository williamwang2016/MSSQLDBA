[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(600,530)  
$Form.StartPosition = "CenterScreen"
if ($host.version.major -lt 3)
{
	$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}
############################################## Start functions

function StartInstallation
{
	$msg = "Enter the credential that will be doing the installation"
	$credential = $Host.UI.PromptForCredential("",$msg,"$env:userdomain\$env:username","")
	$username = $credential.UserName
	$password = $credential.GetNetworkCredential().Password

	if ($txtVirtualName1.Text)
	{
		Powershell.exe -noprofile -file $PSScriptRoot\install.ps1 `
		$cmbAction.SelectedItem.ToString() `
		$txtInstaller.Text `
		$txtVirtualName1.Text `
		$txtIP1.Text `
		$txtPrimaryNode1.Text `
		$txtSecondaryNode1.Text `
		$username `
		$password `
		$PSScriptRoot `
		| Out-String -Stream | ForEach-Object `
		{
		    $outputBox.Lines = $outputBox.Lines + $_
		    $outputBox.Select($outputBox.Text.Length, 0)
		    $outputBox.ScrollToCaret()
		    $Form.Update()
		}
	}
	
	if ($txtVirtualName2.Text)
	{
		Powershell.exe -noprofile -file $PSScriptRoot\install.ps1 `
		$cmbAction.SelectedItem.ToString() `
		$txtInstaller.Text `
		$txtVirtualName2.Text `
		$txtIP2.Text `
		$txtPrimaryNode2.Text `
		$txtSecondaryNode2.Text `
		$username `
		$password `
		$PSScriptRoot `
		| Out-String -Stream | ForEach-Object `
		{
		    $outputBox.Lines = $outputBox.Lines + $_
		    $outputBox.Select($outputBox.Text.Length, 0)
		    $outputBox.ScrollToCaret()
		    $Form.Update()
		}
	}
	
	if ($txtVirtualName3.Text)
	{
		Powershell.exe -noprofile -file $PSScriptRoot\install.ps1 `
		$cmbAction.SelectedItem.ToString() `
		$txtInstaller.Text `
		$txtVirtualName3.Text `
		$txtIP3.Text `
		$txtPrimaryNode3.Text `
		$txtSecondaryNode3.Text `
		$username `
		$password `
		$PSScriptRoot `
		| Out-String -Stream | ForEach-Object `
		{
		    $outputBox.Lines = $outputBox.Lines + $_
		    $outputBox.Select($outputBox.Text.Length, 0)
		    $outputBox.ScrollToCaret()
		    $Form.Update()
		}
	}
} #end pingInfo

############################################## end functions

############################################## Start text fields
$lblAction = New-Object System.Windows.Forms.Label
$lblAction.Location = New-Object System.Drawing.Size(20,10) 
$lblAction.Size = New-Object System.Drawing.Size(80,20)
$lblAction.Text = "Action"
$lblAction.TextAlign = "MiddleRight"
$Form.Controls.Add($lblAction)

$cmbAction = New-Object System.Windows.Forms.ComboBox
$cmbAction.Location = New-Object System.Drawing.Size(100,10)
$cmbAction.Size = New-Object System.Drawing.Size(150,40)
$cmbAction.Items.Add("InstallFailoverCluster")
$cmbAction.Items.Add("AddNode")
$cmbAction.SelectedIndex = 0
$Form.Controls.Add($cmbAction)

$lblInstaller = New-Object System.Windows.Forms.Label
$lblInstaller.Location = New-Object System.Drawing.Size(240,10) 
$lblInstaller.Size = New-Object System.Drawing.Size(80,20)
$lblInstaller.Text = "Installer"
$lblInstaller.TextAlign = "MiddleRight"
$Form.Controls.Add($lblInstaller) 

$txtInstaller = New-Object System.Windows.Forms.TextBox
$txtInstaller.Location = New-Object System.Drawing.Size(320,10)
$txtInstaller.Size = New-Object System.Drawing.Size(240,10)
$txtInstaller.Text = "\\xxx\install\SQL_Svr_Ent_Core_2014w_SP2_64Bit_English_MLF_X21-04314"
$Form.Controls.Add($txtInstaller)

############################################## SQL1 start
$lblVirtualName1 = New-Object System.Windows.Forms.Label
$lblVirtualName1.Location = New-Object System.Drawing.Size(20,40) 
$lblVirtualName1.Size = New-Object System.Drawing.Size(80,20)
$lblVirtualName1.Text = "Virtual Name"
$lblVirtualName1.TextAlign = "MiddleRight"
$Form.Controls.Add($lblVirtualName1)

$txtVirtualName1 = New-Object System.Windows.Forms.TextBox
$txtVirtualName1.Location = New-Object System.Drawing.Size(100,40)
$txtVirtualName1.Size = New-Object System.Drawing.Size(120,40)
$txtVirtualName1.Text = "yyyyy"
$Form.Controls.Add($txtVirtualName1)

$lblIP1 = New-Object System.Windows.Forms.Label
$lblIP1.Location = New-Object System.Drawing.Size(20,70) 
$lblIP1.Size = New-Object System.Drawing.Size(80,20)
$lblIP1.Text = "IP"
$lblIP1.TextAlign = "MiddleRight"
$Form.Controls.Add($lblIP1)

$txtIP1 = New-Object System.Windows.Forms.TextBox
$txtIP1.Location = New-Object System.Drawing.Size(100,70)
$txtIP1.Size = New-Object System.Drawing.Size(120,40)
$txtIP1.Text = "10.xxx.114.89"
$Form.Controls.Add($txtIP1)

$lblPrimaryNode1 = New-Object System.Windows.Forms.Label
$lblPrimaryNode1.Location = New-Object System.Drawing.Size(240,40) 
$lblPrimaryNode1.Size = New-Object System.Drawing.Size(80,20)
$lblPrimaryNode1.Text = "Primary"
$lblPrimaryNode1.TextAlign = "MiddleRight"
$Form.Controls.Add($lblPrimaryNode1)

$txtPrimaryNode1 = New-Object System.Windows.Forms.TextBox
$txtPrimaryNode1.Location = New-Object System.Drawing.Size(320,40)
$txtPrimaryNode1.Size = New-Object System.Drawing.Size(120,40)
$txtPrimaryNode1.Text = "xxx-x-00x"
$Form.Controls.Add($txtPrimaryNode1)

$lblSecondaryNode1 = New-Object System.Windows.Forms.Label
$lblSecondaryNode1.Location = New-Object System.Drawing.Size(240,70) 
$lblSecondaryNode1.Size = New-Object System.Drawing.Size(80,20)
$lblSecondaryNode1.Text = "Secondary"
$lblSecondaryNode1.TextAlign = "MiddleRight"
$Form.Controls.Add($lblSecondaryNode1)

$txtSecondaryNode1 = New-Object System.Windows.Forms.TextBox
$txtSecondaryNode1.Location = New-Object System.Drawing.Size(320,70)
$txtSecondaryNode1.Size = New-Object System.Drawing.Size(120,40)
$txtSecondaryNode1.Text = "xxx-x-00x"
$Form.Controls.Add($txtSecondaryNode1)

############################################## SQL1 end


############################################## SQL2 start
$lblVirtualName2 = New-Object System.Windows.Forms.Label
$lblVirtualName2.Location = New-Object System.Drawing.Size(20,100) 
$lblVirtualName2.Size = New-Object System.Drawing.Size(80,20)
$lblVirtualName2.Text = "Virtual Name"
$lblVirtualName2.TextAlign = "MiddleRight"
$Form.Controls.Add($lblVirtualName2)

$txtVirtualName2 = New-Object System.Windows.Forms.TextBox
$txtVirtualName2.Location = New-Object System.Drawing.Size(100,100)
$txtVirtualName2.Size = New-Object System.Drawing.Size(120,40)
$txtVirtualName2.Text = ""
$Form.Controls.Add($txtVirtualName2)

$lblIP2 = New-Object System.Windows.Forms.Label
$lblIP2.Location = New-Object System.Drawing.Size(20,130) 
$lblIP2.Size = New-Object System.Drawing.Size(80,20)
$lblIP2.Text = "IP"
$lblIP2.TextAlign = "MiddleRight"
$Form.Controls.Add($lblIP2)

$txtIP2 = New-Object System.Windows.Forms.TextBox
$txtIP2.Location = New-Object System.Drawing.Size(100,130)
$txtIP2.Size = New-Object System.Drawing.Size(120,40)
$txtIP2.Text = ""
$Form.Controls.Add($txtIP2)

$lblPrimaryNode2 = New-Object System.Windows.Forms.Label
$lblPrimaryNode2.Location = New-Object System.Drawing.Size(240,100) 
$lblPrimaryNode2.Size = New-Object System.Drawing.Size(80,20)
$lblPrimaryNode2.Text = "Primary"
$lblPrimaryNode2.TextAlign = "MiddleRight"
$Form.Controls.Add($lblPrimaryNode2)

$txtPrimaryNode2 = New-Object System.Windows.Forms.TextBox
$txtPrimaryNode2.Location = New-Object System.Drawing.Size(320,100)
$txtPrimaryNode2.Size = New-Object System.Drawing.Size(120,40)
$txtPrimaryNode2.Text = ""
$Form.Controls.Add($txtPrimaryNode2)

$lblSecondaryNode2 = New-Object System.Windows.Forms.Label
$lblSecondaryNode2.Location = New-Object System.Drawing.Size(240,130) 
$lblSecondaryNode2.Size = New-Object System.Drawing.Size(80,20)
$lblSecondaryNode2.Text = "Secondary"
$lblSecondaryNode2.TextAlign = "MiddleRight"
$Form.Controls.Add($lblSecondaryNode2)

$txtSecondaryNode2 = New-Object System.Windows.Forms.TextBox
$txtSecondaryNode2.Location = New-Object System.Drawing.Size(320,130)
$txtSecondaryNode2.Size = New-Object System.Drawing.Size(120,40)
$txtSecondaryNode2.Text = ""
$Form.Controls.Add($txtSecondaryNode2)

############################################## SQL2 end

############################################## SQL3 start
$lblVirtualName3 = New-Object System.Windows.Forms.Label
$lblVirtualName3.Location = New-Object System.Drawing.Size(20,160) 
$lblVirtualName3.Size = New-Object System.Drawing.Size(80,20)
$lblVirtualName3.Text = "Virtual Name"
$lblVirtualName3.TextAlign = "MiddleRight"
$Form.Controls.Add($lblVirtualName3)

$txtVirtualName3 = New-Object System.Windows.Forms.TextBox
$txtVirtualName3.Location = New-Object System.Drawing.Size(100,160)
$txtVirtualName3.Size = New-Object System.Drawing.Size(120,40)
$txtVirtualName3.Text = ""
$Form.Controls.Add($txtVirtualName3)

$lblIP3 = New-Object System.Windows.Forms.Label
$lblIP3.Location = New-Object System.Drawing.Size(20,190) 
$lblIP3.Size = New-Object System.Drawing.Size(80,20)
$lblIP3.Text = "IP"
$lblIP3.TextAlign = "MiddleRight"
$Form.Controls.Add($lblIP3)

$txtIP3 = New-Object System.Windows.Forms.TextBox
$txtIP3.Location = New-Object System.Drawing.Size(100,190)
$txtIP3.Size = New-Object System.Drawing.Size(120,40)
$txtIP3.Text = ""
$Form.Controls.Add($txtIP3)

$lblPrimaryNode3 = New-Object System.Windows.Forms.Label
$lblPrimaryNode3.Location = New-Object System.Drawing.Size(240,160) 
$lblPrimaryNode3.Size = New-Object System.Drawing.Size(80,20)
$lblPrimaryNode3.Text = "Primary"
$lblPrimaryNode3.TextAlign = "MiddleRight"
$Form.Controls.Add($lblPrimaryNode3)

$txtPrimaryNode3 = New-Object System.Windows.Forms.TextBox
$txtPrimaryNode3.Location = New-Object System.Drawing.Size(320,160)
$txtPrimaryNode3.Size = New-Object System.Drawing.Size(120,40)
$txtPrimaryNode3.Text = ""
$Form.Controls.Add($txtPrimaryNode3)

$lblSecondaryNode3 = New-Object System.Windows.Forms.Label
$lblSecondaryNode3.Location = New-Object System.Drawing.Size(240,190) 
$lblSecondaryNode3.Size = New-Object System.Drawing.Size(80,20)
$lblSecondaryNode3.Text = "Secondary"
$lblSecondaryNode3.TextAlign = "MiddleRight"
$Form.Controls.Add($lblSecondaryNode3)

$txtSecondaryNode3 = New-Object System.Windows.Forms.TextBox
$txtSecondaryNode3.Location = New-Object System.Drawing.Size(320,190)
$txtSecondaryNode3.Size = New-Object System.Drawing.Size(120,40)
$txtSecondaryNode3.Text = ""
$Form.Controls.Add($txtSecondaryNode3)

############################################## SQL3 end


$outputBox = New-Object System.Windows.Forms.TextBox 
$outputBox.Location = New-Object System.Drawing.Size(20,220) 
$outputBox.Size = New-Object System.Drawing.Size(540,250) 
$outputBox.MultiLine = $True 
$outputBox.ScrollBars = "Vertical"

$Form.Controls.Add($outputBox) 

############################################## end text fields

############################################## Start buttons

$Button = New-Object System.Windows.Forms.Button 
$Button.Location = New-Object System.Drawing.Size(450,40) 
$Button.Size = New-Object System.Drawing.Size(110,80) 
$Button.Text = "Start Installation" 
$Button.Add_Click({StartInstallation})
$Button.Cursor = [System.Windows.Forms.Cursors]::Hand

$Form.Controls.Add($Button) 

############################################## end buttons

$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog()
