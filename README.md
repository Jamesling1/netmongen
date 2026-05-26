netmongen

Requirements

Windows with PowerShell 5.1+
.NET WPF assemblies (included in standard Windows installs)
DCOM/RPC access to target machines
Administrator rights on target machines


Usage

Run netmongen.ps1
Enter IP addresses and/or ranges in the generator window
Click GENERATE and save the output script

![Dashboard screenshot](https://github.com/Jamesling1/netmongen/blob/main/1.png)

Run the generated NetworkMonitor.ps1 (or whatever you named it)
Configure display, side, sort order, and scan interval in the setup dialog
Click LAUNCH

![Dashboard screenshot](https://github.com/Jamesling1/netmongen/blob/main/3.png)

![Dashboard screenshot](https://github.com/Jamesling1/netmongen/blob/main/screen.png)

How It Works

The generator parses your IP input, expands any ranges, and writes a self-contained monitoring script with the IP list embedded.
The generated script uses Get-WmiObject with -ComputerName to poll each host in parallel via background jobs.
Results are collected on a configurable interval and bound to a WPF ObservableCollection for live UI updates.
Offline hosts are detected via WMI connection failure and displayed in a dimmed state.
Per-monitor DPI is detected at runtime using a temporary WPF window so the dashboard positions and sizes correctly on high-DPI displays and multi-monitor setups.

Notes

Scanning large IP lists at short intervals will generate significant WMI traffic. A minimum interval of 5 minutes is recommended for lists over 50 hosts.
Target machines must have DCOM/RPC accessible on the network.
The generated script requires no additional dependencies and can be distributed and run independently of the generator.
