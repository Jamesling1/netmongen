Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$conv = New-Object System.Windows.Media.BrushConverter

function Make-TB($text, $size, $color, $bold=$false, $marginB=0, $wrap=$false) {
    $tb            = New-Object System.Windows.Controls.TextBlock
    $tb.Text       = $text
    $tb.FontSize   = $size
    $tb.FontFamily = New-Object System.Windows.Media.FontFamily('Consolas')
    $tb.Foreground = $conv.ConvertFrom($color)
    $tb.Margin     = [System.Windows.Thickness]::new(0,0,0,$marginB)
    if ($bold) { $tb.FontWeight   = [System.Windows.FontWeights]::Bold }
    if ($wrap) { $tb.TextWrapping = [System.Windows.TextWrapping]::Wrap }
    return $tb
}

function Make-TextBox($default='', $width=340) {
    $tb                 = New-Object System.Windows.Controls.TextBox
    $tb.Text            = $default
    $tb.FontFamily      = New-Object System.Windows.Media.FontFamily('Consolas')
    $tb.FontSize        = 11
    $tb.Foreground      = $conv.ConvertFrom('#C8D8E8')
    $tb.Background      = $conv.ConvertFrom('#0F1318')
    $tb.BorderBrush     = $conv.ConvertFrom('#263545')
    $tb.BorderThickness = [System.Windows.Thickness]::new(1)
    $tb.Padding         = [System.Windows.Thickness]::new(8,5,8,5)
    $tb.Width           = $width
    $tb.CaretBrush      = $conv.ConvertFrom('#C8D8E8')
    $tb.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    return $tb
}

function Make-Btn($label, $accent=$false) {
    $b                 = New-Object System.Windows.Controls.Button
    $b.Content         = $label
    $b.FontFamily      = New-Object System.Windows.Media.FontFamily('Consolas')
    $b.FontSize        = 10
    $b.FontWeight      = [System.Windows.FontWeights]::Bold
    $b.Cursor          = [System.Windows.Input.Cursors]::Hand
    $b.Padding         = [System.Windows.Thickness]::new(14,7,14,7)
    $b.BorderThickness = [System.Windows.Thickness]::new(1)
    if ($accent) {
        $b.Foreground  = $conv.ConvertFrom('#1A8FFF')
        $b.Background  = [System.Windows.Media.Brushes]::Transparent
        $b.BorderBrush = $conv.ConvertFrom('#0D4A80')
    } else {
        $b.Foreground  = $conv.ConvertFrom('#4A6070')
        $b.Background  = [System.Windows.Media.Brushes]::Transparent
        $b.BorderBrush = $conv.ConvertFrom('#263545')
    }
    return $b
}

function Make-Sep($marginT=12, $marginB=12) {
    $r                     = New-Object System.Windows.Shapes.Rectangle
    $r.Height              = 1
    $r.Fill                = $conv.ConvertFrom('#1E2A38')
    $r.Margin              = [System.Windows.Thickness]::new(0,$marginT,0,$marginB)
    $r.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    return $r
}

function Parse-IPInput($text) {
    $ips   = [System.Collections.Generic.List[string]]::new()
    $lines = $text -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    foreach ($line in $lines) {
        $tokens = $line -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        foreach ($token in $tokens) {
            if ($token -match '^(\d+\.\d+\.\d+\.)(\d+)-(\d+)$') {
                $base  = $Matches[1]
                $start = [int]$Matches[2]
                $end   = [int]$Matches[3]
                if ($start -le $end) {
                    for ($n = $start; $n -le $end; $n++) { $ips.Add("$base$n") }
                }
            } elseif ($token -match '^\d+\.\d+\.\d+\.\d+$') {
                $ips.Add($token)
            }
        }
    }
    return ($ips | Select-Object -Unique)
}

