#!/usr/bin/perl -w

# declare usage of SOAP::Lite
use Module::Load;
use SOAP::Lite;#( +trace => 'all', maptype => {} );
use POSIX qw(strftime);use MIME::Base64;
use Data::Dumper;
use Class::Struct;
use XML::LibXML;

load 'SelladoCFDI.pl';

# Generar CFDI
my $now = time();
$fecha_actual = strftime("%Y-%m-%dT%H:%M:%S", localtime($now));
# specifying this subroutine, causes basic auth to use
# its credentials when challenged
$numero_certificado = "20001000000200000192";
$archivo_cer = "utilerias/certificados/20001000000200000192.cer";
$archivo_pem = "utilerias/certificados/20001000000200000192.key.pem";

my $rfc = "ESI920427886";
my $url_timbrado = "https://t1demo.facturacionmoderna.com/timbrado/wsdl";
my $user_id = "UsuarioPruebasWS";
my $user_password = "b9ec2afa3361a59af4b4d102d3f704eabdf097d4";


$xml = <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<cfdi:Comprobante xsi:schemaLocation="http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv32.xsd" xmlns:cfdi="http://www.sat.gob.mx/cfd/3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.2" fecha="$fecha_actual" tipoDeComprobante="ingreso" noCertificado="" certificado="" sello="" formaDePago="Pago en una sola exhibición" metodoDePago="Transferencia Electrónica" NumCtaPago="No identificado" LugarExpedicion="San Pedro Garza García, Mty." subTotal="10.00" total="11.60">
<cfdi:Emisor nombre="EMPRESA DEMO" rfc="$rfc">
  <cfdi:RegimenFiscal Regimen="No aplica"/>
</cfdi:Emisor>
<cfdi:Receptor nombre="PUBLICO EN GENERAL" rfc="XAXX010101000"></cfdi:Receptor>
<cfdi:Conceptos>
   <cfdi:Concepto cantidad="10" unidad="No aplica" noIdentificacion="00001" descripcion="Servicio de Timbrado" valorUnitario="1.00" importe="10.00">
    </cfdi:Concepto>
</cfdi:Conceptos>
<cfdi:Impuestos totalImpuestosTrasladados="1.60">
  <cfdi:Traslados>
    <cfdi:Traslado impuesto="IVA" tasa="16.00" importe="1.6"></cfdi:Traslado>
  </cfdi:Traslados>
</cfdi:Impuestos>
</cfdi:Comprobante>
XML
$cfdi = <<LAYOUT;
[Encabezado]

serie|
fecha|$fecha_actual
folio|
tipoDeComprobante|ingreso
formaDePago|PAGO EN UNA SOLA EXHIBICIÓN
metodoDePago|Transferencía Electrónica
condicionesDePago|Contado
NumCtaPago|No identificado
subTotal|10.00
descuento|0.00
total|11.60
Moneda|MXN
noCertificado|
LugarExpedicion|Nuevo León, México.

[Datos Adicionales]

tipoDocumento|Factura
observaciones|

[Emisor]

rfc|$rfc
nombre|EMPRESA DE MUESTRA S.A de C.V.
RegimenFiscal|REGIMEN GENERAL DE LEY

[DomicilioFiscal]

calle|Calle
noExterior|Número Ext.
noInterior|Número Int.
colonia|Colonia
localidad|Localidad
municipio|Municipio
estado|Nuevo León
pais|México
codigoPostal|66260

[ExpedidoEn]
calle|Calle sucursal
noExterior|
noInterior|
colonia|
localidad|
municipio|Nuevo León
estado|Nuevo León
pais|México
codigoPostal|77000

[Receptor]
rfc|XAXX010101000
nombre|PÚBLICO EN GENERAL

[Domicilio]
calle|Calle
noExterior|Num. Ext
noInterior|
colonia|Colonia
localidad|San Pedro Garza García
municipio|
estado|Nuevo León
pais|México
codigoPostal|66260

[DatosAdicionales]

noCliente|09871
email|edgar.duran\@facturacionmoderna.com

[Concepto]

cantidad|1
unidad|No aplica
noIdentificacion|
descripcion|Servicio Profesional
valorUnitario|10.00
importe|10.00


[ImpuestoTrasladado]

impuesto|IVA
importe|1.60
tasa|16.00

LAYOUT


$encoded = encode_base64($cfdi);
# declare the SOAP endpoint here
my $soap = SOAP::Lite->service($url_timbrado);

# create a new incident with the following short_description and category
#my @params = ( SOAP::Data->name( emisorRFC => $rfc ) );
#  push(@params, SOAP::Data->name( UserID => $user_id) );
#  push(@params, SOAP::Data->name( UserPass => $user_password) );
#  push(@params, SOAP::Data->name( text2CFDI => $encoded ) );
#  push(@params, SOAP::Data->name( generarCBB => 'true') );
#  push(@params, SOAP::Data->name( generarTXT => 'true') );
#  push(@params, SOAP::Data->name( generarPDF => 'false') );
my @params = { emisorRFC => $rfc,
  UserID => $user_id,
  UserPass => $user_password,
  text2CFDI => $encoded,
  generarCBB => 'true',
  generarTXT => 'true',
  generarPDF => 'false'};

our $error = 0;
sub ErrorHappen {
  $error = 1;
}
our $response;
eval {
  $response = $soap->requestTimbrarCFDI(@params);
} || ErrorHappen;

unless ($error) {
  print "**********\n";
  print Dumper($response);
  print "**********\n";

  print "*******\n";
  my $cfdi_xml = decode_base64($response->{'xml'});
  my $parser = XML::LibXML->new();
  my $xdoc   = $parser->parse_string($cfdi_xml);

  #$xdoc->registerXPathNamespace("tfd", "http://www.sat.gob.mx/TimbreFiscalDigital");
  my $xpc = XML::LibXML::XPathContext->new($xdoc);
  $xpc->registerNs("tfd", "http://www.sat.gob.mx/TimbreFiscalDigital");
  my @tfd = $xpc->findnodes('//tfd:TimbreFiscalDigital');

  my $uuid = @tfd[0]->getAttribute('UUID');
  print "$cfdi_xml\n******\n";
  print "$uuid\n******\n";

  print "*******\n";
  print decode_base64($response->{'txt'});
  print "******\n";

  print "**Guardar PNG**\n";
  my $out;
  open($out, '>:raw', 'comprobantes/imagen.png') or die "Unable to open: $!";
  print $out decode_base64($response->{'png'});
  close($out);
} else
{
   die "@_ Oh crap\!";
}
#my $data = SOAP::Data->new($response)->dataof('//xml');
# invoke the SOAP call
print "Fin de ejecucion";


