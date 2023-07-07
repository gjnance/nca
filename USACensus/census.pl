#!/usr/bin/perl
require "/home3/gnanceco/public_html/nca/admin/subs/subs.pl";

print "Content-Type: text/html\n\n" if (@ENV{SkipContentType} eq "");

use CGI qw(:standard);
my $classicCutoffYr = 1960;
$qdata = new CGI;
my $debug = 0;
my $pspDir = "$docRoot/psp";
my $ssiDir = "$docRoot/ssi";
my $highlightStartFile = $docRoot . "/ssi/HighlightBorderBegin.html";
my $highlightEndFile = $docRoot . "/ssi/HighlightBorderEnd.html";
my $website = "carousels.org";
my $censusFile = "$docRoot/admin/AllCensus/WebCensus.csv";	# new location
$censusFile =~ s/\/m\//\//;
my $updateFile = "$docRoot/admin/AllCensus/DateUpdated.txt";
my @months = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
my $headerDir = "headers";	# new location
print "Beginning execution<BR>\n" if ($debug);
if (getEnvField("debug") eq "1" ) {
	$debug = 1;
	}

my $show1Field = 0;

my %NCARecs;
my %StateRecs;
my %YearRecs;
my $titlesIncluded = 1;
my $recordCount = 0;
my %statenames = (
	"AB" => "Alberta",
	"AK" => "Alaska",
	"AL" => "Alabama",
	"AZ" => "Arizona",
	"AR" => "Arkansas",
	"BC" => "British Columbia",
	"CA" => "California",
	"CO" => "Colorado",
	"CT" => "Connecticut",
	"DC" => "District of Columbia",
	"DE" => "Delaware",
	"FL" => "Florida",
	"GA" => "Georgia",
	"HI" => "Hawaii",
	"ID" => "Idaho",
	"IL" => "Illinois",
	"IN" => "Indiana",
	"IA" => "Iowa",
	"KS" => "Kansas",
	"KY" => "Kentucky",
	"LA" => "Louisiana",
	"ME" => "Maine",
	"MD" => "Maryland",
	"MA" => "Massachusetts",
	"MB" => "Manitoba",
	"MI" => "Michigan",
	"MN" => "Minnesota",
	"MS" => "Mississippi",
	"MO" => "Missouri",
	"MT" => "Montana",
	"NB" => "New Brunswick",
	"NE" => "Nebraska",
	"NL" => "Newfoundland and Labrador",
	"NL" => "Nova Scotia",
	"NV" => "Nevada",
	"NH" => "New Hampshire",
	"NJ" => "New Jersey",
	"NM" => "New Mexico",
	"NT" => "Northwest Territories",
	"NY" => "New York",
	"NC" => "North Carolina",
	"ND" => "North Dakota",
	"NU" => "Nunavut",
	"OH" => "Ohio",
	"OK" => "Oklahoma",
	"ON" => "Ontario",
	"OR" => "Oregon",
	"PA" => "Pennsylvania",
	"PE" => "Prince Edward Island",
	"QC" => "Quebec",
	"RI" => "Rhode Island",
	"SC" => "South Carolina",
	"SD" => "South Dakota",
	"SK" => "Saskatchewan",
	"TN" => "Tennessee",
	"TX" => "Texas",
	"UT" => "Utah",
	"VT" => "Vermont",
	"VA" => "Virginia",
	"WA" => "Washington",
	"WI" => "Wisconsin",
	"WV" => "West Virginia",
	"WY" => "Wyoming",
	"TY" => "Yukon Territory"
	);
my $allCityString = "All Cities";


# =====================================================================
# =====================================================================
#
#
# Code starts here!
#
#
# =====================================================================
# =====================================================================

	print "Begin code<BR>\n" if ($debug);
	# get ENV values from scripts that generate static pages
	$SkipQuery = @ENV{SkipQuery};
	$SkipQuery = 0 if ($SkipQuery eq "");
	$INACIndex = @ENV{INACIndex};
	$INACIndex = 0 if ($INACIndex eq "");
#	$listNCAAwards = @ENV{NCAAwards};
#	$listNCAAwards = 0 if ($listNCAAwards eq "");
	$PhotoShows = @ENV{PhotoShows};
	$PhotoShows = getEnvField("PhotoShows") if ($PhotoShows eq "");
	$PhotoShows = 0 if ($PhotoShows eq "");
	$RecentUpdates = @ENV{RecentUpdates};
	$RecentUpdates = 0 if ($RecentUpdates eq "");
	$Awards = @ENV{Awards};
	$Awards = 0 if ($Awards eq "");
	$Condensed = @ENV{Condensed};
	$livePage = 0;

	$domestic = 0;
	$international = 0;
	$lost = 0;
	print "Testing for file domestic.txt<BR>\n" if ($debug);
	if (-f "domestic.txt") {
		$domestic = 1;
		$htmlDir = $docRoot . "/census";
		$stateTitleText = "State or Province";
		$allStateTitle = "All States and Provinces";
		}
	elsif (-f "international.txt") {
		$international = 1;
		$htmlDir = $docRoot . "/IntCensus";
		$stateTitleText = "To Be Determined";
		$allStateTitle = "To Be Determined";
		}
	elsif (-f "lost.txt") {
		$lost = 1;
		$htmlDir = $docRoot . "/LostCensus";
		$stateTitleText = "State and City";
		$allStateTitle = $allCityString;
		}
	if ($debug) {
		print "<BR><BR><BR><BR>Census type: ";
		print $domestic ? "Domestic" : $international ? "International" : $lost ? "Lost" : "Unknown";
		print "<BR>\n";
		}
	# get incoming field values
	loadFields();
	$stateToMatch = "" if $stateToMatch =~ "^All ";
	$dateToMatch = "" if $dateToMatch =~ "^Any ";
	$classToMatch = "" if $classToMatch =~ "^All ";
	$BOToMatch = "" if $BOToMatch =~ "^Any ";
	$manufToMatch = "" if $manufToMatch =~ "^Any ";
	if ($stateToMatch =~ /,/) {
		# non-javascript browsers will return STATE, City
		@cityState = split/,/, $stateToMatch, 2;
		$stateToMatch = @cityState[0];
		$stateToMatch = $statenames{$stateToMatch} if (length($stateToMatch) == 2);
		$cityToMatch = @cityState[1];
		$cityToMatch =~ s/^\s+//;
		$selectedState = $stateToMatch;
		$selectedCity = $cityToMatch;
		print "State, City cleaned to $stateToMatch, $cityToMatch<BR>\n" if ($debug);
		}

	print "Parsing CSV File<BR>\n" if ($debug);
	if (!parseCSVFile()) {
		print "Can't parse the database file: $censusFile\n";
		exit(1);
		}
	print "Returned from parsing CSV file<BR>\n" if ($debug);
	if ($show1Field) {
		print "show1Field=$show1Field, Exiting<BR>\n" if ($debug);
		exit(0);
		}

	# display debug values for incoming data
	if ($debug > 1) {
		print "<H3>Incoming values</H3>\n";
		foreach $key ($qdata->param) {
			$val = getEnvField($key);	# the getEnvField func will print the value
			}
		}

	if ($stateToMatch eq "") {
		# an option to generate a static file for 1 state?
		# to be submitted to a search engine
		$stateToMatch = @ENV{stateToMatch};
		$stateToMatch = @statenames{$stateToMatch};
		$DisplayButton = "Display" if $stateToMatch ne "";
		}
	if ($classToMatch eq "") {
		# an option to generate a static file for 1 class?
		$classToMatch = @ENV{classToMatch};
		$DisplayButton = "Display" if $classToMatch ne "";
		}
	print "<BR><BR><BR><BR>State: $stateToMatch<BR>City: $cityToMatch<BR>Date: $dateToMatch<BR>Sort: $sortToMatch<BR>BO: $BOToMatch<BR>MANU: $manufToMatch<BR>CLASS: $classToMatch<BR>DisplayButton: $DisplayButton<BR>\n" if $debug;

	$dynamicPage = 0;	# static page requests have SkipContentType set, dynamic pages don't
	if (@ENV{SkipContentType} eq "") {
		$dynamicPage = 1;
		}
	if ($NCANoToMatch ne "") {
		# the single census page
		$hdrFile = "$ssiDir/SingleCensusHdr.html";
		$SkipQuery = 1;
		}
	elsif ($Awards) {
		$hdrFile = "$headerDir/census-awards.html";
		}
	elsif ($INACIndex) {
		$hdrFile = "$headerDir/census-INAC.html";
		}
	elsif ($PhotoShows) {
		$hdrFile = "$headerDir/census-psp.html";
		}
	elsif ($classToMatch eq "CLA") {
		if ($Condensed) {
			$hdrFile = "$headerDir/census-cCLA.html";
			}
		else {
			$hdrFile = "$headerDir/census-CLA.html";
			}
		}
	elsif ($classToMatch eq "Classic Metal") {
		if ($Condensed) {
			$hdrFile = "$headerDir/census-cMETAL.html";
			}
		else {
			$hdrFile = "$headerDir/census-METAL.html";
			}
		}
	elsif ($classToMatch eq "New Wood") {
		if ($Condensed) {
			$hdrFile = "$headerDir/census-cNEW.html";
			}
		else {
			$hdrFile = "$headerDir/census-NEW.html";
			}
		}
	else {
		$hdrFile = "$headerDir/census-query.html";
		$livePage = 1;
		}
	print "Header file: $hdrFile<BR>\n" if ($debug);
	# display the NCA header
	open(HEADER, "<$hdrFile") || die "Can't open header file '$hdrFile'!\n";
	while (<HEADER>) {
		if (/\!CENSUSPANEL/) {
			showForm();
			}
		elsif (/\!UPDATEDATE/) {
			$date = getDBDate();
			print "Updated $date<BR>\n";
			}
		elsif ($_ =~ /include virtual=/) {
			if ($livePage) {
				includeFile($_, "Query our Census Database");
				}
			else {
				print $_;
				}
			}
		elsif ($_ =~ /<!--#echo\s+var="WindowTitle"-->/) {
			s/<!--#echo\s+var="WindowTitle"-->/Census Entry/;
			print $_;
			}
		else {
			if ($SkipQuery == 0) {
				s/\<\/title\>/ - Operating North American Carousels\<\/title\>/i if ($domestic);
				s/\<\/title\>/ - Lost North American Carousels\<\/title\>/i if ($lost);
				s/\<\/title\>/ - Operating International Carousels\<\/title\>/i if ($international);
				}
			print $_;
			}
		}
	close HEADER;
	showForm() if (! $SkipQuery);
	if ($INACIndex) {
		# build the Index of North American Carousels
		showINACIndex();
		}
	elsif ($PhotoShows) {
		# Photo show page
		showPhotoShows();
		}
	elsif ($Awards) {
		defaultPage();
		}
	elsif ($DisplayButton ne "" || $NCANoToMatch ne "") {
		print "Request for query<BR>\n" if $debug;
		# request to display a set of carousels
		showCarousels($stateToMatch, $BOToMatch, $manufToMatch, $dateToMatch, $classToMatch, $NCANoToMatch, $cityToMatch);
#			}
		}
#	else {
#		defaultPage();
#		}
makeManuf();

# print qq|<DIV ALIGN="CENTER"><input type="button" value="Close This Window" onclick="window.close()"</DIV><BR>\n|;
# Show the NCA footer
if ($dynamicPage == 1) {
	open(FOOTER, "<$ssiDir/SingleCensusFooter.html");
	while (<FOOTER>) {
		print $_;
		}
	}
else {
	print qq|<!--#include virtual="/ssi/SingleCensusFooter.html"-->\n|;
	}
exit(0);


sub showForm
{
	print "<FONT FACE='ARIAL'>\n";

	print qq|<FORM METHOD='POST' NAME='Query'>\n|;

	print "<HR>\n";
	print "<TABLE>\n";
	print qq|<TR><TD VALIGN='TOP' WIDTH="30%">\n|;
	print "To display a list of carousels, select one or more of these options, then click the <I>Display Carousels</I> button.<P>To get a printable listing, click the <I>Condensed Listing</I> checkbox before clicking the display button.<BR><BR>\n";
	print qq|</TD><TD WIDTH="70%"><TABLE>|;

	ClassPickList();
	StatePickList();
	CityPickList() if ($lost || 1);
	ManuPickList();
	BOPickList();
	DatePickList();
	# SortPickList() if ($lost);
	htmlCheckBox("<FONT SIZE='-1'>Condensed Listing</FONT>", "Condensed", $Condensed);

	# submission button
	print "<TR><TD>&nbsp;</TD><TD>\n";
	print "<INPUT TYPE='SUBMIT' NAME='DisplayButton' VALUE='Display Carousels'>\n";
	print "</TD></TR>\n";

	print "</TABLE></TD></TR></TABLE>\n";
	print"</FORM>\n";
	print"</FONT>\n";
}

sub parseDateRange
{
	my $range = @_[0];
	my $startDate;
	my $endDate;

	print "parseDateRange, analyzing: $range<BR>\n" if $debug;
	if ($range =~ /Before 1900/i) {
		$startDate = 0;
		$endDate = 1899;
		}
	elsif ($range =~ /1950-Current/i) {
		$startDate = 1950;
		$endDate = 9999;
		}
	else {
		$range =~ /(\d\d\d\d)-(\d\d\d\d)/;
		$startDate = $1;
		$endDate = $2;
		}
	print "parseDateRange, returning: $startDate to $endDate<BR>\n" if $debug;
	($startDate, $endDate);
}


sub showQueryTitle {
	my $selectedState = @_[0];
	my $selectedBO = @_[1];
	my $selectedManuf = @_[2];
	my $selectedDate = @_[3];
	my $selectedClass = @_[4];
	my $selectedCity = @_[5];

	return if ($NCANoToMatch ne "");	# only the facts, no fluff

	# count the query fields
	$qFlds = 0;
	$qFlds++ if $selectedBO ne "";
	$qFlds++ if $selectedDate ne "";
	$qFlds++ if $selectedState ne "";
	$qFlds++ if $selectedManuf ne "";
	print "Displaying header for $qFlds selected query values<BR>\n" if $debug;

	print qq|<BR><HR>\n|;
	print qq|<DIV ALIGN="CENTER">\n|;
	print qq|<STRONG>Query Results</STRONG><BR>\n|;
	print qq|<STRONG>\n|;

	# display the selected class
	if ($selectedClass eq "") {
		print qq|All Carousel Classes<BR>\n|;
		}
	else {
		print qq|Carousel Class: $selectedClass<BR>\n|;
		}
	# display the selected state
	if ($selectedState eq "") {
		print qq|$allStateTitle<BR>\n| if (!$lost);
		}
	else {
		if ($selectedCity eq "") {
			print qq|$stateTitleText: $selectedState<BR>\n|;
			}
		else {
			print qq|City and State: $selectedCity, $selectedState<BR>\n|;
			}
		}
	if ($selectedManuf) {
		print qq|Manufacturer: $selectedManuf<BR>\n|;
		}
	if ($selectedBO) {
		print qq|Band Organ: $selectedBO<BR>\n|;
		}
	if ($selectedDate) {
		print qq|Date Range: $selectedDate<BR>\n|;
		}
	if ($Condensed) {
		print qq|Condensed Listing<BR>\n|;
		condensedKey();
		}
	print qq|</STRONG>\n|;
	print "$selCount of $recCount carousels matched your request<BR>\n" if ($selCount > 0);;
	$dispDate = "(Census last updated on " . getDBDate() . ")";
	print qq|$dispDate<BR>\n|;
	print qq|</DIV>\n|;
	showJumpTags($selectedState, $selectedBO, $selectedManuf, $selectedDate, $selectedClass, $selectedCity);
}

