<?php

require_once "../modelos/compras.modelo.php";
require_once "../modelos/ventas.modelo.php";
require "../vendor/autoload.php";

use Dompdf\Dompdf;

/* ===================================================================================  */
/* P O S T   P E T I C I O N E S  */
/* ===================================================================================  */

if (isset($_POST["accion"])) {

    switch ($_POST['accion']) {

        case 'obtener_compras':

            $response = ComprasModelo::mdlObtenerCompras($_POST);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;


        case 'obtener_compra_x_id':

            $response = ComprasModelo::mdlObtenerCompraPorId($_POST["id_compra"]);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;


        case 'obtener_detalle_compra_x_id':

            $response = ComprasModelo::mdlObtenerDetalleCompraPorId($_POST["id_compra"]);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        case 'obtener_simbolo_moneda':

            $response = ComprasModelo::mdlObtenerSimboloMoneda($_POST['moneda']);
            echo json_encode($response);
            break;

        case 'registrar_compra':

            //DATOS DE LA COMPRA
            $formulario_compra = [];
            parse_str($_POST['datos_compra'], $formulario_compra);

            //DETALLA DE LA  COMPRA
            $detalle_productos = json_decode($_POST["arr_detalle_productos"]);

            $response = ComprasModelo::mdlRegistrarCompra(
                $formulario_compra,
                $detalle_productos,
                $_POST["ope_gravadas"],
                $_POST["ope_exoneradas"],
                $_POST["ope_inafectas"],
                $_POST["total_igv"],
                $_POST["total_descuento"],
                $_POST["total"]
            );
            echo json_encode($response);

            break;

        case 'actualizar_compra':

            //DATOS DE LA COMPRA
            $formulario_compra = [];
            parse_str($_POST['datos_compra'], $formulario_compra);

            //DETALLA DE LA  COMPRA
            $detalle_productos = json_decode($_POST["arr_detalle_productos"]);

            $response = ComprasModelo::mdlActualizarCompra(
                $formulario_compra,
                $detalle_productos,
                $_POST["ope_gravadas"],
                $_POST["ope_exoneradas"],
                $_POST["ope_inafectas"],
                $_POST["total_igv"],
                $_POST["total_descuento"],
                $_POST["total"]
            );

            echo json_encode($response);

            break;

        case 'confirmar_compra':

            $response = ComprasModelo::mdlConfirmarCompra($_POST["serie"], $_POST["correlativo"], $_POST["id_compra"]);
            echo json_encode($response);
            break;

        case 'mostrar_detalle_compra_x_id':

            $response = ComprasModelo::mdlMostrarDetalleCompraPorId($_POST["id_compra"]);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        default:
            # code...
            break;
    }
}

/* ===================================================================================  */
/* G E T   P E T I C I O N E S  */
/* ===================================================================================  */
if (isset($_GET["accion"])) {

    switch ($_GET["accion"]) {

        case 'generar_pdf_compra':

            $compra = ComprasModelo::mdlImpresionObtenerCompraPorId($_GET["id_compra"]);
            $detalle_compra = ComprasModelo::mdlObtenerDetalleCompraPorId($_GET["id_compra"]);
            $datos_emisor = VentasModelo::mdlObtenerDatosEmpresa(1);

            ob_start();

            require "impresion_compra.php";

            $html = ob_get_clean();

            $dompdf = new Dompdf();

            $dompdf->loadHtml($html);
            $dompdf->setpaper('A4');
            $dompdf->render();
            $dompdf->stream('registro_comra' . $_GET["id_compra"] . '.pdf', array('Attachment' => false));

            break;
    }
}
