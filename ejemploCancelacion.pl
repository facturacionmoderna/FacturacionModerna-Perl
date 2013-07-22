#!/usr/bin/perl -w

use Module::Load;
use POSIX qw(strftime);use MIME::Base64;
use Data::Dumper;
use Class::Struct;


load 'FacturacionModerna/manipularXML.pl';
load 'FacturacionModerna/service.pl';

my $uuid = "C536E2DC-9950-483D-88F8-54F2FCB101E7";
my $rfc = "ESI920427886";
my $service = FacturacionModerna::Service->new();

# Asignación de los parámetros para timbrado
$service->url("https://t1demo.facturacionmoderna.com/timbrado/wsdl");
$service->emisorRFC($rfc);
$service->UserID('UsuarioPruebasWS');
$service->UserPass("b9ec2afa3361a59af4b4d102d3f704eabdf097d4");
$service->cancelar($uuid, \%opciones );
# Timbrado finalizado