function Build-Monitor-Script($ipArray) {
    $ipLines = $ipArray | ForEach-Object { "    '$_'" }
    $ipBlock = $ipLines -join ",`r`n"
    $nl      = "`r`n"

    # Build Add-Type block using string concatenation to avoid nested here-string
    $addTypeLine  = 'Add-Type -TypeDefinition @' + "'" + $nl
    $addTypeLine += 'using System.ComponentModel;' + $nl
    $addTypeLine += 'public class HostRow : INotifyPropertyChanged {' + $nl
    $addTypeLine += '    public event PropertyChangedEventHandler PropertyChanged;' + $nl
    $addTypeLine += '    private void N(string p) {' + $nl
    $addTypeLine += '        PropertyChangedEventHandler h = PropertyChanged;' + $nl
    $addTypeLine += '        if (h != null) { h(this, new PropertyChangedEventArgs(p)); }' + $nl
    $addTypeLine += '    }' + $nl
    $addTypeLine += '    private string _hostname;      public string Hostname       { get { return _hostname; }      set { _hostname=value;      N("Hostname"); } }' + $nl
    $addTypeLine += '    private string _ip;            public string IPAddress      { get { return _ip; }            set { _ip=value;            N("IPAddress"); } }' + $nl
    $addTypeLine += '    private string _uptime;        public string Uptime         { get { return _uptime; }        set { _uptime=value;        N("Uptime"); } }' + $nl
    $addTypeLine += '    private string _time;          public string LocalTime      { get { return _time; }          set { _time=value;          N("LocalTime"); } }' + $nl
    $addTypeLine += '    private string _cpu;           public string CpuText        { get { return _cpu; }           set { _cpu=value;           N("CpuText"); } }' + $nl
    $addTypeLine += '    private string _ram;           public string RamText        { get { return _ram; }           set { _ram=value;           N("RamText"); } }' + $nl
    $addTypeLine += '    private string _rowBg;         public string RowBg          { get { return _rowBg; }         set { _rowBg=value;         N("RowBg"); } }' + $nl
    $addTypeLine += '    private string _hnColor;       public string HostnameColor  { get { return _hnColor; }       set { _hnColor=value;       N("HostnameColor"); } }' + $nl
    $addTypeLine += '    private string _hnWeight;      public string HostnameWeight { get { return _hnWeight; }      set { _hnWeight=value;      N("HostnameWeight"); } }' + $nl
    $addTypeLine += '    private string _upColor;       public string UptimeColor    { get { return _upColor; }       set { _upColor=value;       N("UptimeColor"); } }' + $nl
    $addTypeLine += '    private string _upWeight;      public string UptimeWeight   { get { return _upWeight; }      set { _upWeight=value;      N("UptimeWeight"); } }' + $nl
    $addTypeLine += '    private string _cpuColor;      public string CpuColor       { get { return _cpuColor; }      set { _cpuColor=value;      N("CpuColor"); } }' + $nl
    $addTypeLine += '    private string _ramColor;      public string RamColor       { get { return _ramColor; }      set { _ramColor=value;      N("RamColor"); } }' + $nl
    $addTypeLine += '}' + $nl
    $addTypeLine += "'@ -Language CSharp"

    # XAML block â€“ NO backtick escapes, all $() expansions are runtime values
    $xamlBlock  = '[xml]$xaml = @"' + $nl
    $xamlBlock += '<Window' + $nl
    $xamlBlock += '    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' + $nl
    $xamlBlock += '    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"' + $nl
    $xamlBlock += '    Title="Network Monitor" Background="#0A0C0F"' + $nl
    $xamlBlock += '    WindowStyle="None" AllowsTransparency="False"' + $nl
    $xamlBlock += '    ResizeMode="NoResize" FontFamily="Consolas">' + $nl
    $xamlBlock += '  <Window.Resources>' + $nl
    $xamlBlock += '    <Style x:Key="Lbl" TargetType="TextBlock">' + $nl
    $xamlBlock += '      <Setter Property="Foreground" Value="#4A6070"/>' + $nl
    $xamlBlock += '      <Setter Property="FontSize"   Value="9"/>' + $nl
    $xamlBlock += '      <Setter Property="FontFamily" Value="Consolas"/>' + $nl
    $xamlBlock += '    </Style>' + $nl
    $xamlBlock += '    <Style x:Key="Stat" TargetType="TextBlock">' + $nl
    $xamlBlock += '      <Setter Property="FontSize"   Value="12"/>' + $nl
    $xamlBlock += '      <Setter Property="FontWeight" Value="Bold"/>' + $nl
    $xamlBlock += '      <Setter Property="FontFamily" Value="Consolas"/>' + $nl
    $xamlBlock += '      <Setter Property="Foreground" Value="#C8D8E8"/>' + $nl
    $xamlBlock += '    </Style>' + $nl
    $xamlBlock += '    <Style x:Key="Btn" TargetType="Button">' + $nl
    $xamlBlock += '      <Setter Property="Background"      Value="Transparent"/>' + $nl
    $xamlBlock += '      <Setter Property="BorderBrush"     Value="#263545"/>' + $nl
    $xamlBlock += '      <Setter Property="BorderThickness" Value="1"/>' + $nl
    $xamlBlock += '      <Setter Property="Foreground"      Value="#4A6070"/>' + $nl
    $xamlBlock += '      <Setter Property="FontFamily"      Value="Consolas"/>' + $nl
    $xamlBlock += '      <Setter Property="FontSize"        Value="9"/>' + $nl
    $xamlBlock += '      <Setter Property="Padding"         Value="10,5"/>' + $nl
    $xamlBlock += '      <Setter Property="Cursor"          Value="Hand"/>' + $nl
    $xamlBlock += '      <Setter Property="Template">' + $nl
    $xamlBlock += '        <Setter.Value>' + $nl
    $xamlBlock += '          <ControlTemplate TargetType="Button">' + $nl
    $xamlBlock += '            <Border Background="{TemplateBinding Background}"' + $nl
    $xamlBlock += '                    BorderBrush="{TemplateBinding BorderBrush}"' + $nl
    $xamlBlock += '                    BorderThickness="{TemplateBinding BorderThickness}"' + $nl
    $xamlBlock += '                    CornerRadius="2" Padding="{TemplateBinding Padding}">' + $nl
    $xamlBlock += '              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '            </Border>' + $nl
    $xamlBlock += '            <ControlTemplate.Triggers>' + $nl
    $xamlBlock += '              <Trigger Property="IsMouseOver" Value="True">' + $nl
    $xamlBlock += '                <Setter Property="Background"  Value="#141A22"/>' + $nl
    $xamlBlock += '                <Setter Property="BorderBrush" Value="#1A8FFF"/>' + $nl
    $xamlBlock += '                <Setter Property="Foreground"  Value="#C8D8E8"/>' + $nl
    $xamlBlock += '              </Trigger>' + $nl
    $xamlBlock += '              <Trigger Property="IsPressed" Value="True">' + $nl
    $xamlBlock += '                <Setter Property="Background" Value="#0D2A4A"/>' + $nl
    $xamlBlock += '              </Trigger>' + $nl
    $xamlBlock += '              <Trigger Property="IsEnabled" Value="False">' + $nl
    $xamlBlock += '                <Setter Property="Opacity" Value="0.35"/>' + $nl
    $xamlBlock += '              </Trigger>' + $nl
    $xamlBlock += '            </ControlTemplate.Triggers>' + $nl
    $xamlBlock += '          </ControlTemplate>' + $nl
    $xamlBlock += '        </Setter.Value>' + $nl
    $xamlBlock += '      </Setter>' + $nl
    $xamlBlock += '    </Style>' + $nl
    $xamlBlock += '    <Style x:Key="BtnScan" TargetType="Button" BasedOn="{StaticResource Btn}">' + $nl
    $xamlBlock += '      <Setter Property="BorderBrush" Value="#0D4A80"/>' + $nl
    $xamlBlock += '      <Setter Property="Foreground"  Value="#1A8FFF"/>' + $nl
    $xamlBlock += '    </Style>' + $nl
    $xamlBlock += '    <Style x:Key="BtnClose" TargetType="Button" BasedOn="{StaticResource Btn}">' + $nl
    $xamlBlock += '      <Setter Property="BorderBrush" Value="#7F1D1D"/>' + $nl
    $xamlBlock += '      <Setter Property="Foreground"  Value="#EF4444"/>' + $nl
    $xamlBlock += '    </Style>' + $nl
    $xamlBlock += '  </Window.Resources>' + $nl
    $xamlBlock += '  <Grid Margin="12,10,12,10">' + $nl
    $xamlBlock += '    <Grid.RowDefinitions>' + $nl
    $xamlBlock += '      <RowDefinition Height="Auto"/>' + $nl
    $xamlBlock += '      <RowDefinition Height="3"/>' + $nl
    $xamlBlock += '      <RowDefinition Height="Auto"/>' + $nl
    $xamlBlock += '      <RowDefinition Height="*"/>' + $nl
    $xamlBlock += '      <RowDefinition Height="Auto"/>' + $nl
    $xamlBlock += '    </Grid.RowDefinitions>' + $nl
    $xamlBlock += '    <Grid Grid.Row="0">' + $nl
    $xamlBlock += '      <Grid.ColumnDefinitions>' + $nl
    $xamlBlock += '        <ColumnDefinition Width="Auto"/>' + $nl
    $xamlBlock += '        <ColumnDefinition Width="*"/>' + $nl
    $xamlBlock += '        <ColumnDefinition Width="Auto"/>' + $nl
    $xamlBlock += '      </Grid.ColumnDefinitions>' + $nl
    $xamlBlock += '      <TextBlock Grid.Column="0" Text="NET MONITOR" FontSize="15" FontWeight="Bold"' + $nl
    $xamlBlock += '                 FontFamily="Consolas" Foreground="#1A8FFF" VerticalAlignment="Center" Margin="0,0,20,0"/>' + $nl
    $xamlBlock += '      <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">' + $nl
    $xamlBlock += '        <StackPanel Orientation="Horizontal" Margin="0,0,14,0">' + $nl
    $xamlBlock += '          <TextBlock Style="{StaticResource Lbl}" Text="TOTAL "  VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '          <TextBlock x:Name="StatTotal"   Style="{StaticResource Stat}" Text="--"/>' + $nl
    $xamlBlock += '        </StackPanel>' + $nl
    $xamlBlock += '        <StackPanel Orientation="Horizontal" Margin="0,0,14,0">' + $nl
    $xamlBlock += '          <TextBlock Style="{StaticResource Lbl}" Text="ONLINE " VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '          <TextBlock x:Name="StatOnline"  Style="{StaticResource Stat}" Foreground="#22C55E" Text="--"/>' + $nl
    $xamlBlock += '        </StackPanel>' + $nl
    $xamlBlock += '        <StackPanel Orientation="Horizontal" Margin="0,0,14,0">' + $nl
    $xamlBlock += '          <TextBlock Style="{StaticResource Lbl}" Text="OFFLINE " VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '          <TextBlock x:Name="StatOffline" Style="{StaticResource Stat}" Foreground="#EF4444" Text="--"/>' + $nl
    $xamlBlock += '        </StackPanel>' + $nl
    $xamlBlock += '        <StackPanel Orientation="Horizontal" Margin="0,0,14,0">' + $nl
    $xamlBlock += '          <TextBlock Style="{StaticResource Lbl}" Text="WARN " VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '          <TextBlock x:Name="StatWarn"    Style="{StaticResource Stat}" Foreground="#F59E0B" Text="--"/>' + $nl
    $xamlBlock += '        </StackPanel>' + $nl
    $xamlBlock += '        <StackPanel Orientation="Horizontal">' + $nl
    $xamlBlock += '          <TextBlock Style="{StaticResource Lbl}" Text="CRIT " VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '          <TextBlock x:Name="StatCrit"    Style="{StaticResource Stat}" Foreground="#EF4444" Text="--"/>' + $nl
    $xamlBlock += '        </StackPanel>' + $nl
    $xamlBlock += '      </StackPanel>' + $nl
    $xamlBlock += '      <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">' + $nl
    $xamlBlock += '        <Button x:Name="BtnScan"  Style="{StaticResource BtnScan}"  Content="SCAN NOW"     Margin="0,0,6,0"/>' + $nl
    $xamlBlock += '        <Button x:Name="BtnSave"  Style="{StaticResource Btn}"      Content="SAVE RESULTS" Margin="0,0,14,0"/>' + $nl
    $xamlBlock += '        <StackPanel VerticalAlignment="Center" Margin="0,0,14,0">' + $nl
    $xamlBlock += '          <StackPanel Orientation="Horizontal">' + $nl
    $xamlBlock += '            <TextBlock Style="{StaticResource Lbl}" Text="LAST  "/>' + $nl
    $xamlBlock += '            <TextBlock x:Name="LastScan" FontSize="9" FontFamily="Consolas" Foreground="#4A6070" Text="--"/>' + $nl
    $xamlBlock += '          </StackPanel>' + $nl
    $xamlBlock += '          <StackPanel Orientation="Horizontal">' + $nl
    $xamlBlock += '            <TextBlock Style="{StaticResource Lbl}" Text="NEXT  "/>' + $nl
    $xamlBlock += '            <TextBlock x:Name="NextScan" FontSize="9" FontFamily="Consolas" Foreground="#4A6070" Text="--"/>' + $nl
    $xamlBlock += '          </StackPanel>' + $nl
    $xamlBlock += '        </StackPanel>' + $nl
    $xamlBlock += '        <TextBlock x:Name="ClockLabel" FontSize="13" FontWeight="Bold" FontFamily="Consolas"' + $nl
    $xamlBlock += '                   Foreground="#4A6070" VerticalAlignment="Center" Text="--:--:--" Margin="0,0,14,0"/>' + $nl
    $xamlBlock += '        <Button x:Name="BtnClose" Style="{StaticResource BtnClose}" Content="CLOSE"/>' + $nl
    $xamlBlock += '      </StackPanel>' + $nl
    $xamlBlock += '    </Grid>' + $nl
    $xamlBlock += '    <Grid Grid.Row="1" Margin="0,6,0,6">' + $nl
    $xamlBlock += '      <Rectangle Fill="#1E2A38" RadiusX="1" RadiusY="1"/>' + $nl
    $xamlBlock += '      <Rectangle x:Name="CountdownBar" Fill="#1A8FFF" RadiusX="1" RadiusY="1"' + $nl
    $xamlBlock += '                 HorizontalAlignment="Left" Width="0"/>' + $nl
    $xamlBlock += '    </Grid>' + $nl
    # Proportional columns (star sizing)
    $xamlBlock += '    <Grid Grid.Row="2" Margin="0,0,0,2">' + $nl
    $xamlBlock += '      <Grid.ColumnDefinitions>' + $nl
    $xamlBlock += '        <ColumnDefinition Width="2*"/>' + $nl
    $xamlBlock += '        <ColumnDefinition Width="1.5*"/>' + $nl
    $xamlBlock += '        <ColumnDefinition Width="1.2*"/>' + $nl
    $xamlBlock += '        <ColumnDefinition Width="1.5*"/>' + $nl
    $xamlBlock += '        <ColumnDefinition Width="0.8*"/>' + $nl
    $xamlBlock += '        <ColumnDefinition Width="0.8*"/>' + $nl
    $xamlBlock += '      </Grid.ColumnDefinitions>' + $nl
    $xamlBlock += '      <TextBlock Grid.Column="0" Style="{StaticResource Lbl}" Text="HOSTNAME"   Margin="8,2,0,2"/>' + $nl
    $xamlBlock += '      <TextBlock Grid.Column="1" Style="{StaticResource Lbl}" Text="IP ADDRESS" Margin="4,2,0,2"/>' + $nl
    $xamlBlock += '      <TextBlock Grid.Column="2" Style="{StaticResource Lbl}" Text="UPTIME"     Margin="4,2,0,2"/>' + $nl
    $xamlBlock += '      <TextBlock Grid.Column="3" Style="{StaticResource Lbl}" Text="LOCAL TIME" Margin="4,2,0,2"/>' + $nl
    $xamlBlock += '      <TextBlock Grid.Column="4" Style="{StaticResource Lbl}" Text="CPU%"       Margin="4,2,0,2" TextAlignment="Right"/>' + $nl
    $xamlBlock += '      <TextBlock Grid.Column="5" Style="{StaticResource Lbl}" Text="RAM%"       Margin="4,2,0,2" TextAlignment="Right"/>' + $nl
    $xamlBlock += '      <Rectangle Height="1" Fill="#1E2A38" VerticalAlignment="Bottom"' + $nl
    $xamlBlock += '                 Grid.Column="0" Grid.ColumnSpan="6"/>' + $nl
    $xamlBlock += '    </Grid>' + $nl
    # ItemsControl with runtime variable heights â€“ NO BACKTICKS
    $xamlBlock += '    <ItemsControl x:Name="HostList" Grid.Row="3">' + $nl
    $xamlBlock += '      <ItemsControl.ItemTemplate>' + $nl
    $xamlBlock += '        <DataTemplate>' + $nl
    $xamlBlock += '          <Grid Background="{Binding RowBg}" Height="$($rowDip)">' + $nl
    $xamlBlock += '            <Grid.ColumnDefinitions>' + $nl
    $xamlBlock += '              <ColumnDefinition Width="2*"/>' + $nl
    $xamlBlock += '              <ColumnDefinition Width="1.5*"/>' + $nl
    $xamlBlock += '              <ColumnDefinition Width="1.2*"/>' + $nl
    $xamlBlock += '              <ColumnDefinition Width="1.5*"/>' + $nl
    $xamlBlock += '              <ColumnDefinition Width="0.8*"/>' + $nl
    $xamlBlock += '              <ColumnDefinition Width="0.8*"/>' + $nl
    $xamlBlock += '            </Grid.ColumnDefinitions>' + $nl
    $xamlBlock += '            <TextBlock Grid.Column="0" Text="{Binding Hostname}" Foreground="{Binding HostnameColor}"' + $nl
    $xamlBlock += '                       FontWeight="{Binding HostnameWeight}" FontSize="$($rowFontSize)" FontFamily="Consolas"' + $nl
    $xamlBlock += '                       VerticalAlignment="Center" Margin="8,0,0,0" TextTrimming="CharacterEllipsis"/>' + $nl
    $xamlBlock += '            <TextBlock Grid.Column="1" Text="{Binding IPAddress}" Foreground="#4A6070"' + $nl
    $xamlBlock += '                       FontSize="$($rowFontSize)" FontFamily="Consolas" VerticalAlignment="Center" Margin="4,0,0,0"/>' + $nl
    $xamlBlock += '            <TextBlock Grid.Column="2" Text="{Binding Uptime}" Foreground="{Binding UptimeColor}"' + $nl
    $xamlBlock += '                       FontWeight="{Binding UptimeWeight}" FontSize="$($rowFontSize)" FontFamily="Consolas"' + $nl
    $xamlBlock += '                       VerticalAlignment="Center" Margin="4,0,0,0"/>' + $nl
    $xamlBlock += '            <TextBlock Grid.Column="3" Text="{Binding LocalTime}" Foreground="#4A6070"' + $nl
    $xamlBlock += '                       FontSize="$($rowFontSize)" FontFamily="Consolas" VerticalAlignment="Center" Margin="4,0,0,0"/>' + $nl
    $xamlBlock += '            <TextBlock Grid.Column="4" Text="{Binding CpuText}" Foreground="{Binding CpuColor}"' + $nl
    $xamlBlock += '                       FontSize="$($rowFontSize)" FontFamily="Consolas" FontWeight="Bold"' + $nl
    $xamlBlock += '                       TextAlignment="Right" VerticalAlignment="Center" Margin="4,0,0,0"/>' + $nl
    $xamlBlock += '            <TextBlock Grid.Column="5" Text="{Binding RamText}" Foreground="{Binding RamColor}"' + $nl
    $xamlBlock += '                       FontSize="$($rowFontSize)" FontFamily="Consolas" FontWeight="Bold"' + $nl
    $xamlBlock += '                       TextAlignment="Right" VerticalAlignment="Center" Margin="4,0,4,0"/>' + $nl
    $xamlBlock += '          </Grid>' + $nl
    $xamlBlock += '        </DataTemplate>' + $nl
    $xamlBlock += '      </ItemsControl.ItemTemplate>' + $nl
    $xamlBlock += '    </ItemsControl>' + $nl
    $xamlBlock += '    <Grid Grid.Row="4" Margin="0,5,0,0">' + $nl
    $xamlBlock += '      <Rectangle Height="1" Fill="#1E2A38" VerticalAlignment="Top"/>' + $nl
    $xamlBlock += '      <Grid Margin="0,7,0,0">' + $nl
    $xamlBlock += '        <Grid.ColumnDefinitions>' + $nl
    $xamlBlock += '          <ColumnDefinition Width="*"/>' + $nl
    $xamlBlock += '          <ColumnDefinition Width="Auto"/>' + $nl
    $xamlBlock += '        </Grid.ColumnDefinitions>' + $nl
    $xamlBlock += '        <StackPanel Grid.Column="0" Orientation="Horizontal">' + $nl
    $xamlBlock += '          <Ellipse Width="7" Height="7" Fill="#22C55E" Margin="0,0,4,0" VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '          <TextBlock FontSize="9" FontFamily="Consolas" Foreground="#14532D" Text="OK" Margin="0,0,10,0" VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '          <Ellipse Width="7" Height="7" Fill="#F59E0B" Margin="0,0,4,0" VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '          <TextBlock FontSize="9" FontFamily="Consolas" Foreground="#78350F" Text="CPU/RAM &gt;50%" Margin="0,0,10,0" VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '          <Ellipse Width="7" Height="7" Fill="#EF4444" Margin="0,0,4,0" VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '          <TextBlock FontSize="9" FontFamily="Consolas" Foreground="#7F1D1D" Text="CPU/RAM &gt;75%" Margin="0,0,10,0" VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '          <TextBlock FontSize="9" FontFamily="Consolas" Foreground="#2A3A48"' + $nl
    $xamlBlock += '                     Text=" |  UPTIME &gt;90d=BOLD+BLUE  &gt;180d=LIGHTER BLUE  |  REFRESH $($script:selectedFreqMin) MIN"' + $nl
    $xamlBlock += '                     VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '        </StackPanel>' + $nl
    $xamlBlock += '        <TextBlock Grid.Column="1" FontSize="9" FontFamily="Consolas" Foreground="#0D4A80"' + $nl
    $xamlBlock += '                   Text="CREATED BY JAMES LINDLEY" VerticalAlignment="Center"/>' + $nl
    $xamlBlock += '      </Grid>' + $nl
    $xamlBlock += '    </Grid>' + $nl
    $xamlBlock += '  </Grid>' + $nl
    $xamlBlock += '</Window>' + $nl
    $xamlBlock += '"@'

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('Add-Type -AssemblyName PresentationFramework')
    $lines.Add('Add-Type -AssemblyName PresentationCore')
    $lines.Add('Add-Type -AssemblyName WindowsBase')
    $lines.Add('Add-Type -AssemblyName System.Windows.Forms')
    $lines.Add('Add-Type -AssemblyName System.Drawing')
    $lines.Add('')
    $lines.Add('# IP LIST')
    $lines.Add('$ipAddresses = @(')
    $lines.Add($ipBlock)
    $lines.Add(')')
    $lines.Add('')
    $lines.Add('# DATA MODEL')
    $lines.Add($addTypeLine)
    $lines.Add('')
    $lines.Add('$screens     = [System.Windows.Forms.Screen]::AllScreens')
    $lines.Add('$screenCount = $screens.Count')
    $lines.Add('$script:selectedScreen  = $screens[0]')
    $lines.Add('$script:selectedSide    = ''Left''')
    $lines.Add('$script:selectedSort    = ''IP''')
    $lines.Add('$script:selectedFreqMin = 10')
    $lines.Add('')
    $lines.Add('$conv = New-Object System.Windows.Media.BrushConverter')
    $lines.Add('')
    $lines.Add('function Make-TB($text, $size, $color, $bold=$false, $marginB=0) {')
    $lines.Add('    $tb            = New-Object System.Windows.Controls.TextBlock')
    $lines.Add('    $tb.Text       = $text')
    $lines.Add('    $tb.FontSize   = $size')
    $lines.Add('    $tb.FontFamily = New-Object System.Windows.Media.FontFamily(''Consolas'')')
    $lines.Add('    $tb.Foreground = $conv.ConvertFrom($color)')
    $lines.Add('    $tb.Margin     = [System.Windows.Thickness]::new(0,0,0,$marginB)')
    $lines.Add('    if ($bold) { $tb.FontWeight = [System.Windows.FontWeights]::Bold }')
    $lines.Add('    return $tb')
    $lines.Add('}')
    $lines.Add('')
    $lines.Add('function Make-CB($labelText, $checked=$false) {')
    $lines.Add('    $cb             = New-Object System.Windows.Controls.CheckBox')
    $lines.Add('    $cb.Cursor      = [System.Windows.Input.Cursors]::Hand')
    $lines.Add('    $cb.IsChecked   = $checked')
    $lines.Add('    $cb.Margin      = [System.Windows.Thickness]::new(0,0,0,8)')
    $lines.Add('    $lbl            = New-Object System.Windows.Controls.TextBlock')
    $lines.Add('    $lbl.Text       = $labelText')
    $lines.Add('    $lbl.FontFamily = New-Object System.Windows.Media.FontFamily(''Consolas'')')
    $lines.Add('    $lbl.FontSize   = 11')
    $lines.Add('    $lbl.Foreground = $conv.ConvertFrom($(if($checked){''#1A8FFF''} else {''#C8D8E8''}))')
    $lines.Add('    $cb.Content     = $lbl')
    $lines.Add('    return $cb')
    $lines.Add('}')
    $lines.Add('')
    $lines.Add('$picker                       = New-Object System.Windows.Window')
    $lines.Add('$picker.Title                 = ''Network Monitor Setup''')
    $lines.Add('$picker.Background            = $conv.ConvertFrom(''#0A0C0F'')')
    $lines.Add('$picker.WindowStyle           = [System.Windows.WindowStyle]::None')
    $lines.Add('$picker.ResizeMode            = [System.Windows.ResizeMode]::NoResize')
    $lines.Add('$picker.SizeToContent         = [System.Windows.SizeToContent]::WidthAndHeight')
    $lines.Add('$picker.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen')
    $lines.Add('$picker.FontFamily            = New-Object System.Windows.Media.FontFamily(''Consolas'')')
    $lines.Add('')
    $lines.Add('$outerBorder                 = New-Object System.Windows.Controls.Border')
    $lines.Add('$outerBorder.BorderBrush     = $conv.ConvertFrom(''#1E2A38'')')
    $lines.Add('$outerBorder.BorderThickness = [System.Windows.Thickness]::new(1)')
    $lines.Add('')
    $lines.Add('$root        = New-Object System.Windows.Controls.StackPanel')
    $lines.Add('$root.Margin = [System.Windows.Thickness]::new(30,26,30,26)')
    $lines.Add('')
    $lines.Add('$root.Children.Add((Make-TB "$screenCount display$(if($screenCount -ne 1){''s''}) detected" 14 ''#1A8FFF'' $true 6))  | Out-Null')
    $lines.Add('$root.Children.Add((Make-TB ''Where do you want the Network Monitor?'' 11 ''#4A6070'' $false 20)) | Out-Null')
    $lines.Add('')
    $lines.Add('$root.Children.Add((Make-TB ''DISPLAY'' 9 ''#2A3A48'' $false 6)) | Out-Null')
    $lines.Add('$dispPanel        = New-Object System.Windows.Controls.StackPanel')
    $lines.Add('$dispPanel.Margin = [System.Windows.Thickness]::new(0,0,0,18)')
    $lines.Add('$displayCBs       = @()')
    $lines.Add('')
    $lines.Add('for ($s = 0; $s -lt $screens.Count; $s++) {')
    $lines.Add('    $scr     = $screens[$s]')
    $lines.Add('    $res     = "$($scr.Bounds.Width) x $($scr.Bounds.Height)"')
    $lines.Add('    $primary = if ($scr.Primary) { ''  (Primary)'' } else { '''' }')
    $lines.Add('    $cb      = Make-CB "Display $($s+1)   [$res]$primary" ($s -eq 0)')
    $lines.Add('    $idx     = $s')
    $lines.Add('    $cb.Add_Checked({')
    $lines.Add('        for ($k = 0; $k -lt $displayCBs.Count; $k++) {')
    $lines.Add('            if ($k -ne $idx) {')
    $lines.Add('                $displayCBs[$k].IsChecked = $false')
    $lines.Add('                ($displayCBs[$k].Content).Foreground = $conv.ConvertFrom(''#C8D8E8'')')
    $lines.Add('            }')
    $lines.Add('        }')
    $lines.Add('        ($displayCBs[$idx].Content).Foreground = $conv.ConvertFrom(''#1A8FFF'')')
    $lines.Add('        $script:selectedScreen = $screens[$idx]')
    $lines.Add('    })')
    $lines.Add('    $cb.Add_Unchecked({ ($displayCBs[$idx].Content).Foreground = $conv.ConvertFrom(''#C8D8E8'') })')
    $lines.Add('    $dispPanel.Children.Add($cb) | Out-Null')
    $lines.Add('    $displayCBs += $cb')
    $lines.Add('}')
    $lines.Add('$root.Children.Add($dispPanel) | Out-Null')
    $lines.Add('')
    $lines.Add('$root.Children.Add((Make-TB ''SIDE'' 9 ''#2A3A48'' $false 6)) | Out-Null')
    $lines.Add('$sidePanel             = New-Object System.Windows.Controls.StackPanel')
    $lines.Add('$sidePanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal')
    $lines.Add('$sidePanel.Margin      = [System.Windows.Thickness]::new(0,0,0,18)')
    $lines.Add('$cbLeft  = Make-CB ''Left side '' $true')
    $lines.Add('$cbRight = Make-CB ''Right side'' $false')
    $lines.Add('$cbLeft.Margin  = [System.Windows.Thickness]::new(0,0,20,0)')
    $lines.Add('$cbRight.Margin = [System.Windows.Thickness]::new(0,0,0,0)')
    $lines.Add('$cbLeft.Add_Checked({')
    $lines.Add('    $cbRight.IsChecked = $false')
    $lines.Add('    ($cbRight.Content).Foreground = $conv.ConvertFrom(''#C8D8E8'')')
    $lines.Add('    ($cbLeft.Content).Foreground  = $conv.ConvertFrom(''#1A8FFF'')')
    $lines.Add('    $script:selectedSide = ''Left''')
    $lines.Add('})')
    $lines.Add('$cbLeft.Add_Unchecked({ ($cbLeft.Content).Foreground = $conv.ConvertFrom(''#C8D8E8'') })')
    $lines.Add('$cbRight.Add_Checked({')
    $lines.Add('    $cbLeft.IsChecked = $false')
    $lines.Add('    ($cbLeft.Content).Foreground  = $conv.ConvertFrom(''#C8D8E8'')')
    $lines.Add('    ($cbRight.Content).Foreground = $conv.ConvertFrom(''#1A8FFF'')')
    $lines.Add('    $script:selectedSide = ''Right''')
    $lines.Add('})')
    $lines.Add('$cbRight.Add_Unchecked({ ($cbRight.Content).Foreground = $conv.ConvertFrom(''#C8D8E8'') })')
    $lines.Add('$sidePanel.Children.Add($cbLeft)  | Out-Null')
    $lines.Add('$sidePanel.Children.Add($cbRight) | Out-Null')
    $lines.Add('$root.Children.Add($sidePanel)    | Out-Null')
    $lines.Add('')
    $lines.Add('$root.Children.Add((Make-TB ''SORT BY'' 9 ''#2A3A48'' $false 6)) | Out-Null')
    $lines.Add('$sortPanel             = New-Object System.Windows.Controls.StackPanel')
    $lines.Add('$sortPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal')
    $lines.Add('$sortPanel.Margin      = [System.Windows.Thickness]::new(0,0,0,18)')
    $lines.Add('$cbSortIP   = Make-CB ''IP Address'' $true')
    $lines.Add('$cbSortHost = Make-CB ''Hostname''   $false')
    $lines.Add('$cbSortIP.Margin   = [System.Windows.Thickness]::new(0,0,20,0)')
    $lines.Add('$cbSortHost.Margin = [System.Windows.Thickness]::new(0,0,0,0)')
    $lines.Add('$cbSortIP.Add_Checked({')
    $lines.Add('    $cbSortHost.IsChecked = $false')
    $lines.Add('    ($cbSortHost.Content).Foreground = $conv.ConvertFrom(''#C8D8E8'')')
    $lines.Add('    ($cbSortIP.Content).Foreground   = $conv.ConvertFrom(''#1A8FFF'')')
    $lines.Add('    $script:selectedSort = ''IP''')
    $lines.Add('})')
    $lines.Add('$cbSortIP.Add_Unchecked({ ($cbSortIP.Content).Foreground = $conv.ConvertFrom(''#C8D8E8'') })')
    $lines.Add('$cbSortHost.Add_Checked({')
    $lines.Add('    $cbSortIP.IsChecked = $false')
    $lines.Add('    ($cbSortIP.Content).Foreground   = $conv.ConvertFrom(''#C8D8E8'')')
    $lines.Add('    ($cbSortHost.Content).Foreground = $conv.ConvertFrom(''#1A8FFF'')')
    $lines.Add('    $script:selectedSort = ''Hostname''')
    $lines.Add('})')
    $lines.Add('$cbSortHost.Add_Unchecked({ ($cbSortHost.Content).Foreground = $conv.ConvertFrom(''#C8D8E8'') })')
    $lines.Add('$sortPanel.Children.Add($cbSortIP)   | Out-Null')
    $lines.Add('$sortPanel.Children.Add($cbSortHost) | Out-Null')
    $lines.Add('$root.Children.Add($sortPanel)       | Out-Null')
    $lines.Add('')
    $lines.Add('$root.Children.Add((Make-TB ''SCAN FREQUENCY'' 9 ''#2A3A48'' $false 6)) | Out-Null')
    $lines.Add('$freqRow             = New-Object System.Windows.Controls.StackPanel')
    $lines.Add('$freqRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal')
    $lines.Add('$freqRow.Margin      = [System.Windows.Thickness]::new(0,0,0,24)')
    $lines.Add('$freqBox                   = New-Object System.Windows.Controls.TextBox')
    $lines.Add('$freqBox.Text              = ''10''')
    $lines.Add('$freqBox.FontFamily        = New-Object System.Windows.Media.FontFamily(''Consolas'')')
    $lines.Add('$freqBox.FontSize          = 12')
    $lines.Add('$freqBox.Foreground        = $conv.ConvertFrom(''#C8D8E8'')')
    $lines.Add('$freqBox.Background        = $conv.ConvertFrom(''#0F1318'')')
    $lines.Add('$freqBox.BorderBrush       = $conv.ConvertFrom(''#263545'')')
    $lines.Add('$freqBox.BorderThickness   = [System.Windows.Thickness]::new(1)')
    $lines.Add('$freqBox.Padding           = [System.Windows.Thickness]::new(8,4,8,4)')
    $lines.Add('$freqBox.Width             = 70')
    $lines.Add('$freqBox.MaxLength         = 4')
    $lines.Add('$freqBox.TextAlignment     = [System.Windows.TextAlignment]::Center')
    $lines.Add('$freqBox.VerticalAlignment = [System.Windows.VerticalAlignment]::Center')
    $lines.Add('$freqBox.CaretBrush        = $conv.ConvertFrom(''#C8D8E8'')')
    $lines.Add('$freqBox.Add_PreviewKeyDown({')
    $lines.Add('    param($s, $e)')
    $lines.Add('    $digits = @(')
    $lines.Add('        [System.Windows.Input.Key]::D0,[System.Windows.Input.Key]::D1,')
    $lines.Add('        [System.Windows.Input.Key]::D2,[System.Windows.Input.Key]::D3,')
    $lines.Add('        [System.Windows.Input.Key]::D4,[System.Windows.Input.Key]::D5,')
    $lines.Add('        [System.Windows.Input.Key]::D6,[System.Windows.Input.Key]::D7,')
    $lines.Add('        [System.Windows.Input.Key]::D8,[System.Windows.Input.Key]::D9,')
    $lines.Add('        [System.Windows.Input.Key]::NumPad0,[System.Windows.Input.Key]::NumPad1,')
    $lines.Add('        [System.Windows.Input.Key]::NumPad2,[System.Windows.Input.Key]::NumPad3,')
    $lines.Add('        [System.Windows.Input.Key]::NumPad4,[System.Windows.Input.Key]::NumPad5,')
    $lines.Add('        [System.Windows.Input.Key]::NumPad6,[System.Windows.Input.Key]::NumPad7,')
    $lines.Add('        [System.Windows.Input.Key]::NumPad8,[System.Windows.Input.Key]::NumPad9,')
    $lines.Add('        [System.Windows.Input.Key]::Back,[System.Windows.Input.Key]::Delete,')
    $lines.Add('        [System.Windows.Input.Key]::Left,[System.Windows.Input.Key]::Right,')
    $lines.Add('        [System.Windows.Input.Key]::Tab')
    $lines.Add('    )')
    $lines.Add('    if ($digits -notcontains $e.Key) { $e.Handled = $true }')
    $lines.Add('})')
    $lines.Add('$freqLabel                   = New-Object System.Windows.Controls.TextBlock')
    $lines.Add('$freqLabel.Text              = ''  minutes''')
    $lines.Add('$freqLabel.FontFamily        = New-Object System.Windows.Media.FontFamily(''Consolas'')')
    $lines.Add('$freqLabel.FontSize          = 11')
    $lines.Add('$freqLabel.Foreground        = $conv.ConvertFrom(''#4A6070'')')
    $lines.Add('$freqLabel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center')
    $lines.Add('$freqRow.Children.Add($freqBox)   | Out-Null')
    $lines.Add('$freqRow.Children.Add($freqLabel) | Out-Null')
    $lines.Add('$root.Children.Add($freqRow)      | Out-Null')
    $lines.Add('')
    $lines.Add('$launchRow                     = New-Object System.Windows.Controls.StackPanel')
    $lines.Add('$launchRow.Orientation         = [System.Windows.Controls.Orientation]::Horizontal')
    $lines.Add('$launchRow.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right')
    $lines.Add('$btnLaunch                 = New-Object System.Windows.Controls.Button')
    $lines.Add('$btnLaunch.Content         = ''LAUNCH''')
    $lines.Add('$btnLaunch.FontFamily      = New-Object System.Windows.Media.FontFamily(''Consolas'')')
    $lines.Add('$btnLaunch.FontSize        = 10')
    $lines.Add('$btnLaunch.FontWeight      = [System.Windows.FontWeights]::Bold')
    $lines.Add('$btnLaunch.Foreground      = $conv.ConvertFrom(''#1A8FFF'')')
    $lines.Add('$btnLaunch.Background      = [System.Windows.Media.Brushes]::Transparent')
    $lines.Add('$btnLaunch.BorderBrush     = $conv.ConvertFrom(''#0D4A80'')')
    $lines.Add('$btnLaunch.BorderThickness = [System.Windows.Thickness]::new(1)')
    $lines.Add('$btnLaunch.Padding         = [System.Windows.Thickness]::new(20,8,20,8)')
    $lines.Add('$btnLaunch.Cursor          = [System.Windows.Input.Cursors]::Hand')
    $lines.Add('$btnLaunch.Add_Click({')
    $lines.Add('    $raw    = $freqBox.Text.Trim()')
    $lines.Add('    $parsed = 0')
    $lines.Add('    if ([int]::TryParse($raw, [ref]$parsed) -and $parsed -gt 0) {')
    $lines.Add('        $script:selectedFreqMin = $parsed')
    $lines.Add('    } else {')
    $lines.Add('        $script:selectedFreqMin = 10')
    $lines.Add('    }')
    $lines.Add('    $picker.DialogResult = $true')
    $lines.Add('    $picker.Close()')
    $lines.Add('})')
    $lines.Add('$launchRow.Children.Add($btnLaunch) | Out-Null')
    $lines.Add('$root.Children.Add($launchRow)      | Out-Null')
    $lines.Add('')
    $lines.Add('$outerBorder.Child = $root')
    $lines.Add('$picker.Content    = $outerBorder')
    $lines.Add('$picker.Add_MouseLeftButtonDown({')
    $lines.Add('    param($s,$e)')
    $lines.Add('    if ($e.Source -isnot [System.Windows.Controls.Button]) { $picker.DragMove() }')
    $lines.Add('})')
    $lines.Add('')
    $lines.Add('$pickerResult = $picker.ShowDialog()')
    $lines.Add('if (-not $pickerResult) { exit }')
    $lines.Add('')
    # --- Correct per-monitor DPI via a temporary invisible window ---
    $lines.Add('$chosen     = $script:selectedScreen')
    $lines.Add('')
    $lines.Add('# Get accurate DPI of the chosen monitor using a temp WPF window')
    $lines.Add('$tempWin = New-Object System.Windows.Window')
    $lines.Add('$tempWin.WindowStyle = [System.Windows.WindowStyle]::None')
    $lines.Add('$tempWin.AllowsTransparency = $true')
    $lines.Add('$tempWin.Background = [System.Windows.Media.Brushes]::Transparent')
    $lines.Add('$tempWin.Width  = 1')
    $lines.Add('$tempWin.Height = 1')
    $lines.Add('$tempWin.Left  = $chosen.WorkingArea.Left')
    $lines.Add('$tempWin.Top   = $chosen.WorkingArea.Top')
    $lines.Add('$tempWin.Show()')
    $lines.Add('$dpiX = [System.Windows.Media.VisualTreeHelper]::GetDpi($tempWin).DpiScaleX')
    $lines.Add('$dpiY = [System.Windows.Media.VisualTreeHelper]::GetDpi($tempWin).DpiScaleY')
    $lines.Add('$tempWin.Close()')
    $lines.Add('')
    $lines.Add('$workLeft   = $chosen.WorkingArea.Left   / $dpiX')
    $lines.Add('$workTop    = $chosen.WorkingArea.Top    / $dpiY')
    $lines.Add('$workWidth  = $chosen.WorkingArea.Width  / $dpiX')
    $lines.Add('$workHeight = $chosen.WorkingArea.Height / $dpiY')
    $lines.Add('$winWidth   = $workWidth / 2')
    $lines.Add('$winWidth   = [Math]::Max($winWidth, 650)')
    $lines.Add('$winHeight  = $workHeight')
    $lines.Add('$winLeft    = if ($script:selectedSide -eq ''Left'') { $workLeft } else { $workLeft + $winWidth }')
    $lines.Add('$scanIntervalSec = $script:selectedFreqMin * 60')
    $lines.Add('')

    $lines.Add('$ipAddresses = $ipAddresses | Sort-Object {')
    $lines.Add('    $parts = $_.Split(''.'')')
    $lines.Add('    [int]$parts[0]*16777216 + [int]$parts[1]*65536 + [int]$parts[2]*256 + [int]$parts[3]')
    $lines.Add('}')
    $lines.Add('')
    $lines.Add('$hostCount   = $ipAddresses.Count')
    $lines.Add('$reservedDip = 140')
    $lines.Add('$availRows   = $winHeight - $reservedDip')
    $lines.Add('$rowDip      = [math]::Floor($availRows / $hostCount)')
    $lines.Add('$rowDip      = [math]::Max(13, [math]::Min(22, $rowDip))')
    $lines.Add('$rowFontSize = [math]::Max(8.5, $rowDip - 4)')
    $lines.Add('')
    $lines.Add($xamlBlock)
    $lines.Add('')
    $lines.Add('$scanBlock = {')
    $lines.Add('    param($ip)')
    $lines.Add('    try {')
    $lines.Add('        $os  = Get-WmiObject Win32_OperatingSystem -ComputerName $ip -ErrorAction Stop')
    $lines.Add('        $cs  = Get-WmiObject Win32_ComputerSystem  -ComputerName $ip -ErrorAction Stop')
    $lines.Add('        $cpu = (Get-WmiObject Win32_Processor      -ComputerName $ip -ErrorAction Stop |')
    $lines.Add('                Measure-Object LoadPercentage -Average).Average')
    $lines.Add('        $memPct = [math]::Round((1 - ($os.FreePhysicalMemory / $os.TotalVisibleMemorySize)) * 100, 1)')
    $lines.Add('        $up     = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)')
    $lines.Add('        [PSCustomObject]@{')
    $lines.Add('            Hostname  = $cs.Name')
    $lines.Add('            IP        = $ip')
    $lines.Add('            Uptime    = ''{0}d {1}h {2}m'' -f [math]::Floor($up.TotalDays), $up.Hours, $up.Minutes')
    $lines.Add('            LocalTime = $os.ConvertToDateTime($os.LocalDateTime).ToString(''HH:mm:ss'')')
    $lines.Add('            CPU       = [int]$cpu')
    $lines.Add('            RAM       = $memPct')
    $lines.Add('            Online    = $true')
    $lines.Add('        }')
    $lines.Add('    } catch {')
    $lines.Add('        [PSCustomObject]@{')
    $lines.Add('            Hostname  = ''OFFLINE''')
    $lines.Add('            IP        = $ip')
    $lines.Add('            Uptime    = ''--''')
    $lines.Add('            LocalTime = ''--''')
    $lines.Add('            CPU       = -1')
    $lines.Add('            RAM       = -1')
    $lines.Add('            Online    = $false')
    $lines.Add('        }')
    $lines.Add('    }')
    $lines.Add('}')
    $lines.Add('')
    $lines.Add('function Get-MetricColor($val, $warn, $crit) {')
    $lines.Add('    if ($val -lt 0)     { return ''#2A3A48'' }')
    $lines.Add('    if ($val -gt $crit) { return ''#EF4444'' }')
    $lines.Add('    if ($val -gt $warn) { return ''#F59E0B'' }')
    $lines.Add('    return ''#22C55E''')
    $lines.Add('}')
    $lines.Add('')
    $lines.Add('function Get-UptimeDays($str) {')
    $lines.Add('    if ($str -match ''^(\d+)d'') { return [int]$Matches[1] }')
    $lines.Add('    return -1')
    $lines.Add('}')
    $lines.Add('')
    $lines.Add('function Apply-Result($row, $data) {')
    $lines.Add('    if (-not $data.Online) {')
    $lines.Add('        $row.Hostname       = ''OFFLINE''')
    $lines.Add('        $row.IPAddress      = $data.IP')
    $lines.Add('        $row.Uptime         = ''--''')
    $lines.Add('        $row.LocalTime      = ''--''')
    $lines.Add('        $row.CpuText        = ''--''')
    $lines.Add('        $row.RamText        = ''--''')
    $lines.Add('        $row.RowBg          = ''Transparent''')
    $lines.Add('        $row.HostnameColor  = ''#2A3A48''')
    $lines.Add('        $row.HostnameWeight = ''Normal''')
    $lines.Add('        $row.UptimeColor    = ''#2A3A48''')
    $lines.Add('        $row.UptimeWeight   = ''Normal''')
    $lines.Add('        $row.CpuColor       = ''#2A3A48''')
    $lines.Add('        $row.RamColor       = ''#2A3A48''')
    $lines.Add('        return')
    $lines.Add('    }')
    $lines.Add('    $cpuColor = Get-MetricColor $data.CPU 50 75')
    $lines.Add('    $ramColor = Get-MetricColor $data.RAM 50 75')
    $lines.Add('    $days = Get-UptimeDays $data.Uptime')
    $lines.Add('    $uptimeColor  = ''#4A6070''')
    $lines.Add('    $uptimeWeight = ''Normal''')
    $lines.Add('    if ($days -gt 180)    { $uptimeColor = ''#B0E0FF''; $uptimeWeight = ''Bold'' }')   # lighter blue for >180d
    $lines.Add('    elseif ($days -gt 90) { $uptimeColor = ''#7EC8E3''; $uptimeWeight = ''Bold'' }') # light blue for >90d
    $lines.Add('    $isCrit = ($data.CPU -gt 75 -or $data.RAM -gt 75)')
    $lines.Add('    $isWarn = ($data.CPU -gt 50 -or $data.RAM -gt 50)')
    $lines.Add('    $rowBg = ''Transparent''')
    $lines.Add('    if ($isCrit)     { $rowBg = ''#1A0505'' }')
    $lines.Add('    elseif ($isWarn) { $rowBg = ''#1A1200'' }')
    $lines.Add('    $row.Hostname       = $data.Hostname')
    $lines.Add('    $row.IPAddress      = $data.IP')
    $lines.Add('    $row.Uptime         = $data.Uptime')
    $lines.Add('    $row.LocalTime      = $data.LocalTime')
    $lines.Add('    $row.CpuText        = "$($data.CPU)%"')
    $lines.Add('    $row.RamText        = "$($data.RAM)%"')
    $lines.Add('    $row.RowBg          = $rowBg')
    $lines.Add('    $row.HostnameColor  = ''#C8D8E8''')
    $lines.Add('    $row.HostnameWeight = ''Bold''')
    $lines.Add('    $row.UptimeColor    = $uptimeColor')
    $lines.Add('    $row.UptimeWeight   = $uptimeWeight')
    $lines.Add('    $row.CpuColor       = $cpuColor')
    $lines.Add('    $row.RamColor       = $ramColor')
    $lines.Add('}')
    $lines.Add('')
    $lines.Add('function Sort-Collection($coll, $map, $sortBy) {')
    $lines.Add('    $sorted = if ($sortBy -eq ''Hostname'') {')
    $lines.Add('        $map.Values | Sort-Object { $_.Hostname }')
    $lines.Add('    } else {')
    $lines.Add('        $map.Values | Sort-Object {')
    $lines.Add('            $parts = $_.IPAddress.Split(''.'')')
    $lines.Add('            [int]$parts[0]*16777216 + [int]$parts[1]*65536 + [int]$parts[2]*256 + [int]$parts[3]')
    $lines.Add('        }')
    $lines.Add('    }')
    $lines.Add('    $coll.Clear()')
    $lines.Add('    foreach ($r in $sorted) { $coll.Add($r) }')
    $lines.Add('}')
    $lines.Add('')
    $lines.Add('$reader = [System.Xml.XmlNodeReader]::new($xaml)')
    $lines.Add('$window = [Windows.Markup.XamlReader]::Load($reader)')
    $lines.Add('')
    $lines.Add('$window.Left   = $winLeft')
    $lines.Add('$window.Top    = $workTop')
    $lines.Add('$window.Width  = $winWidth')
    $lines.Add('$window.Height = $winHeight')
    $lines.Add('')
    $lines.Add('$hostList     = $window.FindName(''HostList'')')
    $lines.Add('$statTotal    = $window.FindName(''StatTotal'')')
    $lines.Add('$statOnline   = $window.FindName(''StatOnline'')')
    $lines.Add('$statOffline  = $window.FindName(''StatOffline'')')
    $lines.Add('$statWarn     = $window.FindName(''StatWarn'')')
    $lines.Add('$statCrit     = $window.FindName(''StatCrit'')')
    $lines.Add('$lastScan     = $window.FindName(''LastScan'')')
    $lines.Add('$nextScan     = $window.FindName(''NextScan'')')
    $lines.Add('$clockLabel   = $window.FindName(''ClockLabel'')')
    $lines.Add('$countdownBar = $window.FindName(''CountdownBar'')')
    $lines.Add('$btnScan      = $window.FindName(''BtnScan'')')
    $lines.Add('$btnSave      = $window.FindName(''BtnSave'')')
    $lines.Add('$btnClose     = $window.FindName(''BtnClose'')')
    $lines.Add('')
    $lines.Add('$rowMap = [ordered]@{}')
    $lines.Add('foreach ($ip in $ipAddresses) {')
    $lines.Add('    $r = New-Object HostRow')
    $lines.Add('    $r.Hostname       = ''PENDING''')
    $lines.Add('    $r.IPAddress      = $ip')
    $lines.Add('    $r.Uptime         = ''--''')
    $lines.Add('    $r.LocalTime      = ''--''')
    $lines.Add('    $r.CpuText        = ''--''')
    $lines.Add('    $r.RamText        = ''--''')
    $lines.Add('    $r.RowBg          = ''Transparent''')
    $lines.Add('    $r.HostnameColor  = ''#2A3A48''')
    $lines.Add('    $r.HostnameWeight = ''Normal''')
    $lines.Add('    $r.UptimeColor    = ''#4A6070''')
    $lines.Add('    $r.UptimeWeight   = ''Normal''')
    $lines.Add('    $r.CpuColor       = ''#2A3A48''')
    $lines.Add('    $r.RamColor       = ''#2A3A48''')
    $lines.Add('    $rowMap[$ip] = $r')
    $lines.Add('}')
    $lines.Add('')
    $lines.Add('$collection = New-Object System.Collections.ObjectModel.ObservableCollection[object]')
    $lines.Add('Sort-Collection $collection $rowMap $script:selectedSort')
    $lines.Add('$hostList.ItemsSource = $collection')
    $lines.Add('')
    $lines.Add('$script:nextScanTime = $null')
    $lines.Add('$script:scanning     = $false')
    $lines.Add('$script:jobs         = $null')
    $lines.Add('$script:pollTimer    = $null')
    $lines.Add('')
    $lines.Add('function Start-Scan {')
    $lines.Add('    if ($script:scanning) { return }')
    $lines.Add('    $script:scanning   = $true')
    $lines.Add('    $btnScan.IsEnabled = $false')
    $lines.Add('    $now = Get-Date')
    $lines.Add('    $lastScan.Text       = $now.ToString(''yyyy-MM-dd HH:mm:ss'')')
    $lines.Add('    $script:nextScanTime = $now.AddSeconds($scanIntervalSec)')
    $lines.Add('    $nextScan.Text       = $script:nextScanTime.ToString(''yyyy-MM-dd HH:mm:ss'')')
    $lines.Add('    $script:jobs = $ipAddresses | ForEach-Object { Start-Job -ScriptBlock $scanBlock -ArgumentList $_ }')
    $lines.Add('    $script:pollTimer = New-Object System.Windows.Threading.DispatcherTimer')
    $lines.Add('    $script:pollTimer.Interval = [TimeSpan]::FromSeconds(2)')
    $lines.Add('    $script:pollTimer.Add_Tick({')
    $lines.Add('        $allDone = $true')
    $lines.Add('        foreach ($j in $script:jobs) { if ($j.State -eq ''Running'') { $allDone = $false; break } }')
    $lines.Add('        if ($allDone) {')
    $lines.Add('            $script:pollTimer.Stop()')
    $lines.Add('            $results = foreach ($j in $script:jobs) { Receive-Job -Job $j -Wait; Remove-Job -Job $j }')
    $lines.Add('            $online = 0; $offline = 0; $warn = 0; $crit = 0')
    $lines.Add('            foreach ($data in $results) {')
    $lines.Add('                $row = $rowMap[$data.IP]')
    $lines.Add('                if ($null -eq $row) { continue }')
    $lines.Add('                Apply-Result $row $data')
    $lines.Add('                if (-not $data.Online) { $offline++ }')
    $lines.Add('                else {')
    $lines.Add('                    $online++')
    $lines.Add('                    $isCrit = ($data.CPU -gt 75 -or $data.RAM -gt 75)')
    $lines.Add('                    $isWarn = ($data.CPU -gt 50 -or $data.RAM -gt 50)')
    $lines.Add('                    if ($isCrit) { $crit++ } elseif ($isWarn) { $warn++ }')
    $lines.Add('                }')
    $lines.Add('            }')
    $lines.Add('            Sort-Collection $collection $rowMap $script:selectedSort')
    $lines.Add('            $statTotal.Text   = $ipAddresses.Count')
    $lines.Add('            $statOnline.Text  = $online')
    $lines.Add('            $statOffline.Text = $offline')
    $lines.Add('            $statWarn.Text    = $warn')
    $lines.Add('            $statCrit.Text    = $crit')
    $lines.Add('            $script:scanning   = $false')
    $lines.Add('            $btnScan.IsEnabled = $true')
    $lines.Add('        }')
    $lines.Add('    })')
    $lines.Add('    $script:pollTimer.Start()')
    $lines.Add('}')
    $lines.Add('')
    $lines.Add('$uiTimer = New-Object System.Windows.Threading.DispatcherTimer')
    $lines.Add('$uiTimer.Interval = [TimeSpan]::FromSeconds(1)')
    $lines.Add('$uiTimer.Add_Tick({')
    $lines.Add('    $clockLabel.Text = (Get-Date).ToString(''HH:mm:ss'')')
    $lines.Add('    if ($null -ne $script:nextScanTime) {')
    $lines.Add('        $remaining  = ($script:nextScanTime - (Get-Date)).TotalSeconds')
    $lines.Add('        if ($remaining -lt 0) { $remaining = 0 }')
    $lines.Add('        $pct        = $remaining / $scanIntervalSec')
    $lines.Add('        $totalWidth = $countdownBar.Parent.ActualWidth')
    $lines.Add('        $countdownBar.Width = $totalWidth * $pct')
    $lines.Add('        if ($remaining -le 1 -and -not $script:scanning) { Start-Scan }')
    $lines.Add('    }')
    $lines.Add('})')
    $lines.Add('$uiTimer.Start()')
    $lines.Add('')
    $lines.Add('$btnScan.Add_Click({ Start-Scan })')
    $lines.Add('')
    $lines.Add('$btnSave.Add_Click({')
    $lines.Add('    $dlg          = New-Object Microsoft.Win32.SaveFileDialog')
    $lines.Add('    $dlg.Filter   = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"')
    $lines.Add('    $dlg.FileName = "NetMonitor_$(Get-Date -Format ''yyyyMMdd_HHmmss'').csv"')
    $lines.Add('    if ($dlg.ShowDialog()) {')
    $lines.Add('        $export = foreach ($r in $collection) {')
    $lines.Add('            [PSCustomObject]@{')
    $lines.Add('                Hostname  = $r.Hostname')
    $lines.Add('                IPAddress = $r.IPAddress')
    $lines.Add('                Uptime    = $r.Uptime')
    $lines.Add('                LocalTime = $r.LocalTime')
    $lines.Add('                CPU       = $r.CpuText')
    $lines.Add('                RAM       = $r.RamText')
    $lines.Add('            }')
    $lines.Add('        }')
    $lines.Add('        $export | Export-Csv -Path $dlg.FileName -NoTypeInformation')
    $lines.Add('    }')
    $lines.Add('})')
    $lines.Add('')
    $lines.Add('$btnClose.Add_Click({')
    $lines.Add('    $uiTimer.Stop()')
    $lines.Add('    if ($null -ne $script:pollTimer) { $script:pollTimer.Stop() }')
    $lines.Add('    if ($null -ne $script:jobs) {')
    $lines.Add('        $script:jobs | ForEach-Object {')
    $lines.Add('            Stop-Job  -Job $_ -ErrorAction SilentlyContinue')
    $lines.Add('            Remove-Job -Job $_ -Force -ErrorAction SilentlyContinue')
    $lines.Add('        }')
    $lines.Add('    }')
    $lines.Add('    $window.Close()')
    $lines.Add('})')
    $lines.Add('')
    $lines.Add('$window.Add_MouseLeftButtonDown({')
    $lines.Add('    param($s, $e)')
    $lines.Add('    if ($e.Source -isnot [System.Windows.Controls.Button]) { $window.DragMove() }')
    $lines.Add('})')
    $lines.Add('')
    $lines.Add('$window.Add_Loaded({ Start-Scan })')
    $lines.Add('$window.ShowDialog() | Out-Null')

    return $lines -join $nl
}

