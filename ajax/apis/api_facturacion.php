<?php

require_once("signature.php");

class ApiFacturacion
{

    static public function Genera_XML_Factura_Boleta($path_xml, $name_xml, $datos_emisor, $datos_cliente, $venta, $detalle_venta = null)
    {

        $doc = new DOMDocument();
        $doc->formatOutput = FALSE;
        $doc->preserveWhiteSpace = TRUE;
        $doc->encoding = 'utf-8';

        //CABECERA
        $xml = '<?xml version="1.0" encoding="utf-8"?>
                <Invoice xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:ccts="urn:un:unece:uncefact:documentation:2" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" xmlns:qdt="urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2" xmlns:udt="urn:un:unece:uncefact:data:specification:UnqualifiedDataTypesSchemaModule:2" xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2">
                    <ext:UBLExtensions>
                        <ext:UBLExtension>
                            <ext:ExtensionContent/>
                        </ext:UBLExtension>
                    </ext:UBLExtensions>
                    <cbc:UBLVersionID>2.1</cbc:UBLVersionID>
                    <cbc:CustomizationID schemeAgencyName="PE:SUNAT">2.0</cbc:CustomizationID>
                    <cbc:ProfileID schemeName="Tipo de Operacion" schemeAgencyName="PE:SUNAT" schemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo17">' . $venta['tipo_operacion'] . '</cbc:ProfileID>
                    <cbc:ID>' . $venta['serie'] . '-' . $venta['correlativo'] . '</cbc:ID>
                    <cbc:IssueDate>' . $venta['fecha_emision'] . '</cbc:IssueDate>
                    <cbc:IssueTime>' . $venta['hora_emision'] . '</cbc:IssueTime>
                    <cbc:DueDate>' . $venta['fecha_vencimiento'] . '</cbc:DueDate>
                    <cbc:InvoiceTypeCode listAgencyName="PE:SUNAT" listName="Tipo de Documento" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01" listID="0101" name="Tipo de Operacion">' . $venta['tipo_comprobante'] . '</cbc:InvoiceTypeCode>
                    <cbc:DocumentCurrencyCode listID="ISO 4217 Alpha" listName="Currency" listAgencyName="United Nations Economic Commission for Europe">' . $venta['moneda'] . '</cbc:DocumentCurrencyCode>
                    <cbc:LineCountNumeric>1</cbc:LineCountNumeric>';

        //DATOS DEL FIRMANTE:
        $xml .= '
                    <cac:Signature>
                        <cbc:ID>' . $venta['serie'] . '-' . $venta['correlativo'] . '</cbc:ID>
                        <cac:SignatoryParty>
                            <cac:PartyIdentification>
                                <cbc:ID>' . $datos_emisor['ruc'] . '</cbc:ID>
                            </cac:PartyIdentification>
                            <cac:PartyName>
                                <cbc:Name><![CDATA[' . $datos_emisor['razon_social'] . ']]></cbc:Name>
                            </cac:PartyName>
                        </cac:SignatoryParty>
                        <cac:DigitalSignatureAttachment>
                            <cac:ExternalReference>
                                <cbc:URI>#SignatureSP</cbc:URI>
                            </cac:ExternalReference>
                        </cac:DigitalSignatureAttachment>
                    </cac:Signature>';

        //DATOS DE LA EMPRESA EMISORA:
        $xml .= '
                    <cac:AccountingSupplierParty>
                        <cac:Party>
                            <cac:PartyIdentification>
                                <cbc:ID schemeID="' . $datos_emisor['tipo_documento'] . '" schemeName="Documento de Identidad" schemeAgencyName="PE:SUNAT" schemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06">' . $datos_emisor['ruc'] . '</cbc:ID>
                            </cac:PartyIdentification>
                            <cac:PartyName>
                                <cbc:Name><![CDATA[' . $datos_emisor['razon_social'] . ']]></cbc:Name>
                            </cac:PartyName>
                            <cac:PartyTaxScheme>
                                <cbc:RegistrationName><![CDATA[' . $datos_emisor['razon_social'] . ']]></cbc:RegistrationName>
                                <cbc:CompanyID schemeID="' . $datos_emisor['tipo_documento'] . '" schemeName="SUNAT:Identificador de Documento de Identidad" schemeAgencyName="PE:SUNAT" schemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06">' . $datos_emisor['ruc'] . '</cbc:CompanyID>
                                <cac:TaxScheme>
                                <cbc:ID schemeID="' . $datos_emisor['tipo_documento'] . '" schemeName="SUNAT:Identificador de Documento de Identidad" schemeAgencyName="PE:SUNAT" schemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06">' . $datos_emisor['ruc'] . '</cbc:ID>
                                </cac:TaxScheme>
                            </cac:PartyTaxScheme>
                            <cac:PartyLegalEntity>
                                <cbc:RegistrationName><![CDATA[' . $datos_emisor['razon_social'] . ']]></cbc:RegistrationName>
                                <cac:RegistrationAddress>
                                <cbc:ID schemeName="Ubigeos" schemeAgencyName="PE:INEI">' . $datos_emisor['ubigeo'] . '</cbc:ID>
                                <cbc:AddressTypeCode listAgencyName="PE:SUNAT" listName="Establecimientos anexos">0000</cbc:AddressTypeCode>
                                <cbc:CityName><![CDATA[' . $datos_emisor['provincia'] . ']]></cbc:CityName>
                                <cbc:CountrySubentity><![CDATA[' . $datos_emisor['departamento'] . ']]></cbc:CountrySubentity>
                                <cbc:District><![CDATA[' . $datos_emisor['distrito'] . ']]></cbc:District>
                                <cac:AddressLine>
                                    <cbc:Line><![CDATA[' . $datos_emisor['direccion'] . ']]></cbc:Line>
                                </cac:AddressLine>
                                <cac:Country>
                                    <cbc:IdentificationCode listID="ISO 3166-1" listAgencyName="United Nations Economic Commission for Europe" listName="Country">PE</cbc:IdentificationCode>
                                </cac:Country>
                                </cac:RegistrationAddress>
                            </cac:PartyLegalEntity>
                            <cac:Contact>
                                <cbc:Name><![CDATA[]]></cbc:Name>
                            </cac:Contact>
                        </cac:Party>
                    </cac:AccountingSupplierParty>';

        // DATOS DEL CLIENTE
        $xml .= '
                    <cac:AccountingCustomerParty>
                        <cac:Party>
                        <cac:PartyIdentification>
                            <cbc:ID schemeID="' . $datos_cliente['tipo_documento'] . '" schemeName="Documento de Identidad" schemeAgencyName="PE:SUNAT" schemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06">' . $datos_cliente['nro_documento'] . '</cbc:ID>
                        </cac:PartyIdentification>
                        <cac:PartyName>
                            <cbc:Name><![CDATA[' . $datos_cliente['nombres_apellidos_razon_social'] . ']]></cbc:Name>
                        </cac:PartyName>
                        <cac:PartyTaxScheme>
                            <cbc:RegistrationName><![CDATA[' . $datos_cliente['nombres_apellidos_razon_social'] . ']]></cbc:RegistrationName>
                            <cbc:CompanyID schemeID="' . $datos_cliente['tipo_documento'] . '" schemeName="SUNAT:Identificador de Documento de Identidad" schemeAgencyName="PE:SUNAT" schemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06">' . $datos_cliente['nro_documento'] . '</cbc:CompanyID>
                            <cac:TaxScheme>
                                <cbc:ID schemeID="' . $datos_cliente['tipo_documento'] . '" schemeName="SUNAT:Identificador de Documento de Identidad" schemeAgencyName="PE:SUNAT" schemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06">' . $datos_cliente['nro_documento'] . '</cbc:ID>
                            </cac:TaxScheme>
                        </cac:PartyTaxScheme>
                        <cac:PartyLegalEntity>
                            <cbc:RegistrationName><![CDATA[' . $datos_cliente['nombres_apellidos_razon_social'] . ']]></cbc:RegistrationName>
                            <cac:RegistrationAddress>
                                <cbc:ID schemeName="Ubigeos" schemeAgencyName="PE:INEI"/>
                                <cbc:CityName><![CDATA[]]></cbc:CityName>
                                <cbc:CountrySubentity><![CDATA[]]></cbc:CountrySubentity>
                                <cbc:District><![CDATA[]]></cbc:District>
                                <cac:AddressLine>
                                    <cbc:Line><![CDATA[' . $datos_cliente['direccion'] . ']]></cbc:Line>
                                </cac:AddressLine>                                        
                                <cac:Country>
                                    <cbc:IdentificationCode listID="ISO 3166-1" listAgencyName="United Nations Economic Commission for Europe" listName="Country"/>
                                </cac:Country>
                            </cac:RegistrationAddress>
                        </cac:PartyLegalEntity>
                        </cac:Party>
                    </cac:AccountingCustomerParty>';

        //FORMA DE PAGO:
        $xml .= '
                    <cac:PaymentTerms>
                            <cbc:ID>FormaPago</cbc:ID>
                            <cbc:PaymentMeansID>' . $venta['forma_pago'] . '</cbc:PaymentMeansID>
                    </cac:PaymentTerms>';

        //TOTAL DE IMPUESTOS:
        $xml .= '
                    <cac:TaxTotal>
                        <cbc:TaxAmount currencyID="' . $venta['moneda'] . '">' . number_format($venta['total_impuestos'], 2) . '</cbc:TaxAmount>
                        <cac:TaxSubtotal>
                            <cbc:TaxableAmount currencyID="' . $venta['moneda'] . '">' . number_format($venta['total_operaciones_gravadas'], 2) . '</cbc:TaxableAmount>
                            <cbc:TaxAmount currencyID="' . $venta['moneda'] . '">' . number_format($venta['total_igv'], 2) . '</cbc:TaxAmount>
                            <cac:TaxCategory>
                                <cbc:ID schemeID="UN/ECE 5305" schemeName="Tax Category Identifier" schemeAgencyName="United Nations Economic Commission for Europe">S</cbc:ID>
                                <cac:TaxScheme>
                                    <cbc:ID schemeID="UN/ECE 5153" schemeAgencyID="6">1000</cbc:ID>
                                    <cbc:Name>IGV</cbc:Name>
                                    <cbc:TaxTypeCode>VAT</cbc:TaxTypeCode>
                                </cac:TaxScheme>
                            </cac:TaxCategory>
                        </cac:TaxSubtotal>';

        if ($venta['total_operaciones_exoneradas'] > 0) {
            $xml .= '<cac:TaxSubtotal>
                            <cbc:TaxableAmount currencyID="' . $venta['moneda'] . '">' .  number_format($venta['total_operaciones_exoneradas'], 2) . '</cbc:TaxableAmount>
                            <cbc:TaxAmount currencyID="' . $venta['moneda'] . '">0.00</cbc:TaxAmount>
                            <cac:TaxCategory>
                                <cbc:ID schemeID="UN/ECE 5305" schemeName="Tax Category Identifier" schemeAgencyName="United Nations Economic Commission for Europe">E</cbc:ID>
                                <cac:TaxScheme>
                                <cbc:ID schemeID="UN/ECE 5153" schemeAgencyID="6">9997</cbc:ID>
                                <cbc:Name>EXO</cbc:Name>
                                <cbc:TaxTypeCode>VAT</cbc:TaxTypeCode>
                                </cac:TaxScheme>
                            </cac:TaxCategory>
                        </cac:TaxSubtotal>';
        }

        if ($venta['total_operaciones_inafectas'] > 0) {
            $xml .= '<cac:TaxSubtotal>
                            <cbc:TaxableAmount currencyID="' . $venta['moneda'] . '">' . number_format($venta['total_operaciones_inafectas'], 2) . '</cbc:TaxableAmount>
                            <cbc:TaxAmount currencyID="' . $venta['moneda'] . '">0.00</cbc:TaxAmount>
                            <cac:TaxCategory>
                                <cbc:ID schemeID="UN/ECE 5305" schemeName="Tax Category Identifier" schemeAgencyName="United Nations Economic Commission for Europe">O</cbc:ID>
                                <cac:TaxScheme>
                                <cbc:ID schemeID="UN/ECE 5153" schemeAgencyID="6">9998</cbc:ID>
                                <cbc:Name>INA</cbc:Name>
                                <cbc:TaxTypeCode>FRE</cbc:TaxTypeCode>
                                </cac:TaxScheme>
                            </cac:TaxCategory>
                        </cac:TaxSubtotal>';
        }
        //FIN TOTAL DE IMPUESTOS

        $xml .=     '</cac:TaxTotal>
                    <cac:LegalMonetaryTotal>
                        <cbc:LineExtensionAmount currencyID="' . $venta['moneda'] . '">' . number_format($venta['total_sin_impuestos'], 2) . '</cbc:LineExtensionAmount>
                        <cbc:TaxInclusiveAmount currencyID="' . $venta['moneda'] . '">' . number_format($venta['total_con_impuestos'], 2) . '</cbc:TaxInclusiveAmount>
                        <cbc:PayableAmount currencyID="' . $venta['moneda'] . '">' . number_format($venta['total_a_pagar'], 2) . '</cbc:PayableAmount>
                    </cac:LegalMonetaryTotal>';

        // INICIO INVOICE LINE
        foreach ($detalle_venta as $producto) {            

            $xml .= '<cac:InvoiceLine>
                            <cbc:ID>' . $producto['item'] . '</cbc:ID>
                            <cbc:InvoicedQuantity unitCode="' . $producto['unidad'] . '" unitCodeListID="UN/ECE rec 20" unitCodeListAgencyName="United Nations Economic Commission for Europe">' . $producto['cantidad'] . '</cbc:InvoicedQuantity>
                            <cbc:LineExtensionAmount currencyID="' . $venta['moneda'] . '">' . $producto['valor_total'] . '</cbc:LineExtensionAmount>
                            <cac:PricingReference>
                                <cac:AlternativeConditionPrice>
                                    <cbc:PriceAmount currencyID="' . $venta['moneda'] . '">' . number_format($producto['precio_unitario'], 2) . '</cbc:PriceAmount>
                                    <cbc:PriceTypeCode listName="Tipo de Precio" listAgencyName="PE:SUNAT" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo16">01</cbc:PriceTypeCode>
                                </cac:AlternativeConditionPrice>
                            </cac:PricingReference>
                            <cac:TaxTotal>
                                <cbc:TaxAmount currencyID="' . $venta['moneda'] . '">' . number_format($producto['igv'], 2) . '</cbc:TaxAmount>
                                <cac:TaxSubtotal>
                                    <cbc:TaxableAmount currencyID="' . $venta['moneda'] . '">' . $producto['valor_total'] . '</cbc:TaxableAmount>
                                    <cbc:TaxAmount currencyID="' . $venta['moneda'] . '">' . number_format($producto['igv'], 2) . '</cbc:TaxAmount>
                                    <cac:TaxCategory>
                                    <cbc:ID schemeID="UN/ECE 5305" schemeName="Tax Category Identifier" schemeAgencyName="United Nations Economic Commission for Europe">' . $producto['codigos'][0] . '</cbc:ID>
                                    <cbc:Percent>' . $producto['porcentaje_igv'] . '</cbc:Percent>
                                    <cbc:TaxExemptionReasonCode listAgencyName="PE:SUNAT" listName="Afectacion del IGV" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo07">' . $producto['codigos'][1] . '</cbc:TaxExemptionReasonCode>
                                    <cac:TaxScheme>
                                        <cbc:ID schemeID="UN/ECE 5153" schemeName="Codigo de tributos" schemeAgencyName="PE:SUNAT">' . $producto['codigos'][2] . '</cbc:ID>
                                        <cbc:Name>' . $producto['codigos'][3] . '</cbc:Name>
                                        <cbc:TaxTypeCode>' . $producto['codigos'][4] . '</cbc:TaxTypeCode>
                                    </cac:TaxScheme>
                                    </cac:TaxCategory>
                                </cac:TaxSubtotal>';

            $xml .= '</cac:TaxTotal>
                            <cac:Item>
                                <cbc:Description><![CDATA[' . $producto['descripcion'] . ']]></cbc:Description>
                                <cac:SellersItemIdentification>
                                    <cbc:ID><![CDATA[195]]></cbc:ID>
                                </cac:SellersItemIdentification>
                                <cac:CommodityClassification>
                                    <cbc:ItemClassificationCode listID="UNSPSC" listAgencyName="GS1 US" listName="Item Classification">10191509</cbc:ItemClassificationCode>
                                </cac:CommodityClassification>
                            </cac:Item>
                            <cac:Price>
                                <cbc:PriceAmount currencyID="' . $venta['moneda'] . '">' . $producto['valor_unitario'] . '</cbc:PriceAmount>
                            </cac:Price>
                        </cac:InvoiceLine>';
        }
        $xml .= '</Invoice>';

        $doc->loadXML($xml);
        $doc->save($path_xml . $name_xml . '.XML');

        return "generado xml";
    }

