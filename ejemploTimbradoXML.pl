#!/usr/bin/perl -w

use Module::Load;
use POSIX qw(strftime);use MIME::Base64;
use Class::Struct;


load 'FacturacionModerna/manipularXML.pl';
load 'FacturacionModerna/service.pl';

# Datos para Sellado
my $numero_certificado = "20001000000200000192";
my $archivo_cer = "utilerias/certificados/20001000000200000192.cer";
my $archivo_pem = "utilerias/certificados/20001000000200000192.key.pem";
my $rfc = "ESI920427886";

$xml = FacturacionModerna::manipularXML::generarXML($rfc);
$xml_sellado = FacturacionModerna::manipularXML::sellarCFDI($xml, $numero_certificado, $archivo_cer, $archivo_pem);

my $service = FacturacionModerna::Service->new();

# Asignación de los parámetros para timbrado
$service->url("https://t1demo.facturacionmoderna.com/timbrado/wsdl");
$service->emisorRFC($rfc);
$service->UserID('UsuarioPruebasWS');
$service->UserPass("b9ec2afa3361a59af4b4d102d3f704eabdf097d4");
my %opciones = ( 'generarCBB' => 'false', 'generarTXT' => 'true', 'generarPDF' => 'true' );
$service->timbrar($xml_sellado, \%opciones );
# Timbrado finalizado


print "\nTimbrado terminado, UUID:".$service->uuid. "\n";
print "\nXML:\n".$service->xml. "\n";