function Save-ScriptFile($content, $defaultName) {
    $dlg          = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter   = "PowerShell Script (*.ps1)|*.ps1|All files (*.*)|*.*"
    $dlg.FileName = $defaultName
    if ($dlg.ShowDialog()) {
        [System.IO.File]::WriteAllText($dlg.FileName, $content, [System.Text.Encoding]::UTF8)
        return $dlg.FileName
    }
    return $null
}

# BUILD GENERATOR WINDOW
$win                       = New-Object System.Windows.Window
$win.Title                 = 'Network Monitor Generator'
$win.Background            = $conv.ConvertFrom('#0A0C0F')
$win.WindowStyle           = [System.Windows.WindowStyle]::None
$win.ResizeMode            = [System.Windows.ResizeMode]::NoResize
$win.SizeToContent         = [System.Windows.SizeToContent]::WidthAndHeight
$win.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
$win.FontFamily            = New-Object System.Windows.Media.FontFamily('Consolas')
$win.MinWidth              = 520

$outer                 = New-Object System.Windows.Controls.Border
$outer.BorderBrush     = $conv.ConvertFrom('#1E2A38')
$outer.BorderThickness = [System.Windows.Thickness]::new(1)

$scroll                             = New-Object System.Windows.Controls.ScrollViewer
$scroll.VerticalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Auto
$scroll.MaxHeight                   = 820