    static public function EnviarComprobanteElectronico($path_xml, $name_xml, $datos_emisor, $path_file_cdr)
    {

        //FIRMAR DIGITALMENTE EL XML
        $signature = new Signature();

        $nodo_a_firmar = "0";
        $ruta_xml = $path_xml . $name_xml . '.XML';

        $ruta_certificado = "../fe/certificado/certificado_phperu.pfx";
        $password_certificado = "Emilia1109$";

        $response_signature = $signature->signature_xml($nodo_a_firmar, $ruta_xml, $ruta_certificado, $password_certificado);

        //GENERAMOS EL ARCHIVO ZIP
        $zip = new ZipArchive();

        $nombrezip = $name_xml . ".ZIP";
        $rutazip =  $path_xml . $name_xml . ".ZIP";

        if ($zip->open($rutazip, ZIPARCHIVE::CREATE) === true) {
            $zip->addFile($ruta_xml, $name_xml . '.XML');
            $zip->close();
        }

        //GENERAMOS EL ENVIO A LA SUNAT (AMBIENTE BETA)

        $ws = "https://e-beta.sunat.gob.pe/ol-ti-itcpfegem-beta/billService";

        $ruta_archivo_zip = $rutazip;
        $nombre_archivo_zip = $nombrezip;

        $archivo_zip_base64 = base64_encode(file_get_contents($ruta_archivo_zip));

        $xml_envio = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://service.sunat.gob.pe" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
				 <soapenv:Header>
				 	<wsse:Security>
				 		<wsse:UsernameToken>
				 			<wsse:Username>' . $datos_emisor['ruc'] . $datos_emisor['usuario_sol'] . '</wsse:Username>
				 			<wsse:Password>' . $datos_emisor['clave_sol'] . '</wsse:Password>
				 		</wsse:UsernameToken>
				 	</wsse:Security>
				 </soapenv:Header>
				 <soapenv:Body>
				 	<ser:sendBill>
				 		<fileName>' . $nombre_archivo_zip . '</fileName>
				 		<contentFile>' . $archivo_zip_base64 . '</contentFile>
				 	</ser:sendBill>
				 </soapenv:Body>
				</soapenv:Envelope>';


        $header = array(
            "Content-type: text/xml; charset=\"utf-8\"",
            "Accept: text/xml",
            "Cache-Control: no-cache",
            "Pragma: no-cache",
            "SOAPAction: ",
            "Content-lenght: " . strlen($xml_envio)
        );


        $ch = curl_init();
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 1);
        curl_setopt($ch, CURLOPT_URL, $ws);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_ANY);
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $xml_envio);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $header);

        $response = curl_exec($ch);

        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $estado_respuesta_sunat = "0";

        $resultado["nombre_xml"] = $name_xml . '.XML';
        $resultado["xml_base64"] = base64_encode(file_get_contents($ruta_xml));
        $resultado["mensaje_respuesta_sunat"] = '';
        $resultado["codigo_error_sunat"] = '';
        $resultado["hash_signature"] = $response_signature['hash_cpe'];
        $resultado["estado_respuesta_sunat"] = $estado_respuesta_sunat;


        if ($http_code == 200) { //200->La comunicación fue satisfactoria

            $document = new DOMDocument();
            $document->loadXML($response);

            if (isset($document->getElementsByTagName('applicationResponse')->item(0)->nodeValue)) {

                $applicationResponse = $document->getElementsByTagName('applicationResponse')->item(0)->nodeValue;
                $applicationResponse = base64_decode($applicationResponse);

                file_put_contents($path_file_cdr . "R-" . $nombrezip, $applicationResponse);

                $obj_zip = new ZipArchive;

                //EXTRAER ARCHIVO ZIP (CDR)
                if ($obj_zip->open($path_file_cdr . "R-" . $nombrezip) === true) {
                    $obj_zip->extractTo($path_file_cdr, 'R-' . $name_xml . '.XML');
                    $obj_zip->close();
                }

                $estado_respuesta_sunat = "1";

                $doc_cdr = new DOMDocument();
                $datos_cdr = file_get_contents($path_file_cdr . 'R-' . $name_xml . '.XML');
                $doc_cdr->loadXML($datos_cdr);
                $mensaje_respuesta_sunat = $doc_cdr->getElementsByTagName("Description")->item(0)->nodeValue;

                $resultado['mensaje_respuesta_sunat'] = $mensaje_respuesta_sunat;
                $resultado['xml_cdr_sunat_base64'] = base64_encode($datos_cdr);
            } else {

                $estado_respuesta_sunat = "2";
                $codigo_error_sunat = $document->getElementsByTagName("faultcode")->item(0)->nodeValue;
                $mensaje_respuesta_sunat = $document->getElementsByTagName("faultstring")->item(0)->nodeValue;

                $resultado['codigo_error_sunat'] = $codigo_error_sunat;
                $resultado['mensaje_respuesta_sunat'] = $mensaje_respuesta_sunat;
            }
        } else {

            $estado_respuesta_sunat = "3";
            $resultado['mensaje_respuesta_sunat'] = "ERROR DE CONEXION";
            $resultado['codigo_error_sunat'] = "-1";
        }
        $resultado['estado_respuesta_sunat'] = $estado_respuesta_sunat;

        curl_close($ch);

        return $resultado;
    }
}
