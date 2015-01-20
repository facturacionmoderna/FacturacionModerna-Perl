#!/usr/bin/perl -w
package FacturacionModerna::manipularXML;
use strict;

use MIME::Base64;

use POSIX qw(strftime);
use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;
use IO::All;
use XML::LibXML;
use XML::LibXSLT;

sub sellarCFDI {
  my ($xml, $numero_certificado, $archivo_cer, $archivo_pem) = @_;
  # Leer los archivos de certificados
  my $key_string;
  io($archivo_pem) > $key_string;
  my $certificado;
  io($archivo_cer) > $certificado;

  # Codificación del certificado
  $certificado = encode_base64($certificado);
  $certificado =~ s/\n//g;
  $certificado =~ s/\r//g;

  # Generación de la cadena original con base a los XSLT
  my $parser = XML::LibXML->new();
  my $xslt = XML::LibXSLT->new();

  my $xdoc    = $parser->parse_string($xml);
  my $xsl    = $parser->parse_file('utilerias/xslt32/cadenaoriginal_3_2.xslt');

  $xslt = $xslt->parse_stylesheet($xsl);
  my $result = $xslt->transform($xdoc);
  my $html = $xslt->output_string($result);
  # Generación del sello con base a la llave privada
  my $private = Crypt::OpenSSL::RSA->new_private_key($key_string);
  my $sig = $private->sign($html);
  my $sello = encode_base64($sig);
  $sello =~ s/\n//g;
  $sello =~ s/\r//g;

  # Se modifica el XML para agregar los datos
  my @c = $xdoc->getElementsByTagNameNS('http://www.sat.gob.mx/cfd/3', 'Comprobante');
  my $node = @c[0];
  $node->setAttribute('sello', $sello);
  $node->setAttribute('certificado', $certificado);
  $node->setAttribute('noCertificado', $numero_certificado);

  return $xdoc->toString;
}

sub sellarRetenciones {
  my ($xml, $archivo_cer, $archivo_pem) = @_;
  # Leer los archivos de certificados
  my $key_string;
  io($archivo_pem) > $key_string;
  my $certificado;
  io($archivo_cer) > $certificado;

  # Codificación del certificado
  $certificado = encode_base64($certificado);
  $certificado =~ s/\n//g;
  $certificado =~ s/\r//g;

  # Generación de la cadena original con base a los XSLT
  my $parser = XML::LibXML->new();
  my $xslt = XML::LibXSLT->new();
  my $xdoc    = $parser->parse_string($xml);
  my $xsl    = $parser->parse_file('utilerias/retenciones_xslt/retenciones.xslt');

  my @c = $xdoc->getElementsByTagNameNS('http://www.sat.gob.mx/esquemas/retencionpago/1', 'Retenciones');

  $xslt = $xslt->parse_stylesheet($xsl);
  my $result = $xslt->transform($xdoc);
  my $html = $xslt->output_string($result);

  print $html;

  # Generación del sello con base a la llave privada
  my $private = Crypt::OpenSSL::RSA->new_private_key($key_string);
  my $sig = $private->sign($html);
  my $sello = encode_base64($sig);
  $sello =~ s/\n//g;
  $sello =~ s/\r//g;

  # Agregar Sello y Certificado
  my $node = @c[0];
  $node->setAttribute('Sello', $sello);
  $node->setAttribute('Cert', $certificado);

  return $xdoc->toString;
}

sub generarXML {
  my $rfc = $_[0];
  my $now = time();
  my $fecha_actual = strftime("%Y-%m-%dT%H:%M:%S", localtime($now));
  my $xml = <<XML;
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
  return $xml;
}

sub generarXMLRetenciones {
  my $rfc = $_[0];
  my $numCert = $_[1];
  my $now = time();
  my $fecha_actual = strftime("%Y-%m-%dT%H:%M:%S", localtime($now));

  my $xml = <<XML;
<?xml version="1.0" encoding="UTF-8"?>
  <retenciones:Retenciones xmlns:retenciones="http://www.sat.gob.mx/esquemas/retencionpago/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sat.gob.mx/esquemas/retencionpago/1 http://www.sat.gob.mx/esquemas/retencionpago/1/retencionpagov1.xsd" Version="1.0" FolioInt="RetA" Sello="" NumCert="$numCert" Cert="" FechaExp="$fecha_actual-06:00" CveRetenc="05">
      <retenciones:Emisor RFCEmisor="$rfc" NomDenRazSocE="Empresa retenedora ejemplo"/>
      <retenciones:Receptor Nacionalidad="Nacional">
          <retenciones:Nacional RFCRecep="XAXX010101000" NomDenRazSocR="Publico en General"/>
      </retenciones:Receptor>
      <retenciones:Periodo MesIni="12" MesFin="12" Ejerc="2014"/>
      <retenciones:Totales montoTotOperacion="33783.75" montoTotGrav="35437.50" montoTotExent="0.00" montoTotRet="7323.75">
          <retenciones:ImpRetenidos BaseRet="35437.50" Impuesto="02" montoRet="3780.00" TipoPagoRet="Pago definitivo"/>
          <retenciones:ImpRetenidos BaseRet="35437.50" Impuesto="01" montoRet="3543.75" TipoPagoRet="Pago provisional"/>
      </retenciones:Totales>
  </retenciones:Retenciones>
XML
  return $xml;
}

1;