$root        = New-Object System.Windows.Controls.StackPanel
$root.Margin = [System.Windows.Thickness]::new(30,26,30,26)
$root.Width  = 460

# HEADER
$root.Children.Add((Make-TB 'NET MONITOR GENERATOR' 15 '#1A8FFF' $true 4))  | Out-Null
$root.Children.Add((Make-TB 'Build a ready-to-run monitoring script for your environment.' 10 '#4A6070' $false 20)) | Out-Null

# INDIVIDUAL IPs
$root.Children.Add((Make-TB 'INDIVIDUAL IP ADDRESSES' 9 '#2A3A48' $false 6)) | Out-Null
$root.Children.Add((Make-TB 'One IP per line, or comma separated.' 9 '#4A6070' $false 8)) | Out-Null

$ipBox                = New-Object System.Windows.Controls.TextBox
$ipBox.FontFamily     = New-Object System.Windows.Media.FontFamily('Consolas')
$ipBox.FontSize       = 11
$ipBox.Foreground     = $conv.ConvertFrom('#C8D8E8')
$ipBox.Background     = $conv.ConvertFrom('#0F1318')
$ipBox.BorderBrush    = $conv.ConvertFrom('#263545')
$ipBox.BorderThickness= [System.Windows.Thickness]::new(1)
$ipBox.Padding        = [System.Windows.Thickness]::new(8,6,8,6)
$ipBox.Width          = 400
$ipBox.Height         = 100
$ipBox.AcceptsReturn  = $true
$ipBox.TextWrapping   = [System.Windows.TextWrapping]::Wrap
$ipBox.CaretBrush     = $conv.ConvertFrom('#C8D8E8')
$ipBox.VerticalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Auto
$ipBox.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
$ipBox.Margin         = [System.Windows.Thickness]::new(0,0,0,20)
$root.Children.Add($ipBox) | Out-Null

