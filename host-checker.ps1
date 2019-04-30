# https://github.com/VintageGnu/dns-scripts
# Sorts a list of domains into three categories
#   - Those with their apex A record pointing to the specified IP address
#   - Those with their apex A record pointing to another IP address
#   - Those with no apex A record, or some other DNS issue

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

# Put your IP addresses regex here
# $ippattern = '^123\.123\.123\.(123|124)$'

# Clean up old results and get started
echo "Checking domains in domains.txt to see if their apex A record points to us."
echo "" > our-hosting.txt
echo "" > external-hosting.txt
echo "" > broken-hosting.txt
$i = 1
while($null -ne ($domain = $domains.ReadLine()))
{
	# Update progress bar
	Write-Progress -Activity "Testing Domains" -Status "Testing $domain ($i/$domaincountstring)" -PercentComplete ($i / $domaincount.Lines * 100)

	# Skip if in excludes
	if((-Not $excludes) -OR (-Not (Select-String -quiet $domain .\excludes.txt)))
	{
		try
		{
			# Retrieve apex A record
			$domainip = Resolve-DnsName $domain -type A -NoHostsFile -ErrorAction Stop -DnsOnly | Select-Object -first 1 -Property IPAddress

			if($domainip.IPAddress -match $ippattern)
			{
				echo $domain >> our-hosting.txt
			}
			else
			{
				echo $domain >> external-hosting.txt
			}
		}
		Catch
		{
			# Something went wrong retrieving the apex A record
			echo $domain >> broken-hosting.txt
		}
	}
	$i++
}

echo "Done, see the generated files for domain specifics"
cmd /c pause
