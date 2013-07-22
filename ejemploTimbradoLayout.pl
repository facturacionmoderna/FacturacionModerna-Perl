#!/usr/bin/perl -w

use Module::Load;
use POSIX qw(strftime);use MIME::Base64;
use Class::Struct;


load 'FacturacionModerna/manipularXML.pl';
load 'FacturacionModerna/service.pl';

# Datos necesarios para el layout
my $rfc = "ESI920427886";
my $now = time();
$fecha_actual = strftime("%Y-%m-%dT%H:%M:%S", localtime($now));

$layout = generarLayout($rfc, $fecha_actual);

# Inicia timbrado
my $service = FacturacionModerna::Service->new();

# Asignación de los parámetros para timbrado
$service->url("https://t1demo.facturacionmoderna.com/timbrado/wsdl");
$service->emisorRFC($rfc);
$service->UserID('UsuarioPruebasWS');
$service->UserPass("b9ec2afa3361a59af4b4d102d3f704eabdf097d4");
my %opciones = ( 'generarCBB' => 'false', 'generarTXT' => 'true', 'generarPDF' => 'true' );
$service->timbrar($layout, \%opciones );
# Timbrado finalizado

print "\nTimbrado terminado, UUID:".$service->uuid. "\n";
print "\nXML:\n".$service->xml. "\n";

sub generarLayout {
  ($rfc, $fecha_actual) = @_;
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
 return $cfdi;
}