$root.Children.Add((Make-Sep 0 20)) | Out-Null

# IP RANGES
$root.Children.Add((Make-TB 'IP RANGES' 9 '#2A3A48' $false 6)) | Out-Null
$root.Children.Add((Make-TB 'Format: 10.92.193.101-122' 9 '#4A6070' $false 8)) | Out-Null

$rangePanel        = New-Object System.Windows.Controls.StackPanel
$rangePanel.Margin = [System.Windows.Thickness]::new(0,0,0,6)
$root.Children.Add($rangePanel) | Out-Null

$rangeRows = [System.Collections.Generic.List[System.Windows.Controls.TextBox]]::new()

function Add-RangeRow($defaultText='') {
    $row             = New-Object System.Windows.Controls.StackPanel
    $row.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $row.Margin      = [System.Windows.Thickness]::new(0,0,0,6)

    $tb = Make-TextBox $defaultText 320
    $row.Children.Add($tb) | Out-Null
    $rangeRows.Add($tb)

    $removeBtn                 = New-Object System.Windows.Controls.Button
    $removeBtn.Content         = 'X'
    $removeBtn.FontFamily      = New-Object System.Windows.Media.FontFamily('Consolas')
    $removeBtn.FontSize        = 10
    $removeBtn.Foreground      = $conv.ConvertFrom('#7F1D1D')
    $removeBtn.Background      = [System.Windows.Media.Brushes]::Transparent
    $removeBtn.BorderBrush     = $conv.ConvertFrom('#7F1D1D')
    $removeBtn.BorderThickness = [System.Windows.Thickness]::new(1)
    $removeBtn.Padding         = [System.Windows.Thickness]::new(8,5,8,5)
    $removeBtn.Margin          = [System.Windows.Thickness]::new(8,0,0,0)
    $removeBtn.Cursor          = [System.Windows.Input.Cursors]::Hand
    $removeBtn.Visibility      = if ($rangeRows.Count -eq 1) {
        [System.Windows.Visibility]::Hidden
    } else {
        [System.Windows.Visibility]::Visible
    }

    # Store row and textbox in Tag to fix delete button closure issue
    $removeBtn.Tag = [PSCustomObject]@{ Row = $row; Tb = $tb }
    $removeBtn.Add_Click({
        $item = $this.Tag
        if ($item) {
            $rangePanel.Children.Remove($item.Row)
            $rangeRows.Remove($item.Tb)
            if ($rangeRows.Count -eq 1) {
                $firstRow = $rangePanel.Children[0]
                if ($firstRow) {
                    $firstBtn = $firstRow.Children |
                        Where-Object { $_ -is [System.Windows.Controls.Button] } |
                        Select-Object -First 1
                    if ($firstBtn) { $firstBtn.Visibility = [System.Windows.Visibility]::Hidden }
                }
            }
        }
    })

    $row.Children.Add($removeBtn) | Out-Null
    $rangePanel.Children.Add($row) | Out-Null

    if ($rangeRows.Count -gt 1) {
        $firstRow = $rangePanel.Children[0]
        if ($null -ne $firstRow) {
            $firstBtn = $firstRow.Children |
                Where-Object { $_ -is [System.Windows.Controls.Button] } |
                Select-Object -First 1
            if ($null -ne $firstBtn) { $firstBtn.Visibility = [System.Windows.Visibility]::Visible }
        }
    }
}

