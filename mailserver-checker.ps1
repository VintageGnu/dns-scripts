# https://github.com/VintageGnu/dns-scripts
# Sorts a list of domains into five categories
#   - Those that use the specified mailservers and nameservers
#   - Those that use other mailservers and the specified nameservers
#   - Those that use the specified mailservers and other nameservers
#   - Those that use other mailservers and nameservers
#   - Those that have some issue with MX record resolution

# Get the list of domains
$domains = [System.IO.File]::OpenText("domains.txt")

# Count the number of domains (for the progress bar)
$domaincount = Get-Content .\domains.txt | Measure-Object -Line | Select-Object -property Lines
$domaincountstring = $domaincount.Lines.ToString()

$totaldomains = $domaincount.Lines

# Get the list of domains to exclude
$excludes = [System.IO.File]::Exists("excludes.txt")

if($excludes)
{
    echo "Excludes file found, some domains will be skipped."

}
else
{
    echo "No excludes files found, processing all domains."
}

# Set your hostname regex here
$hostpattern = '^server[1-5]\.example\.com$'

# Set your IP address regex here
$ippattern = '^123\.123\.123\.(123|124|125)$'

# Clean up the old results and get started
echo "Checking domains in domains.txt to check out their mailserver setup."
echo "" > our-mailserver-our-nameserver.txt
echo "" > external-mailserver-our-nameserver.txt
echo "" > our-mailserver-external-nameserver.txt
echo "" > external-mailserver-external-nameserver.txt
echo "" > broken-mailserver.txt
$i = 1

while($null -ne ($domain = $domains.ReadLine()))
{
    Write-Progress -Activity "Testing Domains" -Status "Testing $domain ($i/$totaldomains)" -PercentComplete ($i / $totaldomains * 100)

	# Skip if in excludes
    if((-Not $excludes) -OR (-Not (Select-String -quiet $domain .\excludes.txt)))
    {
        try
        {
			# Retrieve nameserver and MX recod information
			$nsname = Resolve-DnsName $domain -type NS -NoHostsFile -ErrorAction Stop -DnsOnly | Select-Object -first 1 -Property NameHost
            $mxname = Resolve-DnsName $domain -type MX -NoHostsFile -ErrorAction Stop -DnsOnly | Sort-Object -Property Preference | Select-Object -first 1 -Property NameExchange
			$nsip = Resolve-DnsName $nsname.NameHost -NoHostsFile -ErrorAction Stop -DnsOnly  | Select-Object -Property IPAddress
			$mxip = Resolve-DnsName $mxname.NameExchange -NoHostsFile -ErrorAction Stop -DnsOnly  | Select-Object -Property IPAddress
			
            if($nsname.NameHost -match $hostpattern)
            {
				if($mxip.IPAddress -match $ippattern)
				{
					echo $domain >> our-mailserver-our-nameserver.txt
				}
				else
				{
					echo $domain >> external-mailserver-our-nameserver.txt
				}
            }
            else
            {
				# Check if it is using the specified nameserver but with a different hostname
                if($nsip.IPAddress -match $ippattern)
                {
					if($mxip.IPAddress -match $ippattern)
					{
						echo $domain >> our-mailserver-our-nameserver.txt
					}
					else
					{
						echo $domain >> external-mailserver-our-nameserver.txt
					}
                }
                else
                {
					if($mxip.IPAddress -match $ippattern)
					{
						echo $domain >> our-mailserver-external-nameserver.txt
					}
					else
					{
						echo $domain >> external-mailserver-external-nameserver.txt
					}
                }
            }
        }
        Catch
        {
			# Differentiate between DNS errors and missing MX record
			if($mxname.NameExchange -ne $null)
			{
				echo "$domain - $($mxname.NameExchange)" >> broken-mailserver.txt
			}
			else
			{
				echo "$domain - NO_MX_FOUND" >> broken-mailserver.txt
			}
        }
    }

    $i++

}

echo "Done, see the generated files for domain specifics"
cmd /c pause
