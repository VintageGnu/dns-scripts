# DNS Scripts
These scripts were created to help a server admin of a hosting provider figure out where the sites they were supposedly hosting actually were, and pick up domains that might be misconfigured.

## First time setup
(Recommended) Put the .ps1 files in their own folder.
Open up a PowerShell terminal with admin privileges.
Run the command "set-executionpolicy unrestricted" (without quotes) and accept.

This is needed because by default Powershell won't let you run random scripts.

You should also update the IP address and/or hostname regexes in each script to suit your particular needs.

## Extra Files
All the scripts require a domains.txt file in the same directory, which should contain a line-separated list of all the domains to be checked.

They will also look for an optional excludes.txt in the same directory, and any domains listed in this file are skipped.

## Usage
Simply right click on a file and select Run with PowerShell.
As it runs it sort the domains into a couple of different files, depending on what script you run.
If these files already existed then they will be overwritten, so copy them elsewhere if you want them preserved.

## broken-*.txt
The domains that end up in here are usually expired, but in some cases simply have misconfigured nameservers.
In broken-mailserver you get a little extra info, namely the primary MX record that failed to resolve, or NO_MX_FOUND if no MX records were found for the domain.
