#!/usr/bin/perl -w
package FacturacionModerna::Service;
use strict;

sub new(){
  my $self = {
    _UserID => undef,
    _UserPass => undef,
  }
}

sub timbrarCFDI(){
  $encoded = encode_base64($cfdi);
  # declare the SOAP endpoint here
  my $soap = SOAP::Lite->service($url_timbrado);

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
  print "Fin de ejecucion";
}
