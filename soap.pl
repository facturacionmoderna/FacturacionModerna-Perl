#!/usr/bin/perl -w

# declare usage of SOAP::Lite
use SOAP::Lite( +trace => 'all', maptype => {} );
use POSIX qw(strftime);
use MIME::Base64;
use Data::Dumper;
use Class::Struct;

# Generar CFDI
my $now = time();
$fecha_actual = strftime("%Y-%m-%dT%H:%M:%S", localtime($now));
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

rfc|ESI920427886
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


# specifying this subroutine, causes basic auth to use
# its credentials when challenged
my $rfc = "ESI920427886";
my $url_timbrado = "https://t1demo.facturacionmoderna.com/timbrado/wsdl";
my $user_id = "UsuarioPruebasWS";
my $user_password = "b9ec2afa3361a59af4b4d102d3f704eabdf097d4";

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

my $response = $soap->requestTimbrarCFDI(@params);
#my $data = SOAP::Data->new($response)->dataof('//xml');
# invoke the SOAP call
print "**********\n";
print Dumper($response);
print "**********\n";

print "*******\n";
print decode_base64($response->{'xml'});
print "******\n";

print "*******\n";
print decode_base64($response->{'txt'});
print "******\n";

print "Fin de ejecucion"
