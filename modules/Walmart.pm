package Walmart;


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
	my $self = { 'siteUrl' => $siteUrl, 'pageRequest' => "", 'pageResponse' => "", 'httpHeaders' => HTTP::Headers->new('User-Agent' => "Mozilla\/5.0 \(Windows NT 6.1; WOW64\) AppleWebKit\/537.36 \(KHTML, like Gecko\) Chrome\/27.0.1453.110 Safari\/537.36",  'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8', 'Accept-Language' => 'en-US,en;q=0.8', 'Accept-Encoding' => 'gzip,deflate,sdch', 'Connection' => 'keep-alive', 'Host' => 'www.walmart.com', 'Cookie' => ''), 'currentPageContent' => '', 'baseUrl' => '', 'groceries' => {}, 'userAgent' => LWP::UserAgent->new('agent' => "Mozilla\/5.0 \(Windows NT 6.1; WOW64\) AppleWebKit\/537.36 \(KHTML, like Gecko\) Chrome\/27.0.1453.110 Safari\/537.36"), 'cookies' => '' };
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


sub getGroceryCategoryLink{
	my $self = shift;
}
