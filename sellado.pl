#!/usr/bin/perl -w


use MIME::Base64;


use POSIX qw(strftime);
use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;
use IO::All;
use XML::LibXML;
use XML::LibXSLT;

# not necessary if we have /dev/random:
#Crypt::OpenSSL::Random::random_seed($good_entropy);
#Crypt::OpenSSL::RSA->import_random_seed();
#$rsa_pub = Crypt::OpenSSL::RSA->new_public_key($key_string);
#$rsa_pub->use_sslv23_padding(); # use_pkcs1_oaep_padding is the default
#$ciphertext = $rsa->encrypt($plaintext);
#
#$rsa_priv = Crypt::OpenSSL::RSA->new_private_key($key_string);
#$plaintext = $rsa->encrypt($ciphertext);
#
#$rsa = Crypt::OpenSSL::RSA->generate_key(1024); # or
#$rsa = Crypt::OpenSSL::RSA->generate_key(1024, $prime);
#
#print "private key is:\n", $rsa->get_private_key_string();
#print "public key (in PKCS1 format) is:\n",
#$rsa->get_public_key_string();
#print "public key (in X509 format) is:\n",
#$rsa->get_public_key_x509_string();

#$rsa_priv->use_md5_hash(); # use_sha1_hash is the default
#$signature = $rsa_priv->sign($plaintext);
#print "Signed correctly\n" if ($rsa->verify($plaintext, $signature));


# Generar CFDI
my $now = time();
$fecha_actual = strftime("%Y-%m-%dT%H:%M:%S", localtime($now));

my $rfc = "ESI920427886";
$numero_certificado = "20001000000200000192";
$archivo_cer = "utilerias/certificados/20001000000200000192.cer";
$archivo_pem = "utilerias/certificados/20001000000200000192.key.pem";

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

my $key_string;
io($archivo_pem) > $key_string;
my $certificado;
io($archivo_cer) > $certificado;

$certificado = encode_base64($certificado);
$certificado =~ s/\n//g;
$certificado =~ s/\r//g;

$private = Crypt::OpenSSL::RSA->new_private_key($key_string);

print "Certificado: $certificado\n";


my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();

my $xdoc    = $parser->parse_string($xml);
my $xsl    = $parser->parse_file('utilerias/xslt32/cadenaoriginal_3_2.xslt');

$xslt = $xslt->parse_stylesheet($xsl);
my $result = $xslt->transform($xdoc);
my $html = $xslt->output_string($result);
print "$html\n";

$sig= $private->sign($html);
$sello = encode_base64($sig);
$sello =~ s/\n//g;
$sello =~ s/\r//g;
print "$sello";

#$c = $xdoc->getElementsByTagNameNS('http://www.sat.gob.mx/cfd/3', 'Comprobante')->item(0);
#$c->setAttribute('sello', $sello);
#$c->setAttribute('certificado', $certificado);
#$c->setAttribute('noCertificado', $numero_certificado);
#return $xdoc->saveXML();

@c = $xdoc->getElementsByTagNameNS('http://www.sat.gob.mx/cfd/3', 'Comprobante');
$node = @c[0];
$node->setAttribute('sello', $sello);
$node->setAttribute('certificado', $certificado);
$node->setAttribute('noCertificado', $numero_certificado);

print $xdoc->toString;
