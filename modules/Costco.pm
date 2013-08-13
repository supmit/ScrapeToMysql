package Costco;


use strict;
use warnings;

use HTTP::Request;
use HTTP::Response;
use HTTP::Headers;
use LWP::UserAgent;
use HTML::TokeParser;

use Cwd;
use DBI;
use Data::Dumper;



sub new{
    my $class = shift;
    my $siteUrl = shift;
    my $self = { 'siteUrl' => $siteUrl, 'pageRequest' => "", 'pageResponse' => "", 'httpHeaders' => HTTP::Headers->new('User-Agent' => "Mozilla\/5.0 \(Windows NT 6.1; WOW64\) AppleWebKit\/537.36 \(KHTML, like Gecko\) Chrome\/27.0.1453.110 Safari\/537.36",  'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8', 'Accept-Language' => 'en-US,en;q=0.8', 'Accept-Encoding' => 'gzip,deflate,sdch', 'Connection' => 'keep-alive', 'Host' => 'www.costco.com', 'Cookie' => ''), 'currentPageContent' => '', 'baseUrl' => '', 'groceries' => {}, 'userAgent' => LWP::UserAgent->new('agent' => "Mozilla\/5.0 \(Windows NT 6.1; WOW64\) AppleWebKit\/537.36 \(KHTML, like Gecko\) Chrome\/27.0.1453.110 Safari\/537.36"), 'cookies' => '' };
	$self->{'userAgent'}->protocols_allowed([ 'http', 'https' ]);
	return bless $self, $class;
}


sub getHomePage{
	my $self = shift;
	$self->{'pageRequest'} = HTTP::Request->new('GET', $self->{'siteUrl'}, $self->{'httpHeaders'});
	$self->{'pageResponse'} = $self->{'userAgent'}->request($self->{'pageRequest'});
	if($self->{'pageResponse'}->is_success){
		$self->{'currentPageContent'} = $self->{'pageResponse'}->decoded_content;
	}
	return($self->{'currentPageContent'});
}

# The categories relevant for groceries are the 'Food & Gift Baskets' link.
sub getGroceriesLinks{
	my $self = shift;
	my $content = shift;
	my $parser = HTML::TokeParser->new(\$content);
	while(my $anchor = $parser->get_tag("a")){
		next if(!defined($anchor->[1]{'name'}));
		if($anchor->[1]{'name'} eq "Food & Gift Baskets"){ # We have found the desired anchor tag.
			my $link = $anchor->[1]{'href'};
			return $link;
		}
	}
	return undef;
}

sub _getCookiesFromResponseHeaders{
	my $self = shift;
	my $cookies = $self->{'pageResponse'}->header("Set-Cookie");
	return($cookies);
}


sub getPage{
	my $self = shift;
	my $url = shift;
	$self->{'cookies'} = $self->_getCookiesFromResponseHeaders();
	$self->{'httpHeaders'}->header('Cookie' => $self->{'cookies'});
	$self->{'pageRequest'} = HTTP::Request->new('GET', $url, $self->{'httpHeaders'});
	$self->{'pageResponse'} = $self->{'userAgent'}->request($self->{'pageRequest'});
	if($self->{'pageResponse'}->is_success){
		$self->{'currentPageContent'} = $self->{'pageResponse'}->decoded_content;
	}
	return($self->{'currentPageContent'});
}


sub getSubCategoryLinks{
	my $self = shift;
	my $content = shift || $self->{'currentPageContent'};
	my $parser = HTML::TokeParser->new(\$content);
	my @subcatlinks = ();
	while(my $h2Tag = $parser->get_tag("h2")){
		my $header = $parser->get_trimmed_text("/h2");
		if($header eq "Shop by category"){
			while(my $atag = $parser->get_tag("a")){
				my $link = $atag->[1]{'href'};
				if($link =~ /\.html$/){
					push(@subcatlinks, $link);
				}
				else{
					last;
				}
			}
			last;
		}
	}
	return(\@subcatlinks);
}


sub getProductsListPageLinks{
	my $self = shift;
	my $content = shift;
	my @productsLinks = ();
	# Check if this is a product page or a sub-category page... If it is a product list page, we will find a 
	# div tag with class "scMemberProductType".
	my $parser = HTML::TokeParser->new(\$content);
	my $productFlag = 0;
	while(my $divtag = $parser->get_tag("div")){
		$productFlag = 1 if ($divtag->[1]{'class'} eq "scMemberProductType");
	}
	return([]) if($productFlag); # Returning a reference to an empty list if $content is a product list page.
	$parser = HTML::TokeParser->new(\$content); # Re-initialize $parser
	my $h2Tag = $parser->get_tag("h2");
	my $h2Text = $parser->get_trimmed_text("/h2");
	if($h2Text eq "Shop by category"){
		while(my $atag = $parser->get_tag("a")){
			my $link = $atag->[1]{'href'};
			if($link =~ /\.html$/){
				push(@productsLinks, $link);
			}
			else{
				last;
			}
		}
	}
	return(\@productsLinks);
}


sub getProductsListPage{
	my $self = shift;
	my $prodPageUrl = shift;
	my $content = $self->getPage($prodPageUrl);
	return($content);
}


# '%dataStore' is a hash whose keys are the category names and the values are a list of hashes containing 
# information of all the products under that category. This hash has product names as keys and a list containing
# other product information (like price, unit and location) as values.
sub extractProductInfo{
	my $self = shift;
	my $prodPageContent = shift || $self->{'currentPageContent'};
	my %dataStore = ();
	my $parser = HTML::TokeParser->new(\$prodPageContent);
	my $categoryTag = $parser->get_tag("h1");
	my $category = $parser->get_trimmed_text("/h1");
	$dataStore{$category} = [];
	while(my $spanTag = $parser->get_tag("span")){
		my $productInfo = {};
		if($spanTag->[1]{'class'} eq "short-desc"){
			my $name = $parser->get_trimmed_text("/span");
			my $divTag = $parser->get_tag("div");
			my $price = "";
			$price = $parser->get_trimmed_text("/div") if($divTag->[1]{'class'} eq "currency ");
			$productInfo->{$name} = [ $price, ];
			push(@{$dataStore{$category}}, $productInfo);
		}
	}
	return(\%dataStore);
}




1;
