<#
.SYNOPSIS
    Dialog functions for the Scanner panel.
.DESCRIPTION
    Contains dialog creation and handling code extracted from Scanner.ps1.
    These functions handle popup dialogs for machine selection, etc.
#>

function global:Show-MachineSelectionDialog {
    <#
    .SYNOPSIS
        Shows a dialog to select machines for scanning.
    .DESCRIPTION
        Creates a dialog with checkboxes for each discovered machine,
        allowing the user to select which ones to include in the scan.
    .RETURNS
        Array of selected machine objects, or $null if cancelled.
    #>
    param(
        $ParentWindow,
        [array]$Machines
    )
    
    $dialogXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Select Machines for Scanning"
        Width="500" Height="450"
        WindowStartupLocation="CenterOwner"
        Background="#1E1E1E"
        ResizeMode="CanResize">
    <Window.Resources>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#E0E0E0"/>
            <Setter Property="Margin" Value="5,3"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#3C3C3C"/>
            <Setter Property="Foreground" Value="#E0E0E0"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="BorderThickness" Value="0"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#2D2D2D"/>
            <Setter Property="Foreground" Value="#E0E0E0"/>
            <Setter Property="BorderBrush" Value="#3C3C3C"/>
            <Setter Property="Padding" Value="5"/>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <TextBlock Grid.Row="0" Text="Select machines to include in the scan:" 
                   Foreground="#E0E0E0" FontSize="14" Margin="15,15,15,5"/>
        
        <Grid Grid.Row="1" Margin="15,5">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBox x:Name="TxtFilter" Grid.Column="0" Margin="0,0,10,0"/>
            <Button x:Name="BtnSelectAll" Grid.Column="1" Content="Select All" Width="80"/>
            <Button x:Name="BtnSelectNone" Grid.Column="2" Content="Clear All" Width="80"/>
        </Grid>
        
        <Border Grid.Row="2" Margin="15,5" Background="#2D2D2D" BorderBrush="#3C3C3C" BorderThickness="1">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel x:Name="MachineStack"/>
            </ScrollViewer>
        </Border>
        
        <TextBlock Grid.Row="3" x:Name="TxtSelectionCount" 
                   Foreground="#888888" Margin="15,5" FontSize="12"/>
        
        <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right" Margin="15">
            <Button x:Name="BtnOK" Content="OK" Width="80" IsDefault="True"/>
            <Button x:Name="BtnCancel" Content="Cancel" Width="80" IsCancel="True"/>
        </StackPanel>
    </Grid>
</Window>
"@
    
    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($dialogXaml))
    $dialog = [System.Windows.Markup.XamlReader]::Load($reader)
    $dialog.Owner = $ParentWindow
    
    # Add Escape key handler
    $dialog.Add_KeyDown({
        param($sender, $e)
        if ($e.Key -eq 'Escape') {
            $sender.Close()
        }
    })
    
    $machineStack = $dialog.FindName('MachineStack')
    $txtFilter = $dialog.FindName('TxtFilter')
    $txtCount = $dialog.FindName('TxtSelectionCount')
    $btnSelectAll = $dialog.FindName('BtnSelectAll')
    $btnSelectNone = $dialog.FindName('BtnSelectNone')
    $btnOK = $dialog.FindName('BtnOK')
    $btnCancel = $dialog.FindName('BtnCancel')
    
    foreach ($machine in $Machines) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $ouDisplay = if ($machine.OU) { $machine.OU } else { 'Unknown OU' }
        $cb.Content = "$($machine.Hostname) - $ouDisplay"
        $cb.IsChecked = $true
        $cb.Tag = $machine
        $cb.Foreground = [System.Windows.Media.Brushes]::White
        $cb.Margin = [System.Windows.Thickness]::new(5, 3, 5, 3)
        $machineStack.Children.Add($cb)
    }
    
    $updateCount = {
        $selected = 0
        foreach ($cb in $machineStack.Children) { if ($cb.IsChecked) { $selected++ } }
        $txtCount.Text = "$selected of $($Machines.Count) machines selected"
    }.GetNewClosure()
    & $updateCount
    
    $txtFilter.Add_TextChanged({
        $filter = $txtFilter.Text.ToLower()
        foreach ($cb in $machineStack.Children) {
            $cb.Visibility = if ($cb.Content.ToString().ToLower().Contains($filter)) { 'Visible' } else { 'Collapsed' }
        }
    }.GetNewClosure())
    
    $btnSelectAll.Add_Click({ 
        foreach ($cb in $machineStack.Children) { $cb.IsChecked = $true }
        & $updateCount
    }.GetNewClosure())
    
    $btnSelectNone.Add_Click({ 
        foreach ($cb in $machineStack.Children) { $cb.IsChecked = $false }
        & $updateCount
    }.GetNewClosure())
    
    # Store selected machines on dialog.Tag to avoid .GetNewClosure() scope issues
    # (.GetNewClosure() creates a new module scope, so $script: vars inside it
    #  are different from $script: vars in the outer function)
    $dialog.Tag = $null
    
    $btnOK.Add_Click({
        $selectedMachines = @()
        foreach ($cb in $machineStack.Children) {
            if ($cb.IsChecked) { $selectedMachines += $cb.Tag }
        }
        $dialog.Tag = $selectedMachines
        $dialog.DialogResult = $true
        $dialog.Close()
    }.GetNewClosure())
    
    $btnCancel.Add_Click({
        $dialog.DialogResult = $false
        $dialog.Close()
    }.GetNewClosure())
    
    $result = $dialog.ShowDialog()
    
    if ($result -eq $true) { return $dialog.Tag }
    return $null
}