Add-RangeRow

$addRangeBtn = Make-Btn '+ Add Range'
$addRangeBtn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
$addRangeBtn.Margin = [System.Windows.Thickness]::new(0,4,0,20)
$addRangeBtn.Add_Click({ Add-RangeRow })
$root.Children.Add($addRangeBtn) | Out-Null

$root.Children.Add((Make-Sep 0 20)) | Out-Null

# ERROR LABEL
$errLabel              = New-Object System.Windows.Controls.TextBlock
$errLabel.FontFamily   = New-Object System.Windows.Media.FontFamily('Consolas')
$errLabel.FontSize     = 10
$errLabel.Foreground   = $conv.ConvertFrom('#EF4444')
$errLabel.Margin       = [System.Windows.Thickness]::new(0,0,0,10)
$errLabel.Visibility   = [System.Windows.Visibility]::Collapsed
$errLabel.TextWrapping = [System.Windows.TextWrapping]::Wrap
$root.Children.Add($errLabel) | Out-Null

# GENERATE BUTTON
$genBtn = Make-Btn 'GENERATE' $true
$genBtn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
$root.Children.Add($genBtn) | Out-Null

$genBtn.Add_Click({
    $allText = $ipBox.Text
    foreach ($tb in $rangeRows) {
        $t = $tb.Text.Trim()
        if ($t -ne '') { $allText += "`n$t" }
    }

    $parsed = Parse-IPInput $allText

    if ($null -eq $parsed -or @($parsed).Count -eq 0) {
        $errLabel.Text       = 'No valid IP addresses found. Please enter at least one IP or range.'
        $errLabel.Visibility = [System.Windows.Visibility]::Visible
        return
    }

    $errLabel.Visibility = [System.Windows.Visibility]::Collapsed

    # Generate only the monitor script (WinRM removed)
    $monScript = Build-Monitor-Script $parsed
    $savedMon  = Save-ScriptFile $monScript 'NetworkMonitor.ps1'
    if ($null -eq $savedMon) { return }

    $done                       = New-Object System.Windows.Window
    $done.Title                 = 'Done'
    $done.Background            = $conv.ConvertFrom('#0A0C0F')
    $done.WindowStyle           = [System.Windows.WindowStyle]::None
    $done.ResizeMode            = [System.Windows.ResizeMode]::NoResize
    $done.SizeToContent         = [System.Windows.SizeToContent]::WidthAndHeight
    $done.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen

    $dob                 = New-Object System.Windows.Controls.Border
    $dob.BorderBrush     = $conv.ConvertFrom('#1E2A38')
    $dob.BorderThickness = [System.Windows.Thickness]::new(1)

    $dsp        = New-Object System.Windows.Controls.StackPanel
    $dsp.Margin = [System.Windows.Thickness]::new(30,24,30,24)
    $dsp.Width  = 380

    $dsp.Children.Add((Make-TB 'DONE' 13 '#22C55E' $true 12)) | Out-Null
    $dsp.Children.Add((Make-TB 'Your network monitoring script has been saved.' 10 '#C8D8E8' $false 20 $true)) | Out-Null

    $okBtn = Make-Btn 'OK' $true
    $okBtn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $okBtn.Add_Click({
        $done.Close()
        $win.Close()
    })
    $dsp.Children.Add($okBtn) | Out-Null

    $dob.Child    = $dsp
    $done.Content = $dob
    $done.ShowDialog() | Out-Null
})

$scroll.Content  = $root
$outer.Child     = $scroll
$win.Content     = $outer

$win.Add_MouseLeftButtonDown({
    param($s,$e)
    if ($e.Source -isnot [System.Windows.Controls.Button]) { $win.DragMove() }
})

$win.ShowDialog() | Out-Null
