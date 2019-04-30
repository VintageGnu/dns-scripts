# https://github.com/VintageGnu/dns-scripts
# Sorts a list of domains into three categories
#   - Those that use the specified nameservers
#   - Those that use other nameservers
#   - Those that don't have nameservers, or some other issue with DNS

# Get the list of domains
$domains = [System.IO.File]::OpenText("domains.txt")

# Count the domains (for the progress bar)
$domaincount = Get-Content .\domains.txt | Measure-Object -Line | Select-Object -property Lines
$domaincountstring = $domaincount.Lines.ToString()

$totaldomains = $domaincount.Lines

# Look for a list of domains to exclude
$excludes = [System.IO.File]::Exists("excludes.txt")

if($excludes)
{
    echo "Excludes file found, some domains will be skipped."

}
else
{
    echo "No excludes files found, processing all domains."
}

# Enter your hostname regex here
$hostpattern = '^server[1-5]\.example\.com$'

# Enter your IP address regex here
$ippattern = '^123\.123\.123\.(123|124)$'

# Clean up the old results and get started
echo "Checking domains in domains.txt to see if they are using our nameservers."
echo "" > our-nameservers.txt
echo "" > external-nameservers.txt
echo "" > broken-nameservers.txt
$i = 1
while($null -ne ($domain = $domains.ReadLine()))
{
	# Update progress bar
    Write-Progress -Activity "Testing Domains" -Status "Testing $domain ($i/$totaldomains)" -PercentComplete ($i / $totaldomains * 100)

	# Skip if in excludes list
    if((-Not $excludes) -OR (-Not (Select-String -quiet $domain .\excludes.txt)))
    {
        try
        {
			# Retrieve nameservers for domain
            $nsname = Resolve-DnsName $domain -type NS -NoHostsFile -ErrorAction Stop -DnsOnly | Select-Object -first 1 -Property NameHost
        
            if($nsname.NameHost -match $hostpattern)
            {
                echo $domain >> our-nameservers.txt
            }
            else
            {
				# Check if the domain is using the specified nameservers but with a different hostname
                $nsip = Resolve-DnsName $nsname.NameHost | Select-Object -Property IPAddress
                if($nsip.IPAddress -match $ippattern)
                {
                    echo $domain >> our-nameservers.txt
                }
                else
                {
                    echo $domain >> external-nameservers.txt
                }
            }
        }
        Catch
        {
			# Retrieving DNS information failed
            echo $domain >> broken-nameservers.txt
        }
    }

    $i++

}

echo "Done, see the generated files for domain specifics"
cmd /c pause