sub showJumpTags
{
	my $selectedState = @_[0];
	my $selectedBO = @_[1];
	my $selectedManuf = @_[2];
	my $selectedDate = @_[3];
	my $selectedClass = @_[4];
	my $selectedCity = @_[5];

	$classicCount = 0;
	$metalCount = 0;
	$newCount = 0;
	$categoryCount = 0;
	print "Testing for Jump tags <BR>\n" if $debug;
	print "state: $selectedState<BR>\n" if $debug;
	foreach $key (keys %StateRecs) {
		splitCensusRec($NCARecs{$StateRecs{$key}});
		if (testCarousel($selectedState, $selectedBO, $selectedManuf, $selectedDate, $selectedClass, $selectedCity)) {
			if ($Sort_Class =~ /CLA/i) {
				if ($classicCount == 0) {
					$categoryCount++;
					}
				$classicCount++;
				print "Classic Wood, category count = $categoryCount<BR>\n" if $debug;
				}
			elsif ($Sort_Class =~ /METAL/i) {
				if ($metalCount == 0) {
					$categoryCount++;
					}
				$metalCount++;
				print "Classic Metal, category count = $categoryCount<BR>\n" if $debug;
				}
			else {
				if ($newCount == 0) {
					$categoryCount++;
					}
				$newCount++;
				print "New Wood, category count = $categoryCount<BR>\n" if $debug;
				}
			}
		}

	if ($categoryCount > 1) {
		$totCount = $classicCount + $metalCount + $newCount;
		print "<DIV ALIGN='CENTER'>\n";
		# print "<STRONG>$totCount carousels matched this query</STRONG><BR>\n";
		print "<HR>Results were returned for the following carousel classes:<BR>\n";
		if ($classicCount > 0) {
			print "&nbsp;&nbsp;<A HREF='#CLASSIC'>Classic Wood Carousels ($classicCount)</A>&nbsp;&nbsp;\n";
			if ($metalCount > 0 || $newCount > 0) {
				print "|";
				}
			}
		if ($metalCount > 0) {
			print "&nbsp;&nbsp;<A HREF='#METAL'>Classic Metal Carousels ($metalCount)</A>&nbsp;&nbsp;\n";
			if ($newCount > 0) {
				print "|";
				}
			}
		if ($newCount > 0) {
			print "&nbsp;&nbsp;<A HREF='#NEW'>New Wood Carousels ($newCount)</A>&nbsp;&nbsp;\n";
			}
		print "<P></DIV><HR><BR>\n";
		}
}



sub showCarousels
{
	my $selectedState = @_[0];
	my $selectedBO = @_[1];
	my $selectedManuf = @_[2];
	my $selectedDate = @_[3];
	my $selectedClass = @_[4];
	my $selectedNCANo = @_[5];
	my $selectedCity = @_[6];
	my $lastState = "";
	my $recordsDisplayed = 0;
	my $startDate = 0;
	my $endDate = 0;

	($startDate, $endDate) = parseDateRange($selectedDate) if ($selectedDate ne "");
	print "Date Range in showCarousels: $startDate, $endDate<BR>\n" if ($selectedDate ne "" && $debug);

	if ($debug) {
		print "showCarousels:<BR>\n";
		print "Matching state: '$selectedState'<BR>\n";
		print "Matching Manufacturer: '$selectedManuf'<BR>\n";
		print "Matching Band Organ: '$selectedBO'<BR>\n";
		print "Matching date range: '$startDate to $endDate'<BR>\n";
		print "Matching NCA Number: '$selectedNCANo'<BR>\n";
		}

	# count the records
	($selCount, $recCount) = countCarousels($selectedState, $selectedBO, $selectedManuf, $selectedDate, $selectedClass, $selectedNCANo, $selectedCity);

	showQueryTitle($selectedState, $selectedBO, $selectedManuf, $selectedDate, $selectedClass, $selectedCity);
	foreach $key (sort CountryClassKeyCmp keys %CountryClassRecs) {
		print "Checking key: $key<BR>\n" if $debug;
		splitCensusRec($NCARecs{$CountryClassRecs{$key}});
		if (testCarousel($selectedState, $selectedBO, $selectedManuf, $selectedDate, $selectedClass, $selectedNCANo, $selectedCity)) {
			# see if the class has changed
			if ($Sort_Class ne $lastclass) {
				classTitle($Sort_Class, 1);
				$lastclass = $Sort_Class;
				}
			# if ($lost) {
			if ($Census_List_Type eq "def") {
				$sortState = getLostSortState();
				}
			else {
				$sortState = stripQuotes($P_State);
				}
			print "sortState = $sortState, lastState=$lastState<BR>\n" if ($debug);
			if ($sortState ne $lastState) {
				stateTitle($statenames{$sortState}, $sortState);
				print "Display carousel: $sortState<BR>\n" if $debug;
				$lastState = $sortState;
				$lastclass = $Sort_Class;
				$newState = 1;
				}
			showACarousel();
			$recordsDisplayed++;
			}
		}
	print "<DIV ALIGN='CENTER'>\n";
	if ($NCANoToMatch eq "") {
		if ($recordsDisplayed > 0) {
			print "$recordsDisplayed of $recordCount carousels matched your request<BR>\n";
			print "Important Note: NCA census information may not be reproduced in any form<BR>without the express written consent of the National Carousel Association.<BR>\n";
			}
		else {
			print "There are no records in our database that match your request\n";
			}
		}
	print "</DIV>\n";
}

