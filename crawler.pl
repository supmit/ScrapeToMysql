#!/usr/bin/perl

use strict;
use warnings;

use DBI;

sub BEGIN{
	push(@INC, './modules');
}

use Costco;
use Walmart;

print "Starting to scrape costco.com\n";
my $cr = Costco->new("http://www.costco.com");

my $DBNAME = "ShoperTUR";
my $DBHOST = "50.63.244.197";
my $DBUSER = "ShoperTUR";
my $DBPASSWD = 'FJD#@tBO5';
my $dbh = dbConnect($DBNAME, $DBHOST, $DBUSER, $DBPASSWD);

my $content = $cr->getHomePage();
my $giftsUrl = $cr->getGroceriesLinks($content);
$content = $cr->getPage($giftsUrl);
my $subcatlinksref = $cr->getSubCategoryLinks($content);
my $pageCtr = 1;
foreach my $link (@{$subcatlinksref}){
	$content = $cr->getPage($link);
	my $prodPageLinksRef = $cr->getProductsListPageLinks($content);
	my $prodPageContent = $content;
	if (scalar(@{$prodPageLinksRef}) > 0){
		foreach my $prodlink (@{$prodPageLinksRef}){
			print $prodlink."\n";
			$prodPageContent = $cr->getProductsListPage($prodlink);
			my $dataStore = $cr->extractProductInfo($prodPageContent);
			my $filename = "prodpages\\prodpage_".$pageCtr.".html";
			#open(FH, ">>$filename");
			foreach my $cat (keys %{$dataStore}){
				my $level2 = $dataStore->{$cat};
				foreach my $prodhash (@{$level2}) {
					foreach my $prodname (keys %{$prodhash}) {
						my $registered = chr(174);
						my $trademark = chr(8482);
						my $copyright = chr(169);
						my ($brandname, $prodname2) = split(/$registered/, $prodname) if($prodname =~ /$registered/);
						($brandname, $prodname2) = split(/$trademark/, $prodname) if($prodname =~ /$trademark/);
						($brandname, $prodname2) = split(/$copyright/, $prodname) if($prodname =~ /$copyright/);
						#print FH $cat." ========>> ".$brandname." ==========>> ".$prodname." ======>> ".$prodhash->{$prodname}[0]."\n";
						$prodhash->{$prodname}[0] =~ s/\$//g;
						if (!$prodhash->{$prodname}[0]) {
							$prodhash->{$prodname}[0] = "0.00";
						}
						my $exists = searchSQL($dbh, $prodname, $cat, 'costco.com');
						if(!$exists){
							my $insert_sql = "insert into products (productName, category, price, srcWebsite, brand, location) values (\"".$prodname."\", \"".$cat."\", \"".$prodhash->{$prodname}[0]."\", \"costco.com\", \"".$brandname."\", \"\")";
							my $insert_sth = $dbh->prepare($insert_sql);
							$insert_sth->execute();
						}
						else{
							my $update_sql = "update products set price=\"".$prodhash->{$prodname}[0]."\", brand=\"".$brandname."\", location=\"\" where productName=\"".$prodname."\" and category=\"".$cat."\" and srcWebsite='costco.com'";
							my $update_sth = $dbh->prepare($update_sql);
							$update_sth->execute();
						}
					}
				}
			}
			#close FH;
		}
	}
	else{
		my $filename = "prodpages\\prodpage_".$pageCtr.".html";
		my $dataStore = $cr->extractProductInfo($prodPageContent);
		#open(FH, ">>$filename");
		foreach my $cat (keys %{$dataStore}){
			my $level2 = $dataStore->{$cat};
			foreach my $prodhash (@{$level2}) {
				foreach my $prodname (keys %{$prodhash}) {
					my $registered = chr(174);
					my $trademark = chr(8482);
					my $copyright = chr(169);
					my ($brandname, $prodname2) = split(/$registered/, $prodname) if($prodname =~ /$registered/);
					($brandname, $prodname2) = split(/$trademark/, $prodname) if($prodname =~ /$trademark/);
					($brandname, $prodname2) = split(/$copyright/, $prodname) if($prodname =~ /$copyright/);
					#print FH $cat." ========>> ".$brandname." =========>> ".$prodname." ======>> ".$prodhash->{$prodname}[0]."\n";
					$prodhash->{$prodname}[0] =~ s/\$//g;
					if (!$prodhash->{$prodname}[0]) {
						$prodhash->{$prodname}[0] = "0.00";
					}
					my $exists = searchSQL($dbh, $prodname, $cat, 'costco.com');
					if(!$exists){
						my $insert_sql = "insert into products (productName, category, price, srcWebsite, brand, location) values (\"".$prodname."\", \"".$cat."\", \"".$prodhash->{$prodname}[0]."\", \"costco.com\", \"".$brandname."\", \"\")";
						my $insert_sth = $dbh->prepare($insert_sql);
						$insert_sth->execute();
					}
					else{
						my $update_sql = "update products set price=\"".$prodhash->{$prodname}[0]."\", brand=\"".$brandname."\", location=\"\" where productName=\"".$prodname."\" and category=\"".$cat."\" and srcWebsite='costco.com'";
						my $update_sth = $dbh->prepare($update_sql);
						$update_sth->execute();
					}
				}
			}
		}
		#close FH;
		$pageCtr++;
	}
}
dbDisconnect($dbh);
print "Done scraping costco.com\n";




## ======================== Database connection and operational subroutines =======================

sub dbDisconnect{
	my $dbh = shift;
	$dbh->disconnect();
	undef $dbh;
}

sub dbConnect{
	my $dbName = shift;
	my $dbHost = shift;
	my $dbUser = shift;
	my $dbPasswd = shift;
	my $dsn = "DBI:mysql:".$dbName.":".$dbHost;
	my $dbh = DBI->connect($dsn, $dbUser, $dbPasswd) || die "Could not connect to database: $!\n";
	return $dbh;
}


sub searchSQL{
	my $dbh = shift;
	my $prodName = shift;
	my $category = shift;
	my $website = shift;
	my $select_sql = "select count(*) as count_rec from products where productName='".$prodName."' and srcWebsite='".$website."' and category='".$category."'";
	my $select_sth = $dbh->prepare($select_sql);
	$select_sth->execute();
	my $rec = $select_sth->fetchrow_hashref();
	if($rec->{'count_rec'} > 0){
		return(1);
	}
	else{
		return(0);
	}
}