#
# testCarousel -	return 1 if the carousel matches the query
#					return 0 if the carousel doesn't match the query
#
sub testCarousel
{
	my $selectedState = @_[0];
	my $selectedBO = @_[1];
	my $selectedManuf = @_[2];
	my $selectedDate = @_[3];
	my $selectedClass = @_[4];
	my $selectedNCANo = @_[5];
	my $selectedCity = @_[6];
	my $music;
	my $BOAbbrev;
	my $startDate, $endDate;

	if ($selectedNCANo ne "") {
		# only one carousel will match, return if it doesn't
		print "Comparing NCA number: $selectedNCANo and $NCA_No<BR>\n" if $debug;
		if ($selectedNCANo == $NCA_No) {
			return(1);
			}
		return(0);
		}
	if ($selectedBO ne "") {
		# has to match the selected band organ
		if ($BOToMatch ne "") {
			$BOAbbrev = $BOAbbrevs{$selectedBO};
			print "Matching abbreviation '$BOAbbrev' from name '$BOToMatch'<BR>\n" if $debug;
			}
		$music = makeMusic();
		if (!($music =~ /$BOAbbrev/i)) {
			print "REJECT BAND ORGAN: '$BOAbbrev' doesn't match '$music'<BR>\n" if $debug > 1;
			return(0);
			}
		else {
			print "MATCH BAND ORGAN: '$BOAbbrev' and '$music'<BR>\n" if $debug;
			}
		}

	if ($selectedManuf ne "") {
		# has to match the selected manufacturer
		if (!($Description =~ /$selectedManuf/i)) {
			print "REJECT MANUFACTURER: '$selectedManuf' and '$Description'<BR>\n" if $debug > 1;
			return(0);
			}
		else {
			print "MATCH MANUFACTURER: '$selectedManuf' and '$Description'<BR>\n" if $debug;
			}

		}

	if ($selectedDate ne "") {
		($startDate, $endDate) = parseDateRange($selectedDate);
		$testYear = $YR_Built;
		$testYear =~ s/\?//g;	# remove question marks
		$testYear =~ s/'s//g;	# remove 's (eg. 1890's)
		$testYear =~ s/s$//g;	# remove s at the end (eg. 1890s)
		$testYear =~ s/c\.//;	# remove c. (Example: c.1945)
		$testYear =~ s/ //g;	# remove spaces

		if ($testYear =~ /(\d\d\d\d)/) {
			$yearBuilt = $1;
			if ($yearBuilt < $startDate || $yearBuilt > $endDate) {
				print "REJECT YEAR: $yearBuilt and range $startDate to $endDate<BR>\n" if $debug;
				return(0);
				}
			else {
				print "MATCH YEAR: $yearBuilt and range $startDate to $endDate<BR>\n" if $debug;
				}
			}
		else {
			# can't qualify in a date range if it doesn't have a
			# usable date
			return(0);
			}
		}

	# if ($lost) {
	if ($Census_List_Type eq "def") {
		$shortState = findStateAbbrev($stateToMatch);
		print "Comparing $shortState, $cityToMatch with $OL_State,$Second_Loc_State,$Third_Loc_State<BR>\n" if ($debug);
		if ($cityToMatch eq "" || $cityToMatch eq $allCityString) {
			if ($stateToMatch eq "" ||
				$OL_State eq $shortState         ||
				$Second_Loc_State eq $shortState ||
				$Third_Loc_State eq $shortState  ||
				$Fourth_Loc_State eq $shortState ||
				$Fifth_Loc_State eq $shortState  ||
				$Sixth_Loc_State eq $shortState  ||
				$Seventh_Loc_State eq $shortState||
				$Eighth_Loc_State eq $shortState) {
				print "MATCH CITY: '$cityToMatch, shortState' matches one or more locations($OL_City, $Second_Loc_City, $Third_Loc_City, $Fourth_Loc_City, $Fifth_Loc_City, $Sixth_Loc_City, $Seventh_Loc_City, $Eighth_Loc_City)'<BR>\n" if $debug > 1;
				}
			else {
				# don't want this city
				print "REJECT CITY (1): No locations match '$cityToMatch,$shortState' ($OL_City, $Second_Loc_City, $Third_Loc_City, $Fourth_Loc_City, $Fifth_Loc_City, $Sixth_Loc_City, $Seventh_Loc_City, $Eighth_Loc_City)'<BR>\n" if $debug > 1;
				return(0);
				}
			}
		else {
			if (($OL_City          eq $selectedCity && $OL_State eq $shortState)         ||
				($Second_Loc_City  eq $selectedCity && $Second_Loc_State eq $shortState) ||
				($Third_Loc_City   eq $selectedCity && $Third_Loc_State eq $shortState)  ||
				($Fourth_Loc_City  eq $selectedCity && $Fourth_Loc_State eq $shortState) ||
				($Fifth_Loc_City   eq $selectedCity && $Fifth_Loc_State eq $shortState)  ||
				($Sixth_Loc_City   eq $selectedCity && $Sixth_Loc_State eq $shortState)  ||
				($Seventh_Loc_City eq $selectedCity && $Seventh_Loc_State eq $shortState)||
				($Eighth_Loc_City  eq $selectedCity && $Eighth_Loc_State eq $shortState)) {
				print "MATCH CITY: '$selectedCity' matches one or more locations($OL_City, $Second_Loc_City, $Third_Loc_City, $Fourth_Loc_City, $Fifth_Loc_City, $Sixth_Loc_City, $Seventh_Loc_City, $Eighth_Loc_City)'<BR>\n" if $debug > 1;
				}
			else {
				# don't want this city
				print "REJECT CITY (2): No locations match '$selectedCity,$shortState' ($OL_City, $Second_Loc_City, $Third_Loc_City, $Fourth_Loc_City, $Fifth_Loc_City, $Sixth_Loc_City, $Seventh_Loc_City, $Eighth_Loc_City)'<BR>\n" if $debug > 1;
				return(0);
				}
			}
		}
	else {
		# Current park location has to match the selected state
		$thisState = $statenames{$P_State};
		if ($selectedState eq "" || $thisState eq $selectedState) {
			print "MATCH STATE: '$selectedState' and '$thisState'<BR>\n" if $debug;
			}
		else {
			# don't want this state
			print "REJECT STATE: '$thisState' and '$selectedState'<BR>\n" if $debug > 1;
			return(0);
			}
		}

	if ($selectedClass ne "") {
		# has to match the selected class
		$checkClass = "CLA";
		$checkClass = "METAL" if ($selectedClass =~ /Classic Metal/i);
		$checkClass = "NEW" if ($selectedClass =~ /New Wood/i);
		if (substr($Sort_Class, 0, length($checkClass)) =~ /$checkClass/i) {
			print "MATCH CLASS: '$Sort_Class' and '$checkClass'<BR>\n" if $debug;
			}
		else {
			# don't want this class
			print "REJECT CLASS: '$Sort_Class' and '$checkClass'<BR>\n" if $debug > 1;
			return(0);
			}
		}

	return(1);
}


sub showACarousel
{
	if ($Condensed) {
		# line 1 - Carousel identification
		$showName = "";
		$showName = "$Carousel_Name, " if $Carousel_Name ne "";
		$showPark = "";
		$showPark = "$Park, " if $Park ne "";
		$showClass = "$Sort_Class, " if $Sort_Class ne "";
		$curStat = "";
		$curStat = "$Status-" if ($Status ne "" && !($Status =~ /ACTIVE/i));
#		print "<P>";
		print "<B>$showName$showPark";
		if ($P_State eq "DC") {
			print "District of Columbia;";
			}
		else {
			print "$P_City, " if $P_City ne "";
			print "$P_State";
			}
		print "</B> $P_Phone <B>[$curStat$Updated]</B><BR>\n";

		# The Rest!
		print "<B>";
		print "$Description, \n" if $Description ne "";
		print "$YR_Built, \n" if $YR_Built ne "";
		print "$Sort_Class, \n" if $Sort_Class ne "";
		print "W&M,\n" if ($Comp =~ /WOOD \& METAL/);
		print "$Row row, \n" if $Row > 0;
		$Platform =~ s/Jumping//;	# skip the common jumping platform
		print "$Platform, \n" if $Platform ne "";
		print "$Type, \n" if $Type ne "";
		print "</B>\n";
		print "$J_Horses j, " if $J_Horses > 0;
		print "$S_Horses s, " if $S_Horses > 0;
#		$Menag_Total = $J_Menag + $S_Menag;
		print "$Menag_Total m, " if $Menag_Total > 0;
		if ($Menagerie_Type ne "") {
			if (length($Menagerie_Type) > 60) {
				$findComma = 55;
				while ($findComma < length($Menagerie_Type) &&
					substr($Menagerie_Type, $findComma, 1) ne ",") {
					$findComma++;
					}
				print substr($Menagerie_Type, 0, $findComma);
				print ",<BR>\n";
				if ($findComma < length($Menagerie_Type)) {
					print substr($Menagerie_Type, $findComma + 1);
					}
				print ", ";
				}
			else {
				print "$Menagerie_Type, " if $Menagerie_Type ne "";
				}
			}
		print "$Chariots ch, " if $Chariots > 0;
		print "$Tubs tub, " if $Tubs > 0;
#		print "$Music, " if $Music ne "";
		print "$BO_Description, " if $BO_Description ne "";

		# misc values
		print "Rings, " if ($Ring_Oper =~ /yes/i);
		print "OL, " if ($Orig_Loc =~ /yes/i);
		if ($NHL =~ /yes/i) {
			if ($NHL_Year > 0) {
				print "NHL $NHL_Year, ";
				}
			else {
				print "NHL, ";
				}
			}
		if ($NRHP =~ /yes/i) {
			if ($NRHP_Year > 0) {
				print "NRHP $NRHP_Year, ";
				}
			else {
				print "NRHP, ";
				}
			}
		if ($NCA_Hist_Award =~ /yes/i) {
			if ($NCA_Hist_Award_Yr > 0) {
				print "NCA Hist Award $NCA_Hist_Award_Yr, ";
				}
			else {
				print "NCA Hist Award, ";
				}
			}
		
		# General comments
		if ($Gen_Comment ne "") {
			print "<B>Comments:</B> $Gen_Comment \n";
			}

		# History
		if ($hist = makeHist(1)) {
			print "<B>History: </B>$hist \n";
			}

		if ($Directions_And_Operating_times ne "") {
			print "<B>Directions & Hours of Operation: </B>$Directions_And_Operating_times ";
			}
		
		# mailing address
		if ($M_Addr ne "" || $M_City ne "") {
			print "<B>Mailing Address: </B>";
			print "$M_Address, " if $M_Address ne "";
			if ($M_State eq "DC" ) {
				print "District of Columbia, ";
				}
			else {
				print "$M_City, " if $M_City ne "";
				print "$M_State, " if $M_State ne "";
				}
			print "$M_Zip " if $M_Zip ne "";
			}

		# website
		if ($P_Web_Site ne "") {
			if ($P_Web_Site =~ /^http/) {
				$URL = "<A HREF='$P_Web_Site' target='_blank' scrollbars='no'>$P_Web_Site</A>";
				}
			else {
				$URL = "<A HREF='http://$P_Web_Site' target='_blank' scrollbars='no'>$P_Web_Site</A>";
				}
			print "<B>Website: </B> $URL ";
			}
#		print "</P>\n";
		print "<BR><BR>\n";
		return;

		}
	if ($domestic) {
		if ($P_State eq "DC") {
			bulletTitle($Carousel_Name, $Park, "District of Columbia", 65);
			}
		else {
			$cityStateTitle = "$P_City, $P_State";
			if ($cityToMatch ne "") {
				# city was selected, matching on city plus state
				if ($cityToMatch ne $P_City || $stateToMatch != $P_State) {
					# current park city and state don't match selected city and state, this carousel
					# previously operated in the selected city and state
					$cityStateTitle .= "<BR>Previously operated in $cityToMatch, " . findStateAbbrev($stateToMatch);
					}
				}
			bulletTitle($Carousel_Name, $Park, "$cityStateTitle", 65) if $P_City ne "";
			bulletTitle($Carousel_Name, $Park, "$P_State", 65) if $P_City eq "";
			}
		}
	else {
		if ($newState == 1) {
			$newState = 0;
			}
		else {
			print "<BR><HR><BR>\n";
			}
		}

	print "<TABLE CELLPADDING='2'>\n";

	# build the history info
	$longHist = makeLongHistory();
	showField("History", $longHist) if ($lost);

	# Description
	showField("Carousel Name", $Carousel_Name);
	showField("Park", $Park);
	# showField("City/State", $P_City . ", " . $P_State) if ($P_City ne "");
	# showField("State", $P_State) if ($P_City eq "");
	$showDesc = $Description;
	showField("Description", $showDesc);

	# carousel class
	$showClass = "";
	if ($Sort_Class ne "") {
		$showClass = $Sort_Class;
		$showClass =~ s/CLA/Classic Wood Carousel/i;
		$showClass =~ s/New/New Wood Carousel/i;
		$showClass =~ s/METAL/Classic Metal Carousel/i;
		}
	showField("Carousel Class", $showClass) if $showClass ne "";

	# Last updated, status
	showField("Last Update", $Updated);

	# Status
	$Status = stripQuotes($Status);
	$Status =~ s/PAR-ACT/Partially Active/;
	$Status =~ s/IN-RESTO/In Restoration/;
	$Status =~ s/ACTIVE/Active/;
	$Status =~ s/NEW-CONS/New Construction/;
	$Status =~ s/PRIVATE/Privately Owned/;
	$Status =~ s/T-STOR/Temporary Storage/;
	showField("Status", $Status);

	# Model
	showField("Model", stripQuotes($Model));

	# Year Built
	showField("Year Built", $YR_Built);

	# Type
 	$type = ($Row > 0) ? "$Row rows" : "Unknown rows";
 	$type .= ", $Type" if $Type ne "";
	$Platform = stripQuotes($Platform);
	$Platform =~ s/Jumping//;	# don't bother with the too-common jumping platforms
	$Platform =~ s/Sus\/Swing/Suspended Swing/;
	$Platform =~ s/STA/Stationary/;
	$type .= ", $Platform" if $Platform ne "";
	$Comp = stripQuotes($Comp);
	$Comp =~ s/ALL WOOD/All Wood composition/;
	$Comp =~ s/FIBERGLASS/Fiberglass/i;
	$Comp =~ s/METAL/Metal composition/;
	$Comp =~ s/WOOD/Wood/;
	$Comp =~ s/METAL/Metal/;
	$Comp =~ s/\&/and/;
	$type .= ", $Comp" if $Comp ne "";
	$Class_Type = stripQuotes($Class_Type);
	$Class_Type =~ s/CLA/Classical Construction/;
	$Class_Type =~ s/NEW/New Construction/;
	$type .= ", $Class_Type" if $Class_Type ne "";
	showField("Type", stripQuotes($type));

	# Description
	# This pretty well duplicates the manufacturer and model information,
	# so I've removed it
	#	showField("Description", stripQuotes($Description));

	# Figures
	$figures = "";
	if ($J_Horses > 0) {
		$figures .= ", " if $figures ne "";
		$figures .= "$J_Horses Jumping Horse";
		$figures .= "s" if $J_Horses > 1;
		}
	if ($S_Horses > 0) {
		$figures .= ", " if $figures ne "";
		$figures .= "$S_Horses Standing Horse";
		$figures .= "s" if $S_Horses > 1;
		}
	if ($J_Horses == 0 && $S_Horses == 0 && $Horse_Tot > 0) {
		$figures .= ", " if $figures ne "";
		$figures .= "$Horse_Tot Horse";
		$figures .= "s" if $Horse_Tot > 1;
		}
#	$Menag_Total = $J_Menag + $S_Menag;
	if ($Menag_Total > 0) {
		$figures .= ", " if $figures ne "";
		$figures .= "$Menag_Total Menagerie Animal";
		$figures .= "s" if $Menag_Total > 1;
		if ($Menagerie_Type ne "") {
			$Menagerie_Type = expandMenagerie($Menagerie_Type);
			$figures .= " $Menagerie_Type";
			}
		}
	if ($Chariots > 0) {
		$figures .= ", " if $figures ne "";
		$figures .= "$Chariots chariot";
		$figures .= "s" if $Chariots > 1;
		}
	if ($Tubs > 0) {
		$figures .= ", " if $figures ne "";
		$figures .= "$Tubs Tub";
		$figures .= "s" if $Tubs > 1;
		}
	showField("Figures", $figures);

	# Music
		showField("Music", makeMusic()) if ($domestic);
#	showField("Band Organ Comments", $BO_Description);	# this seeme redundant to the Music field



	# notes
	$notes = "";
	$comma = "";
	if ($Ring_Oper =~ /YES/i) {
		$notes = "Operational Ring Arm";
		$comma = ",";
		}
#	if ($Gen_Comment =~ /2LP/i || $Gen_Comment =~ /two[ -]?level/i) {
#		$notes .= "$comma Two-Level Platform";
#		$comma = ",";
#		}
#	if ($Gen_Comment =~ /3-level platform/) {
#		$notes .= "$comma Three-Level Platform";
#		$comma = ",";
#		}
	if ($Orig_Loc =~ /YES/i) {
		$notes .= "$comma Still in original location"; 
		$comma = ",";
		}
	if ($NHL =~ /YES/i) {
		$NHL_Year = int(stripQuotes($NHL_Year));
		$notes .= "$comma Recognized as a National Historic Landmark";
		if ($NHL_Year > 0) {
			$notes .= " - $NHL_Year";
			}
		$comma = ",";
		}
	if ($NRHP =~ /YES/i) {
		$NRHP_Year = int(stripQuotes($NRHP_Year));
		$notes .= "$comma Placed on the National Register of Historic Places";
		if ($NRHP_Year > 0) {
			$notes .= " - $NRHP_Year";
			}
		$comma = ",";
		}
	if ($NCA_Hist_Award =~ /YES/i) {
		$notes .= "$comma Received the NCA Historic Carousel Award";
		if ($NCA_Hist_Award_Yr > 0) {
			$notes .= " - $NCA_Hist_Award_Yr";
			}
		$comma = ",";
		}
	showField("Notes", $notes);


	# General Comments
	showField("Comments", stripQuotes($Gen_Comment));

	# History
	showField("History", $longHist) if ($domestic);

	# Directions and Hours of Operation
	showField("Directions/Hours", $Directions_And_Operating_times) if ($lost == 0);

	# Mailing Address
	$addr = $M_Address;
	if ($M_State eq "DC") {
		$addr .= ", District of Columbia";
		}
	else {
		if ($M_City ne "") {
			$addr .= ", " if $addr ne "";
			$addr .= $M_City;
			}
		if ($M_State ne "") {
			$addr .= ", " if $addr ne "";
			$addr .= $M_State;
			}
		}
	if ($M_Zip ne "") {
		$addr .= ", " if $addr ne "";
		$addr .= $M_Zip;
		}
	showField("Mailing Address", $addr) if ($lost == 0);

	# Phone
	showField("Telephone", $P_Phone) if ($lost == 0);

	# Website
	$URL = "";
	if ($P_Web_Site ne "") {
		if ($P_Web_Site =~ /^http/) {
			$URL = "<A HREF='$P_Web_Site' target='_blank'>$P_Web_Site</A>" if ($P_Web_Site ne "");
			}
		else {
			$URL = "<A HREF='http://$P_Web_Site' target='_blank'>$P_Web_Site</A>";
			}
		}
	showField("Website", $URL);
		

	# NCA Photo Show
	$tableEnded = 0;
if ($NCANoToMatch eq "" || $fromMap ne "") {	# skip it if it's the single entry from the photo show
	$photoDir = "";
	$photoThumb = "";
	$numberFile = "$docRoot/admin/AllCensus/NCANumbers.txt";
	open(NCANO, "<$numberFile") || print "Can't open $numberFile\n";
	while (<NCANO>) {
		chomp;
		@parts = split(/\s+/, $_, 4);
		if (@parts[0] == $NCA_No) {
			# found it
			$photoDir = @parts[1];
			$pspThumb = @parts[2];
			last;
			}
		}
	close(NCANO);
	if ($photoDir ne "" && -d "$pspDir/$photoDir") {
		$pspThumb =~ s/\%20/ /g; # html uses the %20's, file system doesn't
		if ($pspThumb ne "" && -f "$pspDir/$photoDir/$pspThumb") {
			$tableEnded = 1;
			print "</TABLE></UL>\n";
			print "<DIV ALIGN='CENTER'>\n";
			addFile($highlightStartFile);
			print qq|<TD><A HREF="/psp/$photoDir"><IMG SRC='https://$website/psp/$photoDir/$pspThumb' BORDER="0" ALT='Click for NCA Photo Show'><BR>|;
			addFile($highlightEndFile);
			print qq|<A HREF="/psp/$photoDir">|;
			print qq|Click to see the NCA Photo Show for this carousel!\n|;
			print "</A><BR><BR>\n";
			print "</DIV>\n";

			}
		else {
			showField("NCA Photo Show", "<A HREF='https://$website/psp/$photoDir' target='_blank'>https://$website/$photoDir</A>");
			}
		}
}
	# Wrap it up
	print "</TABLE>\n" if (!$tableEnded);
#	print "<HR>\n";
}




sub defaultPage
{
	my	%rings;
	my	%twolev;

	print "Default display page<BR>\n" if $debug;

	# NCA Awards
	$recs = 0;
	print "<A NAME='NCAAward'></A>\n";
	print "<P>\n";

	print "This page lists operating North American carousels that have received awards and carousels that include special features.  Select one of the links below to jump to a specific category.<BR><BR>\n";

	print qq|<DIV ALIGN="CENTER">\n|;
	print qq|<A HREF="#HIST">Carousels That Have Received the NCA Historic Carousel Award</A>&nbsp;&nbsp;&nbsp;\|&nbsp;&nbsp;&nbsp;\n|;
	print qq|<A HREF="#NRHP">Carousels in the National Register of Historic Places</A><BR><BR>\n|;
	print qq|<A HREF="#NHL">Carousels Listed as National Historic Landmarks</A>&nbsp;&nbsp;&nbsp;\|&nbsp;&nbsp;&nbsp;\n|;
	print qq|<A HREF="#RINGS">Carousels With Operating Ring Arms</A>&nbsp;&nbsp;&nbsp;\|&nbsp;&nbsp;&nbsp;\n|;
	print qq|<A HREF="#OL">Carousels In Original Location</A><BR>\n|;
	print qq|</DIV><BR><BR>\n|;

	foreach $key (sort keys %NCAAwardRecs) {
		if ($recs == 0) {
			print qq|<A ID="HIST"></A>\n|;
			bulletTitle("Carousels That Have Received the NCA Historic Carousel Award", "", "", 95);

print <<ENDBLURB;
<P>
<DIV ALIGN="CENTER">
<TABLE WIDTH="80%" BORDER="1" CELLPADDING="4"><TR><TD>
Note: The NCA Historic Carousel Award is given to recognize carousels that meet the following criteria:
<UL>
<LI>Historic significance 
<LI>Innate quality or character 
<LI>A proven program of restoration and maintenance 
<LI>A regular schedule of operation 
<LI>An owner or support group likely to ensure that the carousel will continue to be available to the public as an operating machine 
</UL>
</TD></TR></TABLE>
</DIV>
<P>
ENDBLURB
			print "<TABLE WIDTH='100%'><TR><TD VALIGN='TOP' WIDTH='50%'><UL>\n";
			}
		splitCensusRec($NCARecs{$NCAAwardRecs{$key}});
		if ($recs == int(($NCAAwardCount + 1) / 2)) {
			print "</UL></TD><TD VALIGN='TOP' WIDTH='50%'><UL>\n";
			}
		print "<LI><B>$NCA_Hist_Award_Yr</B><BR>\n";
		print qq|<B><A HREF="javascript:censusWindow($NCA_No)">$Park</A></B><BR>\n| if ($Park ne "");
		$Description =~ s/&/&amp;/;
		$Carousel_Name =~ s/&/&amp;/;
		print "$Carousel_Name<BR>\n" if ($Carousel_Name ne "");
		print "$P_City, $P_State<BR>\n" if ($P_City ne "" && $P_State ne "");
		if ($Description ne "") {
			print "$Description";
			if ($YR_Built ne "") {
				print ", $YR_Built";
				}
			print "<BR>\n";
			}
		$recs++;
		}
	print "</UL></TD></TR></TABLE>\n";

	# NRHP
	$recs = 0;
	print "<A NAME='RHP'></A><P>\n";
	foreach $key (sort CountryKeyCmp keys %RHP) {
		if ($recs == 0) {
			print qq|<A ID="NRHP"></A>\n|;
			bulletTitle("Carousels Listed in the National Register of Historic Places", "", "", 95);
			print "<P><TABLE WIDTH='100%'><TR><TD VALIGN='TOP' WIDTH='50%'><UL>\n";
			}
		if ($recs == int(($NRHPCount + 1) / 2)) {
			print "</UL></TD><TD VALIGN='TOP' WIDTH='50%'><UL>\n";
			}
		carouselBullet($NCARecs{$RHP{$key}});
		print "Registered: " . int($NRHP_Year) if ($NRHP_Year > 0);
		print "</LI>\n";
		$recs++;
		}
	print "</UL></TD></TR></TABLE>\n";

	# NHL
	$recs = 0;
	print "<A NAME='NHL'></A><P>\n";
	foreach $key (sort CountryKeyCmp keys %landmark) {
		if ($recs == 0) {
			print qq|<A ID="NHL"></A>\n|;
			bulletTitle("Carousels Listed as National Historic Landmarks", "", "", 95);
			print "<P><TABLE WIDTH='100%'><TR><TD VALIGN='TOP' WIDTH='50%'><UL>\n";
			}
		if ($recs == int(($NHLCount + 1) / 2)) {
			print "</UL></TD><TD VALIGN='TOP' WIDTH='50%'><UL>\n";
			}
		carouselBullet($NCARecs{$landmark{$key}});
		print "Listed: " . int($NHL_Year) if ($NHL_Year > 0);
		print "</LI>\n";
		$recs++;
		}
	print "</UL></TD></TR></TABLE>\n";

	# Brass Rings
	$recs = 0;
	print "<A NAME='RINGS'></A><P>\n";
	foreach $key (sort CountryKeyCmp keys %BrassRing) {
		if ($recs == 0) {
			print qq|<A ID="RINGS"></A>\n|;
			bulletTitle("Carousels with Operating Ring Machines", "", "", 95);
			print "<P><TABLE WIDTH='100%'><TR><TD VALIGN='TOP' WIDTH='50%'><UL>\n";
			}
		if ($recs == int(($BrassRingCount + 1) / 2)) {
			print "</UL></TD><TD VALIGN='TOP' WIDTH='50%'><UL>\n";
			}
		carouselBullet($NCARecs{$BrassRing{$key}});
		print "</LI>\n";
		$recs++;
		}
	print "</UL></TD></TR></TABLE>\n";

	# Two-level Platforms
#	$recs = 0;
#	print "<A NAME='2LP'><P>\n";
#	foreach $key (sort CountryKeyCmp keys %TwoLevel) {
#		if ($recs == 0) {
#			bulletTitle("Carousels With Two-Level Platforms", "(Operating pre-$classicCutoffYr machines)", "", 95);
#			print "<P><TABLE WIDTH='100%'><TR><TD VALIGN='TOP' WIDTH='50%'><UL>\n";
#			}
#		if ($recs == int(($TwoLevelCount + 1) / 2)) {
#			print "</UL></TD><TD VALIGN='TOP' WIDTH='50%'><UL>\n";
#			}
#		carouselBullet($NCARecs{$TwoLevel{$key}});
#		print "</LI>\n";
#		$recs++;
#		}
#	print "</UL></TD></TR></TABLE>\n";
	

	# Original Location
	$recs = 0;
	print "<A NAME='OL'></A><P>\n";
	foreach $key (sort CountryKeyCmp keys %OrigLocations) {
		if ($recs == 0) {
			print qq|<ID="OL"></A>\n|;
			bulletTitle("Carousels in Original Location", "", "", 95);
			print "<P><TABLE WIDTH='100%'><TR><TD VALIGN='TOP' WIDTH='50%'><UL>\n";
			}
		if ($recs == int(($OrigLocCount + 1) / 2)) {
			print "</UL></TD><TD VALIGN='TOP' WIDTH='50%'><UL>\n";
			}
		carouselBullet($NCARecs{$OrigLocations{$key}});
		print "</LI>\n";
		$recs++;
		}
	print "</UL></TD></TR></TABLE>\n";
}

sub showField
{
	my $prompt = @_[0];
	my $field = @_[1];
	if ($field ne "") {
		print "<TR><TD ALIGN='RIGHT' VALIGN='TOP'><B><NOBR>$prompt:</NOBR></B></TD><TD VALIGN='TOP'>$field</TD></TR>\n" if $field ne "";
		}

}

sub queryTitle
{
	my $widthPct = @_[2];
	startHighlightTable($widthPct);
	print "<BR>@_[0]\n";
	if (@_[1] ne "") {
		print "<BR>@_[1]\n";
		}
	print "<BR><BR>\n";
	endHighlightTable();
	print "<BR>\n";
}

sub condensedKey
{
	if ($Condensed && ! $keyPrinted) {
		print "<DIV ALIGN='CENTER'>";
print qq|(A list of the abbreviations used on this page is available <a href="#" onClick="window.open('https://$website/census/CondensedKey.html', '','scrollbars=yes, width=750, height=550')" title="Abbreviations">Here</A>)</DIV><P>\n|;
		$keyPrinted = 1;
		return;
		}
	if ($Condensed && ! $keyPrinted) {


		print <<EOKEYTABLE;

<HR>
<DIV ALIGN='CENTER'>
	<TABLE WIDTH='100%' BORDER='2'>
		<TR>
			<TD VALIGN='TOP' COLSPAN='10'>
				<DIV ALIGN='CENTER'>
					<B>Abbreviations and Key Information</B>
				</DIV>
			<TD>
		</TR>
		<TR>
			<!-- Carousel Class -->
			<TD VALIGN='TOP' WIDTH='45%'>
				<DIV ALIGN='CENTER'><B><FONT SIZE='-1'>Carousel Class</FONT></B></DIV>
				<TABLE WIDTH='100%' CELLSPACING='4'>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>CLA</B>
						</TD>
						<TD>
							Classic Wood Carousels<BR>(1800s - 1940s wood and W&M)
						</TD>
					</TR>

					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>METAL</B>
						</TD>
						<TD>
							Classic Metal Carousels (1940s - 1960s)
						</TD>
					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>NEW</B>
						</TD>
						<TD>
							New Wood Carousels (1980 - present)
						</TD>
					</TR>
				</TABLE>
			</TD>

			<!-- Status -->
			<TD VALIGN='TOP'>
				<DIV ALIGN='CENTER'><B>Status</B></DIV>
				<TABLE WIDTH='100%' CELLSPACING='4'>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>[IN-RESTO]</B>
						</TD>
						<TD>
							In restoration - may not be operational
						</TD>
					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>[PAR-ACT]</B>
						</TD>
						<TD>
							Partially active - does not operate regularly
						</TD>
					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>[T-STOR]</B>
						</TD>
						<TD>
							Temporary storage - will return to operation
						</TD>
					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>[TRANS]</B>
						</TD>
						<TD>
							In transition - location change or other situation
						</TD>
					</TR>
					<TR>
						<TD COLSPAN='2'>
							<FONT SIZE='-1'>
								<DIV ALIGN='CENTER'>
									(Carousels in long term storage, dismantled, destroyed &
									confidential status are not listed in the census)
								</DIV>
							</FONT>
						</TD>
					</TR>
				</TABLE>
			</TD>
		</TR>
		<TR>
			<!-- Carousel Figures -->
			<TD VALIGN='TOP'>
				<DIV ALIGN='CENTER'><B>Carousel Figures</B></DIV>
				<TABLE CELLSPACING='4'>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>Alum</B>
						</TD>
						<TD VALIGN='TOP'>
							Aluminum
						</TD>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>sh</B>
						</TD>
						<TD VALIGN='TOP'>
							Standing horses
						</TD>
					</TR>

					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>ch</B>
						</TD>
						<TD VALIGN='TOP'>
							Chariots
						</TD>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>sm</B>
						</TD>
						<TD VALIGN='TOP'>
							Standing menagerie
						</TD>
					</TR>

					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>Fbgl</B>
						</TD>
						<TD VALIGN='TOP'>
							Fiberglass
						</TD>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>W&M</B>
						</TD>
						<TD VALIGN='TOP'>
							Wood & Metal
						</TD>
					</TR>

					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>jh</B>
						</TD>
						<TD VALIGN='TOP'>
							Jumping horses
						</TD>
					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>jm</B>
						</TD>
						<TD VALIGN='TOP'>
							Jumping menagerie
						</TD>
					</TR>
				</TABLE>
			</TD>
			<TD VALIGN='TOP'>
				<!-- Miscellaneous Abbreviations-->
				<DIV ALIGN='CENTER'><B>Miscellaneous Abbreviations</B></DIV>

	<TABLE WIDTH='100%'>
		<TR>
			<TD>
				<TABLE>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>2LP</B>
						</TD>
						<TD>
							2-Level platform
						</TD>
					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>b/o</B>
						</TD>
						<TD>
							band organ
						</TD>
					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>BR</B>
						</TD>
						<TD>
							brass ring
						</TD>
					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>CD</B>
						</TD>
						<TD>
							Compact Disks
						</TD>
					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>NHL</B>
						</TD>
						<TD>
							National Historic Landmark
						</TD>
					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>NRHP</B>
						</TD>
						<TD>
							Natl Register of Historic Places
						</TD>
					</TR>
				</TABLE>
			</TD>
			<TD>
				<TABLE>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>OL</B>
						</TD>
						<TD>
							original location
						</TD>
					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>Port</B>
						</TD>
						<TD>
							portable
						</TD>

					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>STA</B>
						</TD>
						<TD>
							Stationary
						</TD>
					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>unk</B>
						</TD>
						<TD>
							unknown
						</TD>

					</TR>
					<TR>
						<TD ALIGN='RIGHT' VALIGN='TOP'>
							<B>Wurl</B>
						</TD>
						<TD>
							Wurlitzer
						</TD>
					</TR>
				</TABLE>
			</TD>
		</TR>
	</TABLE>
			<TR>
				<TD COLSPAN='10'>
					<DIV ALIGN='CENTER'>
						The date, i.e. [20??], at the end of the first line is the most
						recent update to the file for each carousel.
					</DIV>
				</TD>
			</TR>
		</TABLE>



		</TD></TR></TABLE></DIV><P>
EOKEYTABLE
		$keyPrinted = 1;
		}

}


sub stateTitle
{
	print "stateTitle for state=@_[0]<BR>\n" if ($debug);
	$stateAbbrev = @_[1];
	return if ($NCANoToMatch ne "");	# no fluff if just getting 1 carousel
	$country = "";
	if (makeCountry(@_[1]) eq "Canada") {
		$country = "(Canada)";
		}
	queryTitle(@_[0], "$country", 80) if ($domestic);
	$dispState = $statenames{@_[0]};
	$dispState = "Unknown" if ($dispState eq "");
	queryTitle("State of last known operation: $dispState", "$country", 80) if ($lost);
}

sub classTitle
{
	$class = @_[0];
	$topHR = @_[1];

	return if ($NCANoToMatch ne "");	# no fluff if just getting 1 carousel
	if ($class ne "") {

		if ($class =~ /cla/i) {
			print "<A NAME='CLASSIC'></A>\n";
			startHighlightTable(95);
			print "<BR><FONT SIZE='+1'><B>Classic Wood Carousels (1800s - 1940s Wood and W&M)</B></FONT><BR><BR>";
			endHighlightTable();
			print "<BR>\n";
			}
		elsif ($class =~ /metal/i) {
			print "<A NAME='METAL'></A>\n";
			startHighlightTable(95);
			print "<BR><FONT SIZE='+1'><B>Classic Metal Carousels (1940s - 1960s)</B></FONT><BR><BR>";
			endHighlightTable();
			print "<BR>\n";
			}
		elsif ($class =~ /new/i) {
			print "<A NAME='NEW'></A>\n";
			startHighlightTable(95);
			print "<BR><FONT SIZE='+1'><B>New Wood Carousels (1980 - present)</B></FONT><BR><BR>";
			endHighlightTable();
			print "<BR>\n";
			}
		}
#		print "<BR><BR></FONT></TD></TR></TABLE></DIV>\n";
}

sub bulletTitle
{
	my $title = @_[0];
	my $subTitle = @_[1];
	my $subSubTitle = @_[2];
	my $widthPct = @_[3];
	if ($title eq "") {
		$title = $subTitle;
		$subTitle = $subSubTitle;
		$subSubTitle = "";
		}
	if ($title eq "") {
		$title = $subTitle;
		$subTitle = "";
		}

#	print "<TABLE WIDTH='100%'><TR><TD BGCOLOR='#829C9C' HEIGHT='24'><DIV ALIGN='CENTER'>\n";
	startHighlightTable($widthPct);

	print "<FONT SIZE='+1'>$title</FONT>\n";
	$NCA_No = int($NCA_No);
	print "<BR>NCA #: $NCA_No\n" if $displayNumbers ne "";
	print "<BR><FONT>$subTitle</FONT>\n" if $subTitle ne "";
	print "<BR><FONT>$subSubTitle</FONT>\n" if $subSubTitle ne "";
	endHighlightTable();
#	print "</DIV></TR></TD></TABLE>\n";
}


sub carouselBullet
{
	splitCensusRec(@_[0]);
	$countryToShow = "";
	if (makeCountry($P_State) eq "Canada") {
		$countryToShow = " (Canada)";
		}


	print qq|<LI><B><A HREF="javascript:censusWindow($NCA_No)">$P_City, $P_State$countryToShow</A></B><BR>\n|;
	print "$Park<BR>\n" if ($Park ne "");
	$Carousel_Name =~ s/&/&amp;/;
	print "$Carousel_Name<BR>\n" if $Carousel_Name ne "";
	if ($Description ne "") {
		$Description =~ s/&/&amp;/;
		print "$Description";
		print ", $YR_Built" if ($YR_Built ne "" && !($YR_Built =~ /unk/i));
		print "<BR>";
		}
}

sub ClassPickList
{
	print "<TR><TD ALIGN='RIGHT'><B><FONT SIZE='-1'>Carousel Class:</FONT></B></TD><TD>\n";

	my @sortClasses = (
		"All Carousel Classes",
		"Classic Wood Carousels (1800s - 1940s wood and W&M)",
		"Classic Metal Carousels (1940s - 1960)");
	push @sortClasses, "New Wood Carousels (1980 - present)" if (!$lost);

	$selected = "";
	print "<SELECT NAME='classToMatch'>\n";
	foreach $class (@sortClasses) {
		if ($class eq $classToMatch) {
			print "<OPTION SELECTED>$class</OPTION>\n";
			}
		else {
			print "<OPTION>$class</OPTION>\n";
			}
		}
	print "</SELECT>\n";
	print "</TD></TR>\n";

}


sub DatePickList
{
	print "<TR><TD ALIGN='RIGHT'><B><FONT SIZE='-1'>Manufacture Date:</FONT></B></TD><TD>\n";

	my @dateRanges = (
		"Any Date",
		"Before 1900",
		"1900-1904",
		"1905-1909",
		"1910-1914",
		"1915-1919",
		"1920-1924",
		"1925-1929",
		"1930-1939",
		"1940-1949",
		"1950-Current");

	# date picklist
	$selected = "";
	print "<SELECT NAME='dateToMatch'>\n";
	foreach $date (@dateRanges) {
		if ($date eq $dateToMatch) {
			print "<OPTION SELECTED>$date</OPTION>\n";
			}
		else {
			print "<OPTION>$date</OPTION>\n";
			}
		}
	print "</SELECT>\n";
	print "</TD></TR>\n";
}


sub StatePickList
{
print <<ENDJS;
<SCRIPT TYPE="text/javascript">
<!--
function addSelect(optName, optText, optVal) {
	option0 = new Option(optText,optVal)
	// alert("optName=" + optName + ", optText=" + optText + ", optVal=" + optVal);
	document.Query.cityToMatch.options[optVal] = option0;
	}
function enableCity(stateIndex) {
	// City list is: statename|All Cities|City1|CityN
	var cities = document.Query.stateToMatch.options[stateIndex].value;
	var parts = cities.split("|");
	document.Query.cityToMatch.length = 0;
	addSelect("cityToMatch", "$allCityString", "0");
	document.Query.cityToMatch.selectedIndex = 0;
	if (stateIndex == 0) {
		document.Query.cityToMatch.disabled = true;
		}
	else {
		document.Query.cityToMatch.disabled = false;
		for (i = 2; i < parts.length; i++) {
			addSelect("cityToMatch", parts[i], i - 1);
			}
		}
	}
-->
</SCRIPT>
ENDJS

	# state picklist
	if ($lost || 1) {
		# ===============================================================================
		# no javascript, put state, city (eg. WA, Spokane) in the pick list
		# The selection list is called $stateToMatch
		# ===============================================================================
		print "<NOSCRIPT>\n";
		print "<TR><TD ALIGN='RIGHT'><B><FONT SIZE='-1'>State and City:</FONT></B></TD><TD>\n";
		print "<SELECT NAME='stateToMatch'>\n";
		print "<OPTION>$allCityString</OPTION>\n";
		foreach $city (keys %cityList) {
			push @sNames, $city;
			}
		foreach $thisState (sort @sNames) {
			$shortName = findStateAbbrev($stateToMatch);
			$stateAndCity = $shortName . ", " . $cityToMatch;
			if ($thisState eq $stateAndCity) {
				print "<OPTION SELECTED>$thisState</OPTION>\n";
				}
			else {
				print "<OPTION>$thisState</OPTION>\n";
				}
			}
		print "</SELECT>\n";
		print "</TD></TR>\n";
		print "</NOSCRIPT>\n";
		$#sNames = -1;

		# ===============================================================================
		# javascript capable - build a picklist of states, enable the city pick list when
		# a state is chosenthe selection lists are called $stateToMatch and $cityToMatch
		# ===============================================================================
		print "<script type='text/javascript'>\n";
		print "<!--\n";
		print qq|document.write("<TR><TD ALIGN='RIGHT'><B><FONT SIZE='-1'>State or Province:</FONT></B></TD><TD>");\n|;
		print qq|document.write("<SELECT NAME='stateToMatch' onchange='javascript:enableCity(document.Query.stateToMatch.selectedIndex)'>");\n|;
		print qq|document.write("<OPTION>All States and Provinces</OPTION>");\n|;
		$curState = "";
		foreach $city (sort keys %cityList) {
			$nextState = substr($city, 0, 2);
			$nextState = $statenames{$nextState};
			if ($nextState ne $curState) {
				$stateCities{$curState} = cityClean($stateCities{$curState});
				$curState = $nextState;
				push @sNames, $curState;
				$stateCities{$curState} = $curState . "|" . $allCityString;
				}
			$stateCities{$curState} .= "|" . substr($city, 4);
			}
		$stateCities{$curState} = cityClean($stateCities{$curState});
		foreach $thisState (sort @sNames) {
			next if ($thisState eq "");
			if ($thisState eq $stateToMatch) {
				print qq|document.write("<OPTION SELECTED VALUE='$stateCities{$thisState}'>$thisState</OPTION>");\n|;
				}
			else {
				print qq|document.write("<OPTION VALUE='$stateCities{$thisState}'>$thisState</OPTION>");\n|;
				}
			}

		print qq|document.write("</SELECT>");\n|;
		print qq|document.write("</TD></TR>");\n|;
		print qq|document.write("</NOSCRIPT>");\n|;
		print "-->\n";
		print "</script>\n";
		$#sNames = -1;
		}
	else {
		# state only for domestic census
		print "<TR><TD ALIGN='RIGHT'><B><FONT SIZE='-1'>State or Province:</FONT></B></TD><TD>\n";
		print "<SELECT NAME='stateToMatch'>\n";
		print "<OPTION>All States and Provinces</OPTION>\n";
		foreach $state (keys %statenames) {
			push @sNames, $statenames{$state};
			}
		foreach $thisStateCities (@stateCities) {
			print "<OPTION>$thisStateCities</OPTION>\n";
			}
		foreach $thisState (sort @sNames) {
			if ($thisState eq $stateToMatch) {
				print "<OPTION SELECTED>$thisState</OPTION>\n";
				}
			else {
				print "<OPTION>$thisState</OPTION>\n";
				}
			}
		print "</SELECT>\n";
		print "</TD></TR>\n";
		}
}

sub BOPickList
{
	return if ($lost && 0);

	print "<TR><TD ALIGN='RIGHT'><B><FONT SIZE='-1'>Band Organ:</FONT></B></TD><TD>\n";

	# Band Organ picklist
	print "<SELECT NAME='BOToMatch'>\n";
	print "<OPTION>Any Band Organ</OPTION>\n";
	$bandFile = "$docRoot/admin/AllCensus/bandorgan.txt";
	open(BAND, "<$bandFile") || print "Can't open $bandFile\n";
	while (<BAND>) {
		chomp;
		$_ = trimwhite($_);
		@BOparts = split/\|/;
		if (@BOparts[0] ne "" && @BOparts[1] ne "") {
			push @bandorgans, @BOparts[0] if @BOparts[0] ne "";
			$BOAbbrevs{@BOparts[0]} = @BOparts[1];	# save for abbreviation in search
			}
		}
	close(BAND);
	foreach $band (sort @bandorgans) {
		if ($band eq $BOToMatch) {
			print "<OPTION SELECTED>$band</OPTION>\n";
			}
		else {
			print "<OPTION>$band</OPTION>\n";
			}
		}
	print "</SELECT>\n";
	print "</TD></TR>\n";
}
sub ManuPickList
{
	# Manufacturer picklist
	print "<TR><TD ALIGN='RIGHT'><B><FONT SIZE='-1'>Manufacturer:</FONT></B></TD><TD>\n";
	print "<SELECT NAME='manufToMatch'>\n";
	print "<OPTION>Any Manufacturer</OPTION>\n";
	if ($lost) {
		foreach $manuf (sort keys %manufList) {
			if ($manuf eq $manufToMatch) {
				print "<OPTION SELECTED>$manuf</OPTION>\n";
				}
			else {
				print "<OPTION>$manuf</OPTION>\n";
				}
			}
		}
	else {
		$manufFile = "$docRoot/admin/AllCensus/manufacturers.txt";
		open(MANU, "<$manufFile" || print "Can't open $manufFile\n");
		while (<MANU>) {
			chomp;
			push @manus, $_;
			}
		close(MANU);
		foreach $manuf (sort @manus) {
			if ($manuf eq $manufToMatch) {
				print "<OPTION SELECTED>$manuf</OPTION>\n";
				}
			else {
				print "<OPTION>$manuf</OPTION>\n";
				}
			}
		}
	print "</SELECT>\n";
	print "</TD></TR>\n";
}


sub showType
{
	my $name = @_[0];
	my $qty = @_[1];
	my $rem = @_[2];
	my $plural = @_[3];
	if ($qty) {
		if ($qty > 1) {
			print "$qty $plural";
			}
		else {
			print "$qty $name";
			}
		$rem--;
		if ($rem) {
			print ", ";
			}

		}
	$rem;
}

sub showTypes
{
	my $remaining = countTypes();
	if ($remaining) {
		print "(";
		$remaining = showType("Bear", $bear, $remaining, "Bears");
		$remaining = showType("Cat", $cat, $remaining, "Cats");
		$remaining = showType("Elk", $elk, $remaining, "Elk");
		$remaining = showType("Camel", $camel, $remaining, "Camels");
		$remaining = showType("Dog", $dog, $remaining, "Dogs");
		$remaining = showType("Zebra", $zebra, $remaining, "Zebras");
		$remaining = showType("Giraffe", $giraffe, $remaining, "Giraffes");
		$remaining = showType("Goat", $goat, $remaining, "Goats");
		$remaining = showType("Deer", $deer, $remaining, "Deer");
		$remaining = showType("Lion", $lion, $remaining, "Lions");
		$remaining = showType("Tiger", $tiger, $remaining, "Tigers");
		$remaining = showType("Hippocampus", $hippo, $remaining, "Hippocampus");
		$remaining = showType("Rabbit", $rabbit, $remaining, "Rabbits");
		$remaining = showType("Seahorse", $seahorse, $remaining, "Seahorses");
		$remaining = showType("Fish", $fish, $remaining, "Fish");
		$remaining = showType("Pig", $pig, $remaining, "Pigs");
		$remaining = showType("Ostrich", $ostrich, $remaining, "Ostriches");
		$remaining = showType("Rooster", $rooster, $remaining, "Roosters");
		$remaining = showType("Frog", $frog, $remaining, "Frogs");
		$remaining = showType("Dragon", $dragon, $remaining, "Dragons");
		$remaining = showType("Mule", $mule, $remaining, "Mules");
		$remaining = showType("Stork", $stork, $remaining, "Storks");
		$remaining = showType("Kangaroo", $kangaroo, $remaining, "Kangaroos");
		$remaining = showType("Burro", $burro, $remaining, "Burros");
		$remaining = showType("Chetah", $chetah, $remaining, "Chetahs");
		$remaining = showType("Monkey", $monkey, $remaining, "Monkeys");
		$remaining = showType("Cougar", $cougar, $remaining, "Cougars");
		$remaining = showType("Elephant", $elephant, $remaining, "Elephants");
		$remaining = showType("Panther", $panther, $remaining, "Panthers");
		$remaining = showType("Cow", $cow, $remaining, "Cows");
		$remaining = showType("Goose", $goose, $remaining, "Geese");
		$remaining = showType("Wil", $wil, $remaining, "Wils");
		$remaining = showType("Moose", $moose, $remaining, "Moose");
		$remaining = showType("Mouse", $mouse, $remaining, "Mice");
		$remaining = showType("Raccoon", $raccoon, $remaining, "Raccoons");
		$remaining = showType("Squirrel", $squirrel, $remaining, "Squirrels");
		$remaining = showType("Loon", $loon, $remaining, "Loons");
		$remaining = showType("Duck", $duck, $remaining, "Ducks");
		$remaining = showType("Swan", $swan, $remaining, "Swans");
		$remaining = showType("Rhino", $rhino, $remaining, "Rhinos");
		$remaining = showType("Skunk", $skunk, $remaining, "Skunks");
		$remaining = showType("Ram", $ram, $remaining, "Rams");
		$remaining = showType("Donkey", $donkey, $remaining, "Donkeys");
		$remaining = showType("Llama", $llama, $remaining, "Llamas");
		$remaining = showType("Bison", $bison, $remaining, "Bison");
		$remaining = showType("Unknown", $unknown, $remaining, "Unknown");
		print ")\n";
		}
}


sub htmlCheckBox
{
	my $fldPrompt = $_[0];
	my $fldName = $_[1];
	my $fldValue = $_[2];

	$checked = "";
	if ($fldValue == 1) {
		$checked = "CHECKED";
		}

	print "<TD ALIGN='RIGHT'>\n";
	print "<B>$fldPrompt:</B><BR>\n";
	print "</TD>\n";
	print "<TD>\n";
	print "<INPUT TYPE='CHECKBOX' NAME='$fldName' VALUE='1' $checked>\n";
	print "</TD>\n";
	print "</TR>\n";

}


sub htmlSelection
{
	my $fldPrompt = $_[0];
	my $fldName = $_[1];
	my $fldValue = $_[2];
	my $changeFlag = $_[3];
	my $selString = $_[4];

	print "<TR>\n";
	print "<TD ALIGN='RIGHT'>\n";
	print "<B>$fldPrompt:</B><BR>\n";
	print "</TD>\n";
	print "<TD>\n";
	if ($changeFlag == 1) {
		# field can be changed
		print "<SELECT NAME='$fldName'>\n";
		foreach $item (split(/\|/, $selString)) {
			if ($item eq $fldValue) {
				print "<OPTION SELECTED>";
				}
			else {
				print "<OPTION>";
				}
			print "$item";
			print "</OPTION>";
			}
		print "</SELECT>\n";
		}
	else {
		# field can't be changed, put it out as a hidden field so its value
		# will be available on submit
		print "$fldValue\n";
		print "<INPUT TYPE='HIDDEN' VALUE='$fldValue' NAME='$fldName'></INPUT>\n";
		}
	print "</TD>\n";
	print "</TR>\n";
}


sub htmlAnimalCount
{
	my $fldPrompt = $_[0];
	my $fldName = $_[1];
	my $fldValue = $_[2];
	print "<TR><TD ALIGN='RIGHT'><B>$fldPrompt:</B></TD><TD><INPUT TYPE='TEXT' VALUE='$fldValue' NAME='$fldName' MAXLENGTH='2' SIZE='2'></INPUT></TD></TR>";
}


sub htmlTextField
{
	my $fldPrompt = $_[0];
	my $fldName = $_[1];
	my $fldValue = $_[2];
	my $changeFlag = $_[3];

	print "<TR>\n";
	print "<TD ALIGN='RIGHT'>\n";
	print "<B>$fldPrompt:</B><BR>\n";
	print "</TD>\n";
	print "<TD>\n";
	if ($changeFlag == 1) {
		# field can be changed
		print "<INPUT TYPE='TEXT' VALUE='$fldValue' NAME='$fldName' SIZE='50'></INPUT>\n";
		}
	else {
		# field can't be changed, put it out as a hidden field so its value
		# will be available on submit
		print "$fldValue\n";
		print "<INPUT TYPE='HIDDEN' VALUE='$fldValue' NAME='$fldName' SIZE='50'></INPUT>\n";
		}
	print "</TD>\n";
	print "</TR>\n";
}


sub htmlTextArea
{
	my $fldPrompt = $_[0];
	my $fldName = $_[1];
	my $fldValue = $_[2];
	my $changeFlag = $_[3];

	print "<TR>\n";
	print "<TD ALIGN='RIGHT' VALIGN='TOP'>\n";
	print "<B>$fldPrompt:</B><BR>\n";
	print "</TD>\n";
	print "<TD>\n";
	if ($changeFlag == 1) {
		# field can be changed
		print "<TEXTAREA NAME='$fldName' ROWS='5' COLS='50'>";
		}
	else {
		# field can't be changed
		print "<TEXTAREA NAME='$fldName' ROWS='5' COLS='50' READONLY='1'>";
		}
	print "$fldValue";
	print "</TEXTAREA>\n";
	print "</TD>\n";
	print "</TR>\n";
}


sub trimwhite
{
	my $trimLine = @_[0];
	$_ = $trimLine;
	s/^\s+//;
	s/\s+$//;
	$_;
}


sub parseCSVFile
{
	my $addon = 0;
	my $beenhere = 0;
	my $line;
	my @parts;
	my $key;

	print "Opening census file: $censusFile<BR>\n" if $debug;
	if (! open(CENSUS, "<$censusFile")) {
		print "Can't open input file: $censusFile!\n" if $debug;
		return 0;
		}

	$NCAAwardCount = 0;
	$BrassRingCount = 0;
	$OrigLocCount = 0;
	$TwoLevelCount = 0;
	$NHLCount = 0;
	$NRHPCount = 0;

	$recordCount = 0;
	$lines = 0;
	while (<CENSUS>) {
		chomp;
		$lines++;
		print "Read line: $_<BR>\n" if ($debug);
		if (! $beenhere && $titlesIncluded) {
			# skip the title line
			$beenhere = 1;
			print "Skipping title line<BR>\n" if ($debug);
			next;
			}
		if (/^$/) {
			print "Empty line\n" if $debug;
			next;
			}
		if ($addon) {
			# a line broken by a newline
			$line .= "<BR>$_";
			$addon = 0;
			}
		else {
			$line = $_;
			}
		s/\s+$//;
		if (!/\"$/ && !/\|$/) {
			# No quote or vertical bar at the end, must be a continued line
			$addon = 1;
			}
		else {
			splitCensusRec($line);
			print "Record has been split, NCA_No=$NCA_No<BR>\n" if ($debug);
			if (($domestic && $Census_List_Type ne "dom") ||
#				($lost && $Census_List_Type ne "def") ||
				($international && $Census_List_Type ne "int")) {
				# ignore records that don't match this list type
				print "Skipping on Census_List_Type=$CensusListType<BR>\n" if ($debug);
				next;
				}
			if (($INACIndex == 0) && ($NCANoToMatch eq "") && ($Sort_Class =~ /MOD/i)) {
				# skip type MOD except for INAC index and Single Census
				print "Skipping $NCANoToMatch, INACIndex=$INACIndex, NACNoToMatch=$NCANoToMatch, Sort_Class=$Sort_Class<BR>\n" if ($debug);
				next;
				}
			$recordCount++;
			if ($show1Field) {
				# change this line to show other fields
				# print ">> $BO_Description\n";
				# print "   " . makeMusic() . "\n";
				print "Manufacturer: $Description<BR>\n";
				}
			$NCA_No = int(stripQuotes($NCA_No));
			$P_State = stripQuotes($P_State);
			$P_City = stripQuotes($P_City);
			$Ring_Oper = stripQuotes($Ring_Oper);
			$YR_Built = stripQuotes($YR_Built);
			$NHL = stripQuotes($NHL);
			$NRHP = stripQuotes($NRHP);
			
		print "Checking NCA_No for >0, NCA_No=$NCA_No<BR>\n" if ($debug);
		if ($NCA_No > 0) {
			$NCARecs{$NCA_No} = $line;		# the main record keyed by sortclass:state:city:ncano
			$StateRecs{"$Sort_Class:$P_State:$P_City:$NCA_No"} = $NCA_No;	# cross reference by state
			$country = makeCountry($P_State);
			$CountryRecs{"$country:$P_State:$P_City:$Park:$Description:$NCA_No"} = $NCA_No;		# xref by country, state, city, park

			# an index first by sort class, then by the standard fields
			if ($lost) {
				$sortState = getLostSortState();
				}
			else {
				$sortState = stripQuotes($P_State);
				}
			$CountryClassRecs{"$Sort_Class:$country:$sortState:$P_City:$Park:$Description:$NCA_No"} = $NCA_No;

			$_ = $line;
			if (/2LP/i || /two[ -]?level/i) {
				# build this key in sort order
				$TwoLevel{"$country:$P_State:$P_City:$Park:$Description"} = $NCA_No;
				$TwoLevelCount++;
				}
			if ($Orig_Loc =~ /yes/i && # $Orig_Config =~ /^y/i &&
				($Sort_Class =~ /CLA/i || $Sort_Class =~ /METAL/i)) {
				# build this key in sort order
				$OrigLocations{"$country:$P_State:$P_City:$Park:$Description"} = $NCA_No;
				$OrigLocCount++;
				}

			if ($Ring_Oper =~ /YES/i && # $Orig_Config =~ /^y/i &&
				($Sort_Class =~ /CLA/i || $Sort_Class =~ /METAL/i)) {
				# build this key in sort order
				$BrassRing{"$country:$P_State:$P_City:$Park:$Description"} = $NCA_No;
				$BrassRingCount++;
				}
			if ($NHL =~ /YES/i) {
				$nhlYear = "Year Unknown";
				if (/\d\d\d\d/, $NHL_Year) {
					$nhlYear = $1;
					}
				# build the key in sort order
				$landmark{"$country:$P_State:$P_City:$Park:$Description"} = $NCA_No;
				$NHLCount++;
				}
			if ($NCA_Hist_Award =~ /YES/i) {
				# build this key in sort order
				$NCAAwardRecs{"$NCA_Hist_Award_Yr:$country:$P_State:$P_City:$Park:$Description"} = $NCA_No;
				$NCAAwardCount++;
				}
			if ($NRHP =~ /YES/i && !($NHL =~ /YES/i)) { # don't show in NHRP if it's already shown in NHL
				$nrhpYear = "Year Unknown";
				if ($NRHP_Year > 0) {
					$NRHP_Year = int($NRHP_Year);
					}
				if (/(\d\d\d\d)/, $NRHP_Year) {
					$nrhpYear = $1;
					}
				# build the key in sort order
				$RHP{"$country:$P_State:$P_City:$Park:$Description"} = $NCA_No;
				$NRHPCount++;
				}
			$_ = $YR_Built;
			/(\d\d\d\d)/;
			if ($1 ne "") {
				$thisState = $statenames{$P_State};
				$YearRecs{"$1$thisState:$P_City"} = $NCA_No;					# year built key
				}
			else {
				# print "Can't get year from: '$_'<BR>\n" if $debug;
				}
			}
		}
		if ($lost || 1) {
			$cityList{$OL_State          . ", " . $OL_City}           = 1 if ($OL_State ne "");
			$cityList{$Second_Loc_State  . ", " . $Second_Loc_City}   = 1 if ($Second_Loc_State ne "");
			$cityList{$Third_Loc_State   . ", " . $Third_Loc_City}    = 1 if ($Third_Loc_State ne "");
			$cityList{$Fourth_Loc_State  . ", " . $Fourth_Loc_City}   = 1 if ($Fourth_Loc_State ne "");
			$cityList{$Fifth_Loc_State   . ", " . $Fifth_Loc_City}    = 1 if ($Fifth_Loc_State ne "");
			$cityList{$Sixth_Loc_State   . ", " . $Sixth_Loc_City}    = 1 if ($Sixth_Loc_State ne "");
			$cityList{$Seventh_Loc_State . ", " . $Seventh_Loc_City}  = 1 if ($Seventh_Loc_State ne "");
			$cityList{$Eighth_Loc_State  . ", " . $Eighth_Loc_City}   = 1 if ($Eighth_Loc_State ne "");
			if ($Description ne "") {
				$manuf = $Description;
				$manuf = "PTC" if ($manuf =~ /^PTC #/);
				$manufList{$manuf} = 1 if ($manuf ne "");
				}
			}
		}
	print "Closing CENSUS<BR>\n" if ($debug);
	close(CENSUS);

	if ($debug > 2) {
		foreach $key (sort keys %NCARecs) {
			print "Key: $key<BR>\n" if $debug > 50;
			}
		foreach $key (sort keys %cityList) {
			print "City: $key<BR>\n";
			}
		foreach $key (sort keys %manufList) {
			print "Manufacturer: $key<BR>\n";
			}
		}
	print "Read $lines lines, $recordCount records<BR>\n" if $debug;
	return 1;
}

#
# Get a parameter by name, trim white space, escape special characters
# Note: The param function gets incoming data,
# it doesn't matter if the data was from a POST or a GET
#
sub getEnvField
{
	$fldName = $_[0];
    $fld = $qdata->param($_[0]);
    if ($fld) {
        # trim leading & trailing white space
        $fld =~ s/^\s+//;
        $fld =~ s/\s+$//;

        # replace the problem characters
        $fld =~ s/\|/%7c/g; # escape the vertical bar
        $fld =~ s/\+/%2b/g; # escape the + sign
        $fld =~ s/\"/%22/g; # escape the double quote
        $fld =~ s/\'/%27/g; # escape the single quote
        }
# print "Field: $fldName, Data: " . UnescapeString($fld) . "<BR>\n" if $debug > 1;

    return UnescapeString($fld);
}

sub keycmp
{
	my	@aParts;
	my	@bParts;

	@aParts = split(/:/, $a);
	@bParts = split(/:/, $b);

	# first field is the sort class
	if (@aParts[0] ne @bParts[0]) {
		if (@aParts[0] =~ /cla/i) {
			# a is classical, first sort priority
			return(-1);
			}
		if (@bParts[0] =~ /cla/i) {
			# b is classical, first sort priority
			return(1);
			}
		if (@aParts[0] =~ /metal/i) {
			# a is metal, second sort priority
			return(-1);
			}
		if (@bParts[0] =~ /metal/i) {
			# b is metal, second sort priority
			return(1);
			}
		return(-1);	# neither is classical wood or metal
		}

	# second field is the state
	if (@aParts[1] eq @bParts[1]) {
		# state is the same, sort class is the same, sort on the whole string
		return($a cmp $b);
		}
	else {
		# Different states, sort on state
		return($statenames{@aParts[1]} cmp $statenames{@bParts[1]});
		}
}

sub CountryClassKeyCmp
{
	my	@aParts;
	my	@bParts;

	# get the sort class out of the key
	@aParts = split(/:/, $a, 2);
	@bParts = split(/:/, $b, 2);

	# if sort classes are equal, pass the rest of the key through
	# the CountryKeyCmp routine
	if (@aParts[0] eq @bParts[0]) {
		$result = CountryKeyCmpSub(@aParts[1], @bParts[1], 1);
		return($result);
		}

	if (@aParts[0] =~ /cla/i) {
		# a is classical, first sort priority
		return(-1);
		}
	if (@bParts[0] =~ /cla/i) {
		# b is classical, first sort priority
		return(1);
		}
	if (@aParts[0] =~ /metal/i) {
		# a is metal, second sort priority
		return(-1);
		}
	if (@bParts[0] =~ /metal/i) {
		# b is metal, second sort priority
		return(1);
		}
	if (@aParts[0] =~ /new/i) {
		# a is new, third sort priority
		return(-1);
		}
	if (@bParts[0] =~ /new/i) {
		# b is new, third sort priority
		return(1);
		}
	return(-1);	# neither is classical, metal or new
}

sub CountryKeyCmpByStateName
{
	CountryKeyCmpSub($a, $b, 1);
}
sub CountryKeyCmp
{
	CountryKeyCmpSub($a, $b, 0);
}
sub CountryKeyCmpSub
{
	my	$left = @_[0];
	my	$right = @_[1];
	my	$compareByStateName = @_[2];
	my	@aParts;
	my	@bParts;

	@aParts = split(/:/, $left);
	@bParts = split(/:/, $right);

	# first field is the country
	if (@aParts[0] ne @bParts[0]) {
		# countries are different, return decision based on the country
		if (@aParts[0] eq "America") {
			return(-1);
			}
		return(1);
		}

	# state
	if (@aParts[1] ne @bParts[1]) {
		# states not equal, return decision based on state
		if ($compareByStateName) {
			$name1 = @statenames{@aParts[1]};
			$name2 = @statenames{@bParts[1]};
			return($name1 lt $name2 ? -1 : 1);
			}
		else {
			return(@aParts[1] lt @bParts[1] ? -1 : 1);
			}
		}

	# city
	if (@aParts[2] ne @bParts[2]) {
		# Cities not equal, return decision based on city
		return(@aParts[2] lt @bParts[2] ? -1 : 1);
		}

	# park
	if (@aParts[3] lt @bParts[3]) {
		return(-1);
		}
	if (@aParts[3] gt @bParts[3]) {
		return(1);
		}
	return(0);
}

sub loadFields
{
	$NCANoToMatch = getEnvField("NCANo");
	$fromMap = getEnvField("Map");
	print "Matching NCA Number: $NCANoToMatch<BR>\n" if ($debug && $NCANoToMatch ne "");
	$stateToMatch = getEnvField("stateToMatch");
	if (($lost || 1) && $stateToMatch =~ /\|/) {
		$cityToMatch = getEnvField("cityToMatch");
		@parts = split/\|/, $stateToMatch;
		$stateToMatch = @parts[0];	# the state is the first vertical bar delimited field
		print "cityToMatch(index)=$cityToMatch, " if ($debug);
		$cityToMatch = @parts[$cityToMatch + 1];	# turn the index into a name
		print "stateToMatch: $stateToMatch, cityToMatch: $cityToMatch<BR>\n" if ($debug);
		}
	$dateToMatch = getEnvField("dateToMatch");
	$sortToMatch = getEnvField("sortToMatch");
	$classToMatch = getEnvField("classToMatch");
	$BOToMatch = getEnvField("BOToMatch");
	$manufToMatch = getEnvField("manufToMatch");
	$DisplayButton = getEnvField("DisplayButton");
	$displayNumbers = getEnvField("numbers");
	$Condensed = getEnvField("Condensed") if ($Condensed eq "");
}

sub expandMenagerie
{
	$menag = $_[0];
	$menag = animalAbbrev($menag, "FIS", "Fish", "Fish");
	$menag = animalAbbrev($menag, "SEA", "Seal", "Seals");
	$menag = animalAbbrev($menag, "WHL", "Whale", "Whales");
	$menag = animalAbbrev($menag, "BTF", "Butterfly", "Butterflies");
	$menag = animalAbbrev($menag, "LIO", "Lion", "Lions");
	$menag = animalAbbrev($menag, "DEE", "Deer", "Deer");
	$menag = animalAbbrev($menag, "CAMEL", "Camel", "Camels");
	$menag = animalAbbrev($menag, "CAM", "Camel", "Camels");
	$menag = animalAbbrev($menag, "BEA", "Bear", "Bears");
	$menag = animalAbbrev($menag, "CAT", "Cat", "Cats");
	$menag = animalAbbrev($menag, "DOG", "Dog", "Dogs");
	$menag = animalAbbrev($menag, "TIG", "Tiger", "Tigers");
	$menag = animalAbbrev($menag, "ELK", "Elk", "Elk");
	$menag = animalAbbrev($menag, "GOA", "Goat", "Goats");
	$menag = animalAbbrev($menag, "ZEB", "Zebra", "Zebras");
	$menag = animalAbbrev($menag, "GIR", "Giraffe", "Giraffes");
	$menag = animalAbbrev($menag, "GIF", "Giraffe", "Giraffes");
	$menag = animalAbbrev($menag, "HIP", "Hippocampus", "Hippocampus");
	$menag = animalAbbrev($menag, "RAB", "Rabbit", "Rabbits");
	$menag = animalAbbrev($menag, "SEA", "Seahorse", "Seahorses");
	$menag = animalAbbrev($menag, "FIS", "Fish", "Fish");
	$menag = animalAbbrev($menag, "PIG", "Pig", "Pigs");
	$menag = animalAbbrev($menag, "OST", "Ostrich", "Ostriches");
	$menag = animalAbbrev($menag, "ROO", "Rooster", "Roosters");
	$menag = animalAbbrev($menag, "FRO", "Frog", "Frogs");
	$menag = animalAbbrev($menag, "DRA", "Dragon", "Dragons");
	$menag = animalAbbrev($menag, "MUL", "Mule", "Mules");
	$menag = animalAbbrev($menag, "STO", "Stork", "Storks");
	$menag = animalAbbrev($menag, "KAN", "Kangaroo", "Kangaroos");
	$menag = animalAbbrev($menag, "BUR", "Burro", "Burros");
	$menag = animalAbbrev($menag, "CHE", "Cheetah", "Cheetahs");
	$menag = animalAbbrev($menag, "ELE", "Elephant", "Elephants");
	$menag = animalAbbrev($menag, "MON", "Monkey", "Monkeys");
	$menag = animalAbbrev($menag, "COU", "Cougar", "Cougars");
	$menag = animalAbbrev($menag, "PAN", "Panther", "Panthers");
	$menag = animalAbbrev($menag, "COW", "Cow", "Cows");
	$menag = animalAbbrev($menag, "GOO", "Goose", "Geese");
	$menag = animalAbbrev($menag, "WIL", "Wildebeest", "Wildebeests");
	$menag = animalAbbrev($menag, "LOO", "Loon", "Loons");
	$menag = animalAbbrev($menag, "MOO", "Moose", "Mooses");
	$menag = animalAbbrev($menag, "SQU", "Squirrel", "Squirrels");
	$menag = animalAbbrev($menag, "MOU", "Mouse", "Mice");
	$menag = animalAbbrev($menag, "RAC", "Raccoon", "Raccoons");
	$menag = animalAbbrev($menag, "DUC", "Duck", "Ducks");
	$menag = animalAbbrev($menag, "SWA", "Swan", "Swans");
	$menag = animalAbbrev($menag, "RHI", "Rhino", "Rhinos");
	$menag = animalAbbrev($menag, "SKU", "Skunk", "Skunks");
	$menag = animalAbbrev($menag, "RAM", "Ram", "Rams");
	$menag = animalAbbrev($menag, "DON", "Donkey", "Donkeys");
	$menag = animalAbbrev($menag, "LLA", "Llama", "Llamas");
	$menag = animalAbbrev($menag, "BIS", "Bison", "Bison");
	$menag = animalAbbrev($menag, "UNK", "Unknown", "Unknown");
	$menag =~ s/,(\d)/, $1/g;
	$menag;
}

sub animalAbbrev
{
	my $menag = @_[0];
	my $abbrev = @_[1];
	my $singular = @_[2];
	my $plural = @_[3];
	my $count;

	if ($menag =~ s/(\d+)($abbrev)/xxx/) {
		$count = $1;
		if ($count > 1) {
			$menag =~ s/xxx/$count $plural/;
			}
		else {
			$menag =~ s/xxx/$count $singular/;
			}
		}
	else {
		$menag =~ s/$abbrev/1 $singular/;
		}
	$menag;
}

sub makeMusic
{
# print "BO_Description: $BO_Description<BR>\n";
	chomp $BO_Description;
	$BO_Description = trimwhite($BO_Description);

	if ($BO_Desciption eq "b/o no") {
		# just "b/o no", an easy one to fix
		return("No Band Organ");
		}
	if ($BO_Description =~ /^b\/o\s+unk$/i) {
		return("Band Organ Unknown");
		}
	if ($BO_Description =~ /^b\/o\s+no\s+/i) {
		$BO_Description =~ s/^b\/o\s+no\s+/No Band Organ: /i;
		}

	# most common case, sub "b/o no" with "No Band Organ"
	$BO_Description =~ s/^b\/o no$/No Band Organ:/;

	$BO_Description =~ s/none/No Band Organ/;
	$BO_Description =~ s/^:/No Band Organ/;
	$BO_Description =~ s/^b\/o none$/No Band Organ/;
	$BO_Description =~ s/no b\/o/No Band Organ/;

	$BO_Description =~ s/^b\/o[:\?]?/Band Organ:/;
	$BO_Description = trimwhite($BO_Description);
	$BO_Description = uc(substr($BO_Description, 0, 1)) . substr($BO_Description, 1);
#
#
#
# Clear the Music var, we don't want it right now.
#
$Music = "";
	$Music =~ s/RECORD[S]?\/TAPES?/Recorded Music/;
	$Music =~ s/UNKNOWN//;
	$Music =~ s/BAND ORGAN/Band Organ/;
	$Music =~ s/NONE//;
	$Music =~ s/b\/o no//;
	$Music =~ s/ta;es/Tapes/;
	$Music =~ s/\s+-\s+//;
	if ($BO_Description =~ /^$Music$/i) {
		$BO_Description = "";
		}

	return($BO_Description);

	$makeModel = "";
	$musicString = "";
	$comma = "";

	if ($BO_Description eq "" && $makeModel eq "") {
		if ($Music eq "") {
			# Nothing!
			# print "1) NOTHING!<BR>\n";
			# $musicString = "1) NOTHING";
			}
		else {
			# print "2) $Music<BR>\n";
			$musicString = $Music;
			}
		}
	elsif ($Music eq "" && $BO_Description eq "Unknown") {
		#Nothing worth printing
		# print "3) NOTHING GOOD!<BR>\n";
		# $musicString = "3) NOTHING GOOD";
		}
	elsif ($Music eq $BO_Description && $makeModel eq "") {
		# Music only
		# print "4) $Music<BR>\n";
		$musicString = "$Music";
		}
	else {
		# print "5) ";
		$comma = "";
		if ($Music ne "") {
			$musicString = "$Music";
			$comma = ", ";
			}
		if ($BO_Description ne "") {
			$musicString .= "$comma$BO_Description";
			}
		if ($makeModel ne "") {
			if ($BO_Description ne "" || $Music ne "") {
				$openParen = " (";
				$closeParen = ")";
				}
			else {
				$openParen = "";
				$closeParen = "";
				}
			$musicString .= "$openParen$makeModel$closeParen";
			}
		}
	$musicString;
}

sub makeHistCityState
{
	my $curCity = @_[0];
	my $curState = @_[1];
	if ($curState eq "DC" ) {
		return("", "District of Columbia");
		}
	return($curCity, $curState);
}

sub makeHist
{
	my $makeCond = @_[0];	# condensed history?

	@ln[0] = makeHistLine($makeCond, $Orig_Location, makeHistCityState($OL_City, $OL_State), $OL_From, $OL_To);
	@ln[1] = makeHistLine($makeCond, $Second_Loc, makeHistCityState($Second_Loc_City, $Second_Loc_State), $Second_Loc_From, $Second_Loc_To);
	@ln[2] = makeHistLine($makeCond, $Third_Loc, makeHistCityState($Third_Loc_City, $Third_Loc_State), $Third_Loc_From, $Third_Loc_To);
	@ln[3] = makeHistLine($makeCond, $Fourth_Loc, makeHistCityState($Fourth_Loc_City, $Fourth_Loc_State), $Fourth_Loc_From, $Fourth_Loc_To);
	@ln[4] = makeHistLine($makeCond, $Fifth_Loc, makeHistCityState($Fifth_Loc_City, $Fifth_Loc_State), $Fifth_Loc_From, $Fifth_Loc_To);
	@ln[5] = makeHistLine($makeCond, $Sixth_Loc, makeHistCityState($Sixth_Loc_City, $Sixth_Loc_State), $Sixth_Loc_From, $Sixth_Loc_To);
	@ln[6] = makeHistLine($makeCond, $Seventh_Loc, makeHistCityState($Seventh_Loc_City, $Seventh_Loc_State), $Seventh_Loc_From, $Seventh_Loc_To);
	@ln[7] = makeHistLine($makeCond, $Eighth_Loc, makeHistCityState($Eighth_Loc_City, $Eighth_Loc_State), $Eighth_Loc_From, $Eighth_Loc_To);
	if ($lost) {
		# display with most recent location at the top of the list
		$histLine = @ln[7] . @ln[6] . @ln[5] . @ln[4] . @ln[3] . @ln[2] . @ln[1] . @ln[0];
		}
	else {
		# display with oldest location at the top
		$histLine = @ln[0] . @ln[1] . @ln[2] . @ln[3] . @ln[4] . @ln[5] . @ln[6] . @ln[7];
		}
	$histLine;
}

sub makeHistLine
{
	my $makeCond = @_[0];
	my $makeLoc = @_[1];
	my $makeCity = @_[2];
	my $makeState = @_[3];
	my $makeFrom = @_[4];
	my $makeTo = @_[5];
	my $makeResult;

	$makeResult = "";
	if ($makeCond) {
		# condensed listing
		if ($makeLoc ne "" || $makeCity ne "" || $makeState ne "") {
			if ($makeLoc ne "") {
				$makeResult .= "$makeLoc, ";
				}
			if ($makeCity ne "") {
				$makeResult .= "$makeCity, ";
				}
			if ($makeState ne "") { $makeResult .= "$makeState, ";
				}
			if ($makeFrom ne "" && $makeTo ne "") {
				$makeResult .= "$makeFrom to $makeTo; ";
				}
			}
		}
	$makeResult;
}

sub makeLongHistory
{
	my @ln;
	my $histDisp = "";
	my $indx;
	@ln[0] = makeLongHistLine($Orig_Location, $OL_City, $OL_State, $OL_From, $OL_To);
	@ln[1] = makeLongHistLine($Second_Loc, $Second_Loc_City, $Second_Loc_State, $Second_Loc_From, $Second_Loc_To);
	@ln[2] = makeLongHistLine($Third_Loc, $Third_Loc_City, $Third_Loc_State, $Third_Loc_From, $Third_Loc_To);
	@ln[3] = makeLongHistLine($Fourth_Loc, $Fourth_Loc_City, $Fourth_Loc_State, $Fourth_Loc_From, $Fourth_Loc_To);
	@ln[4] = makeLongHistLine($Fifth_Loc, $Fifth_Loc_City, $Fifth_Loc_State, $Fifth_Loc_From, $Fifth_Loc_To);
	@ln[5] = makeLongHistLine($Sixth_Loc, $Sixth_Loc_City, $Sixth_Loc_State, $Sixth_Loc_From, $Sixth_Loc_To);
	@ln[6] = makeLongHistLine($Seventh_Loc, $Seventh_Loc_City, $Seventh_Loc_State, $Seventh_Loc_From, $Seventh_Loc_To);
	@ln[7] = makeLongHistLine($Eighth_Loc, $Eighth_Loc_City, $Eighth_Loc_State, $Eighth_Loc_From, $Eighth_Loc_To);
	if ($lost) {
		for ($indx = 7; $indx >= 0; $indx--) {
			$histDisp .= @ln[$indx] . "<BR>" if (@ln[$indx] ne "");
			}
		}
	else {
		for ($indx = 0; $indx <= 7; $indx++) {
			$histDisp .= @ln[$indx] . "<BR>" if (@ln[$indx] ne "");
			}
		}
	$histDisp;
}

sub makeLongHistLine
{
	my $histLine = "";
# $histLine = "@_[0], @_[1], @_[2], @_[3], @_[4]<BR>\n";
# print "makeLongHist:@_[0]:@_[1]:@_[2]:@_[3]:$_[4]<BR>\n";
	my $loc = @_[0];
	if ($loc eq "") {
		$loc = "Unk" if (@_[1] ne "" || @_[2] ne "" || @_[3] ne "" || @_[4] ne "");
		}
	if ($loc ne "") {
		$histLine .= "$loc, ";
		}
	if (@_[2] eq "DC") {
		$histLine .= "District of Columbia";
		}
	else {
		if (@_[1] ne "") {
			# City
			$histLine .= "@_[1]";
			}
		if (@_[2] ne "") {
			# State
			$histLine .= ", @_[2]";
			}
		}
	if ((@_[3] =~ /^unk/i ||
		@_[3] =~ /^[\?\/]/) && 							# if from_date contains ? or / and
		(@_[4] =~ /^[\/\?]/ || @_[4] =~ /^unk/i) && 	# to_date contains ? or / and
		!(@_[3] =~ /\d/) && !(@_[4] =~ /\d/))			# and neither field contains a digit
		{
		# unknown
		$histLine .= ", Date Unknown to Unknown";
		}
	else {
		if (@_[3] ne "") {
			# from date
			if (@_[3] =~ /[\?\/]/ && ! (@_[3] =~ /\d/)) {	# if it has a ? or a / and no digits
				$histLine .= ", Date Unknown";
				}
			else {
				$histLine .= ", @_[3]"; 
				}
			@_[4] = "Unknown" if @_[4] eq "";	# default to unknown
			}
		if (@_[4] ne "") {
			# to date
			if (@_[3] eq "") {
				# add a comma
				$histLine .= ",";
				}
			$histLine .= " to @_[4]";
			}
		}
	$histLine =~ s/OL/Original Location/;
	$histLine =~ s/Unk/Unknown/ig;
	$histLine =~ s/Unknownnown/Unknown/ig;
	$histLine =~ s/unknown\?/Unknown/ig;
	$histLine =~ s/ , / /;
	$histLine =~ s/, \<\/B\>, /, \<\/\B\>/;
	$histLine;
}

sub getDBDate
{
	my $date;

	print "getDBDate, updateFile=$updateFile<BR>\n" if ($debug);
	open(UPDATEFILE, "<$updateFile") || print "Can't open $updateFile\n";
	while (<UPDATEFILE>) {
		close(UPDATEFILE);
		print "getDBDate, Using date: $_\n" if $debug;
		$date = @months[substr($_, 4, 2) - 1] . " " . substr($_, 6, 2) . ", " . substr($_, 0, 4);
		$hr = substr($_, 8, 2);
		$min = substr($_, 10, 2);
		$AmPm = "AM";
		if ($hr > 12) {
			$hr -= 12;
			$AmPm = "PM";
			}
#		$date .= ", $hr:$min $AmPm";
		return($date);
		}
}

sub
showINACIndex
{
	$prevType = "";

print <<EOINAC;
<P>The index below shows all operating carousels listed in the NCA census database. 
Included are Classic Wood, Classic Metal, New Wood and Modern (post 1960) carousels of various composition.</P>

<P> Pre-1960 Classic Wood and Classic Metal carousels along with New Wood carousels will have a full history
and information listing in their respective classes elsewhere in this census.  These carousels are noted
by a (*).  Modern carousels have only limited information available as shown in the index.</P>

<P> The index was developed to allow quick searches by state and city.  Also, the carousel class can
readily been seen from the index.  </P>
<P>
Please contact the <A HREF="javascript:antiSpam('carousels.org','census');">NCA Census Chairman</A> with any additions or corrections to this list.</P>

EOINAC

	print qq|<DIV ALIGN="CENTER"><TABLE BORDER="2"><TR><TD>|;
	print qq|<TABLE>\n|;
	$INACTotal = 0;
	foreach $key (sort CountryKeyCmp keys %CountryRecs) {
		splitCensusRec($NCARecs{$CountryRecs{$key}});
		if ($prevType ne makeCountry($P_State)) {
			# switchover for country
			$prevType = makeCountry($P_State);
			if ($prevType eq "America") {
				$countryTitle = "American Carousels";
				}
			else {
				$countryTitle = "Canadian Carousels";
				}
			print qq|<TR><TD COLSPAN="6" ALIGN="CENTER"><B><FONT SIZE="+1">&nbsp;<BR>$countryTitle</FONT></B></TD></TR>\n|;
			print qq|<TR>\n|;
			print "<TD ALIGN='CENTER'><FONT SIZE='-1'><B>Location</B></FONT></TD>\n";
			print "<TD ALIGN='CENTER'><B><FONT SIZE='-1'>City</FONT></B></TD>\n";
			print "<TD ALIGN='CENTER'><B><FONT SIZE='-1'>ST</FONT></B></TD>\n";
			print "<TD ALIGN='CENTER'><B><FONT SIZE='-1'>Description</FONT></B></TD>\n";
			print "<TD><B><FONT SIZE='-1'>YR Built</FONT></B></TD>\n";
			print "<TD><B><FONT SIZE='-1'>Class</FONT></B></TD>\n";
			print "</TR>\n";
			}
		print qq|<TR>\n|;
		print qq|<TD VALIGN="TOP"><FONT SIZE='-1'>$Park</FONT></TD>\n|;
		print qq|<TD VALIGN="TOP"><FONT SIZE='-1'>$P_City</FONT></TD>\n|;
		print qq|<TD ALIGN="CENTER" VALIGN="TOP"><FONT SIZE='-1'>$P_State</FONT></TD>\n|;
		print qq|<TD VALIGN="TOP"><FONT SIZE='-1'>$Description</FONT></TD>\n|;
		print qq|<TD VALIGN="TOP"><FONT SIZE='-1'>$YR_Built</FONT></TD>\n|;
		if ($Sort_Class ne "MOD") {
			print qq|<TD VALIGN="TOP"><FONT SIZE='-1'>$Sort_Class<SUP>*</SUP></FONT></TD>\n|;
			}
		else {
			print qq|<TD VALIGN="TOP"><FONT SIZE='-1'>$Sort_Class</FONT></TD>\n|;
			}
		print qq|</TR>\n|;
		$INACTotal++;
		}
	print qq|</TABLE></TD></TR></TABLE></DIV>\n|;
	print "INACTotal: $INACTotal<BR>\n" if $debug;
print <<ENDABBREV;
<DIV ALIGN="CENTER">
<TABLE CELLSPACING='4' border='0'>
	<TR>
		<TD ALIGN="CENTER" COLSPAN="2">
			<B>Key to Carousel Class Abbreviations</B>
		</TD>
	</TR>
	<TR>
		<TD ALIGN='RIGHT' VALIGN='TOP'>
			<B>CLA</B>
		</TD>
		<TD>
			Classic wood (figures) Carousels 1800s - 1940s wood and W&M
		</TD>
	</TR>

	<TR>
		<TD ALIGN='RIGHT' VALIGN='TOP'>
			<B>METAL</B>
		</TD>
		<TD>
			Classic Metal (figures) Carousels 1940s - 1960s
		</TD>
	</TR>
	<TR>
		<TD ALIGN='RIGHT' VALIGN='TOP'>
			<B>NEW</B>
		</TD>
		<TD>
			New Wood (figures) Carousels 1980 - present
		</TD>
	</TR>
	<TR>
		<TD ALIGN='RIGHT' VALIGN='TOP'>
			<B>MOD</B>
		</TD>
		<TD>
			New carousels 1961 to present with fiberglass or composition animals
		</TD>
	</TR>
</TABLE>
</DIV>
ENDABBREV
print qq|<DIV ALIGN="CENTER"><SUP>*</SUP>See main census data for additional info</DIV>\n|;
}

#sub
#showNCAAwards
#{
#	print qq|<DIV ALIGN="CENTER">|;
#	print "<H2>Carousels That Have Received the<BR>NCA Historic Carousel Award</H2>";
#	print qq|<TABLE BORDER="2" CELLSPACING="4"><TR><TD>|;
#	print qq|<TABLE ><TR>|;
#	print qq|<TD ALIGN='LEFT'><B>Year</B></TD>|;
#	print qq|<TD ALIGN='LEFT'><B>Location</B></TD>|;
#	print qq|<TD ALIGN='LEFT'><B>Description</B></TD>|;
#	print qq|</TR>|;
#	foreach $key (sort keycmp keys %StateRecs) {
#		splitCensusRec($NCARecs{$StateRecs{$key}});
#		if ($NCA_Hist_Award_Yr > 0) {
#			print "<TR>";
#			print qq|<TD align="LEFT">$NCA_Hist_Award_Yr</TD>|;
#			print qq|<TD ALIGN="LEFT">$P_City, $P_State</TD>|;
#			print qq|<TD ALIGN="LEFT">$Description</TD>|;
#			print "</TR>\n";
#			}
#		}
#	print qq|</TD></TR></TABLE>|;
#	print qq|</DIV>|;
#}


sub
showPhotoShows
{
#	print "<P>";
#	bulletTitle("Carousels That Have NCA Photo Shows", "", "");
#	print "<P>";
print <<EOPSP;
<P>The NCA Photo Show Project has been put into place to allow individuals to
contribute photographs of their favorite carousels to the  NCA website.
This ever-growing collection of photographs provides a unique opportunity
for visitors to our website to see carousels across the country without
leaving their homes.</P>
<P> More information on the Photo Show Project is available by <A HREF="/NCApsp.html">Clicking Here.</A><P>
<BR>
<HR>
<DIV ALIGN="CENTER">
<A HREF="#USA">American Carousels</A>&nbsp;|&nbsp;<A HREF="#CANADA">Canadian Carousels</A>
</DIV>
<HR>
EOPSP


	# Make an array of the carousels with photo shows (they must be listed in NCANumbers.txt)
	$first = 1;
	$numberFile = "$docRoot/admin/AllCensus/NCANumbers.txt";
	open(SHOWNUMBERS, "<$numberFile") || print "Can't open $numberFile<BR>\n";
	while (<SHOWNUMBERS>) {
		chomp;
		$line = $_;
		@parts = split/\s+/, $_, 4;
		if (@parts[1] ne "") {
			if (!$first) {
				@numbers{@parts[0]} = $line;
				}
			$first = 0;
			}
		}

	# find out how many American, how many Canadian,
	# save their nca numbers in arrays
	$USCount = 0;
	$CanCount = 0;
	foreach $key (sort CountryKeyCmpByStateName keys %CountryRecs) {
		splitCensusRec($NCARecs{$CountryRecs{$key}});
		$keyNo = int($NCA_No);
		if (@numbers{$keyNo} ne "") {
			# Found the entry!
			if (makeCountry($P_State) eq "America") {
				push @US_ID, $NCA_No;
				$USCount++;
				}
			else {
				push @CAN_ID, $NCA_No;
				$CanCount++;
				}
			}
		}

	$lastState = "";
	for ($ix = 0; $ix < 2; $ix++) {
		if ($ix == 0) {
			# american carousels
			@CarNo = @US_ID;
			}
		else {
			@CarNo = @CAN_ID;
			}
		if ($#CarNo >= 0) {
			$leftCount = int(($#CarNo) / 2);
			if ($ix == 0) {
				$countryTitle = "American Carousels with Photo Shows";
				print qq|<A ID="USA"></A>\n|;
				}
			else {
				$countryTitle = "Canadian Carousels with Photo Shows";
				print qq|</TABLE></TD></TR></TABLE><A ID="CANADA"></A><BR><BR>\n|;
				}
			startHighlightTable(95);
			print "<B><BR>$countryTitle<BR></B>\n";
			print qq|<IMG SRC="/images/hrbar.gif" ALT="" HEIGHT="3" WIDTH="75%"><BR>\n|;
			print qq|<SPAN  CLASS="NCAMenuText">\n|;
			$lastState = "";
			$vertBar = "";
			$ixCOunt = 0;
			for ($iy = 0; $iy <= $#CarNo; $iy++) {
				$keyNo = @CarNo[$iy];
				splitCensusRec($NCARecs{$keyNo});
				@parts = split/\s+/, @numbers{$keyNo};
				if (@parts[1] ne "") {
					if ($lastState ne $P_State) {
						$lastState = $P_State;
						print qq|$vertBar<A HREF="#$P_State">$P_State</A>|;
						$vertBar = " | ";
						if (++$ixCount % 16 == 0) {
							$vertBar = "<BR>";
							}
						}
					}
			}
			print "</SPAN>\n";
			print "<BR><BR>\n";
			endHighlightTable();
			print "<BR>\n";

			print qq|<TABLE BORDER="0" WIDTH="95%"><TR><TD VALIGN="TOP">\n|;
			print qq|<TABLE BORDER="0">\n|;

			$lastState = "";
			$needToBreak = 0;
			$NYFound = 0;
			for ($iy = 0; $iy <= $#CarNo; $iy++) {
				$keyNo = @CarNo[$iy];
				splitCensusRec($NCARecs{$keyNo});
				@parts = split/\s+/, @numbers{$keyNo};
				if ($NYFound == 0 && $P_State eq "NY") {
					$needToBreak = 1;
					$NYFound = 1;
					$leftCount = 1000000;
					}
				if (@parts[1] ne "") {
					if ($lastState ne $P_State) {
						if ($needToBreak) {
							print qq|</TABLE></TD><TD WIDTH="1"></TD><TD CLASS="highlightBorderLeft">&nbsp</TD><TD WIDTH="1"></TD><TD VALIGN="TOP"><TABLE BORDER="0">\n|;
							$needToBreak = 0;
							}
						$lastState = $P_State;
						print "<TR><TD>\n";
						print qq|<A ID="$P_State"></A>\n|;
						startHighlightTable(100);
						print "@statenames{$P_State}<BR>\n";
						endHighlightTable();
						print "<BR>\n";
						print "</TD></TR>\n";
						}
					print qq|<TR><TD><DIV ALIGN="CENTER">\n|;
					print qq|<A HREF="/psp/@parts[1]">|;
					print qq|$P_City, $P_State</A></DIV>\n|;
					print qq|<TABLE WIDTH="100%" BORDER="2" CELLPADDING="4"><TR><TD>\n|;
					print qq|<DIV CLASS="LeftPicture">|;
					startHighlightTable(1);
					print qq|<A HREF="/psp/@parts[1]">|;
					print qq|<IMG BORDER="0" ALT="" SRC="/psp/@parts[1]/@parts[2]"></A>|;
					endHighlightTable();
					print qq|</DIV>\n|;
					print qq|<A HREF="/psp/@parts[1]">|;
					print qq|$Park<BR>\n|;
					print qq|$Description|;
					print qq|<BR>$YR_Built| if ($YR_Built ne "");
					print qq|</A>\n|;
					print qq|</TD></TR></TABLE><BR>\n|;
					print qq|</TD></TR>\n|;
					if ($iy == $leftCount) {
						$needToBreak = 1;
						}
					$lastState = $P_State;
					}
				}
			}
		}
	print "</TABLE></TD></TR></TABLE>\n";
}

sub
isClassic
{
	$classicYr = @_[0];
	print "isClassic: $classicYr   " if $debug;
	$classicYr =~ s/^c.//i;
	$classicYr = substr($classicYr, 0, 4);
	if ($classicYr > 0 && $classicYr < $classicCutoffYr) {
		print "Yes\n" if $debug;
		return(1);
		}
	print "No\n" if $debug;
	return(0);
}


sub
makeCountry
{
	$fromState = $_[0];
	if ($fromState =~ /AB/i ||
		$fromState =~ /BC/i ||
		$fromState =~ /MB/i ||
		$fromState =~ /NB/i ||
		$fromState =~ /NL/i ||
		$fromState =~ /NS/i ||
		$fromState =~ /NT/i ||
		$fromState =~ /NU/i ||
		$fromState =~ /ON/i ||
		$fromState =~ /PE/i ||
		$fromState =~ /QC/i ||
		$fromState =~ /SK/i ||
		$fromState =~ /YT/i) {
		return("Canada");
		}
	return("America");
}

sub startHighlightTable
{
	my $widthPct = @_[0];
	print <<STARTHIGHLIGHTTABLE;
<DIV ALIGN="CENTER">
<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="$widthPct%">
<TR>
	<TD CLASS="HighlightBorderTopLeft"><IMG ALT="" SRC="/images/invis.gif" WIDTH="4"></TD>
	<TD CLASS="HighlightBorderTop" HEIGHT="4"></TD>
	<TD CLASS="HighlightBorderTopRight" WIDTH="4"></TD>
</TR>
<TR>
	<TD CLASS="HighlightBorderLeft" WIDTH="4" HEIGHT="100%"><IMG ALT="" SRC="/images/invis.gif"></TD>
	<TD BGCOLOR="#fffbcd" ALIGN="CENTER">
STARTHIGHLIGHTTABLE

}
sub endHighlightTable
{
	print <<ENDHIGHLIGHTTABLE;
</TD>
<TD CLASS="HighlightBorderRight" WIDTH="4"></TD>
</TR>
<TR>
<TD CLASS="HighlightBorderBottomLeft"><IMG ALT="" SRC="/images/invis.gif" WIDTH="4"></TD>
<TD CLASS="HighlightBorderBottom"></TD>
<TD CLASS="HighlightBorderBottomRight"><IMG ALT="" SRC="/images/invis.gif" WIDTH="4"></TD>
</TR>
</TABLE>
</DIV>
ENDHIGHLIGHTTABLE

}

sub addFile
{
	open(ADDER, "<@_[0]") || die "Can't open $_[0]\n";
	while (<ADDER>) {
		print $_;
		}
	close(ADDER);
}

sub countCarousels
{
	my $selectedState = @_[0];
	my $selectedBO = @_[1];
	my $selectedManuf = @_[2];
	my $selectedDate = @_[3];
	my $selectedClass = @_[4];
	my $selectedNCANo = @_[5];
	my $selectedCity = @_[6];
	my $areSelected = 0;
	my $areRecords = 0;

	foreach $key (sort CountryClassKeyCmp keys %CountryClassRecs) {
		splitCensusRec($NCARecs{$CountryClassRecs{$key}});
		if (($domestic && $Census_List_Type eq "dom") ||
		(($lost || 1) && $Census_List_Type eq "def") ||
		($international && $Census_List_Type eq "int")) {
			$areRecords++;
			}
		if (testCarousel($selectedState, $selectedBO, $selectedManuf, $selectedDate, $selectedClass, $selectedNCANo, $selectedCity)) {
			$areSelected++;
			}
		}
	print "countCarousels, Selected: $areSelected, records: $areRecords<BR>\n" if ($debug);
	($areSelected, $areRecords);
}

# =======================================================================
# Functions for Lost Census
# =======================================================================
sub findStateAbbrev {
	$longName = @_[0];
	foreach $key (keys %statenames) {
		if ($statenames{$key} eq $longName) {
			return $key;
			}
		}
	print "findStateAbbrev: Returning Unknown for state=$longName<BR>\n" if ($debug);
	return "Unknown";
}

sub cityClean {
	@cityParts = split/\|/, @_[0];
	$curCity = "";
	$cleanedCity = @cityParts[0] . "|" . @cityParts[1];
	shift @cityParts;
	shift @cityParts;
	foreach $thisCity (sort @cityParts) {
		if ($thisCity ne $curCity) {
			$cleanedCity .= "|" . $thisCity;
			$curCity = $thisCity;
			}
		}
	$cleanedCity;
}

sub CityPickList
{
	print qq|<SCRIPT type='text/javascript'>\n|;
	print qq|<!--\n|;
	print qq|document.write("<TR><TD ALIGN='RIGHT'><B><FONT SIZE='-1'>City:</FONT></B></TD><TD>");\n|;
	if ($stateToMatch eq $allStateTitle || $stateToMatch eq "") {
		print qq|document.write("<SELECT NAME='cityToMatch' disabled='True'>");\n|;
		print qq|document.write("<OPTION SELECTED>All Cities</OPTION>");\n|;
		print qq|document.write("<OPTION>$stateToMatch</OPTION>");\n|;
		}
	else {
		print qq|document.write("<SELECT NAME='cityToMatch'>");\n|;
		@cityNames = split/\|/, $stateCities{$stateToMatch};
		shift @cityNames;
		$cityIx = 0;
		foreach $someCity (sort @cityNames) {
			if ($someCity eq $cityToMatch) {
				print qq|document.write("<OPTION SELECTED VALUE='$cityIx'>$someCity</OPTION>");\n|;
				}
			else {
				print qq|document.write("<OPTION VALUE='$cityIx'>$someCity</OPTION>");\n|;
				}
			$cityIx++;
			}
		}
	print qq|document.write("</SELECT>");\n|;
	print qq|document.write("</TD></TR>")\n|;
	print qq|-->\n|;
	print qq|</SCRIPT>\n|;
}

sub SortPickList
{
	if ($lost) {
		print "<TR><TD ALIGN='RIGHT'><B><FONT SIZE='-1'>Sort by:</FONT></B></TD><TD>\n";

		my @sortChoices = (
			"State of Last Operation",
			"Manufacturer");

		# date picklist
		$selected = "";
		print "<SELECT NAME='sortToMatch'>\n";
		foreach $sortType (@sortChoices) {
			if ($sortType eq $sortToMatch) {
				print "<OPTION SELECTED>$sortType</OPTION>\n";
				}
			else {
				print "<OPTION>$sortType</OPTION>\n";
				}
			}
		print "</SELECT>\n";
		print "</TD></TR>\n";
	}
}

sub getLostSortState {
	my $stateToUse;
	$stateToUse = stripQuotes($Eighth_Loc_State);
	$stateToUse = stripQuotes($Seventh_Loc_State) if ($stateToUse eq "" || $stateToUse =~ /^Unk/i);
	$stateToUse = stripQuotes($Sixth_Loc_State) if ($stateToUse eq "" || $stateToUse =~ /^Unk/i);
	$stateToUse = stripQuotes($Fifth_Loc_State) if ($stateToUse eq "" || $stateToUse =~ /^Unk/i);
	$stateToUse = stripQuotes($Fourth_Loc_State) if ($stateToUse eq "" || $stateToUse =~ /^Unk/i);
	$stateToUse = stripQuotes($Third_Loc_State) if ($stateToUse eq "" || $stateToUse =~ /^Unk/i);
	$stateToUse = stripQuotes($Second_Loc_State) if ($stateToUse eq "" || $stateToUse =~ /^Unk/i);
	$stateToUse = stripQuotes($OL_State) if ($stateToUse eq "" || $stateToUse =~ /^Unk/i);
	$stateToUse = stripQuotes($P_State) if ($stateToUse eq "" || $stateToUse =~ /^Unk/i);
	print "getLostSortState: Returning $stateToUse<BR>\n" if ($debug);
	$stateToUse;
	}

sub makeManuf {

#	$#manufNames = -1;
#	open(MANUFDB, "<$myCensusFile");
#	open(MANUFOUT, ">manufacturers.txt");
#print MANUFOUT "Entering\n";
#	while (<MANUFDB>) {
#		chomp;
#		splitCensusRec($_);
#		$manufNames{$Description} = 1;
#print MANUFOUT "Description: $Description<BR>\n";
#		}
#	foreach $key (keys %manufNames) {
#print MANUFOUT "Key: $key<BR>\n";
#		print MANUFOUT "$key\n";
#		}
#    close(MANUFDB);
#	close(MANUFOUT);
	}

sub includeFile {
	my $includeLine = @_[0];
	my $pageTitle = @_[1];
	my @incParts = split/"/, $includeLine;
	print "includeFile, @incParts[1]<BR>\n" if ($debug);;
	open(INC, "<$docRoot/@incParts[1]") || die "Can't open $docRoot/@incParts[1]!<BR>\n";
	while (<INC>) {
		if ($_ =~ /include virtual=/) {
			@nestParts = split/\"/;
			system("cat $docRoot/@nestParts[1]");
			}
		else {
			s/<!--#echo var="WindowTitle"-->/$pageTitle/;
			s/<!--#echo var="ContentTitle" -->/$pageTitle/;
			print $_;
			}
		}
	close(INC);
	}

